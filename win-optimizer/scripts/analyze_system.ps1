# analyze_system.ps1 - Windows 11 System Analysis Script
# Scans startup items, bloatware services, performance settings
# Outputs structured JSON for easy AI parsing

# Import PathManager for unified paths
. "$PSScriptRoot\PathManager.ps1"

$ErrorActionPreference = "Continue"

$results = @{
    StartupItems = @()
    Services = @()
    BloatwareStatus = @()
    TempFolders = @()
    Status = "OK"
}

# ============================================
# 1. Scan Startup Items
# ============================================
Write-Host "Scanning Startup Items..." -ForegroundColor Cyan

$startupItems = Get-CimInstance Win32_StartupCommand | Select-Object Name, Command, Location

if ($startupItems) {
    $results.StartupItems = @($startupItems | ForEach-Object {
        @{
            Name = $_.Name
            Command = $_.Command
            Location = $_.Location
            IsPotentialIssue = ($_.Name -match "OneDrive|Edge|Teams|Spotify|Discord|Steam")
        }
    })
}

# ============================================
# 2. Check Known Bloatware Services
# ============================================
Write-Host "Checking Bloatware Services..." -ForegroundColor Cyan

$knownServices = @(
    # PC Manager
    @{ Name = "PCManager"; DisplayName = "PC Manager"; Category = "Bloatware" },
    @{ Name = "LGHUB"; DisplayName = "Logitech Hub"; Category = "Peripheral" },
    @{ Name = "logi_"; DisplayName = "Logitech Driver"; Category = "Peripheral" },
    # Xbox
    @{ Name = "XblAuthManager"; DisplayName = "Xbox Auth Manager"; Category = "Bloatware" },
    @{ Name = "XblGameSave"; DisplayName = "Xbox Game Save"; Category = "Bloatware" },
    @{ Name = "XboxNetApiSvc"; DisplayName = "Xbox Network API"; Category = "Bloatware" },
    # Delivery Optimization
    @{ Name = "DoSvc"; DisplayName = "Delivery Optimization"; Category = "Bloatware" },
    # Windows Search (Indexing)
    @{ Name = "WSearch"; DisplayName = "Windows Search"; Category = "System" }
)

$serviceResults = Get-Service | Where-Object { 
    $svc = $_
    ($knownServices | Where-Object { $svc.Name -match $_.Name }).Count -gt 0 
}

if ($serviceResults) {
    $results.Services = @($serviceResults | ForEach-Object {
        $svc = $_
        $info = $knownServices | Where-Object { $svc.Name -match $_.Name } | Select-Object -First 1
        @{
            Name = $svc.Name
            DisplayName = $svc.DisplayName
            Status = $svc.Status.ToString()
            StartType = $svc.StartType.ToString()
            Category = if ($info) { $info.Category } else { "Unknown" }
        }
    })
}

# ============================================
# 3. Check Bloatware/Optimization Settings
# ============================================
Write-Host "Checking System Settings..." -ForegroundColor Cyan

$systemSettings = @(
    # Delivery Optimization
    @{ Path = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DeliveryOptimization"; Name = "DODownloadMode"; Description = "Delivery Optimization"; Category = "Bloatware" },
    
    # Widgets
    @{ Path = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced"; Name = "TaskbarDa"; Description = "Widgets Panel"; Category = "Feature" },
    
    # Edge Background
    @{ Path = "HKCU:\Software\Microsoft\Edge\Main"; Name = "StartupBoostEnabled"; Description = "Edge Startup Boost"; Category = "Bloatware" },
    @{ Path = "HKCU:\Software\Microsoft\Edge\Main"; Name = "BackgroundModeEnabled"; Description = "Edge Background Mode"; Category = "Bloatware" },
    
    # Power Throttling
    @{ Path = "HKLM:\SYSTEM\CurrentControlSet\Control\Power\PowerThrottling"; Name = "PowerThrottlingOff"; Description = "Power Throttling"; Category = "Performance" },
    
    # Windows Spotlight
    @{ Path = "HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager"; Name = "RotatingLockScreenEnabled"; Description = "Windows Spotlight"; Category = "Annoyance" }
)

foreach ($s in $systemSettings) {
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
    
    $results.BloatwareStatus += @{
        Description = $s.Description
        Value = $currentValue
        Category = $s.Category
        IsIssue = ($currentValue -eq 1 -or $currentValue -eq "Enabled" -or $currentValue -eq "Not Configured")
    }
}

# ============================================
# 4. Scan Temp Folders
# ============================================
Write-Host "Scanning Temp Folders..." -ForegroundColor Cyan

$tempFolders = @(
    @{ Path = "$env:TEMP"; Name = "User Temp" },
    @{ Path = "$env:SystemRoot\Temp"; Name = "System Temp" },
    @{ Path = "$env:SystemRoot\SoftwareDistribution\Download"; Name = "Update Cache" }
)

foreach ($f in $tempFolders) {
    if (Test-Path $f.Path) {
        try {
            $size = (Get-ChildItem -Path $f.Path -Recurse -File -ErrorAction SilentlyContinue | Measure-Object -Property Length -Sum).Sum
            if (!$size) { $size = 0 }
            
            $results.TempFolders += @{
                Name = $f.Name
                Path = $f.Path
                SizeMB = [Math]::Round($size / 1MB, 2)
            }
        } catch { }
    }
}

# Final Output & Save
Initialize-WinOptimizerDirs
$paths = Get-WinOptimizerPaths

# Calculate total temp size safely
$totalTempSize = 0
foreach ($folder in $results.TempFolders) {
    if ($folder.SizeMB) {
        $totalTempSize += $folder.SizeMB
    }
}

# Save to session directory
$jsonOutput = $results | ConvertTo-Json -Depth 5
$jsonOutput | Out-File -FilePath $paths.AnalysisSystem -Encoding UTF8

# Also save to latest folder
Update-Latest -SourcePath $paths.AnalysisSystem -DestName "analysis_system.json"

# Add to history
Add-ToHistory -Entry @{
    Type = "SystemAnalysis"
    StartupItemsCount = $results.StartupItems.Count
    ServicesCount = $results.Services.Count
    TotalTempSizeMB = $totalTempSize
    File = "analysis_system.json"
}

# Output to console
Write-Host "`n✅ System Analysis complete." -ForegroundColor Green
Write-Host "   Session: $($paths.SessionID)" -ForegroundColor White
Write-Host "   Saved to: $($paths.AnalysisSystem)" -ForegroundColor White

# Output JSON to console for piping/AI parsing
$jsonOutput
