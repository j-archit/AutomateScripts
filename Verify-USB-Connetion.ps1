$ID = $env:HDDID
$ScriptPath = $env:DIRSYNCSCRIPT
$Log = $env:DIRSYNCDEFLOG

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

$Timestamp = Get-Date
Logger -LogFile $Log -Message "`n$Timestamp"
Logger -LogFile $Log -Message "USB Connected, Starting Drive Check`nCheck Drive ID: $ID"

$FilterHash = @{
    LogName = "Microsoft-Windows-DriverFrameworks-UserMode/Operational"
    ID = 2006
}

$Event = Get-WinEvent -FilterHashtable $FilterHash -MaxEvents 1
$OutputXML = $Event.ToXml()

if(!$OutputXML.Contains($ID)) {
    Logger -LogFile $Log -Message "Check Failed, Event XML:`n$OutputXML"
 }
else{
    Logger -LogFile $Log -Message "Check Succeded, Starting Dir-Sync.ps1"
    pwsh.exe -WindowStyle Hidden $ScriptPath -purge True
}
