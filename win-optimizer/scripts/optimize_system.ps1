param (
    [switch]$CleanTemp,
    [switch]$CleanUpdateCache,
    [switch]$Privacy,
    [switch]$DisableThrottling,
    [string[]]$itemsToDisable
)

if ($DisableThrottling) {
    Write-Host "Disabling Power Throttling..."
    $powerPath = "HKLM:\SYSTEM\CurrentControlSet\Control\Power\PowerThrottling"
    if (!(Test-Path $powerPath)) { New-Item -Path $powerPath -Force | Out-Null }
    Set-ItemProperty -Path $powerPath -Name "PowerThrottlingOff" -Value 1 -Type DWord
    Write-Host "Power Throttling has been disabled for maximum performance."
}

if ($Privacy) {
    Write-Host "Optimizing Privacy Settings..."
    
    # Tailored Experiences
    $privacyPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Privacy"
    if (!(Test-Path $privacyPath)) { New-Item -Path $privacyPath -Force | Out-Null }
    Set-ItemProperty -Path $privacyPath -Name "TailoredExperiencesWithDiagnosticDataEnabled" -Value 0 -Type DWord
    
    # Activity History (Timeline)
    $systemPolicyPath = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\System"
    if (!(Test-Path $systemPolicyPath)) { New-Item -Path $systemPolicyPath -Force | Out-Null }
    Set-ItemProperty -Path $systemPolicyPath -Name "EnableActivityFeed" -Value 0 -Type DWord
    
    Set-ItemProperty -Path $privacyPath -Name "PublishUserActivities" -Value 0 -Type DWord
    
    Write-Host "Privacy optimizations applied (Activity History & Tailored Experiences disabled)."
}

if ($CleanTemp) {
    Write-Host "Cleaning Temp Files..."
    $tempFolders = @($env:TEMP, "C:\Windows\Temp")
    foreach ($folder in $tempFolders) {
        Get-ChildItem -Path $folder -Recurse -ErrorAction SilentlyContinue | Remove-Item -Recurse -Force -ErrorAction SilentlyContinue
    }
}

if ($CleanUpdateCache) {
    Write-Host "Cleaning Windows Update Cache..."
    $updatePath = "C:\Windows\SoftwareDistribution\Download"
    if (Test-Path $updatePath) {
        Get-ChildItem -Path $updatePath -Recurse -ErrorAction SilentlyContinue | Remove-Item -Recurse -Force -ErrorAction SilentlyContinue
    }
}

foreach ($item in $itemsToDisable) {
    Write-Host "Disabling $item..."
    # Custom disabling logic can be added here
}
