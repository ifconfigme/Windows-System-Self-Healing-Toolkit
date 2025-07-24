# WinSystemFirstAidKit.ps1

*A robust, modular PowerShell toolkit for diagnosing and repairing Windows 10/11 systems—crafted for technical users, creative professionals, and anyone seeking clarity and confidence in their PC’s health.*

---

## Overview

**WinSystemFirstAidKit.ps1** is a comprehensive script designed to help users maintain and repair their Windows systems by running diagnostic checks, performing repairs, and resetting or reconfiguring key components.

Whether you’re troubleshooting problems, ensuring system reliability before an important project, or simply want to keep your PC in optimal condition, this toolkit provides clarity, transparency, and user agency at every step.

---

## Features

- **Admin rights check:** Script ensures it’s run with proper privileges.
- **Logging:** All actions are logged to a timestamped file, with levels (`INFO`, `WARN`, `ERROR`) for easy review.
- **Menu-driven interface:** Select only the diagnostics or repairs you need.
- **Modular design:** Easily extend the toolkit with new or custom modules.
- **Human-friendly prompts:** Confirm before impactful actions; help/about menu built in.
- **Localization-ready:** All user-facing strings are centralized for easy translation.
- **Versioned & auditable:** Includes versioning and robust feedback.
- **No forced reboots:** You’re always in control.

---

## Architecture & Key Sections

- **Settings:** Script name, version, and log file location.
- **Localization Strings:** All messages and prompts for easy adaptation.
- **Logging Functions:** Centralized logging to both file and console, with colored output for severity.
- **Admin Rights Check:** Exits gracefully if not run as administrator.
- **Utility Functions:** Includes confirmation prompts, pause, and user-friendly section headers.
- **Repair & Diagnostic Functions:**
  - **Show-SystemInfo:** Displays key system information.
  - **Create-RestorePoint:** Safely creates a Windows restore point.
  - **Run-SFC:** Repairs missing or corrupted files.
  - **Run-DISM:** Repairs Windows image corruption.
  - **Run-CHKDSK:** Checks and fixes file system errors.
  - **Reset-WindowsUpdate:** Repairs Windows Update services.
  - **Reset-MicrosoftStore:** Clears Microsoft Store cache.
  - **Reset-Network:** Resets the network stack.
  - **Rebuild-IconCache:** Rebuilds the Windows icon cache.
  - **Reregister-WindowsApps:** Re-registers all Windows apps.
  - **Reset-WindowsStoreApp:** Repairs the Windows Store app itself.
  - **Show-Help:** In-script documentation and help.
- **Main Menu Loop:** Choose actions interactively; includes Help/About and Quit (with log file location).

---

## Usage

1. **Download** [`WinSystemFirstAidKit.ps1`](./WinSystemFirstAidKit.ps1).
2. **Right-click** the file and select **Run with PowerShell**  
   *(or run from an elevated PowerShell terminal)*.
3. **Choose** desired actions from the interactive menu.
4. **Follow prompts**—the script explains each step and always seeks confirmation for impactful changes.
5. **Reboot** after major repairs for best results.

---

## Example Actions

- View basic system info
- Create a system restore point
- Run System File Checker (`sfc /scannow`)
- Repair Windows image with DISM
- Scan/fix disk errors (`chkdsk`)
- Reset Windows Update components
- Clear Microsoft Store cache
- Reset the network stack
- Rebuild icon cache
- Re-register Windows apps
- Repair Windows Store app

---

## Who Should Use This?

- **End Users:** Anyone seeking to diagnose or repair a sluggish or problematic Windows system.
- **Creators:** Musicians, producers, writers, and other creatives who rely on a stable, responsive machine.
- **Technologists:** Users who value transparency, control, and the ability to audit or customize repairs.
- **Power Users:** Those maintaining, optimizing, or preparing a system for demanding tasks.

---

## Philosophy

This toolkit is founded on the principle that technical tools should foster understanding, not mystery; empower users, not alienate them.  
A healthy system isn’t just fast—it’s calm, reliable, and invisible, quietly supporting your best work.

---

## Credits

Created by **Daniel Monbrod** and [ChatGPT](https://openai.com/chatgpt)  
*With gratitude to the open source and Windows communities that inspire digital resilience and transparency.*

---

## License

MIT License

Copyright (c) 2025 ifconfigme

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.

---

## Contribute

Suggestions, issues, improvements, and pull requests are welcome!  

---

*May your system be smooth, your sessions uninterrupted, and your curiosity never exhausted.*
