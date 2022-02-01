#!"C:\Program Files\PowerShell\7\pwsh.exe"
$ConfigTable = Import-PowerShellDataFile $env:DIRSYNCCONFIG
$HDD_LABELS_IDS = $ConfigTable["HDD_LABELS_IDS"]
$ScriptPath = $ConfigTable["DIRSYNCSCRIPT"]
$Log = $ConfigTable["DIRSYNCDEFLOG"]

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

$HDD_IDS = $HDD_LABELS_IDS.Values
$Timestamp = Get-Date
Logger -LogFile $Log -Message "`n$Timestamp"
Logger -LogFile $Log -Message "USB Connected, Starting Drive Check`nCheck Drive IDs: $HDD_IDS"

$FilterHash = @{
    LogName = "Microsoft-Windows-DriverFrameworks-UserMode/Operational"
    ID = 2006
}

$EventLog = Get-WinEvent -FilterHashtable $FilterHash -MaxEvents 1
$OutputXML = $EventLog.ToXml()

$flag = 0
foreach ($LABEL in $HDD_LABELS_IDS.Keys){
    $ID = $HDD_LABELS_IDS[$LABEL]
    if(!$OutputXML.Contains($ID)) {
        continue
    }
    else{
        $flag = 1
        Logger -LogFile $Log -Message "Check Succeded`nFound Drive = $ID`nLabel = $LABEL`nStarting Dir-Sync.ps1"
        pwsh.exe -WindowStyle Hidden $ScriptPath
        break
    }
}
if(!$flag){
    Logger -LogFile $Log -Message "Check Failed, Event XML:`n$OutputXML"
}
