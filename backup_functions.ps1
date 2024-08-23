<#
.SYNOPSIS
Backup functions for retention policies, logging, and backup catalog management.

.DESCRIPTION
This script contains functions for setting retention policies, logging, and backup catalog management.

.NOTES
Requires 7-Zip and SevenZipSharp.dll.
#>

function New-BackupDirectory {
    param (
        [string]$Path
    )
    if (!(Test-Path -Path $Path)) {
        New-Item -Path $Path -ItemType Directory
    }
}

function Compress-Backup {
    param (
        [string]$SourcePath,
        [string]$BackupFilePath,
        [string[]]$ExcludePaths
    )
    Add-Type -Path "C:\Program Files\7-Zip\7z.dll"
    Add-Type -Path "C:\Program Files\SevenZipSharp\lib\net45\SevenZipSharp.dll"
    $archive = New-Object SevenZipSharp.SevenZipCompressor
    $archive.ArchiveFormat = [SevenZipSharp.OutArchiveFormat]::Zip
    $archive.CompressionLevel = [SevenZipSharp.CompressionLevel]::Ultra
    $archive.FastCompression = $true
    $archive.IncludeEmptyDirectories = $false
    foreach ($excludePath in $ExcludePaths) {
        $archive.ExcludeFiles.Add($excludePath + "\*")
    }
    $archive.CompressFiles($BackupFilePath, $SourcePath)
}
function Write-Log {
    param (
        [string]$Path,
        [string]$Message
    )
    Add-Content -Path $Path -Value "$(Get-Date) - $Message"
}

function Set-RetentionPolicies {
    param (
        [string]$BackupPath,
        [string]$LogPath,
        [string]$CatalogPath
    )
    try {
        # Daily retention (keep last 3 backups)
        $dailyBackups = Get-ChildItem -Path $BackupPath -Filter "Backup-*.zip" | Sort-Object LastWriteTime -Descending
        if ($dailyBackups.Count -gt 3) {
            $dailyBackups[3..$dailyBackups.Count - 1] | Remove-Item -Force
            Write-Log -Path $LogPath -Message "Removed daily backups older than 3 days"
        }

        # Weekly retention (keep the most recent backup from the last 4 weeks)
        $currentWeek = [DateTime]::Now.AddDays( - ([int]([DateTime]::Now.DayOfWeek))).Date
        for ($i = 1; $i -le 4; $i++) {
            $weekStart = $currentWeek.AddDays(-7 * ($i - 1))
            $weekEnd = $weekStart.AddDays(6)
            $weeklyBackup = Get-ChildItem -Path $BackupPath -Filter "Backup-*.zip" | Where-Object { $_.LastWriteTime -ge $weekStart -and $_.LastWriteTime -le $weekEnd } | Sort-Object LastWriteTime -Descending | Select-Object -First 1
            if ($weeklyBackup) {
                Write-Log -Path $LogPath -Message "Keeping weekly backup from week $($i): $($weeklyBackup.Name)"
            }
        }

        # Monthly retention (keep the most recent backup from the last 3 months)
        $currentMonth = [DateTime]::Now.AddDays( - ([int]([DateTime]::Now.Day - 1))).Date
        for ($i = 1; $i -le 3; $i++) {
            $monthStart = $currentMonth.AddMonths( - ($i - 1))
            $monthEnd = $monthStart.AddMonths(1).AddDays(-1)
            $monthlyBackup = Get-ChildItem -Path $BackupPath -Filter "Backup-*.zip" | Where-Object { $_.LastWriteTime -ge $monthStart -and $_.LastWriteTime -le $monthEnd } | Sort-Object LastWriteTime -Descending | Select-Object -First 1
            if ($monthlyBackup) {
                Write-Log -Path $LogPath -Message "Keeping monthly backup from $($monthStart.ToString('MMM')): $($monthlyBackup.Name)"
            }
        }

        # Yearly retention (keep the most recent backup from the last 3 years)
        $currentYear = [DateTime]::Now.AddDays( - ([int]([DateTime]::Now.DayOfYear - 1))).Date
        for ($i = 1; $i -le 3; $i++) {
            $yearStart = $currentYear.AddYears( - ($i - 1))
            $yearEnd = $yearStart.AddYears(1).AddDays(-1)
            $yearlyBackup = Get-ChildItem -Path $BackupPath -Filter "Backup-*.zip" | Where-Object { $_.LastWriteTime -ge $yearStart -and $_.LastWriteTime -le $yearEnd } | Sort-Object LastWriteTime -Descending | Select-Object -First 1
            if ($yearlyBackup) {
                Write-Log -Path $LogPath -Message "Keeping yearly backup from $($yearStart.ToString('yyyy')): $($yearlyBackup.Name)"
            }
        }
    }
    catch {
        Write-Error "Error setting retention policies: $_"
    }
}