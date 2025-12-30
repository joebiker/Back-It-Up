# Backup Configuration File
# This file stores all configuration variables for the backup script
# Modify these values to customize your backup behavior per computer instance

# Backup destination directory
$backupDir = "C:\backup"

# Temporary directory for creating zip files before copying to destination
$tempDir = "C:\temp"

# Maximum allowed backup folder size in GB
$maxFolderSizeGB = 10

# Date format for backup file names (yyyyMMdd creates format like 20251228)
$dateStamp = Get-Date -Format "yyyyMMdd"

# Folders to backup
# Add or remove entries as needed
$foldersToBackup = @(
    @{
        Name = "Documents"
        Path = [Environment]::GetFolderPath("MyDocuments")
    },
    @{
        Name = "Pictures"
        Path = [Environment]::GetFolderPath("MyPictures")
    },
    @{
        Name = "Desktop"
        Path = [Environment]::GetFolderPath("Desktop")
    }
)
