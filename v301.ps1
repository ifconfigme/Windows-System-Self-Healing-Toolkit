<# Windows System First Aid Toolkit — v2.0.1 #>

# ----- SETTINGS -----
$SessionActions = @()
$ScriptVersion = "2.0.1"
$ScriptName = "Windows System First Aid Toolkit"
$defaultLogFile = Join-Path -Path $env:TEMP -ChildPath ("WinSystemFirstAid-{0}.log" -f (Get-Date -Format 'yyyyMMdd_HHmmss'))
$SectionHeaderColor = "Cyan"
function Get-LogFilePath {
    param (
        [string]$DefaultLogFile
    )
    $logPathInput = Read-Host "Enter a custom log file path (e.g., C:\Logs\MyToolkit.log), or press Enter to use the default in `$env:TEMP:"
    $illegalChars = [System.IO.Path]::GetInvalidPathChars() + [System.IO.Path]::GetInvalidFileNameChars()
    if (-not [string]::IsNullOrWhiteSpace($logPathInput)) {
        if ($logPathInput.IndexOfAny($illegalChars) -ge 0) {
            Write-Host "The path contains invalid characters. Using default log file path." -ForegroundColor Yellow
            return $DefaultLogFile
        }
        $directory = Split-Path -Path $logPathInput -Parent
        if ($directory -and -not (Test-Path -Path $directory)) {
            try {
                New-Item -Path $directory -ItemType Directory -Force | Out-Null
            } catch {
                Write-Host "Failed to create directory: $directory. Using default log file path." -ForegroundColor Yellow
                return $DefaultLogFile
            }
        }
        return $logPathInput
    } else {
        Write-Host "No custom log path entered. Using default log file path."
        return $DefaultLogFile
    }
}
$defaultLogFile = Join-Path $env:TEMP ("WinSystemFirstAid-{0}.log" -f (Get-Date -Format 'yyyyMMdd_HHmmss'))
$LogFile = Get-LogFilePath -DefaultLogFile $defaultLogFile
# ----- STRINGS -----
$Strings = @{
    ScriptName       = $ScriptName
    Version          = $ScriptVersion
    NeedAdmin        = "This script must be run as Administrator. Please restart PowerShell as Administrator and try again."
    PressEnter       = "Press Enter to continue..."
    MainMenu         = "Choose an option (enter number, H for help, Q to quit):"
    InvalidSelection = "Invalid selection."
    ExitMessage      = "Exiting... Thank you for using the Toolkit."
    LoggingOn        = "Logging enabled. All actions will be recorded to:"
    LogFileSaved     = "Log file saved as:"
    ConfirmAction    = "Are you sure you want to proceed? (y/n): "
    ActionCancelled  = "Action cancelled."
    SummaryTitle     = "=== Action Summary ==="
    Success          = "SUCCESS"
    Failure          = "FAILURE"
    HelpTitle        = "Help & About"
    HelpBody         = @"
This toolkit offers interactive repair and diagnostics for Windows 10/11.
Menu options include: system info, restore point creation, file & image repair, update/network resets, app fixes, and more.

- Select an item to see its action, then follow the prompts.
- Logs all actions to a file for review.
- Modular for easy extension.

Note: The 'Repair Windows Store App' feature requires PowerShell 7 or later.
"@
}

# ----- LOGGING FUNCTION -----
Function Write-Log {
    param([string]$Message, [string]$Level = "INFO")
    $time = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
    $entry = "$time [$Level] $Message"
    Add-Content -Path $LogFile -Value $entry
    $color = Switch ($Level) {
        "INFO" { "Gray" }
        "WARN" { "Yellow" }
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
if (-not (Test-Path $LogFile)) {
    New-Item -Path $LogFile -ItemType File -Force | Out-Null
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
Function Wait-Continue { Read-Host $Strings.PressEnter | Out-Null }
Function Show-Section ($msg) { Write-Host "`n==== $msg ==== `n" -ForegroundColor $SectionHeaderColor }

# ----- REPAIR/DIAGNOSTIC FUNCTIONS -----
Function Show-SystemInfo {
    Show-Section "Basic System Info"
    Try {
        [string[]](systeminfo) | Select-String "OS Name|OS Version|System Type|Total Physical Memory|Available Physical Memory"
        Write-Log "Displayed basic system info." "INFO"
        $SessionActions += "Displayed basic system info"
        Write-Host "$($Strings.Success): System info shown."
    }
    Catch {
        Write-Log "Unable to retrieve system info. Error: $_" "ERROR"
        $SessionActions += "Failed to retrieve system info"
        Write-Host "$($Strings.Failure): Could not retrieve system info." -ForegroundColor Red
    }
    Wait-Continue
}

Function New-RestorePoint {
    Show-Section "System Restore Point"
    If (-not (Confirm-Action $Strings.ConfirmAction)) { return }
    Try {
        Enable-ComputerRestore -Drive "C:\"
        Checkpoint-Computer -Description "WinSystemFirstAid" -RestorePointType "MODIFY_SETTINGS"
        Write-Log "Restore point created." "INFO"
        $SessionActions += "Created system restore point"
        Write-Host "$($Strings.Success): Restore point created." -ForegroundColor Green
    }
    Catch {
        Write-Log "Failed to create restore point. Error: $_" "ERROR"
        $SessionActions += "Failed to create restore point"
        Write-Host "$($Strings.Failure): Could not create restore point." -ForegroundColor Red
    }
    Wait-Continue
}

Function Invoke-CommandAction {
    param([string]$cmd, [string]$desc)
    Show-Section $desc
    Write-Host "`nPlease wait, this may take several minutes..." -ForegroundColor Yellow
    Try {
        Invoke-Expression $cmd
        Write-Log "Ran command: $cmd" "INFO"
        $SessionActions += "Ran $desc"
        Write-Host "$($Strings.Success): $desc" -ForegroundColor Green
    }
    Catch {
        Write-Log "Command failed: $cmd. Error: $_" "ERROR"
        $SessionActions += "$desc failed"
        Write-Host "$($Strings.Failure): $desc" -ForegroundColor Red
    }
    Wait-Continue
}

Function Invoke-SFC { Invoke-CommandAction "sfc /scannow" "System File Checker (SFC)" }
Function Invoke-DISM { Invoke-CommandAction "DISM /Online /Cleanup-Image /RestoreHealth" "DISM Health Restore" }

Function Invoke-CHKDSK {
    Show-Section "Check Disk"
    $drive = Read-Host "Enter the drive letter to check (e.g., C), or press Enter for default (C):"
    if (-not $drive) { $drive = "C" }
    if (-not (Confirm-Action "Run CHKDSK on drive $drive? (y/n): ")) { return }
    Write-Host "`nPlease wait, this may take several minutes..." -ForegroundColor Yellow
    Try {
        Invoke-Expression "chkdsk $drive`: /f"
        Write-Log "Ran Check Disk on $drive" "INFO"
        $SessionActions += "Ran CHKDSK on $drive drive"
        Write-Host "$($Strings.Success): Check Disk run on $drive (may need reboot)." -ForegroundColor Green
    }
    Catch {
        Write-Log "Check Disk failed on $drive. Error: $_" "ERROR"
        $SessionActions += "CHKDSK failed on $drive drive"
        Write-Host "$($Strings.Failure): Check Disk on $drive." -ForegroundColor Red
    }
    Wait-Continue
}

Function Reset-WindowsUpdate {
    Show-Section "Reset Windows Update Components"
    If (-not (Confirm-Action $Strings.ConfirmAction)) { return }
    Try {
        net stop wuauserv
        net stop cryptSvc
        net stop bits
        net stop msiserver
        Remove-Item -Path "$env:SystemRoot\SoftwareDistribution" -Recurse -Force -ErrorAction SilentlyContinue
        Remove-Item -Path "$env:SystemRoot\System32\catroot2" -Recurse -Force -ErrorAction SilentlyContinue
        net start wuauserv
        net start cryptSvc
        net start bits
        net start msiserver
        Write-Log "Windows Update components reset." "INFO"
        $SessionActions += "Reset Windows Update components"
        Write-Host "$($Strings.Success): Windows Update reset." -ForegroundColor Green
    }
    Catch {
        Write-Log "Windows Update reset failed. Error: $_" "ERROR"
        $SessionActions += "Failed to reset Windows Update components"
        Write-Host "$($Strings.Failure): Windows Update reset." -ForegroundColor Red
    }
    Wait-Continue
}

Function Reset-MicrosoftStore { Invoke-CommandAction "wsreset.exe" "Clear Microsoft Store Cache" }

Function Reset-Network {
    Show-Section "Reset Network Stack"
    If (-not (Confirm-Action "Are you sure you want to reset the entire network stack?")) { return }
    If (-not (Confirm-Action "This will reset network components and may disrupt connections. Continue?")) { return }
    Invoke-CommandAction "netsh int ip reset" "Network IP Stack Reset"
    Invoke-CommandAction "netsh winsock reset" "Winsock Reset"
    Invoke-CommandAction "ipconfig /flushdns" "Flush DNS Cache"
    $SessionActions += "Reset entire network stack"
}

Function Reset-IconCache {
    Show-Section "Reset Icon Cache"
    $iconCachePath = "$env:LOCALAPPDATA\IconCache.db"
    Write-Host "Warning: This will close all File Explorer windows and your desktop may temporarily disappear." -ForegroundColor Yellow
    if (Test-Path $iconCachePath) {
        if (-not (Confirm-Action "Proceed to terminate all explorer.exe processes? (y/n): ")) {
            Write-Log "User cancelled explorer.exe termination for icon cache reset." "WARN"
            $SessionActions += "Cancelled explorer.exe termination for icon cache reset"
            Write-Host "Cancelled icon cache reset." -ForegroundColor Yellow
            Wait-Continue
            return
        }
        Try {
            Stop-Process -Name explorer -Force -ErrorAction SilentlyContinue
            Remove-Item $iconCachePath -Force
            Write-Log "Icon cache deleted." "INFO"
            $SessionActions += "Deleted and reset icon cache"
            Write-Host "$($Strings.Success): Icon cache deleted (reboot to reset)." -ForegroundColor Green
        }
        Catch {
            Write-Log "Icon cache removal failed. Error: $_" "ERROR"
            $SessionActions += "Failed to remove icon cache"
            Write-Host "$($Strings.Failure): Icon cache removal." -ForegroundColor Red
        }
    }
    else {
        Write-Log "Icon cache not found." "WARN"
        $SessionActions += "Icon cache not found (nothing done)"
        Write-Host "Icon cache not found. Skipped." -ForegroundColor Yellow
    }
    Wait-Continue
}

Function Reset-WindowsApps {
    If (-not (Confirm-Action $Strings.ConfirmAction)) { return }
    Try {
        Get-AppXPackage -AllUsers | Foreach-Object {
            Add-AppxPackage -DisableDevelopmentMode -Register "$($_.InstallLocation)\AppXManifest.xml"
        }
        Write-Log "Re-registered all Windows Apps." "INFO"
        $SessionActions += "Re-registered all Windows apps"
        Write-Host "$($Strings.Success): All Windows Apps re-registered." -ForegroundColor Green
    }
    Catch {
        Write-Log "Failed to re-register Windows Apps. Error: $_" "ERROR"
        $SessionActions += "Failed to re-register Windows apps"
        Write-Host "$($Strings.Failure): Re-register Windows Apps." -ForegroundColor Red
    }
    Wait-Continue
}

Function Reset-WindowsStoreApp {
    Show-Section "Repair Windows Store App"
    If (-not (Confirm-Action $Strings.ConfirmAction)) { return }
    Try {
        if (Get-Command Reset-AppxPackage -ErrorAction SilentlyContinue) {
            Get-AppxPackage *windowsstore* | Reset-AppxPackage
            Write-Log "Windows Store app reset." "INFO"
            $SessionActions += "Reset Windows Store app"
            Write-Host "$($Strings.Success): Windows Store app reset." -ForegroundColor Green
        }
        else {
            Write-Log "Reset-AppxPackage not available. Please use PowerShell 7+ for this feature." "WARN"
            $SessionActions += "Windows Store app reset not available (PowerShell 7+ required)"
            Write-Host "Reset-AppxPackage is not available in this version of PowerShell. Please use PowerShell 7 or later for this feature." -ForegroundColor Yellow
        }
    }
    Catch {
        Write-Log "Windows Store reset failed. Error: $_" "ERROR"
        $SessionActions += "Failed to reset Windows Store app"
        Write-Host "$($Strings.Failure): Windows Store app reset." -ForegroundColor Red
    }
    Wait-Continue
}

Function Show-Help {
    Show-Section $Strings.HelpTitle
    Write-Host $Strings.HelpBody -ForegroundColor White
    $SessionActions += "Viewed help/about"
    Wait-Continue
}

# --- Network Diagnostics ---
Function Test-NetworkDiagnostics {
    Show-Section "Network Diagnostics"
    Try {
        Write-Host "Testing connectivity to 8.8.8.8..."
        $ping = Test-Connection -ComputerName 8.8.8.8 -Count 2 -ErrorAction Stop
        $ping | Out-Host
        Write-Log "Pinged 8.8.8.8 successfully." "INFO"
        $SessionActions += "Pinged 8.8.8.8 (Google DNS)"
    }
    Catch {
        Write-Log "Failed to ping 8.8.8.8. Error: $_" "ERROR"
        $SessionActions += "Failed to ping 8.8.8.8"
        Write-Host "Failed to ping 8.8.8.8." -ForegroundColor Red
    }
    Try {
        Write-Host "Testing DNS resolution for www.microsoft.com..."
        Resolve-DnsName www.microsoft.com | Out-Host
        Write-Log "DNS resolution for www.microsoft.com completed." "INFO"
        $SessionActions += "Resolved DNS for www.microsoft.com"
    }
    Catch {
        Write-Log "DNS resolution failed. Error: $_" "ERROR"
        $SessionActions += "Failed DNS resolution for www.microsoft.com"
        Write-Host "DNS resolution failed." -ForegroundColor Red
    }
    Try {
        $gateway = Get-NetRoute | Where-Object { $_.DestinationPrefix -eq '0.0.0.0/0' } | Select-Object -First 1
        if ($gateway) {
            Write-Host "Default Gateway: $($gateway.NextHop)"
            Try {
                Test-Connection -ComputerName $gateway.NextHop -Count 2 | Out-Host
                Write-Log "Pinged default gateway $($gateway.NextHop) successfully." "INFO"
                $SessionActions += "Pinged default gateway $($gateway.NextHop)"
            }
            Catch {
                Write-Log "Failed to ping default gateway $($gateway.NextHop). Error: $_" "WARN"
                $SessionActions += "Failed to ping default gateway"
            }
        }
        else {
            Write-Log "No default gateway found." "WARN"
            $SessionActions += "No default gateway found"
            Write-Host "No default gateway found." -ForegroundColor Yellow
        }
    }
    Catch {
        Write-Log "Error retrieving default gateway: $_" "ERROR"
        $SessionActions += "Failed to get default gateway"
    }
    Wait-Continue
}

# --- Disk Usage & Cleanup ---
Function Show-DiskUsage {
    Show-Section "Disk Usage"
    Try {
        Get-PSDrive -PSProvider FileSystem | Select-Object Name, Free, Used, @{Name = "FreeGB"; Expression = { "{0:N2}" -f ($_.Free / 1GB) } }, @{Name = "UsedGB"; Expression = { "{0:N2}" -f ($_.Used / 1GB) } } | Format-Table | Out-Host
        Write-Log "Displayed disk usage." "INFO"
        $SessionActions += "Displayed disk usage"
    }
    Catch {
        Write-Log "Failed to display disk usage. Error: $_" "ERROR"
        $SessionActions += "Failed to display disk usage"
        Write-Host "Failed to display disk usage." -ForegroundColor Red
    }
    Wait-Continue
}

Function Clear-TempFiles {
    Show-Section "Clean Temp Files"
    If (-not (Confirm-Action $Strings.ConfirmAction)) { return }
    Try {
        $temp = $env:TEMP
        Remove-Item "$temp\*" -Force -Recurse -ErrorAction SilentlyContinue
        Write-Log "Temp files cleaned from $temp." "INFO"
        $SessionActions += "Cleaned temp files"
        Write-Host "$($Strings.Success): Temp files cleaned." -ForegroundColor Green
    }
    Catch {
        Write-Log "Failed to clean temp files. Error: $_" "ERROR"
        $SessionActions += "Failed to clean temp files"
        Write-Host "$($Strings.Failure): Temp files not cleaned." -ForegroundColor Red
    }
    Wait-Continue
}

# --- Windows Update Status ---
Function Get-WindowsUpdates {
    Show-Section "Check for Windows Updates"
    Try {
        $updateLogPath = "$env:USERPROFILE\Desktop\WindowsUpdate.log"
        Write-Host "Windows now stores Windows Update logs in ETW trace format." -ForegroundColor Yellow
        Write-Host "To view update logs, a readable log will be generated on your Desktop using Get-WindowsUpdateLog."
        if (Confirm-Action "Do you want to generate WindowsUpdate.log on your Desktop now? (y/n): ") {
            Try {
                Get-WindowsUpdateLog -LogPath $updateLogPath | Out-Null
                Write-Host "Log generated at $updateLogPath" -ForegroundColor Green
                Write-Log "Generated WindowsUpdate.log at $updateLogPath" "INFO"
                $SessionActions += "Generated WindowsUpdate.log"
            }
            Catch {
                Write-Host "Failed to generate WindowsUpdate.log. See Microsoft documentation for troubleshooting." -ForegroundColor Red
                Write-Log "Failed to generate WindowsUpdate.log. Error: $_" "ERROR"
                $SessionActions += "Failed to generate WindowsUpdate.log"
            }
        }
        else {
            Write-Host "Skipped generating WindowsUpdate.log." -ForegroundColor Yellow
            Write-Log "Skipped generating WindowsUpdate.log." "INFO"
            $SessionActions += "Skipped generating WindowsUpdate.log"
        }
    }
    Catch {
        Write-Host "Unexpected error checking for Windows Update log." -ForegroundColor Red
        Write-Log "Unexpected error in Get-WindowsUpdates: $_" "ERROR"
        $SessionActions += "Unexpected error in Get-WindowsUpdates"
    }
    Wait-Continue
}

# --- Check/Restart Critical Services ---
Function Test-RestartCriticalServices {
    Show-Section "Check & Restart Critical Windows Services"
    $criticalServices = @("wuauserv", "bits", "lanmanworkstation", "lanmanserver", "eventlog")
    foreach ($svc in $criticalServices) {
        Try {
            $service = Get-Service -Name $svc -ErrorAction Stop
            if ($service.Status -ne 'Running') {
                Write-Host "$svc is not running. Attempting to restart..."
                Try {
                    Start-Service -Name $svc -ErrorAction Stop
                    Write-Log "$svc restarted." "INFO"
                    $SessionActions += "$svc restarted"
                    Write-Host "$svc restarted." -ForegroundColor Green
                }
                Catch {
                    Write-Log "Failed to restart $svc. Error: $_" "ERROR"
                    $SessionActions += "Failed to restart $svc"
                    Write-Host "Failed to restart $svc." -ForegroundColor Red
                }
            }
            else {
                Write-Host "$svc is running." -ForegroundColor Green
                Write-Log "$svc is running." "INFO"
                $SessionActions += "$svc running"
            }
        }
        Catch {
            Write-Log "Service $svc not found. Error: $_" "WARN"
            $SessionActions += "Service $svc not found"
            Write-Host "Service $svc not found." -ForegroundColor Yellow
        }
    }
    Wait-Continue
}

# ----- MENU -----
$menu = @{
    "1"  = @{Label = "Show Basic System Info"; Action = { Show-SystemInfo } }
    "2"  = @{Label = "Create System Restore Point"; Action = { New-RestorePoint } }
    "3"  = @{Label = "Run System File Checker (SFC)"; Action = { Invoke-SFC } }
    "4"  = @{Label = "Run DISM Health Restore"; Action = { Invoke-DISM } }
    "5"  = @{Label = "Check Disk (chkdsk)"; Action = { Invoke-CHKDSK } }
    "6"  = @{Label = "Reset Windows Update"; Action = { Reset-WindowsUpdate } }
    "7"  = @{Label = "Clear Microsoft Store Cache"; Action = { Reset-MicrosoftStore } }
    "8"  = @{Label = "Reset Network Stack"; Action = { Reset-Network } }
    "9"  = @{Label = "Reset Icon Cache"; Action = { Reset-IconCache } }
    "10" = @{Label = "Re-register All Windows Apps"; Action = { Reset-WindowsApps } }
    "11" = @{Label = "Repair Windows Store App"; Action = { Reset-WindowsStoreApp } }
    "12" = @{Label = "Run Network Diagnostics"; Action = { Test-NetworkDiagnostics } }
    "13" = @{Label = "Show Disk Usage"; Action = { Show-DiskUsage } }
    "14" = @{Label = "Clean Temp Files"; Action = { Clear-TempFiles } }
    "15" = @{Label = "Check for Windows Updates"; Action = { Get-WindowsUpdates } }
    "16" = @{Label = "Check & Restart Critical Services"; Action = { Test-RestartCriticalServices } }
    "H"  = @{Label = "Help/About"; Action = { Show-Help } }
    "Q"  = @{
        Label  = "Quit";
        Action = {
            Write-Host "`n==== Session Summary ====" -ForegroundColor Cyan
            if ($SessionActions.Count -eq 0) {
                Write-Host "No actions performed this session." -ForegroundColor Yellow
                Add-Content -Path $LogFile -Value "`n==== Session Summary ====`nNo actions performed this session."
            }
            else {
                $SessionActions | ForEach-Object {
                    Write-Host "• $_" -ForegroundColor White
                    Add-Content -Path $LogFile -Value "• $_"
                }
            }
            Write-Log $Strings.ExitMessage "INFO"
            Write-Host "`n$($Strings.LogFileSaved) $LogFile" -ForegroundColor Cyan
            Write-Host "`nThank you for using Windows System First Aid Toolkit!" -ForegroundColor Green
            Write-Host ""
            Exit
        }
    }
}

Function Get-SortedMenuKeys {
    return $menu.Keys | Sort-Object {
        if ($_ -match '^\d+$') { [int]$_ } else { [int]::MaxValue }
    }, { $_.ToString() }
}

do {
    Show-Section "$($Strings.ScriptName) — v$($Strings.Version)"
    Write-Host $Strings.MainMenu
    foreach ($key in (Get-SortedMenuKeys)) {
        Write-Host "  $key`t$($menu[$key].Label)"
    }
    $choice = (Read-Host "Your choice").Trim().ToUpper()
    if ($menu.ContainsKey($choice)) {
        & $menu[$choice].Action
    }
    else {
        Write-Host $Strings.InvalidSelection -ForegroundColor Yellow
        Wait-Continue
    }
} while ($true)
