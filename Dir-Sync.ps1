# Requirements: dirsync via python or an executable on path
param (
    [double]$InitSleep
)

$ErrorActionPreference = "Stop";
$DateTime = Get-Date
$DateTime = $DateTime.ToString()

############################
# Functions and Parameters #
############################

$PSDefaultParameterValues = @{
    "Notify-Popup:Delay" = 0
    "Notify-Popup:Flag" =  1
}
if($InitSleep -ne $null){
    $InitSleep = 5
}

function Logger {
    param(
        [parameter(ValueFromPipeline=$true, Mandatory=$false)]$piped,
        [string]$Message,
        [string]$LogFile
    )
    if($piped){
        $Message = $piped
    }
    $Message | Tee-Object -FilePath $LogFile -Append | Write-host
}

function Notify-Popup {
    param(
        [string]$Message,
        $Delay,
        $Flag
    )
    $wshell = New-Object -ComObject Wscript.Shell
    $wshell.popup($Message, $Delay, "Dir-Sync Backup", $Flag)
}

function Get-Volume-Info-By-Label{
    param(
        [string]$Label
    )
    try{
        $temp = Get-Volume
        foreach($VOL in $temp){
            if($VOL.FileSystemLabel -eq $Label){
                return $VOL
            }
            else{
                continue
            }
        }
    }
    catch{
        # For Systems that Do not have Get-Volume
    }
}

function Get-Target-Root {
    # Returns the First Match Only. 
    # So Plug Only One at a time.
    param(
        [array]$HDD_Labels
    )
    $FOUND = $null
    foreach($Label in $HDD_Labels){
        $Rec = Get-Volume-Info-By-Label -Label $Label
        if($null -ne $Rec){
            $FOUND = $Rec
            return $FOUND.DriveLetter
        }
    }
    return $FOUND
}

##########################
# Get Configuration Data #
##########################
# Requires Environment
# Variable DIRSYNCCONFIG be set to the default .psd1 data file
$ConfigTable = Import-PowerShellDataFile $env:DIRSYNCCONFIG
$HDD_LABELS_IDS = $ConfigTable["HDD_LABELS_IDS"]
$DefaultLog = $ConfigTable["DIRSYNCDEFLOG"]

# Get Target Drive
$TargetRoot = Get-Target-Root -HDD_Labels $HDD_LABELS_IDS.Keys
if($null -eq $TargetRoot){
    Logger -Message "No Configured Targets Found. Exiting!" -LogFile $DefaultLog
    exit(-1)
}

$TargetSyncDir = $TargetRoot + ":\" + $ConfigTable["FirstLevelSyncDir"]
$Tasks = $ConfigTable["Tasks"]

$TargetLogDir = $TargetSyncDir + $ConfigTable["TargetLogDir"]
$TargetLog = "$TargetLogDir\adir-sync.log"
mkdir -Force $TargetLogDir | Out-Null

$DefaultOptions = $ConfigTable["DefaultOptions"]

#######################################
# Main Program

Logger -Message "----------------------------------------------`n@Starting Dir-Sync.. at $DateTime`n----------------------------------------------" -LogFile $TargetLog
Logger -Message "Sleeping for $InitSleep Seconds; to allow for interruptions to `nscheduled sync task if required, as it is destructive in nature." -LogFile $TargetLog
Logger -Message "Defaut Options:" -LogFile $TargetLog
Write-Output $DefaultOptions | Logger -LogFile $TargetLog
Start-Sleep -Seconds $InitSleep
$Okay = Notify-Popup -Message "Starting Tasks. `nPress Ok to Continue or Cancel to Stop Sync" -Flag 33

if($Okay -eq 2){ 
    $Okay = Notify-Popup -Message "Sync Task Cancelled" -Flag 64
    Logger -Message "! Sync Task Aborted by User." -LogFile $TargetLog
    exit(2) 
}

$Jobs = foreach ($Source in $Tasks.Keys){
    $SourceOptions = $Tasks[$Source]
    $Target = $TargetSyncDir + $SourceOptions["Target"]
    $Log = $TargetSyncDir + $SourceOptions["Log"]
    $SpecificOptions = $SourceOptions["Options"]

    $CommandString = "dirsync '$Source' '$Target' "
    
    # Append Default Options
    $ThrowVar = foreach($Option in $DefaultOptions){
        $CommandString += "$Option "
    }

    # Append Source Specific Options
    $ThrowVar = foreach($Option in $SpecificOptions.Keys){
        $CommandString += "$Option "
        if($SpecificOptions[$Option] -is [System.Array])
        {
            $Array = $SpecificOptions[$Option];
            foreach($Value in $Array){
                $CommandString += '"' + $Value + '" '
            }
        }
        else{
            $CommandString += "'$SpecificOptions[$Option]' "
        }
    }

    # Individual Tasks Logs
    $CommandString += " *> '$Log' "
    $block = [Scriptblock]::Create($CommandString)
    
    # Main Target Log
    $ThrowVar = Logger -Message "------------`nStarting Job`n------------`n`tSource: '$Source'`n`tTarget: '$Target'`n`tLogfile: '$Log'`n`tCommandBlock:`n`t`t$block" -LogFile $TargetLog

    Start-Job -ScriptBlock $block
}

$ThrowVar = Wait-Job $Jobs

$DateTime = Get-Date
$DateTime = $DateTime.ToString()
Logger -Message "--------------------------------------------`nAll Tasks Finished at $DateTime`n--------------------------------------------`n`n`n" -LogFile $TargetLog

$Okay = Notify-Popup -Message "Sync Tasks Completed!" -Flag 64
exit(0)