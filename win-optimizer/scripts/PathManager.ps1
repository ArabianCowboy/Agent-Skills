# PathManager.ps1 - WinOptimizer Shared Path Utilities
# This module provides unified path management for all WinOptimizer scripts
# Works on ANY PC - uses $env:USERPROFILE for cross-user compatibility

$Script:BaseDir = "$env:USERPROFILE\WinOptimizer"
$Script:SessionID = Get-Date -Format "yyyy-MM-dd_HH-mm"
$Script:SessionDir = "$Script:BaseDir\sessions\$Script:SessionID"
$Script:LatestDir = "$Script:BaseDir\latest"

function Get-WinOptimizerPaths {
    <#
    .SYNOPSIS
    Returns a hashtable of all WinOptimizer paths
    #>
    return @{
        BaseDir = $Script:BaseDir
        SessionID = $Script:SessionID
        SessionDir = $Script:SessionDir
        LatestDir = $Script:LatestDir
        HistoryFile = "$Script:BaseDir\history.json"
        AnalysisPrivacy = "$Script:SessionDir\analysis_privacy.json"
        AnalysisSystem = "$Script:SessionDir\analysis_system.json"
        OptimizationLog = "$Script:SessionDir\optimization.log"
        BackupDir = "$Script:SessionDir\backups"
    }
}

function Initialize-WinOptimizerDirs {
    <#
    .SYNOPSIS
    Creates all necessary directories for WinOptimizer
    #>
    $paths = Get-WinOptimizerPaths
    $dirs = @(
        $paths.SessionDir,
        $paths.LatestDir,
        $paths.BackupDir
    )
    
    foreach ($dir in $dirs) {
        if (!(Test-Path $dir)) {
            New-Item -ItemType Directory -Path $dir -Force | Out-Null
        }
    }
}

function Add-ToHistory {
    <#
    .SYNOPSIS
    Adds an entry to the history.json file
    .PARAMETER Entry
    Hashtable containing the entry to add
    #>
    param(
        [hashtable]$Entry
    )
    
    $paths = Get-WinOptimizerPaths
    $historyFile = $paths.HistoryFile
    $history = @()
    
    # Safe JSON loading - handles empty files, null, etc.
    if (Test-Path $historyFile) {
        $content = Get-Content $historyFile -Raw -ErrorAction SilentlyContinue
        if ($content -and $content.Trim() -ne "") {
            try {
                $history = $content | ConvertFrom-Json
                if ($history -isnot [array]) {
                    $history = @($history)
                }
            } catch {
                $history = @()
            }
        }
    }
    
    # Add timestamp to entry
    $Entry["Timestamp"] = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $Entry["SessionID"] = $paths.SessionID
    
    # Append new entry
    $history += $Entry
    
    # Save back to file
    $history | ConvertTo-Json -Depth 5 | Out-File $historyFile -Encoding UTF8
}

function Update-Latest {
    <#
    .SYNOPSIS
    Copies a file to the 'latest' folder for quick access
    .PARAMETER SourcePath
    Full path to the source file
    .PARAMETER DestName
    Name to use for the file in the latest folder
    #>
    param(
        [string]$SourcePath,
        [string]$DestName
    )
    
    $paths = Get-WinOptimizerPaths
    $dest = "$($paths.LatestDir)\$DestName"
    
    if (Test-Path $SourcePath) {
        Copy-Item $SourcePath $dest -Force
    }
}

function Write-WinOptimizerLog {
    <#
    .SYNOPSIS
    Writes a log message to the optimization log file
    .PARAMETER Message
    The message to log
    .PARAMETER Type
    Type of message: Info, Success, Warning, Error
    #>
    param(
        [string]$Message,
        [string]$Type = "Info"
    )
    
    $paths = Get-WinOptimizerPaths
    $timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
    $logEntry = "[$timestamp] [$Type] $Message"
    
    # Ensure directory exists
    $logDir = Split-Path $paths.OptimizationLog -Parent
    if (!(Test-Path $logDir)) {
        New-Item -ItemType Directory -Path $logDir -Force | Out-Null
    }
    
    Add-Content -Path $paths.OptimizationLog -Value $logEntry
    
    # Also output to console with color
    $color = switch ($Type) {
        "Success" { "Green" }
        "Warning" { "Yellow" }
        "Error"   { "Red" }
        default   { "White" }
    }
    Write-Host $Message -ForegroundColor $color
}

# Scripts that dot-source this can access the $Script:BaseDir, $Script:SessionID, etc. variables directly.
