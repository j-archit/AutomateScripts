#############################
# Install Required Programs #
#############################

winget install --accept-source-agreements --accept-package-agreements `
vscode -s winget

winget install --accept-source-agreements --accept-package-agreements `
"Python 3" -s winget

winget install --accept-source-agreements --accept-package-agreements `
"Windows Terminal" -s winget 

winget install --accept-source-agreements --accept-package-agreements `
obs -s winget

winget install --accept-source-agreements --accept-package-agreements `
"Onenote for Windows 10" -s msstore

winget install --accept-source-agreements --accept-package-agreements `
discord -s winget

winget install --accept-source-agreements --accept-package-agreements `
"VLC media player" -s winget

winget install --accept-source-agreements --accept-package-agreements `
Spotify -s msstore

winget install --accept-source-agreements --accept-package-agreements `
Whatsapp -s msstore

winget install --accept-source-agreements --accept-package-agreements `
git -s winget

winget install --accept-source-agreements --accept-package-agreements `
"NVIDIA GeForce Experience" -s winget

winget install --accept-source-agreements --accept-package-agreements `
"GNU Octave" -s winget

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