Write-Host "Checking Telemetry Services..."
$telemetryServices = @("DiagTrack", "dmwappushservice", "WerSvc")
Get-Service | Where-Object { $telemetryServices -contains $_.Name } | Select-Object Name, DisplayName, Status, StartType | ConvertTo-Json

Write-Host "Checking Privacy Settings and Annoyances..."
$privacyResults = @()
$settings = @(
    @{ Path = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection"; Name = "AllowTelemetry"; Description = "Telemetry Level" },
    @{ Path = "HKCU:\Software\Microsoft\Windows\CurrentVersion\AdvertisingInfo"; Name = "Enabled"; Description = "Advertising ID" },
    @{ Path = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Privacy"; Name = "TailoredExperiencesWithDiagnosticDataEnabled"; Description = "Tailored Experiences" },
    @{ Path = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\System"; Name = "EnableActivityFeed"; Description = "Activity History" },
    @{ Path = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Privacy"; Name = "PublishUserActivities"; Description = "Publish User Activities" },
    # New "Sneaky" Features
    @{ Path = "HKCU:\Software\Policies\Microsoft\Windows\Explorer"; Name = "DisableSearchBoxSuggestions"; Description = "Bing Search Disabled" },
    @{ Path = "HKCU:\Software\Microsoft\Windows\CurrentVersion\UserProfileEngagement"; Name = "ScoobeSystemSettingEnabled"; Description = "Finish Setup Nudge (SCOOBE)" },
    @{ Path = "HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager"; Name = "SubscribedContent-338387Enabled"; Description = "Suggested Content (Start)" }
)

foreach ($s in $settings) {
    $val = $null
    if (Test-Path $s.Path) {
        $val = Get-ItemProperty -Path $s.Path -Name $s.Name -ErrorAction SilentlyContinue
    }
    
    $privacyResults += @{ 
        "Setting" = $s.Description; 
        "Value" = if ($val -and $null -ne $val.($s.Name)) { $val.($s.Name) } else { "Default/Enabled" } 
    }
}
$privacyResults | ConvertTo-Json

Write-Host "Checking Background Apps Permission..."
$bgAppsKey = "HKCU:\Software\Microsoft\Windows\CurrentVersion\BackgroundAccessApplications"
if (Test-Path $bgAppsKey) {
    $val = Get-ItemProperty -Path $bgAppsKey -Name "GlobalUserDisabled" -ErrorAction SilentlyContinue
    @{ "Name" = "Background Apps Disabled"; "Value" = if ($val) { $val.GlobalUserDisabled } else { 0 } } | ConvertTo-Json
}