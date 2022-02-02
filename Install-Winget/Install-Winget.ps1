# Define Sources, Hashes, Constants and Program Lists in Hashes
$ConfigTable = Import-PowerShellDataFile "$PSScriptRoot\config\install-config.psd1"
$ProgramSets = $ConfigTable["ProgramSets"]
$DefaultOptions = $ConfigTable["DefaultOptions"]
$PackageParams = $ConfigTable["PackageParams"]
$PythonLibs = $ConfigTable["PythonLibs"]

# Required Constants
$Sources = @("", "winget", "msstore")
$NotInstalledString = "No installed package found matching input criteria."
$Log = ".\installer.log"
"" | Out-File -FilePath $Log

# Functions
function Logger {
    param(
        [parameter(ValueFromPipeline=$true, Mandatory=$false)]$piped,
        [string]$Message
    )
    if(!$piped){
        $Message | Tee-Object -File $Log -Append | Write-Host
    }
    else{
        $piped | Tee-Object -File $Log -Append | Write-Host
    }
}

function Install-Package-Command-String {
    param (
        [string]$Package, 
        [string]$SourceNum,
        [hashtable]$PackageParams,
        [hashtable]$OtherParameters
    )

    $QueryString = "'" + $Package + "'"

    if($SourceNum -ne 0){
        $QueryString = $QueryString + " -s " + $Sources[$SourceNum]
    }
    
    if($null -ne $PackageParams){
        ForEach($Option in $PackageParams.Keys){
            $QueryString = $QueryString + " " + $Option + " " + $PackageParams[$Option]
        }
    }

    # Before Adding Default Parameters, create the CheckInstallString
    $CheckInstallString = "winget list -q " + $QueryString

    # Check if Already Exists
    $scriptBlock = [Scriptblock]::Create($CheckInstallString)
    $exist = Start-Job -ScriptBlock $scriptBlock
    $ToThrow = Wait-Job $exist; # Powershell has weird return semantics.
    $exists = Receive-Job $exist

    if($exists -is [System.Array]){
        $exists = $exists[-1];
    }

    Logger -Message "Package: $Package"

    if($exists.Contains($NotInstalledString)){    
        # Add Default Installer Parameters
        if($OtherParameters -ne $null){
            ForEach($Option in $OtherParameters.Keys){
                $QueryString = $QueryString + " " + $Option + " " + $OtherParameters[$Option]
            }
        }
        
        # Install
        $InstallString = "winget install " + $QueryString
        $message = "`tCommand: " + $InstallString
        
        # Log and Send Installer Job
        Logger -Message $message
        return $InstallString
    }
    else{
        # No Install Job required, send Null Command
        $mes = "`tAlready installed, skipping."
        Logger -Message $mes
        return "$null"
    }
}

function Install-From-Hashes {
    param(
        [hashtable]$Programs
    )
    
    $Jobs = foreach($Package in $Programs.Keys){   
    
        if($null -eq $PackageParams[$Package]) {
            $blockstring = Install-Package-Command-String `
                -Package $Package `
                -SourceNum $Programs[$Package] `
                -OtherParameters $DefaultOptions;
        }
        else {
            $blockstring = Install-Package-Command-String `
                -Package $Package `
                -SourceNum $Programs[$Package] `
                -PackageParams $PackageParams[$Package] `
                -OtherParameters $DefaultOptions;
        }

        $scriptBlock = [Scriptblock]::Create($blockstring);
        Start-Job -ScriptBlock $scriptBlock
    }
    
    # Wait For all Install Jobs to Finish
    $ToThrow = Wait-Job $Jobs
    
    $ResultLogRequired = 1;

    foreach ($Job in $Jobs){
        $Output = Receive-Job $Job
    
        # Skipped Install
        if($null -eq $Output){
            continue;
        }
        
        $ResultLogRequired = 0;
        if(-not $ResultLogRequired){
            Logger -Message "`r`nAction Log: "
        }

        if($Output -Contains "Successfully installed"){
            $ResultLog = "Successfully Installed."
        }
        else {
            $ResultLog = "Failed to Install."
        }

        $ResultLog = $Job.Command.Split("'")[1] + ": " + $ResultLog;
        Logger -Message $ResultLog
    }
}

########################
# Install Program Sets #
########################
$SetNum = 1
foreach($Set in $ProgramSets){
    Logger -Message "Installing Set $SetNum.."
    Install-From-Hashes -Programs $Set
    $SetNum += 1
}

Logger -Message "Updating Session PATH.."
$env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User") 

############################
# Install Python Libraries #
############################

if($PythonLibs.Length -eq 0){
    Logger -Message "No Python Libraries Found in Config.. Exiting"
    exit(1)
}

Logger -Message "Installing Python Libraries.."
Logger -Message "using Pip to install.."
foreach($PythonLib in $PythonLibs){
    pip install $PythonLib | Logger
}