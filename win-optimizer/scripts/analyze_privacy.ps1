# analyze_privacy.ps1 - Windows 11 Privacy Analysis Script
# Scans telemetry, privacy settings, and annoyances
# Outputs structured JSON for easy AI parsing

$ErrorActionPreference = "Continue"

$results = @{
    TelemetryServices = @()
    PrivacySettings = @()
    Status = "OK"
}

# ============================================
# 1. Check Telemetry Services
# ============================================
Write-Host "Checking Telemetry Services..." -ForegroundColor Cyan

$telemetryServices = @("DiagTrack", "dmwappushservice", "WerSvc")
$serviceResults = Get-Service | Where-Object { $telemetryServices -contains $_.Name } | Select-Object Name, DisplayName, Status, StartType

if ($serviceResults) {
    $results.TelemetryServices = @($serviceResults | ForEach-Object {
        @{
            Name = $_.Name
            DisplayName = $_.DisplayName
            Status = $_.Status.ToString()
            StartType = $_.StartType.ToString()
        }
    })
}

# ============================================
# 2. Check Privacy Settings
# ============================================
Write-Host "Checking Privacy Settings..." -ForegroundColor Cyan

$settings = @(
    # Telemetry/Privacy
    @{ Path = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection"; Name = "AllowTelemetry"; Description = "Telemetry Level (0=Disabled)"; Category = "Telemetry" },
    
    # Advertising
    @{ Path = "HKCU:\Software\Microsoft\Windows\CurrentVersion\AdvertisingInfo"; Name = "Enabled"; Description = "Advertising ID"; Category = "Advertising" },
    
    # Tailored Experiences
    @{ Path = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Privacy"; Name = "TailoredExperiencesWithDiagnosticDataEnabled"; Description = "Tailored Experiences"; Category = "Privacy" },
    
    # Activity History / Timeline
    @{ Path = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\System"; Name = "EnableActivityFeed"; Description = "Activity History (Timeline)"; Category = "Privacy" },
    @{ Path = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Privacy"; Name = "PublishUserActivities"; Description = "Publish User Activities"; Category = "Privacy" },
    
    # Bing Search
    @{ Path = "HKCU:\Software\Policies\Microsoft\Windows\Explorer"; Name = "DisableSearchBoxSuggestions"; Description = "Bing Search Suggestions"; Category = "Privacy" },
    
    # SCOOBE (Finish Setup)
    @{ Path = "HKCU:\Software\Microsoft\Windows\CurrentVersion\UserProfileEngagement"; Name = "ScoobeSystemSettingEnabled"; Description = "Finish Setup Nudge (SCOOBE)"; Category = "Annoyance" },
    
    # Start Menu Suggested Content
    @{ Path = "HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager"; Name = "SubscribedContent-338387Enabled"; Description = "Suggested Content (Start Menu)"; Category = "Annoyance" },
    @{ Path = "HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager"; Name = "SubscribedContent-314559Enabled"; Description = "Suggested Content (Apps)"; Category = "Annoyance" },
    
    # Cloud Experience
    @{ Path = "HKCU:\Software\Microsoft\Windows\CurrentVersion\CloudExperienceHost\State"; Name = "AccountsClientToken"; Description = "Cloud Experience Host"; Category = "Privacy" },
    
    # Background Apps
    @{ Path = "HKCU:\Software\Microsoft\Windows\CurrentVersion\BackgroundAccessApplications"; Name = "GlobalUserDisabled"; Description = "Background Apps Access"; Category = "Privacy" }
)

foreach ($s in $settings) {
    $val = $null
    $currentValue = "Not Configured"
    
    if (Test-Path $s.Path) {
        try {
            $val = Get-ItemProperty -Path $s.Path -Name $s.Name -ErrorAction SilentlyContinue
            if ($val -and $null -ne $val.($s.Name)) {
                $currentValue = $val.($s.Name)
            }
        } catch { }
    }
    
    # Determine if setting is concerning (not disabled)
    $isIssue = $false
    if ($currentValue -eq 1 -or $currentValue -eq "Enabled" -or $currentValue -eq "Not Configured") {
        $isIssue = $true
    }
    if ($currentValue -eq 0 -or $currentValue -eq "Disabled") {
        $isIssue = $false
    }
    
    $results.PrivacySettings += @{
        Path = $s.Path
        Name = $s.Name
        Description = $s.Description
        Category = $s.Category
        Value = $currentValue
        IsIssue = $isIssue
    }
}

# ============================================
# 3. Summary
# ============================================
$issueCount = ($results.PrivacySettings | Where-Object { $_.IsIssue -eq $true }).Count
$results | Add-Member -NotePropertyName "IssueCount" -NotePropertyValue $issueCount -PassThru

# Output as single JSON object
$results | ConvertTo-Json -Depth 4
