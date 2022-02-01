# AutomateScripts

Powershell Scripts to Quickly Setup/ Run Routine Tasks for Windows Based Machines.

Scripts:

1. `Install-Winget` : Quickly Download and Install Windows Programs using `winget` tool.
2. `Dir-Sync` : Automatically Sync Local Directories to External Backup Disks using [`Python Dirsync`](https://github.com/tkhyn/dirsync). Supports Autodetection of External HDD when inserted via the `Verify-USB-Connection.ps1` script  

Requirements:
1. Powershell Core/ Windows Powershell v5+
2. Winget
3. Python 3
4. Python Dirsync: `pip install dirsync`
