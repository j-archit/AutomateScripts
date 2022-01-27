# Define Sources, Hashes, Constants and Program Lists in Hashes
$s1 = "winget"
$s2 = "msstore"

$NotInstalledString = "No installed package found matching input criteria."
$Log = ".\installer.log"
"" | Out-File -FilePath $Log


$DefaultOptionsHash = @{
    '--accept-source-agreements'  = ""
    '--accept-package-agreements' = ""
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
    "Geogebra Classic" = $s1
}

$PackageParams = @{
    "Geogebra Classic" = @{
                            "--id" = "Geogebra.Classic"
                            }

}

# Functions
function Logger{
    param(
        [string]$Message
    )
    $Message | Out-File -FilePath $Log -Append
    Write-Host $Message
}

function Install-Package-ScriptBlock {
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
            $QueryString = $QueryString + " " + $Option + " " + $OtherParameters[$Option]
        }
    }

    # Before Adding Default Parameters, create the CheckInstallString
    $CheckInstallString = "winget list -q " + $QueryString + "| Out-String -Stream"

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
    Logger -Message "Package: $Package"

    if(!$exists.Contains($NotInstalledString)){
        # No Install Job required, send Null Command
        $mes = "`tAlready installed, skipping."
        Logger -Message $mes
        return "$null"
    }
    else{
        # Install
        $InstallString = "winget install " + $QueryString
        $message = "`tCommand: " + $InstallString
        
        # Log and Send Installer Job
        Logger -Message $message
        return $InstallString
    }
}

function Install-From-Hashes {
}

#############################
# Install Required Programs #
#############################

Logger -Message "Installing Required Programs.. "

$Jobs = foreach($Package in $MainPrograms.Keys){   
    
    if($PackageParams[$Package] -eq $null) {
        $blockstring = Install-Package-ScriptBlock `
            -Package $Package `
            -Source $MainPrograms[$Package] `
            -OtherParameters $DefaultOptionsHash;
    }
    else {
        $blockstring = Install-Package-ScriptBlock `
            -Package $Package `
            -Source $MainPrograms[$Package] `
            -PackageParams $PackageParams[$Package] `
            -OtherParameters $DefaultOptionsHash;
    }

    $scriptBlock = [Scriptblock]::Create($blockstring);
    Start-Job -ScriptBlock $scriptBlock
}

# Wait For all Install Jobs to Finish
Logger -Message "`r`nResult Log: "
$tisofbpttop = Wait-Job $Jobs

foreach ($Job in $Jobs){
    $Output = Receive-Job $Job
    if(($Output -ne $null) -and ($Output -is [Array])){
        $Output = $Output[-1];
    }
    
    if($Output.Contains("Successfully installed")){
        $ResultLog = "Successful"
    }
    else {
        if($Output.Contains("skipping")){
            $ResultLog = $item
        }
        else {
            $ResultLog = "Failed"
        }
    }
    Logger -Mesage $ResultLog
}

<#
$env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User") 

# Python Library installs
pip install numpy scipy python-dotenv psycopg2 nuitka

#>