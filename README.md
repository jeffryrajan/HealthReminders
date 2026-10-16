# Health reminders

[![Latest release](https://img.shields.io/github/v/release/jeffryrajan/HealthReminders)](https://github.com/jeffryrajan/HealthReminders/releases/latest)
[![Downloads](https://img.shields.io/github/downloads/jeffryrajan/HealthReminders/total)](https://github.com/jeffryrajan/HealthReminders/releases)
![Windows 10 and 11](https://img.shields.io/badge/Windows-10%20%7C%2011-0078D4)
[![MIT License](https://img.shields.io/github/license/jeffryrajan/HealthReminders)](LICENSE)

A small Windows tray app. When it's time to drink water or stretch, a little character walks along the top of your taskbar to remind you.

https://github.com/user-attachments/assets/8b98d956-49be-42fb-ae72-98cbfaa7af10

Also on [Instagram](https://www.instagram.com/reel/DejiANETDsj/).

**[⬇ Download the latest version (ZIP)](https://github.com/jeffryrajan/HealthReminders/releases/latest/download/HealthReminders.zip)**: free, open source, Windows 10 and 11. Install steps are [below](#install).

- Water every 30 min and a stretch every 60 min, counted only while you're at the PC.
- Being away for 5 minutes (no keyboard or mouse) restarts both timers.
- When the character arrives, click **Done** (the timer restarts) or **Snooze 10 min**.
  If you don't click anything, it leaves after a minute and comes back in 10.
- The colours follow Windows light or dark mode.

Needs Windows 10 or 11. It uses the built-in Windows PowerShell 5.1, so there's nothing else to install, and it sends nothing anywhere.

## Install

1. Download [HealthReminders.zip](https://github.com/jeffryrajan/HealthReminders/releases/latest/download/HealthReminders.zip) and unzip it somewhere permanent, such as `Documents\HealthReminders`.
2. Right-click `install.ps1` and choose **Run with PowerShell**.
   If Windows blocks it, open PowerShell in the folder and run:
   ```powershell
   powershell -ExecutionPolicy Bypass -File .\install.ps1
   ```

A blue water-drop icon appears next to the clock. It may be hidden under the `^` arrow. The app starts by itself each time you sign in to Windows.

If you use [Scoop](https://scoop.sh), you can install it with one command instead:

```powershell
scoop install https://raw.githubusercontent.com/jeffryrajan/HealthReminders/main/scoop/healthreminders.json
```

## Is it safe?

- **It sends nothing anywhere.** The scripts make no network calls.
- **It doesn't need admin rights.** It runs as you, and it doesn't change any system settings.
- **It changes very little.** `install.ps1` adds two shortcuts, one in the Start menu and one in Startup. The app saves your choices to `settings.json` in its own folder. It reads one registry value, the Windows light or dark theme setting, and doesn't write to the registry.
- **You can read all of it.** It's about 800 lines of plain PowerShell, in `HealthReminders.ps1` and `material.ps1`, with no compiled code.
- **It's easy to remove.** `uninstall.ps1` stops the app and removes the two shortcuts. Then you delete the folder.

Windows may warn you before running a script you downloaded. That's because the scripts aren't code-signed, not because something was found.
Each release lists the ZIP's SHA-256 hash, so you can check your download.

## Use

Click the tray icon to open the menu:

| Item | What it does |
|---|---|
| Water break / Stretch | Shows when each one is due. Click a row to see it now. |
| Stop / Start reminders | Pauses all reminders, or starts them again. |
| Reminder timers... | Changes the intervals, or turns one off. |

Your choices are saved in `settings.json` in the app folder.

To test it right away, run `powershell -STA -File .\HealthReminders.ps1 -Test`.

## Remove

Right-click `uninstall.ps1`, choose **Run with PowerShell**, then delete the folder.
If you installed it with Scoop, run `scoop uninstall healthreminders` instead.

## Credits and license

The code is under the [MIT License](LICENSE).

The character frames in `assets/health/` are rendered from **"AJ" by [Adobe Mixamo](https://www.mixamo.com)**. They are **not** covered by the MIT License. See [assets/health/README.txt](assets/health/README.txt) for details.
