<#
.SYNOPSIS
    Creates compressed backups of the current user's Documents AND Pictures folders
.DESCRIPTION
    Automatically detects current user's special folders
    Creates dated zip archives first in C:\temp (for reliable compression)
    Then copies the completed zip to D:\FLEX pc
    This avoids potential issues with writing large zip files directly to mapped/network drives
.EXAMPLE
    .\backup.ps1
    .\backup.ps1 -ConfigFile ".\backup-config.ps1"
.PARAMETER ConfigFile
    Path to the configuration file. Defaults to backup-config.ps1 in the same directory.
#>

param(
    [string]$ConfigFile = (Join-Path (Split-Path -Parent $MyInvocation.MyCommand.Path) "backup-config.ps1")
)

# Load configuration from file
if (-not (Test-Path $ConfigFile)) {
    Write-Error "Configuration file not found: $ConfigFile"
    Write-Host "Please create a configuration file or specify the correct path with -ConfigFile parameter"
    exit 1
}

Write-Host "Loading configuration from: $ConfigFile" -ForegroundColor Cyan
. $ConfigFile

# Validate required configuration variables
if (-not $backupDir) {
    Write-Error "Configuration error: \$backupDir not defined in $ConfigFile"
    exit 1
}

if (-not $tempDir) {
    Write-Error "Configuration error: \$tempDir not defined in $ConfigFile"
    exit 1
}

if (-not $foldersToBackup) {
    Write-Error "Configuration error: \$foldersToBackup not defined in $ConfigFile"
    exit 1
}

# Check if folders to backup exist and calculate total size
$totalSizeGB = 0
$validFolders = @()

foreach ($folder in $foldersToBackup) {
    $folderPath = $folder.Path
    if (Test-Path $folderPath) {
        $folderSize = (Get-ChildItem -Path $folderPath -Recurse -Force -ErrorAction SilentlyContinue | Measure-Object -Property Length -Sum).Sum
        $folderSizeGB = $folderSize / 1GB
        $totalSizeGB += $folderSizeGB
        $validFolders += $folder
        Write-Host "Folder: $($folder.Name) - Size: $([math]::Round($folderSizeGB, 2)) GB" -ForegroundColor Cyan
    }
}

Write-Host "Total backup size: $([math]::Round($totalSizeGB, 2)) GB" -ForegroundColor Cyan

# Check if total size exceeds 10GB limit
if ($totalSizeGB -gt 10) {
    Write-Error "Total backup size ($([math]::Round($totalSizeGB, 2)) GB) exceeds 10GB limit!"
    exit 1
}

$foldersToBackup = $validFolders

# Set default date stamp if not provided in config
if (-not $dateStamp) {
    $dateStamp = Get-Date -Format "yyyyMMdd"
}

# Ensure temp directory exists
if (-not (Test-Path $tempDir)) {
    New-Item -ItemType Directory -Path $tempDir -Force | Out-Null
    Write-Host "Created temporary directory: $tempDir" -ForegroundColor Green
}

# Create destination folder if it doesn't exist
if (-not (Test-Path $backupDir)) {
    New-Item -ItemType Directory -Path $backupDir -Force | Out-Null
    Write-Host "Created backup destination folder: $backupDir" -ForegroundColor Green
}

Write-Host "Current user: $env:USERNAME" -ForegroundColor Cyan
Write-Host "Date stamp: $dateStamp`n" -ForegroundColor Cyan

foreach ($folder in $foldersToBackup) {
    $folderName = $folder.Name
    $sourcePath = $folder.Path
    $backupFileName = "${dateStamp} ${folderName} backup.zip"
    $tempBackupPath = Join-Path $tempDir $backupFileName
    $finalBackupPath = Join-Path $backupDir $backupFileName

    Write-Host "----------------------------------------" -ForegroundColor DarkGray
    Write-Host "Backing up $folderName..." -ForegroundColor Cyan
    Write-Host "From: $sourcePath"
    Write-Host "Temporary zip: $tempBackupPath"
    Write-Host "Final location: $finalBackupPath`n"

    if (-not (Test-Path $sourcePath)) {
        Write-Warning "Folder not found, skipping: $sourcePath"
        continue
    }

    try {
        # Create the zip in the local temp directory
        Compress-Archive `
            -Path "$sourcePath\*" `
            -DestinationPath $tempBackupPath `
            -CompressionLevel Optimal `
            -Force `
            -ErrorAction Stop

        $tempSizeMB = "{0:N1}" -f ((Get-Item $tempBackupPath).Length / 1MB)
        Write-Host "Created temporary backup: $tempBackupPath ($tempSizeMB MB)" -ForegroundColor Green
        # Move the completed zip to the final backup directory
        Move-Item -Path $tempBackupPath -Destination $finalBackupPath -Force
        Write-Host "Moved backup to final location: $finalBackupPath" -ForegroundColor Green
    }
    catch {
        Write-Error "Failed to backup $folderName!"
        Write-Error $_.Exception.Message

        # Clean up partial temp file if it exists
        if (Test-Path $tempBackupPath) {
            Remove-Item -Path $tempBackupPath -Force
        }
    }
}

Write-Host "----------------------------------------" -ForegroundColor DarkGray
Write-Host "Backup process finished!" -ForegroundColor Green

# Show recent backups
Write-Host "`nRecent backups in $backupDir :"
Get-ChildItem $backupDir -Filter "* backup.zip" |
    Sort-Object LastWriteTime -Descending |
    Select-Object -First 8 |
    ForEach-Object {
        $size = "{0:N1}" -f ($_.Length / 1MB)
        "$($_.Name) - $size MB"
    }
