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
Prior to running, edit the list of files to exclude in exclusions.txt and in the backup.ps1 file $ExcludePaths variable.
Also, configure what to do with Write-Debug statements:
$DebugPreference = 'Continue'
A typical call to capture stdout, stderr, and debug stream:
.\backup.ps1 2>&1 4>&1 | Tee-Object -Debug -FilePath debugbackup.log

In PowerShell, there are six streams:
- stdout (1): Standard Output - contains the normal output of a command.
- stderr (2): Standard Error - contains error messages from a command.
- stdin (0): Standard Input - contains input for a command (not typically used in redirection).
- debug (4): Debug Output - contains debug messages from a command (e.g., Write-Debug).
- verbose (5): Verbose Output - contains verbose messages from a command (e.g., Write-Verbose).
- information (6): Information Output - contains informational messages from a command (e.g., Write-Information).
-Debug is an argument that is supported by some commands starting in PowerShell 5.
#>

# Import functions from backup_functions.ps1
. ./backup_functions.ps1

# Define which directories to skip archiving:
$ExclusionList = Join-Path -Path $PSScriptRoot -ChildPath "exclusions.txt"
# Some directories require more wildcards, so it is better to define them differently.
$ExcludePaths = @(
    "C:\Users\All Users\*",
    "C:\Users\Default\*",
    "C:\Users\Default User\*",
    "C:\Users\Public\*",
    "C:\Users\Administrator\*",
    "C:\Users\LocalService\*",
    "C:\Users\NetworkService\*",
    "C:\$Recycle.Bin\*",
    "C:\$GetCurrent\*",
    "C:\$SysReset\*",
    "C:\$WinREAgent\*"
)
# Define backup settings
$sourcePath = "C:\"
$backupPath = "D:\Backups"
$logPath = Join-Path -Path $backupPath -ChildPath "Backup.log"
$catalogPath = Join-Path -Path $backupPath -ChildPath "BackupCatalog.csv"
$timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
$backupFileName = "Backup-$timestamp.zip"
$backupFilePath = Join-Path -Path $backupPath -ChildPath $backupFileName

try {
    # Create backup directory if it doesn't exist
    New-BackupDirectory -Path $backupPath

    # Compress backup
    Compress-Backup -SourcePath $sourcePath -BackupFilePath $backupFilePath -ExclusionList $ExclusionList  -ExcludePaths $ExcludePaths
    #debug#Compress-Backup -SourcePath $sourcePath -BackupFilePath $backupFilePath -ExcludePaths $ExcludePaths

    # Apply retention policies
    Set-RetentionPolicies -BackupPath $backupPath -LogPath $logPath -CatalogPath $catalogPath

    # Output completion message
    Write-Output "Backup completed successfully: $backupFilePath"
}
catch {
    Write-Error "Backup failed: $_"
}