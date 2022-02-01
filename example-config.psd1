@{
    # This is required to identify the backup device. 
    # The DUID is used to verify last USB connection via event manager and Verify-USB-Connection Script
    # The latter is optional and only the Labels may be used to directly run Dir-Sync.ps1, 
    # in which case DUIDs are not required and may be left as empty strings: ""
    HDD_LABELS_IDS  = @{
        "DRIVE_LABEL1" = "<DRIVE_DUID1>" 
        "DRIVE_LABEL2" = "<DRIVE_DUID2>" 
        "DRIVE_LABEL3" = "<DRIVE_DUID3>" 
        # DUID Can be found using the event viewer and looking for event #2006 
        # event 2006 is not logged by default, enable operational logs first
        # A typical DUID looks like XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX in hexadecimal
    }

    # This should be on local computer/ or a shared network location
    DIRSYNCDEFLOG = "<Path to Default Log>" 
    DIRSYNCSCRIPT = "<Path to Dir-Sync.ps1 Script>"
    
    # These options are common to all tasks
    DefaultOptions = @("--verbose", "--purge")

    # First Level Sync Dir is the Directory inside the Target Root Drive/Directory. It may be equal to "\".
    # All Task Target Directories/Logs should be specified relative to this directory only.
    FirstLevelSyncDir = "\John-Backup-PC"
    # Relative to FirstLevelSyncDir
    TargetLogDir = "\dir-sync\logs" 
    
    # Each Key inside the Tasks hashtable, defines a Sync Task
    Tasks = @{ 
        "<Task Source Directory>" = 
        @{
            Target = "<Task Target Directory>" # Relative to FirstLevelSyncDir
            Log = "<Task Log File>" # Relative to FirstLevelSyncDir
            Options = @{"--exclude" = @("^Games.*", "XYZ.[5]*"), "--diff" = ""}
        }

        "<Task2 Source Directory>" = 
        @{
            Target = "<Task2 Target Directory>"
            Log = "<Task2 Log File>"
            Options = @{}
        }
    }
}