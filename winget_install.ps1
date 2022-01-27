$Log = ".\installer.log"
$NotInstalledString = "No installed package found matching input criteria."

function Install-Package-ScriptBlock {
    param (
        [string]$Package, 
        [string]$Source,
        [hashtable]$PackageParams,
        [hashtable]$OtherParameters
    )

    $QueryString = $Package

    if($Source -ne ""){
        $QueryString = $QueryString + " -s " + $Source
    }
    if($OtherParameters -ne $null){
        ForEach($Option in $OtherParameters.Keys){
            $QueryString = $QueryString + " " + $Option + " " + $OtherParameters[$Option]
        }
    }

    # Check if Already Exists
    $CheckInstallString = "winget list -q " + $QueryString + "| Out-String -Stream"
    $scriptBlock = [Scriptblock]::Create($CheckInstallString)
    $exist = Start-Job -ScriptBlock $scriptBlock
    Wait-Job $exist
    $exists = Receive-Job $exist

    if(!$exists.Contains($NotInstalledString)){
        $LogOp = $Package + " already installed, skipping."
        $abc = "Write-Output " + $LogO
        return $abc
    }
    else{
        # Install
        $InstallString = "winget install " + $QueryString
        $LogOutput = "Issuing Install of " + $Package + " with command: `r`n" + $InstallString
        $LogOutput | Out-File -FilePath $Log -Append
        return $InstallString
    }
}

# Define Sources
$s1 = "winget"
$s2 = "msstore"

$DefaultOptionsHash = @{
    '--accept-source-agreements'  = ""
    '--accept-package-agreements' = ""
    }

#############################
# Install Required Programs #
#############################

Write-Output "Installing Required Programs.. " | Out-File -FilePath $Log -Append

$MainProgramsw = @{
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
    "GNU Octave" = $s1
}

$MainPrograms = @{
    "Python 3"   = $s1
    "windows terminal" = $s1
}

$Jobs = foreach($Package in $MainPrograms.Keys){   
    $blockstring = Install-Package-ScriptBlock -Package $Package -Source $MainPrograms[$Package] -OtherParameters $DefaultOptionsHash
    $scriptBlock = [Scriptblock]::Create($blockstring)
    
    Start-Job -ScriptBlock $scriptBlock
}

Wait-Job $Jobs
$Output = Receive-Job $Jobs
foreach ($item in $Output){
    if($item.Contains("Successfully installed")){
        $ResultLog = "Successful"
    }
    else {
        if($item.Contains("skipping")){
            $ResultLog = $item
        }
        else {
            $ResultLog = "Failed"
        }
    }
    $ResultLog | Out-File -FilePath $Log -Append
}

<#
$env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User") 

# Python Library installs
pip install numpy scipy python-dotenv psycopg2 nuitka

#######################################
# Not Very Important, yet recommended #
#######################################

winget install --accept-source-agreements --accept-package-agreements `
"7-Zip" -s winget

winget install --accept-source-agreements --accept-package-agreements `
libreoffice -s winget --id TheDocumentFoundation.LibreOffice

winget install --accept-source-agreements --accept-package-agreements `
ModernFlyouts -s winget

winget install --accept-source-agreements --accept-package-agreements `
"geogebra classic" -s winget --id "Geogebra.Classic"

#>