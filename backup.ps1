<#
.SYNOPSIS
Backup script to compress and retain backups.

.DESCRIPTION
This script creates a compressed backup of the specified source path, applies retention policies, and logs errors, keeping:
- Daily backups: last 3 backups
- Weekly backups: last 4 weeks
- Monthly backups: last 3 months
- Yearly backups: last 3 years
Logs errors and outputs completion message.

.PARAMETER sourcePath
Source path to backup (default: C:).

.PARAMETER backupPath
Backup destination path (default: D:\Backups).

.NOTES
Requires 7-Zip and SevenZipSharp.dll.

.EXAMPLE
.\backup.ps1
#>

# Import functions from backup_functions.ps1
. ./backup_functions.ps1

# Define which directories to skip archiving:
$ExcludePaths = @(
    "c:\Apps",
    "c:\Dell",
    "c:\Drivers",
    "c:\Intel",
    "c:\PerfLogs",
    "c:\Program Files",
    "c:\Program Files (x86)",
    "c:\Windows",
    "c:\Windows10Upgrade"
)
# Define backup settings
$sourcePath = "C:"
$backupPath = "D:\Backups"
$logPath = Join-Path -Path $backupPath -ChildPath "BackupLog.txt"
$catalogPath = Join-Path -Path $backupPath -ChildPath "BackupCatalog.csv"
$timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
$backupFileName = "Backup-$timestamp.zip"
$backupFilePath = Join-Path -Path $backupPath -ChildPath $backupFileName

try {
    # Create backup directory if it doesn't exist
    New-BackupDirectory -Path $backupPath

    # Compress backup
    Compress-Backup -SourcePath $sourcePath -BackupFilePath $backupFilePath -ExcludePaths @ExcludePaths

    # Apply retention policies
    Set-RetentionPolicies -BackupPath $backupPath -LogPath $logPath -CatalogPath $catalogPath

    # Output completion message
    Write-Output "Backup completed successfully: $backupFilePath"
}
catch {
    Write-Error "Backup failed: $_"
}