# Windows System Health Toolkit

*A thoughtful, modular, and transparent Windows repair & diagnostics script—curated for technical enthusiasts, creative professionals, and anyone who seeks to maintain harmony between human creativity and digital infrastructure.*

---

## What Is This?

**Windows System Health Toolkit** is an interactive PowerShell script designed to help you diagnose, repair, and rejuvenate your PC running Windows 10/11.

Rather than a blunt “fix-everything” hammer, this toolkit is a gentle companion: it explains what it’s doing, invites your consent for every step, and lets you choose only what you need—nothing more, nothing less.

Whether you’re a developer seeking stability, a musician chasing low latency, or simply someone who wants their system to just work, this script aims to be your digital first aid kit—clear, safe, and robust.

---

## Features

- **Menu-driven:** Select which tasks to run; skip what you don’t need.
- **Human-friendly output:** Each step is explained—no black boxes.
- **Safe by design:** Offers to create a System Restore Point before major changes.
- **Comprehensive:** Repairs system files, Windows image, network stack, Windows Store, icons, and more.
- **Diagnostics:** Get basic system info in one click.
- **Modular:** Easily add, remove, or customize features to suit your needs.
- **No forced reboots:** You’re always in control.

---

## Included Functions

- View key system info
- Create a System Restore Point
- Run System File Checker (`sfc /scannow`)
- Repair Windows image with DISM
- Scan and fix disk errors (`chkdsk`)
- Reset Windows Update components
- Clear Microsoft Store cache
- Reset the network stack
- Rebuild icon cache
- Re-register all Windows apps
- Repair Windows Store app

---

## How To Use

1. **Download** the script:  
   [`WinHealthToolkit.ps1`](./WinHealthToolkit.ps1)

2. **Right-click** the file and select  
   **Run with PowerShell**  
   *(or run it from an elevated PowerShell terminal)*

3. **Choose** the repairs or diagnostics you want from the interactive menu.

4. **Follow prompts**—the script will guide you and explain each step.

5. **Reboot** after any major repairs for best results.

---

## Who Should Use This?

- Creators (musicians, artists, writers) seeking a “quiet” machine for their flow
- Technologists who value transparency and control
- Power users who want to maintain or revive a Windows system without risky guesswork

---

## Philosophy

This toolkit is inspired by the conviction that technical tools should foster understanding, not mystery; empower users, not alienate them.
A healthy system isn’t just fast—it’s calm, reliable, and invisible, quietly supporting your best work.

---

## Credits

Created by **Daniel Monbrod** and [ChatGPT4.1](https://openai.com/chatgpt)  
*(with gratitude for the open source and creative communities that make digital resilience possible)*

---

## License

MIT License

---

## Contribute

If you have ideas, improvements, or new diagnostics to add, open an issue or submit a pull request.
All thoughtful contributions—technical, editorial, or philosophical—are welcome.

---

*May your system be swift, your sessions uninterrupted, and your curiosity never exhausted.*
