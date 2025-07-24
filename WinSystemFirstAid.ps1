<#
.SYNOPSIS
    Windows System Health Toolkit (Interactive)
.DESCRIPTION
    Menu-driven, modular, and safe repair & diagnostic script for Windows 10/11.
    Designed for thoughtful users who want clarity, transparency, and control.
.NOTES
    Author: Daniel Monbrod & ChatGPT 4.1
    Date: 2025-07-24
#>

function Write-Section {
    param([string]$msg)
    Write-Host "`n==== $msg ==== `n" -ForegroundColor Cyan
}

function Pause-Continue {
    Write-Host ""
    Read-Host "Press Enter to continue..."
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
    systeminfo | Select-String "OS Name|OS Version|System Type|Total Physical Memory|Available Physical Memory"
    Pause-Continue
}

function Create-RestorePoint {
    Write-Section "System Restore Point"
    Try {
        Enable-ComputerRestore -Drive "C:\"
        Checkpoint-Computer -Description "WinHealthToolkit" -RestorePointType "MODIFY_SETTINGS"
        Write-Host "Restore point created." -ForegroundColor Green
    } Catch {
        Write-Host "Failed to create restore point. (May require admin or be disabled.)" -ForegroundColor Yellow
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

# ---- Menu System ----
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
   "Q"  = @{Label="Quit";                           Action={Write-Host "Exiting..."; exit}}
}

# Main menu loop
do {
    Write-Section "Windows System Health Toolkit"
    Write-Host "Choose an option (enter number):"
    foreach ($key in $menu.Keys) {
        Write-Host "  $key`t$($menu[$key].Label)"
    }
    $choice = Read-Host "Your choice"
    if ($menu.ContainsKey($choice)) {
        & $menu[$choice].Action
    } else {
        Write-Host "Invalid selection." -ForegroundColor Yellow
    }
} while ($true)
