<#
.SYNOPSIS
    Windows System Health Toolkit (Interactive, Robust)
.DESCRIPTION
    Modular, safe, and transparent repair & diagnostics script for Windows 10/11.
    Checks for admin rights, logs all actions, offers a menu-driven interface,
    and is ready for future extensibility and localization.
.NOTES
    Author: Daniel Monbrod & ChatGPT-4.1
    Date: 2025-07-24
#>

# --- Localization-ready strings ---
$Strings = @{
    ScriptName        = "Windows System Health Toolkit"
    NeedAdmin         = "This script must be run as Administrator. Please restart PowerShell as Administrator and try again."
    PressEnter        = "Press Enter to continue..."
    MainMenu          = "Choose an option (enter number):"
    InvalidSelection  = "Invalid selection."
    ExitMessage       = "Exiting... Thank you for using the Toolkit."
    HelpTitle         = "Help & About"
    HelpBody          = @"
This toolkit offers interactive repair and diagnostics for Windows 10/11.
Menu options include: system info, restore point creation, file & image repair, update/network resets, app fixes, and more.

- Select an item to see its action, then follow the prompts.
- Logs all actions to a file for review.
- Modular for easy extension.

Most tasks require admin rights. Use at your own discretion—no changes are made without your consent.

For documentation, contributions, or updates, visit the project repository.
"@
    LoggingOn         = "Logging enabled. All actions will be recorded to:"
    LoggingOff        = "Logging is disabled."
    LogFileSaved      = "Log file saved as:"
}

# --- Admin check ---
If (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Host $Strings.NeedAdmin -ForegroundColor Red
    Read-Host $Strings.PressEnter
    Exit
}

# --- Logging setup ---
$LogFile = Join-Path -Path $env:TEMP -ChildPath ("WinHealthToolkit-{0}.log" -f (Get-Date -Format 'yyyyMMdd-HHmmss'))
Start-Transcript -Path $LogFile -Append | Out-Null
Write-Host "$($Strings.LoggingOn) $LogFile" -ForegroundColor Cyan

# --- Helper functions ---
function Write-Section {
    param([string]$msg)
    Write-Host "`n==== $msg ==== `n" -ForegroundColor Cyan
}

function Pause-Continue {
    Write-Host ""
    Read-Host $Strings.PressEnter | Out-Null
}

function Run-Command {
    param([string]$cmd, [string]$desc)
    Write-Section $desc
    Write-Host "Running: $cmd" -ForegroundColor DarkGray
    Try {
        Invoke-Expression $cmd
        Write-Host "Done." -ForegroundColor Green
    } Catch {
        Write-Host "Error: $_" -ForegroundColor Red
    }
    Pause-Continue
}

function Show-SystemInfo {
    Write-Section "Basic System Info"
    Try {
        systeminfo | Select-String "OS Name|OS Version|System Type|Total Physical Memory|Available Physical Memory"
    } Catch {
        Write-Host "Unable to retrieve system info." -ForegroundColor Yellow
    }
    Pause-Continue
}

function Create-RestorePoint {
    Write-Section "System Restore Point"
    Try {
        Enable-ComputerRestore -Drive "C:\"
        Checkpoint-Computer -Description "WinHealthToolkit" -RestorePointType "MODIFY_SETTINGS"
        Write-Host "Restore point created." -ForegroundColor Green
    } Catch {
        Write-Host "Failed to create restore point (may require admin or be disabled)." -ForegroundColor Yellow
    }
    Pause-Continue
}

function Run-SFC {
    Run-Command "sfc /scannow" "System File Checker"
}

function Run-DISM {
    Run-Command "DISM /Online /Cleanup-Image /RestoreHealth" "DISM Health Restore"
}

function Run-CHKDSK {
    Write-Section "Check Disk"
    $resp = Read-Host "Run Check Disk? (will prompt for reboot if needed) [y/n]"
    if ($resp -eq "y") {
        Run-Command "chkdsk C: /f" "Check Disk"
        Write-Host "If prompted, confirm and reboot after script completes." -ForegroundColor Yellow
    } else {
        Write-Host "Skipped Check Disk." -ForegroundColor Yellow
    }
}

function Reset-WindowsUpdate {
    Write-Section "Reset Windows Update Components"
    net stop wuauserv
    net stop bits
    Rename-Item -Path "C:\Windows\SoftwareDistribution" -NewName "SoftwareDistribution.old" -ErrorAction SilentlyContinue
    net start wuauserv
    net start bits
    Write-Host "Windows Update reset complete." -ForegroundColor Green
    Pause-Continue
}

function Reset-MicrosoftStore {
    Run-Command "wsreset.exe" "Clear Microsoft Store Cache"
}

function Reset-Network {
    Run-Command "netsh int ip reset" "Network IP Stack Reset"
    Run-Command "netsh winsock reset" "Winsock Reset"
    Run-Command "ipconfig /flushdns" "Flush DNS Cache"
}

function Rebuild-IconCache {
    Write-Section "Rebuild Icon Cache"
    if (Test-Path "$env:LOCALAPPDATA\IconCache.db") {
        Remove-Item "$env:LOCALAPPDATA\IconCache.db" -Force
        Write-Host "Icon cache deleted. Please reboot to rebuild." -ForegroundColor Green
    } else {
        Write-Host "Icon cache not found. Skipped." -ForegroundColor Yellow
    }
    Pause-Continue
}

function Reregister-WindowsApps {
    Run-Command "Get-AppXPackage -AllUsers | Foreach {Add-AppxPackage -DisableDevelopmentMode -Register `"$($_.InstallLocation)\AppXManifest.xml`"}" "Re-register All Windows Apps"
}

function Reset-WindowsStoreApp {
    Write-Section "Repair Windows Store App"
    Try {
        Get-AppxPackage *windowsstore* | Reset-AppxPackage
        Write-Host "Windows Store app reset." -ForegroundColor Green
    } Catch {
        Write-Host "Reset failed or not required." -ForegroundColor Yellow
    }
    Pause-Continue
}

function Show-Help {
    Write-Section $Strings.HelpTitle
    Write-Host $Strings.HelpBody -ForegroundColor White
    Pause-Continue
}

# --- Main menu structure ---
$menu = @{
    "1" = @{Label="Show Basic System Info";         Action={Show-SystemInfo}}
    "2" = @{Label="Create System Restore Point";    Action={Create-RestorePoint}}
    "3" = @{Label="Run System File Checker (SFC)";  Action={Run-SFC}}
    "4" = @{Label="Run DISM Health Restore";        Action={Run-DISM}}
    "5" = @{Label="Check Disk (chkdsk)";            Action={Run-CHKDSK}}
    "6" = @{Label="Reset Windows Update";           Action={Reset-WindowsUpdate}}
    "7" = @{Label="Clear Microsoft Store Cache";    Action={Reset-MicrosoftStore}}
    "8" = @{Label="Reset Network Stack";            Action={Reset-Network}}
    "9" = @{Label="Rebuild Icon Cache";             Action={Rebuild-IconCache}}
   "10" = @{Label="Re-register All Windows Apps";   Action={Reregister-WindowsApps}}
   "11" = @{Label="Repair Windows Store App";       Action={Reset-WindowsStoreApp}}
   "H"  = @{Label="Help/About";                     Action={Show-Help}}
   "Q"  = @{Label="Quit";                           Action={
        Write-Host $Strings.ExitMessage -ForegroundColor Cyan
        Stop-Transcript | Out-Null
        Write-Host "$($Strings.LogFileSaved) $LogFile" -ForegroundColor Cyan
        exit
    }}
}

# --- Main menu loop ---
do {
    Write-Section $Strings.ScriptName
    Write-Host $Strings.MainMenu
    foreach ($key in $menu.Keys) {
        Write-Host "  $key`t$($menu[$key].Label)"
    }
    $choice = Read-Host "Your choice"
    if ($menu.ContainsKey($choice)) {
        & $menu[$choice].Action
    } else {
        Write-Host $Strings.InvalidSelection -ForegroundColor Yellow
        Pause-Continue
    }
} while ($true)
