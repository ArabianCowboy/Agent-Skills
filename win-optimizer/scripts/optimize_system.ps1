# optimize_system.ps1 - Windows Optimizer Execution Module
# Applies all optimizations: Privacy, Telemetry, Bloatware, and Performance

param (
    [switch]$All,
    [switch]$Privacy,
    [switch]$Telemetry,
    [switch]$Bloatware,
    [switch]$Performance,
    [switch]$CleanTemp,
    [switch]$CleanUpdateCache
)

$ErrorActionPreference = "Continue"

function Write-OptimizationLog {
    param([string]$Message, [string]$Type = "Info")
    $timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
    $logEntry = "[$timestamp] [$Type] $Message"
    $logPath = "$env:USERPROFILE\WinOptimizer_Log.txt"
    Add-Content -Path $logPath -Value $logEntry
    
    $color = switch ($Type) {
        "Success" { "Green" }
        "Warning" { "Yellow" }
        "Error"   { "Red" }
        default   { "White" }
    }
    Write-Host $Message -ForegroundColor $color
}

function Set-RegistryValue {
    param(
        [string]$Path,
        [string]$Name,
        $Value,
        [string]$Type = "DWord"
    )
    
    try {
        if (!(Test-Path $Path)) {
            New-Item -Path $Path -Force | Out-Null
            Write-OptimizationLog "Created registry path: $Path" "Info"
        }
        Set-ItemProperty -Path $Path -Name $Name -Value $Value -Type $Type -Force
        Write-OptimizationLog "Set $Path\$Name = $Value" "Success"
        return $true
    } catch {
        Write-OptimizationLog "Failed to set $Path\$Name : $($_.Exception.Message)" "Error"
        return $false
    }
}

function Disable-Telemetry {
    Write-Host "`n=== Disabling Telemetry ===" -ForegroundColor Cyan
    
    # 1. AllowTelemetry (requires Pro/Enterprise)
    [void](Set-RegistryValue -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection" -Name "AllowTelemetry" -Value 0)
    
    # 2. DiagTrack Service
    try {
        $diagTrack = Get-Service -Name "DiagTrack" -ErrorAction SilentlyContinue
        if ($diagTrack) {
            Stop-Service -Name "DiagTrack" -Force -ErrorAction SilentlyContinue
            Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\DiagTrack" -Name "Start" -Value 4 -ErrorAction SilentlyContinue
            Write-OptimizationLog "DiagTrack service stopped and disabled" "Success"
        }
    } catch {
        Write-OptimizationLog "Could not modify DiagTrack service" "Warning"
    }
    
    # 3. Feedback Hub
    [void](Set-RegistryValue -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Privacy" -Name "FeedbackProductImprovementConfig" -Value 0)
    
    # 4. Handwriting data collection
    [void](Set-RegistryValue -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Privacy" -Name "TailoredExperiencesWithDiagnosticDataEnabled" -Value 0)
    
    # 5. Activity History
    [void](Set-RegistryValue -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\System" -Name "EnableActivityFeed" -Value 0)
    [void](Set-RegistryValue -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Privacy" -Name "PublishUserActivities" -Value 0)
}

function Disable-PrivacyAnnoyances {
    Write-Host "`n=== Disabling Privacy Annoyances ===" -ForegroundColor Cyan
    
    # 1. Advertising ID
    [void](Set-RegistryValue -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\AdvertisingInfo" -Name "Enabled" -Value 0)
    
    # 2. Tailored Experiences
    [void](Set-RegistryValue -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Privacy" -Name "TailoredExperiencesWithDiagnosticDataEnabled" -Value 0)
    
    # 3. Bing Search Suggestions
    [void](Set-RegistryValue -Path "HKCU:\Software\Policies\Microsoft\Windows\Explorer" -Name "DisableSearchBoxSuggestions" -Value 1)
    
    # 4. SCOOBE (Finish Setup Nudge)
    [void](Set-RegistryValue -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\UserProfileEngagement" -Name "ScoobeSystemSettingEnabled" -Value 0)
    
    # 5. Start Menu Suggested Content
    [void](Set-RegistryValue -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" -Name "SubscribedContent-338387Enabled" -Value 0)
    [void](Set-RegistryValue -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" -Name "SubscribedContent-314559Enabled" -Value 0)
    
    # 6. Cloud Experience
    [void](Set-RegistryValue -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\CloudExperienceHost\State" -Name "AccountsClientToken" -Value 0)
    
    # 7. Background Apps
    [void](Set-RegistryValue -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\BackgroundAccessApplications" -Name "GlobalUserDisabled" -Value 1)
}

function Disable-Bloatware {
    Write-Host "`n=== Disabling Bloatware ===" -ForegroundColor Cyan
    
    # 1. Delivery Optimization (bandwidth sharing)
    [void](Set-RegistryValue -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DeliveryOptimization" -Name "DODownloadMode" -Value 0)
    
    # 2. Windows Update Delivery Optimization
    [void](Set-RegistryValue -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\DeliveryOptimization\Config" -Name "DODownloadMode" -Value 0)
    
    # 3. Windows Spotlight (lock screen suggestions)
    [void](Set-RegistryValue -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" -Name "RotatingLockScreenEnabled" -Value 0)
    [void](Set-RegistryValue -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" -Name "RotatingLockScreenOverlayEnabled" -Value 0)
    
    # 4. Tips and Suggestions
    [void](Set-RegistryValue -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" -Name "SoftLandingEnabled" -Value 0)
    [void](Set-RegistryValue -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" -Name "PreviewEnabled" -Value 0)
    
    # 5. Edge Startup Boost (prevents Edge from running at startup)
    [void](Set-RegistryValue -Path "HKCU:\Software\Microsoft\Edge\Main" -Name "StartupBoostEnabled" -Value 0)
    
    # 6. Edge Background Mode
    [void](Set-RegistryValue -Path "HKCU:\Software\Microsoft\Edge\Main" -Name "BackgroundModeEnabled" -Value 0)

    
    # 7. OneDrive Startup (if installed)
    $oneDrivePath = "$env:APPDATA\Microsoft\Windows\Start Menu\Programs\Startup"
    if (Test-Path "$oneDrivePath\OneDrive.lnk") {
        Remove-Item "$oneDrivePath\OneDrive.lnk" -Force -ErrorAction SilentlyContinue
        Write-OptimizationLog "Removed OneDrive startup shortcut" "Success"
    }
    
    # 8. Xbox Services (gaming bloat)
    $xboxServices = @("XblAuthManager", "XblGameSave", "XboxNetApiSvc")
    foreach ($svc in $xboxServices) {
        try {
            $service = Get-Service -Name $svc -ErrorAction SilentlyContinue
            if ($service) {
                Stop-Service -Name $svc -Force -ErrorAction SilentlyContinue
                Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\$svc" -Name "Start" -Value 4 -ErrorAction SilentlyContinue
                Write-OptimizationLog "Disabled Xbox service: $svc" "Success"
            }
        } catch { }
    }
}

function Set-PerformanceTweaks {
    Write-Host "`n=== Applying Performance Tweaks ===" -ForegroundColor Cyan
    
    # 1. Disable Power Throttling (for performance PCs)
    [void](Set-RegistryValue -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Power\PowerThrottling" -Name "PowerThrottlingOff" -Value 1)
    
    # 2. Disable Visual Effects (optional - can slow down)
    # [void](Set-RegistryValue -Path "HKCU:\Control Panel\Desktop" -Name "MenuShowDelay" -Value 0)
    # [void](Set-RegistryValue -Path "HKCU:\Control Panel\Desktop" -Name "ForegroundLockTimeout" -Value 0)
    
    # 3. Faster shutdown
    [void](Set-RegistryValue -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" -Name "ClearPageFileAtShutdown" -Value 0)
    
    # 4. Disable Remote Assessment
    [void](Set-RegistryValue -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\PolicySystem" -Name "RemoteAssistanceAllow" -Value 0)

    
    # 5. Disable Windows Defender SmartScreen (optional - security risk if disabled)
    # Set-RegistryValue -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\System" -Name "EnableSmartScreen" -Value 0
    
    # 6. Faster DNS resolution
    Write-OptimizationLog "Flushing DNS cache..." "Info"
    Clear-DnsClientCache
    
    # 7. Prefetch/Superfetch - Note: User said to leave this enabled for SSD
    # SysMain (Superfetch) is actually beneficial for SSDs - do NOT disable
}

function Clear-TempFiles {
    Write-Host "`n=== Cleaning Temp Files ===" -ForegroundColor Cyan
    
    $folders = @(
        $env:TEMP,
        "C:\Windows\Temp"
    )
    
    foreach ($folder in $folders) {
        if (Test-Path $folder) {
            try {
                Get-ChildItem -Path $folder -Recurse -Force -ErrorAction SilentlyContinue | 
                    Where-Object { $_.FullName -notmatch "Windows Defender" } | 
                    Remove-Item -Recurse -Force -ErrorAction SilentlyContinue
                Write-OptimizationLog "Cleaned: $folder" "Success"
            } catch {
                Write-OptimizationLog "Could not clean: $folder" "Warning"
            }
        }
    }
}

function Clear-UpdateCache {
    Write-Host "`n=== Cleaning Windows Update Cache ===" -ForegroundColor Cyan
    
    # Stop Windows Update service
    $wuauserv = Get-Service -Name "wuauserv" -ErrorAction SilentlyContinue
    if ($wuauserv -and $wuauserv.Status -eq "Running") {
        Stop-Service -Name "wuauserv" -Force -ErrorAction SilentlyContinue
        Start-Sleep -Seconds 2
    }
    
    $updatePath = "C:\Windows\SoftwareDistribution\Download"
    if (Test-Path $updatePath) {
        try {
            Get-ChildItem -Path $updatePath -Recurse -Force -ErrorAction SilentlyContinue | 
                Remove-Item -Recurse -Force -ErrorAction SilentlyContinue
            Write-OptimizationLog "Cleaned Windows Update cache" "Success"
        } catch {
            Write-OptimizationLog "Could not clean update cache: $($_.Exception.Message)" "Error"
        }
    }
    
    # Restart Windows Update service with wait
    $wuauserv = Get-Service -Name "wuauserv" -ErrorAction SilentlyContinue
    if ($wuauserv) {
        Start-Service -Name "wuauserv" -ErrorAction SilentlyContinue
        Start-Sleep -Seconds 1
    }
}

# ============================================
# MAIN EXECUTION
# ============================================

Write-Host "`n========================================" -ForegroundColor Magenta
Write-Host "   Windows 11 Optimization Suite" -ForegroundColor Magenta
Write-Host "========================================" -ForegroundColor Magenta
Write-OptimizationLog "Starting optimization process..." "Info"

# 0. Safety First: Create System Restore Point
try {
    Write-Host "`n=== Creating System Restore Point ===" -ForegroundColor Cyan
    Checkpoint-Computer -Description "Before Win-Optimizer" -RestorePointType "MODIFY_SETTINGS" -ErrorAction Stop
    Write-OptimizationLog "System Restore Point created successfully." "Success"
} catch {
    Write-OptimizationLog "Failed to create Restore Point: $($_.Exception.Message). Continuing anyway..." "Warning"
}

# Run all optimizations if -All is specified
if ($All) {
    $Privacy = $true
    $Telemetry = $true
    $Bloatware = $true
    $Performance = $true
    $CleanTemp = $true
    $CleanUpdateCache = $true
}

# Execute based on flags
if ($Telemetry) { Disable-Telemetry }
if ($Privacy) { Disable-PrivacyAnnoyances }
if ($Bloatware) { Disable-Bloatware }
if ($Performance) { Set-PerformanceTweaks }
if ($CleanTemp) { Clear-TempFiles }
if ($CleanUpdateCache) { Clear-UpdateCache }

# Summary
Write-Host "`n========================================" -ForegroundColor Magenta
Write-Host "   Optimization Complete!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Magenta
Write-Host "Log file: $env:USERPROFILE\WinOptimizer_Log.txt" -ForegroundColor White

if ($CleanTemp -or $CleanUpdateCache) {
    Write-Host "`n NOTE: Restart your PC to complete cleanup." -ForegroundColor Yellow
}
