Write-Host "Scanning Startup Items..."
Get-CimInstance Win32_StartupCommand | Select-Object Name, Command, Location | ConvertTo-Json

Write-Host "Checking PC Manager Status..."
Get-Service | Where-Object { $_.Name -match 'PCManager' } | Select-Object Name, Status, StartType | ConvertTo-Json

Write-Host "Calculating Temp Files..."
$tempFolders = @($env:TEMP, "C:\Windows\Temp")
foreach ($folder in $tempFolders) {
    if (Test-Path $folder) {
        $size = (Get-ChildItem $folder -Recurse -ErrorAction SilentlyContinue | Measure-Object -Property Length -Sum).Sum
        Write-Host "$folder : $( [Math]::Round($size / 1MB, 2) ) MB"
    }
}
