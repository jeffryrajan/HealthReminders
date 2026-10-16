# Health reminders

A small Windows tray app. When it's time to drink water or stretch, a little character walks along the top of your taskbar to remind you.

- Water every 30 min and a stretch every 60 min, counted only while you're at the PC.
- Being away for 5 minutes (no keyboard or mouse) restarts both timers.
- When the character arrives, click **Done** (the timer restarts) or **Snooze 10 min**.
  If you don't click anything, it leaves after a minute and comes back in 10.
- The colours follow Windows light or dark mode.

Needs Windows 10 or 11. It uses the built-in Windows PowerShell 5.1, so there's nothing else to install, and it sends nothing anywhere.

## Install

1. Download this repo (**Code > Download ZIP**, then unzip) or clone it. Put it somewhere permanent, such as `Documents\HealthReminders`.
2. Right-click `install.ps1` and choose **Run with PowerShell**.
   If Windows blocks it, open PowerShell in the folder and run:
   ```powershell
   powershell -ExecutionPolicy Bypass -File .\install.ps1
   ```

A blue water-drop icon appears next to the clock. It may be hidden under the `^` arrow. The app starts by itself each time you sign in to Windows.

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

## Credits and license

The code is under the [MIT License](LICENSE).

The character frames in `assets/health/` are rendered from **"AJ" by [Adobe Mixamo](https://www.mixamo.com)**. They are **not** covered by the MIT License. See [assets/health/README.txt](assets/health/README.txt) for details.
