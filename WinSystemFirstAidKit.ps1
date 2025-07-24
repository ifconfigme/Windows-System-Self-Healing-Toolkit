<#
.SYNOPSIS
    Windows System First Aid Toolkit (Robust & Modular)
.DESCRIPTION
    Diagnostic and repair script for Windows 10/11—featuring admin rights check, logging with levels, confirmation prompts,
    modular design, robust error handling, a Help menu, and a clear version identifier.
    Ready for collaborative extension and future localization.
.NOTES
    Version: 1.0.0
    Author: Daniel Monbrod & ChatGPT
    Date: 2025-07-24
#>

# ----- SETTINGS -----
$ScriptVersion = "1.0.0"
$ScriptName    = "Windows System First Aid Toolkit"
$LogFile       = Join-Path -Path $env:TEMP -ChildPath ("WinSystemFirstAid-{0}.log" -f (Get-Date -Format 'yyyyMMdd-HHmmss'))

# ----- STRINGS FOR LOCALIZATION -----
$Strings = @{
    ScriptName           = $ScriptName
    Version              = $ScriptVersion
    NeedAdmin            = "This script must be run as Administrator. Please restart PowerShell as Administrator and try again."
    PressEnter           = "Press Enter to continue..."
    MainMenu             = "Choose an option (enter number):"
    InvalidSelection     = "Invalid selection."
    ExitMessage          = "Exiting... Thank you for using the Toolkit."
    LoggingOn            = "Logging enabled. All actions will be recorded to:"
    LogFileSaved         = "Log file saved as:"
    ConfirmAction        = "Are you sure you want to proceed? (y/n): "
    ActionCancelled      = "Action cancelled."
    SummaryTitle         = "=== Action Summary ==="
    Success              = "SUCCESS"
    Failure              = "FAILURE"
    HelpTitle            = "Help & About"
    HelpBody             = @"
This toolkit offers interactive repair and diagnostics for Windows 10/11.
Menu options include: system info, restore point creation, file & image repair, update/network resets, app fixes, and more.

- Select an item to see its action, then follow the prompts.
- Logs all actions to a file for review.
- Modular for easy extension.

Most tasks require admin rights. Use at your own discretion—no changes are made without your consent.

For documentation, contributions, or updates, visit the project repository.
"@
}

# ----- LOGGING FUNCTIONS -----
Function Write-Log {
    param(
        [string]$Message,
        [string]$Level = "INFO"
    )
    $time = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
    $entry = "$time [$Level] $Message"
    Add-Content -Path $LogFile -Value $entry
    $color = Switch ($Level) {
        "INFO"  { "Gray" }
        "WARN"  { "Yellow" }
        "ERROR" { "Red" }
        Default { "White" }
    }
    Write-Host $entry -ForegroundColor $color
}

# ----- ADMIN CHECK -----
If (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Log $Strings.NeedAdmin "ERROR"
    Read-Host $Strings.PressEnter | Out-Null
    Exit
}
Write-Log "$($Strings.LoggingOn) $LogFile" "INFO"

# ----- UTILITY FUNCTIONS -----
Function Confirm-Action ($Prompt) {
    $confirm = Read-Host $Prompt
    if ($confirm -ne "y") {
        Write-Log $Strings.ActionCancelled "WARN"
        return $false
    }
    return $true
}
Function Pause-Continue { Read-Host $Strings.PressEnter | Out-Null }

Function Show-Section ($msg) { Write-Host "`n==== $msg ==== `n" -ForegroundColor Cyan }

# ----- REPAIR/DIAGNOSTIC FUNCTIONS -----
Function Show-SystemInfo {
    Show-Section "Basic System Info"
    Try {
        systeminfo | Select-String "OS Name|OS Version|System Type|Total Physical Memory|Available Physical Memory"
        Write-Log "Displayed basic system info." "INFO"
        Write-Host "$($Strings.Success): System info shown."
    } Catch {
        Write-Log "Unable to retrieve system info. Error: $_" "ERROR"
        Write-Host "$($Strings.Failure): Could not retrieve system info." -ForegroundColor Red
    }
    Pause-Continue
}

Function Create-RestorePoint {
    Show-Section "System Restore Point"
    If (-not (Confirm-Action $Strings.ConfirmAction)) { return }
    Try {
        Enable-ComputerRestore -Drive "C:\"
        Checkpoint-Computer -Description "WinSystemFirstAid" -RestorePointType "MODIFY_SETTINGS"
        Write-Log "Restore point created." "INFO"
        Write-Host "$($Strings.Success): Restore point created." -ForegroundColor Green
    } Catch {
        Write-Log "Failed to create restore point. Error: $_" "ERROR"
        Write-Host "$($Strings.Failure): Could not create restore point." -ForegroundColor Red
    }
    Pause-Continue
}

Function Run-Command {
    param(
        [string]$cmd,
        [string]$desc
    )
    Show-Section $desc
    Try {
        Invoke-Expression $cmd
        Write-Log "Ran command: $cmd" "INFO"
        Write-Host "$($Strings.Success): $desc" -ForegroundColor Green
    } Catch {
        Write-Log "Command failed: $cmd. Error: $_" "ERROR"
        Write-Host "$($Strings.Failure): $desc" -ForegroundColor Red
    }
    Pause-Continue
}

Function Run-SFC { Run-Command "sfc /scannow" "System File Checker" }
Function Run-DISM { Run-Command "DISM /Online /Cleanup-Image /RestoreHealth" "DISM Health Restore" }

Function Run-CHKDSK {
    Show-Section "Check Disk"
    If (-not (Confirm-Action $Strings.ConfirmAction)) { return }
    Try {
        Invoke-Expression "chkdsk C: /f"
        Write-Log "Ran Check Disk." "INFO"
        Write-Host "$($Strings.Success): Check Disk run (may need reboot)." -ForegroundColor Green
    } Catch {
        Write-Log "Check Disk failed. Error: $_" "ERROR"
        Write-Host "$($Strings.Failure): Check Disk." -ForegroundColor Red
    }
    Pause-Continue
}

Function Reset-WindowsUpdate {
    Show-Section "Reset Windows Update Components"
    If (-not (Confirm-Action $Strings.ConfirmAction)) { return }
    Try {
        net stop wuauserv
        net stop bits
        Rename-Item -Path "C:\Windows\SoftwareDistribution" -NewName "SoftwareDistribution.old" -ErrorAction SilentlyContinue
        net start wuauserv
        net start bits
        Write-Log "Windows Update components reset." "INFO"
        Write-Host "$($Strings.Success): Windows Update reset." -ForegroundColor Green
    } Catch {
        Write-Log "Windows Update reset failed. Error: $_" "ERROR"
        Write-Host "$($Strings.Failure): Windows Update reset." -ForegroundColor Red
    }
    Pause-Continue
}

Function Reset-MicrosoftStore { Run-Command "wsreset.exe" "Clear Microsoft Store Cache" }

Function Reset-Network {
    Run-Command "netsh int ip reset" "Network IP Stack Reset"
    Run-Command "netsh winsock reset" "Winsock Reset"
    Run-Command "ipconfig /flushdns" "Flush DNS Cache"
}

Function Rebuild-IconCache {
    Show-Section "Rebuild Icon Cache"
    If (-not (Confirm-Action $Strings.ConfirmAction)) { return }
    Try {
        if (Test-Path "$env:LOCALAPPDATA\IconCache.db") {
            Remove-Item "$env:LOCALAPPDATA\IconCache.db" -Force
            Write-Log "Icon cache deleted." "INFO"
            Write-Host "$($Strings.Success): Icon cache deleted (reboot to rebuild)." -ForegroundColor Green
        } else {
            Write-Log "Icon cache not found." "WARN"
            Write-Host "Icon cache not found. Skipped." -ForegroundColor Yellow
        }
    } Catch {
        Write-Log "Icon cache removal failed. Error: $_" "ERROR"
        Write-Host "$($Strings.Failure): Icon cache removal." -ForegroundColor Red
    }
    Pause-Continue
}

Function Reregister-WindowsApps {
    Run-Command "Get-AppXPackage -AllUsers | Foreach {Add-AppxPackage -DisableDevelopmentMode -Register `"$($_.InstallLocation)\AppXManifest.xml`"}" "Re-register All Windows Apps"
}

Function Reset-WindowsStoreApp {
    Show-Section "Repair Windows Store App"
    If (-not (Confirm-Action $Strings.ConfirmAction)) { return }
    Try {
        Get-AppxPackage *windowsstore* | Reset-AppxPackage
        Write-Log "Windows Store app reset." "INFO"
        Write-Host "$($Strings.Success): Windows Store app reset." -ForegroundColor Green
    } Catch {
        Write-Log "Windows Store reset failed. Error: $_" "ERROR"
        Write-Host "$($Strings.Failure): Windows Store app reset." -ForegroundColor Red
    }
    Pause-Continue
}

Function Show-Help {
    Show-Section $Strings.HelpTitle
    Write-Host $Strings.HelpBody -ForegroundColor White
    Pause-Continue
}

# ----- MENU -----
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
        Write-Log $Strings.ExitMessage "INFO"
        Stop-Transcript | Out-Null
        Write-Host "$($Strings.LogFileSaved) $LogFile" -ForegroundColor Cyan
        Exit
    }}
}

# ----- MAIN MENU LOOP -----
do {
    Show-Section "$($Strings.ScriptName) — v$($Strings.Version)"
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
