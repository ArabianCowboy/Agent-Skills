Write-Host "Scanning Startup Items..."
Get-CimInstance Win32_StartupCommand | Select-Object Name, Command, Location | ConvertTo-Json

Write-Host "Checking PC Manager Status..."
Get-Service | Where-Object { $_.Name -match 'PCManager' } | Select-Object Name, Status, StartType | ConvertTo-Json

Write-Host "Checking Logitech Services..."
Get-Service | Where-Object { $_.Name -match 'LGHUB' -or $_.Name -match 'logi_' } | Select-Object Name, Status, StartType | ConvertTo-Json

Write-Host "Checking Delivery Optimization (Bandwidth Sharing)..."
$doPath = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DeliveryOptimization"
$doVal = if (Test-Path $doPath) { Get-ItemProperty -Path $doPath -Name "DODownloadMode" -ErrorAction SilentlyContinue } else { $null }
@{ "Name" = "Delivery Optimization Mode"; "Value" = if ($null -ne $doVal) { $doVal.DODownloadMode } else { "Enabled (Default)" } } | ConvertTo-Json

Write-Host "Checking Widgets Status..."
$widgetsKey = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced"
if (Test-Path $widgetsKey) {
    $val = Get-ItemProperty -Path $widgetsKey -Name "TaskbarDa" -ErrorAction SilentlyContinue
    @{ "Name" = "Widgets (TaskbarDa)"; "Value" = if ($val -and $null -ne $val.TaskbarDa) { $val.TaskbarDa } else { 1 } } | ConvertTo-Json
}

Write-Host "Checking Edge Background Settings..."
$edgeStartup = Get-ItemProperty -Path "HKCU:\Software\Microsoft\Edge\Main" -Name "StartupBoostEnabled" -ErrorAction SilentlyContinue
$edgeBgUser = Get-ItemProperty -Path "HKCU:\Software\Microsoft\Edge" -Name "BackgroundModeEnabled" -ErrorAction SilentlyContinue
$edgeBgPolicy = Get-ItemProperty -Path "HKCU:\Software\Microsoft\Policies\Microsoft\Edge" -Name "BackgroundModeEnabled" -ErrorAction SilentlyContinue

$bgStatus = 1
if (($null -ne $edgeBgUser -and $edgeBgUser.BackgroundModeEnabled -eq 0) -or ($null -ne $edgeBgPolicy -and $edgeBgPolicy.BackgroundModeEnabled -eq 0)) {
    $bgStatus = 0
}

@{ "StartupBoost" = if ($edgeStartup) { $edgeStartup.StartupBoostEnabled } else { 1 }; "BackgroundMode" = $bgStatus } | ConvertTo-Json

Write-Host "Checking Power Throttling Status..."
$powerPath = "HKLM:\SYSTEM\CurrentControlSet\Control\Power\PowerThrottling"
if (Test-Path $powerPath) {
    $val = Get-ItemProperty -Path $powerPath -Name "PowerThrottlingOff" -ErrorAction SilentlyContinue
    @{ "Name" = "Power Throttling Disabled"; "Value" = if ($val) { $val.PowerThrottlingOff } else { 0 } } | ConvertTo-Json
} else {
    @{ "Name" = "Power Throttling Disabled"; "Value" = "Not Configured (Default)" } | ConvertTo-Json
}

Write-Host "Calculating Temp and Cache Files..."
$tempFolders = @(
    @{ Name = "User Temp"; Path = $env:TEMP },
    @{ Name = "Windows Temp"; Path = "C:\Windows\Temp" },
    @{ Name = "Update Download Cache"; Path = "C:\Windows\SoftwareDistribution\Download" }
)
foreach ($f in $tempFolders) {
    if (Test-Path $f.Path) {
        $size = (Get-ChildItem $f.Path -Recurse -ErrorAction SilentlyContinue | Measure-Object -Property Length -Sum).Sum
        Write-Host "$($f.Name) : $( [Math]::Round($size / 1MB, 2) ) MB"
    }
}