# safety.ps1 - Windows Optimizer Safety Module
# Creates restore points and registry backups before optimization

param (
    [switch]$BackupOnly,
    [switch]$Restore
)

# Import PathManager for unified paths
. "$PSScriptRoot\PathManager.ps1"

$ErrorActionPreference = "Stop"

# Initialize directories
Initialize-WinOptimizerDirs
$paths = Get-WinOptimizerPaths

function New-SafetyBackup {
    Write-Host "=== Creating Safety Backup ===" -ForegroundColor Yellow
    
    # Use unified backup directory from PathManager
    $backupDir = $paths.BackupDir
    
    # Create backup directory (should already exist from Initialize, but ensure it)
    if (!(Test-Path $backupDir)) {
        New-Item -ItemType Directory -Path $backupDir -Force | Out-Null
    }
    Write-Host "Backup directory: $backupDir"
    
    # 1. Create System Restore Point
    Write-Host "`n[1/2] Creating System Restore Point..." -ForegroundColor Cyan
    $restorePointCreated = $false
    try {
        # Check if system protection is enabled
        $systemProperties = Get-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\SystemRestore" -ErrorAction SilentlyContinue
        if ($null -ne $systemProperties -and $systemProperties.RPSessionInterval -ne 0) {
            Checkpoint-Computer -Description "WinOptimizer_PreOptimization" -RestorePointType "MODIFY_SETTINGS" -ErrorAction Stop
            $restorePointCreated = $true
            Write-Host "OK: Restore point created successfully" -ForegroundColor Green
        } else {
            Write-Host "WARN: System Protection is disabled. Enable it in System Properties to use restore points." -ForegroundColor Yellow
        }
    } catch {
        Write-Host "WARN: Could not create restore point: $($_.Exception.Message)" -ForegroundColor Yellow
        Write-Host "  Continuing with registry backup only..." -ForegroundColor Yellow
    }
    
    # 2. Export Critical Registry Hives
    Write-Host "`n[2/2] Backing up critical registry hives..." -ForegroundColor Cyan
    
    $registryKeys = @(
        @{ Path = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection"; Name = "Telemetry" },
        @{ Path = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Privacy"; Name = "Privacy" },
        @{ Path = "HKCU:\Software\Microsoft\Windows\CurrentVersion\AdvertisingInfo"; Name = "AdvertisingInfo" },
        @{ Path = "HKCU:\Software\Policies\Microsoft\Windows\Explorer"; Name = "Explorer_Policies" },
        @{ Path = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DeliveryOptimization"; Name = "DeliveryOptimization" },
        @{ Path = "HKCU:\Software\Microsoft\Windows\CurrentVersion\UserProfileEngagement"; Name = "UserProfileEngagement" },
        @{ Path = "HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager"; Name = "ContentDeliveryManager" },
        @{ Path = "HKCU:\Software\Microsoft\Windows\CurrentVersion\BackgroundAccessApplications"; Name = "BackgroundApps" }
    )
    
    $backedUpCount = 0
    foreach ($key in $registryKeys) {
        $regFile = "$backupDir\$($key.Name).reg"
        
        if (Test-Path $key.Path) {
            try {
                # Transform "HKLM:\Path" to "HKLM\Path" for reg.exe
                $regKeyForExport = $key.Path -replace ':', ''
                
                # Use native call operator instead of cmd /c
                & reg export "$regKeyForExport" "$regFile" /y *>$null
                
                if (Test-Path $regFile) {
                    $backedUpCount++
                    Write-Host "  OK: Backed up: $($key.Name)" -ForegroundColor Green
                }
            } catch {
                Write-Host "  WARN: Failed to backup: $($key.Name)" -ForegroundColor Yellow
            }
        } else {
            Write-Host "  SKIP: Skipped (not found): $($key.Name)" -ForegroundColor Gray
        }
    }
    
    # Create backup manifest
    $manifest = @{
        Timestamp = $paths.SessionID
        RestorePointCreated = $restorePointCreated
        KeysBackedUp = $backedUpCount
        TotalKeys = $registryKeys.Count
        BackupPath = $backupDir
    } | ConvertTo-Json
    
    $manifest | Out-File -FilePath "$backupDir\backup_manifest.json" -Encoding UTF8
    
    # Add to history
    Add-ToHistory -Entry @{
        Type = "SafetyBackup"
        RestorePointCreated = $restorePointCreated
        KeysBackedUp = $backedUpCount
        File = "backups\backup_manifest.json"
    }

    # Update latest backups
    $latestBackupDir = "$($paths.LatestDir)\backups"
    if (!(Test-Path $latestBackupDir)) {
        New-Item -ItemType Directory -Path $latestBackupDir -Force | Out-Null
    }
    Copy-Item -Path "$backupDir\*" -Destination $latestBackupDir -Force -Recurse
    
    Write-Host "`n=== Backup Complete ===" -ForegroundColor Yellow
    Write-Host "   Session: $($paths.SessionID)" -ForegroundColor White
    Write-Host "   Location: $backupDir" -ForegroundColor White
    Write-Host "   Registry hives backed up: $backedUpCount/$($registryKeys.Count)" -ForegroundColor White
    Write-Host "   History: $($paths.HistoryFile)" -ForegroundColor White
    
    return $backupDir
}

function Restore-FromBackup {
    param (
        [string]$BackupPath = $backupDir
    )
    
    Write-Host "=== Restoring from Backup ===" -ForegroundColor Yellow
    Write-Host "Backup path: $BackupPath" -ForegroundColor White
    
    if (!(Test-Path $BackupPath)) {
        Write-Host "ERROR: Backup directory not found: $BackupPath" -ForegroundColor Red
        return $false
    }
    
    # Read manifest
    $manifestPath = "$BackupPath\backup_manifest.json"
    if (Test-Path $manifestPath) {
        $manifest = Get-Content $manifestPath | ConvertFrom-Json
        Write-Host "Backup timestamp: $($manifest.Timestamp)" -ForegroundColor White
    }
    
    # Restore registry files
    $regFiles = Get-ChildItem -Path $BackupPath -Filter "*.reg"
    foreach ($file in $regFiles) {
        Write-Host "Restoring: $($file.Name)..." -ForegroundColor Cyan
        try {
            Write-Host "  WARN: Manual restoration required. Import: $($file.FullName)" -ForegroundColor Yellow
        } catch {
            Write-Host "  ERROR: Failed: $($file.Name)" -ForegroundColor Red
        }
    }
    
    Write-Host "`n=== Restore Instructions ===" -ForegroundColor Yellow
    Write-Host "To restore registry:" -ForegroundColor White
    Write-Host "  1. Open Registry Editor (regedit)" -ForegroundColor White
    Write-Host "  2. File -> Import" -ForegroundColor White
    Write-Host "  3. Select the .reg files from: $BackupPath" -ForegroundColor White
    
    return $true
}

# Main execution
if ($Restore) {
    Restore-FromBackup
} else {
    $result = New-SafetyBackup
    Write-Host "`nOK: Safety backup completed. Proceed with optimization." -ForegroundColor Green
}
