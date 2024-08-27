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
        [string]$ExclusionList,
        [string[]]$ExcludePaths
    )
    $7zipPath = "C:\Program Files\7-Zip\7z.exe"
    #20240822#$excludeArgs = @()
    #20240822#foreach ($excludePath in $ExcludePaths) {
    #20240822#    $excludeArgs += "-xr!$excludePath "
    #20240822#}
    $excludeArgs = @()
    if ($ExclusionList) {
        $excludeArgs += "-x@`"$ExclusionList`" " #+= is needed to append the string to the array
    }
    if ($ExcludePaths) {
        foreach ($excludePath in $ExcludePaths) {
            $excludeArgs += "-xr!`"$excludePath`" "
        }
    }

    # Check if the backup file already exists
    #debug#Write-Host "HERE!"
    Write-Output "Backing up to '$BackupFilePath'"
    #20240823#    if (Test-Path $BackupFilePath) {
    #20240823#        # If it exists, we will still use the 'a' command to add files
    #20240823#        Write-Host "Archive exists. Adding files to existing archive, $BackupFilePath."
    #20240823#        $sevenZipArgs += @( "a" )
    #20240823#    }
    #20240823#    else {
    #20240823#        Write-Host "Archive does not exist. Creating new archive, $BackupFilePath."
    #20240823#        $sevenZipArgs += @( )
    #20240823#    }
    $sevenZipArgs += @( 
        "a",
        "-y",
        "-tzip", 
        "-mx=9", 
        #20240824#"-bb1",
        "-bb3",
        "`"$BackupFilePath`"", 
        "`"$SourcePath`""
    ) + $excludeArgs
    Write-Debug "7-Zip command: $7zipPath $($sevenZipArgs -join ' ')"
    #debug#exit 1
    #& $7zipPath $sevenZipArgs This failed to launch correctly because of the complex arguments.
    # Execute the 7-Zip command using Start-Process to better handle the complex argument list
    # Start-Process -FilePath $7zipPath -ArgumentList $sevenZipArgs -Wait -NoNewWindow This was'nt sending output to stdout like it should, probably because of the -NoNewWindow flag.
    # Start-Process -FilePath $7zipPath -ArgumentList $sevenZipArgs -Wait -NoNewWindow -RedirectStandardOutput $null -RedirectStandardError $null The interpreter sometimes complains about RedirectStandardOutput being null
    $process = Start-Process -FilePath $7zipPath -ArgumentList $sevenZipArgs -Wait -NoNewWindow -PassThru
    $process | Tee-Object -FilePath $null
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
            #200240824#$dailyBackups[3..$dailyBackups.Count - 1] | Remove-Item -Force # PowerShell can't handle this level of abstraction (index slicing) when removing elements of an array.
            $dailyBackupsToKeep = $dailyBackups | Where-Object { $_.Index -lt 3 }
            $dailyBackupsToRemove = $dailyBackups | Where-Object { $_.Index -ge 3 }

            $dailyBackupsToRemove | Remove-Item -Force
            
            # Output the names of the backups being retained/discarded
            Write-Output "Retaining the following daily backups:"
            $dailyBackupsToKeep | ForEach-Object { Write-Output $_.FullName }
            Write-Output "Removed the following daily backups:"
            $dailyBackupsToRemove | ForEach-Object { Write-Output $_.FullName }
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