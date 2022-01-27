# Define Sources, Hashes, Constants and Program Lists in Hashes
$s1 = "winget"
$s2 = "msstore"

$NotInstalledString = "No installed package found matching input criteria."
$Log = ".\installer.log"
"" | Out-File -FilePath $Log


$DefaultOptionsHash = @{
    '--accept-source-agreements'  = ""
    '--accept-package-agreements' = ""
    '-h' = ""
    }

$MainPrograms = @{
    "vscode"   = $s1
    "Python 3" = $s1
    "Windows Terminal" = $s1
    "obs" = $s1
    "onenote for windows 10" = $s2
    "discord" = $s1
    "VLC media player" = $s1
    "Spotify" = $s2
    "Whatsapp" = $s2
    "git" = $s1
    "NVIDIA GeForce Experience" = $s1
    "Octave" = $s1
}

$SecondaryPrograms = @{
    "7-Zip" = $s1
    "libreoffice" = $s1
    "ModernFlyouts" = $s1
    "GeoGebra Classic" = $s1
}

$PackageParams = @{
    "Geogebra Classic" = 
    @{"--id" = "Geogebra.Classic"}
}

$PythonLibs = @(
    'numpy', 
    'scipy', 
    'python-dotenv', 
    'psycopg2', 
    'nuitka'
)

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
        [string]$Source,
        [hashtable]$PackageParams,
        [hashtable]$OtherParameters
    )

    $QueryString = "'" + $Package + "'"

    if($Source -ne ""){
        $QueryString = $QueryString + " -s " + $Source
    }
    
    if($PackageParams -ne $null){
        ForEach($Option in $PackageParams.Keys){
            $QueryString = $QueryString + " " + $Option + " " + $PackageParams[$Option]
        }
    }

    # Before Adding Default Parameters, create the CheckInstallString
    $CheckInstallString = "winget list -q " + $QueryString

    # Add Default Installer Parameters
    if($OtherParameters -ne $null){
        ForEach($Option in $OtherParameters.Keys){
            $QueryString = $QueryString + " " + $Option + " " + $OtherParameters[$Option]
        }
    }

    # Check if Already Exists
    $scriptBlock = [Scriptblock]::Create($CheckInstallString)
    $exist = Start-Job -ScriptBlock $scriptBlock
    $this_is_to_stop_the_object_being_put_to_the_output_stream = Wait-Job $exist; # Powershell has weird return semantics.
    $exists = Receive-Job $exist

    if($exists -is [System.Array]){
        $exists = $exists[-1];
    }

    Logger -Message "Package: $Package"

    if($exists.Contains($NotInstalledString)){
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
    
        if($PackageParams[$Package] -eq $null) {
            $blockstring = Install-Package-Command-String `
                -Package $Package `
                -Source $Programs[$Package] `
                -OtherParameters $DefaultOptionsHash;
        }
        else {
            $blockstring = Install-Package-Command-String `
                -Package $Package `
                -Source $Programs[$Package] `
                -PackageParams $PackageParams[$Package] `
                -OtherParameters $DefaultOptionsHash;
        }

        $scriptBlock = [Scriptblock]::Create($blockstring);
        Start-Job -ScriptBlock $scriptBlock
    }
    
    # Wait For all Install Jobs to Finish
    $tisofbpttop = Wait-Job $Jobs
    
    $ResultLogRequired = 1;

    foreach ($Job in $Jobs){
        $Output = Receive-Job $Job
    
        # Skipped Install
        if($Output -eq $null){
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


#############################
# Install Required Programs #
#############################

Logger -Message "Installing Required Programs.. "
Install-From-Hashes -Programs $MainPrograms

############################
# Install Python Libraries #
############################

Logger -Message "Installing Python Libraries.."
Logger -Message "Updating Session PATH.."

$env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User") 

Logger -Message "using Pip to install.."
foreach($PythonLib in $PythonLibs){
    pip install $PythonLib | Logger
}

##############################
# Install Secondary Programs #
##############################

Logger -Message "Installing Secondary Programs.. "
Install-From-Hashes -Programs $SecondaryPrograms