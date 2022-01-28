# Requirements: dirsync via python or an executable on path
param (
    [string]$purge,
    [string]$diff,
    [double]$InitSleep
)

$ErrorActionPreference = "Stop";
$DateTime = Get-Date
$DateTime = $DateTime.ToString()
$DefaultLog = "$env:USERPROFILE\AutoDirSync.log"

#######################################
# Logging

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

#######################################
# Get/Set Target and Sources

try{
    $TargetDrive = (Get-Volume -FileSystemLabel Archit).DriveLetter + ":"
}
catch{
    Logger -Message $DateTime -LogFile $DefaultLog
    Logger -Message "Target Drive Not Found!`r`nExiting" -LogFile $DefaultLog
    exit(-1)
}

$TargetDriveCUserData = "\C\UserData"
$TargetDriveData = "\Data"
$TargetLogDir = "$TargetDrive\Dir-Sync\logs\"
$TargetLog = "$TargetLogDir\adir-sync.log"

# Data Source Drive
$DataDrive = (Get-Volume -FileSystemLabel Data).DriveLetter + ":"

#######################################
# Set Tasks and Options

$DefaultOptions = @("--verbose")
if($purge -ieq "true" ){$DefaultOptions += "--purge"}
if($diff -ieq "true" ){$DefaultOptions += "--diff"}

$Tasks = @{
    "$DataDrive\" = 
    @{
        Target = "$TargetDrive\$TargetDriveData\"
        Log = "$TargetLogDir\data-sync.log"
        Options = @{"--exclude" = @("^Games.Control.*", "^\$", "^Xilinx.*")}
    }
    
    "$env:USERPROFILE\OneDrive\Documents" = 
    @{
        Target = "$TargetDrive$TargetDriveCUserData\Documents"
        Log = "$TargetLogDir\docs-sync.log"
        Options = @{"--exclude" = @(".*Assassin's Creed Valhalla/cache.*")}
    }

    "$env:USERPROFILE\OneDrive\Desktop" = 
    @{
        Target = "$TargetDrive$TargetDriveCUserData\Desktop"
        Log ="$TargetLogDir\desk-sync.log"
        Options = @{}
    }
    
    "$env:USERPROFILE\Downloads" = 
    @{
        Target = "$TargetDrive$TargetDriveCUserData\Downloads"
        Log = "$TargetLogDir\down-sync.log"
        Options = @{}
    }
    
    "$env:USERPROFILE\OneDrive\Pictures" = 
    @{
        Target = "$TargetDrive$TargetDriveCUserData\Pictures"
        Log = "$TargetLogDir\pics-sync.log"
        Options = @{}
    }
    
    "$env:USERPROFILE\Videos" = 
    @{
        Target = "$TargetDrive$TargetDriveCUserData\Videos"
        Log = "$TargetLogDir\vids-sync.log"
        Options = @{}
    }
}

#######################################
# Main Program

Logger -Message "------------------------------------------------`r`n@Starting AutoDirSync.. at $DateTime`r`n------------------------------------------------" -LogFile $TargetLog
Logger -Message "Sleeping for $InitSleep Seconds; to allow for interruptions to scheduled sync task if required, as it is destructive in nature." -LogFile $TargetLog
Logger -Message "Defaut Options:" -LogFile $TargetLog
Write-Output $DefaultOptions | Logger -LogFile $TargetLog
Start-Sleep -Seconds $InitSleep

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
    $ThrowVar = Logger -Message "------------`r`nStarting Job`r`n------------`r`n`tSource: '$Source'`r`n`tTarget: '$Target'`r`n`tLogfile: '$Log'`r`n`tCommandBlock:`r`n`t`t$block" -LogFile $TargetLog

    Start-Job -ScriptBlock $block
}

$ThrowVar = Wait-Job $Jobs

$DateTime = Get-Date
$DateTime = $DateTime.ToString()
Logger -Message "--------------------------------------------`r`nAll Tasks Finished at $DateTime`r`n--------------------------------------------`r`n`r`n`r`n" -LogFile $TargetLog

exit(0)