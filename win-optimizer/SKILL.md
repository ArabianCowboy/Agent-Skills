---
name: win-optimizer
description: Performs recurring Windows maintenance, optimizes startup, and removes system bloat. Use this when the user asks for "maintenance", "system tune-up", "win-optimizer", or "clean my startup".
---

# Win-Optimizer

This skill provides a structured workflow for Windows maintenance and startup optimization.

## Workflow

1.  Scan for Bloat: Execute scripts/analyze_system.ps1 to collect data on startup items, active services (specifically PC Manager), and temp file sizes.
2.  Analyze and Categorize: Process the script output and categorize items:
    *   Known Offenders: Docker, LGHUB, PC Manager, Edge AutoLaunch, OneDrive.
    *   High Impact: Any item consuming significant CPU/Memory or slowing down boot.
    *   System Critical: Windows Security, Audio Drivers (usually safe to keep).
3.  Present Findings: Show the user a structured report of what was found.
4.  Execute Optimization: Upon user approval, use scripts/optimize_system.ps1 or direct registry/service commands to disable unwanted entries.
5.  Clean Temp Files: Calculate and offer to clear Windows temp and User temp folders.

## Best Practices

*   Always ask for confirmation before modifying Registry keys or stopping services.
*   Never disable SecurityHealth or critical system drivers.
*   Log all changes made so they can be reviewed or reverted if needed.