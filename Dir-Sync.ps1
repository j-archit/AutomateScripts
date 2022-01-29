# Requirements: dirsync via python or an executable on path
param (
    [string]$purge,
    [string]$diff,
    [double]$InitSleep
)

$ErrorActionPreference = "Stop";
$DateTime = Get-Date
$DateTime = $DateTime.ToString()
$DefaultLog = "$env:USERPROFILE\adir-sync.log"

#######################################
# Functions and Parameters

$PSDefaultParameterValues = @{
    "InitSleep" = 15
    "Notify-Popup:Delay" = 0
    "Notify-Popup:Flag" =  1
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

#######################################
# Get/Set Target and Sources
# Note that this section is not important for the script in general.
# You should set up your own sources with hardcoded 
# absolute paths in the Tasks Hashtable as required.

try{
    $TargetDrive = (Get-Volume -FileSystemLabel Archit).DriveLetter + ":"
}
catch{
    Logger -Message $DateTime -LogFile $DefaultLog
    Logger -Message "Target Drive Not Found!`nExiting" -LogFile $DefaultLog
    exit(-1)
}

# Data Source Drive
$DataDrive = (Get-Volume -FileSystemLabel Data).DriveLetter + ":"
$MediaDrive = (Get-Volume -FileSystemLabel Media).DriveLetter + ":"

#######################################
# Set Tasks and Options

$TargetLogDir = "$TargetDrive\dir-sync\logs\"
$TargetLog = "$TargetLogDir\adir-sync.log"

try{
    mkdir $TargetLogDir | Out-Null
} catch {}

$TargetDriveCUserData = "\C\UserData"

$DefaultOptions = @("--verbose")
if($purge -ieq "true" ){$DefaultOptions += "--purge"}
if($diff -ieq "true" ){$DefaultOptions += "--diff"}

$Tasks = @{

    "$DataDrive\" = 
    @{
        Target = "$TargetDrive\Data"
        Log = "$TargetLogDir\data.log"
        Options = @{"--exclude" = @("^Games.Control.*", "^\$", "^Xilinx.*")}
    }
    
    "$MediaDrive\" = 
    @{
        Target = "$TargetDrive\Media"
        Log = "$TargetLogDir\media.log"
        Options = @{"--exclude" = @("^\$")}
    }

    "$env:USERPROFILE\OneDrive\Documents" = 
    @{
        Target = "$TargetDrive$TargetDriveCUserData\Documents"
        Log = "$TargetLogDir\docs.log"
        Options = @{"--exclude" = @(".*Assassin's Creed Valhalla/cache.*")}
    }

    "$env:USERPROFILE\OneDrive\Desktop" = 
    @{
        Target = "$TargetDrive$TargetDriveCUserData\Desktop"
        Log ="$TargetLogDir\desk.log"
        Options = @{}
    }
    
    "$env:USERPROFILE\Downloads" = 
    @{
        Target = "$TargetDrive$TargetDriveCUserData\Downloads"
        Log = "$TargetLogDir\down.log"
        Options = @{}
    }
    
    "$env:USERPROFILE\OneDrive\Pictures" = 
    @{
        Target = "$TargetDrive$TargetDriveCUserData\Pictures"
        Log = "$TargetLogDir\pics.log"
        Options = @{}
    }
    
    "$env:USERPROFILE\Videos" = 
    @{
        Target = "$TargetDrive$TargetDriveCUserData\Videos"
        Log = "$TargetLogDir\vids.log"
        Options = @{}
    }
}

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
    $Target = $SourceOptions["Target"]
    $Log = $SourceOptions["Log"]
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