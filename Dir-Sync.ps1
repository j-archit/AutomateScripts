# Requirements: dirsync via python or an executable on path

# Source
$data_drive_letter = (Get-Volume -FileSystemLabel Data).DriveLetter
$data_source_path = $data_drive_letter + ":\"
$C_source = "C:\Users\Archit"

# Target
$driveLetter = (Get-Volume -FileSystemLabel Archit).DriveLetter
$target_drive = $driveLetter+":\"
$target_data_path = $driveLetter + ":\Data\"
$target_C_path = $driveLetter + ":\C\UserData\"

# Start Jobs

#$j_data = Start-Job -ScriptBlock {dirsync $data_source_path $target_data_path --purge --verbose *> $target_drive"autoDirsync_Data.log"}

$sb = {
    param($C_source, $target_C_path, $target_drive)
    dirsync '$C_source\OneDrive\Desktop' '$target_C_path\Desktop' --purge --verbose
}
 
$j2 = Start-Job $sb -ArgumentList $C_source, $target_C_path, $target_drive

<#
$j_desk = Start-Job -ScriptBlock {dirsync "$C_source\OneDrive\Desktop" "$target_C_path\Desktop" --purge --verbose }#*> $target_drive"autoDirsync_desk.log"}
$j_down = Start-Job -ScriptBlock {dirsync $C_source\OneDrive\Downloads\ $target_C_path\Downloads\ --purge --verbose *> $target_drive"autoDirsync_down.log"}
$j_docs = Start-Job -ScriptBlock {dirsync $C_source\OneDrive\Documents\ $target_C_path\Documents\ --purge --verbose *> $target_drive"autoDirsync_docs.log"}
$j_pics = Start-Job -ScriptBlock {dirsync $C_source\OneDrive\Pictures\ $target_C_path\Pictures\ --purge --verbose *> $target_drive"autoDirsync_pics.log"}
$j_vids = Start-Job -ScriptBlock {dirsync $C_source\Videos\ $target_C_path\Videos\ --purge --verbose *> $target_drive"autoDirsync_vids.log"}

 $j_*
#>
Wait-Job $j_desk 