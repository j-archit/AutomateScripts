$ErrorActionPreference = "Stop";
$DateTime = Get-Date
$DateTime = $DateTime.ToString()
$DefaultLog = "$env:USERPROFILE/AutoDirSync.log"

# Requirements: dirsync via python or an executable on path

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
    $TargetLog = "$TargetDrive/AutoDirSync.log"
}
catch{
    Logger -Message $DateTime -LogFile $DefaultLog
    Logger -Message "Target Drive Not Found!`r`nExiting" -LogFile $DefaultLog
    exit(-1)
}

$TargetDriveCUserData = "\C\UserData"
$TargetDriveData = "\Data"

# Data Source Drive
$DataDrive = (Get-Volume -FileSystemLabel Data).DriveLetter + ":"

#######################################
# Set Tasks and Options
$DefaultOptions = @("--verbose", "--diff", "")

$Tasks = @{
    "$DataDrive\" = 
    @("$TargetDrive\$TargetDriveData\", "$TargetDrive/AutoDirSync.data.log")
    
    "$env:USERPROFILE\OneDrive\Documents" = 
    @("$TargetDrive$TargetDriveCUserData\Documents", "$TargetDrive\AutoDirSync.docs.log")

    "$env:USERPROFILE\OneDrive\Desktop" = 
    @("$TargetDrive$TargetDriveCUserData\Desktop", "$TargetDrive\AutoDirSync.desk.log")
    
    "$env:USERPROFILE\OneDrive\Downloads" = 
    @("$TargetDrive$TargetDriveCUserData\Downloads", "$TargetDrive\AutoDirSync.down.log")    
    
    "$env:USERPROFILE\OneDrive\Pictures" = 
    @("$TargetDrive$TargetDriveCUserData\Pictures", "$TargetDrive\AutoDirSync.pics.log")
    
    "$env:USERPROFILE\Videos" = 
    @("$TargetDrive$TargetDriveCUserData\Videos", "$TargetDrive\AutoDirSync.vids.log")
}


#######################################
# Main Program

Logger -Message "$DateTime`r`nStarting AutoDirSync.." -LogFile $TargetLog

$Jobs = foreach ($Source in $Tasks.Keys){
    $SourceOptions = $Tasks[$Source]
    $Target = $SourceOptions[0]
    $Log = $SourceOptions[1]
    $CommandString = "dirsync '$Source' '$Target' "
    
    # Append Default Options
    $ToThrow = foreach($Option in $DefaultOptions){
        $CommandString += "$Option "
    }

    # Individual Tasks Logs
    $CommandString += " *> '$Log' "
    $block = [Scriptblock]::Create($CommandString)
    
    # Main Target Log
    $haha = Logger -Message "Starting Job`r`n`tSource: $Source`r`n`tTarget: $Target`r`n`tLogfile: $Log`r`n`tCommandBlock:`r`n`t`t$block" -LogFile $TargetLog

    Start-Job -ScriptBlock $block
}

$Redndnt = Wait-Job $Jobs

$DateTime = Get-Date
$DateTime = $DateTime.ToString()
Logger -Message "-----------------------------------------------`r`nAll Tasks Finished at $DateTime`r`n-----------------------------------------------" -LogFile $TargetLog

exit(0)