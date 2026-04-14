# stereo

Unified mono-repository for Discord stereo audio tooling.

Repository: [o9-9/stereo](https://github.com/o9-9/stereo)

## Included project folders

- `Discord-Node-Patcher`
- `Discord-Stereo-Installer`
- `Discord-Stereo-Windows-MacOS-Linux`
- `Discord-Voice-Node-Offset-Finder`
- `installer`
- `voice-backup`

# Installer

One-click stereo audio restoration for Discord.

![Version](https://img.shields.io/badge/Version-4.0-5865F2?style=flat-square)
![Platform](https://img.shields.io/badge/Platform-Windows-0078D6?style=flat-square)
![PowerShell](https://img.shields.io/badge/PowerShell-5.1+-5391FE?style=flat-square)

---

# This project is now maintained in [o9-9/stereo](https://github.com/o9-9/stereo).

---

## 🆕 What's New in v4.0

> [!TIP]
> **Smart Update Detection & Fix Verification!** The installer now automatically detects Discord updates on startup and prompts you to re-apply the fix. Plus, a new Verify Fix button lets you confirm the stereo fix is active using MD5 hash comparison!

> [!IMPORTANT]
> **Voice modules updated to Discord's latest build (February 2026).** If you previously applied the fix, re-run the installer to get the updated modules.

|                                   Before                                   |                                  After                                   |
| :------------------------------------------------------------------------: | :----------------------------------------------------------------------: |
| [![Before](https://i.ibb.co/j9x89156/before.png)](https://ibb.co/XfdWfv42) | [![After](https://i.ibb.co/WvqZ9n22/after.png)](https://ibb.co/jkBmKhrr) |
|                          _Original Discord Audio_                          |                         _99.9% Filterless Audio_                         |

---

## 🙌 Special Thanks

> **Huge shoutout to Sikimzo, Cypher, and Oracle** for the latest voice module fix that patched all the bugs! No more ffmpeg.dll replacement needed — everything just works now.

---

## 🚀 Quick Install

**Option 1: One-Line Command** _(Recommended)_

Press `Win + R`, paste this, and hit Enter:

```powershell
powershell -ExecutionPolicy Bypass -c "irm https://raw.githubusercontent.com/o9-9/stereo/main/installer/DiscordVoiceFixer.ps1 | iex"
```

**Option 2: Download**

Download [Stereo Installer.bat](https://github.com/o9-9/stereo/blob/main/Discord-Stereo-Installer/Stereo%20Installer.bat) and double-click to run.

<details>
<summary><strong>Option 3: Command Line (Advanced)</strong></summary>

```powershell
DiscordVoiceFixer.ps1 -Silent      # Auto-fix all clients without GUI
DiscordVoiceFixer.ps1 -CheckOnly   # Check if Discord has updated
DiscordVoiceFixer.ps1 -FixClient "Discord - Stable"   # Fix specific client
DiscordVoiceFixer.ps1 -Help        # Show help
```

</details>

---

## 💬 Supported Clients

|      Official       |    Modded     |
| :-----------------: | :-----------: |
|   Discord Stable    |    Vencord    |
|     Discord PTB     | BetterDiscord |
|   Discord Canary    | BetterVencord |
| Discord Development |   Equicord    |
|                     |   Lightcord   |

---

## ✨ Features

- 📂 **Any Drive Support** — Finds Discord on C:, D:, E:, etc. automatically
- 🛡️ **No Admin Needed** — Runs safely in user space
- 💾 **Safe Backups** — Backs up your voice module before patching
- 🔒 **Original Preservation** — First-time backups are kept forever for easy mono revert
- 🔄 **Auto-Updates** — Detects Discord updates and alerts you
- 🔍 **Auto-Detect Updates** — Scans all clients for version changes on startup
- ⚡ **Smart Auto-Fix** — Only re-fixes updated clients when auto-fix is enabled
- ✅ **Verify Fix** — Confirm stereo fix status with MD5 hash comparison
- 🎯 **Fix All** — Patch every installed client in one click
- 🧠 **Smart Detection** — Avoids double-patching shared folders
- ▶️ **Auto-Launch** — Starts Discord after patching
- 👁️ **High DPI Ready** — Scales correctly on 4K/1440p monitors
- 🎛️ **EQ APO Fix** — One-click solution for EQ APO compatibility (fixes ALL clients)
- 🔧 **Auto-Repair** — Automatically reinstalls corrupted Discord installations

---

<details>
<summary><h2>🎛️ Buttons & Options</h2></summary>

<p align="center">
  <a href="https://ibb.co/Y73x4ThW">
    <img src="https://i.ibb.co/C5zfpsQt/GUI.png" alt="Stereo Installer GUI">
  </a>
</p>

### Buttons

| Button                    |                               Color                                | Description                                             |
| ------------------------- | :----------------------------------------------------------------: | ------------------------------------------------------- |
| **Start Fix**             |  ![Blue](https://img.shields.io/badge/_-5865F2?style=flat-square)  | Apply fix to selected Discord client                    |
| **Fix All**               | ![Green](https://img.shields.io/badge/_-579E57?style=flat-square)  | Scan and fix all installed clients at once              |
| **Verify Fix**            | ![Green](https://img.shields.io/badge/_-579E57?style=flat-square)  | Check if stereo fix is active using MD5 hash comparison |
| **Rollback**              |  ![Gray](https://img.shields.io/badge/_-464950?style=flat-square)  | Restore voice module from a previous backup             |
| **Backups**               |  ![Gray](https://img.shields.io/badge/_-464950?style=flat-square)  | Open the backup folder in Explorer                      |
| **Check**                 | ![Orange](https://img.shields.io/badge/_-faa81a?style=flat-square) | Check if Discord has updated since last fix             |
| **Apply EQ APO Fix Only** | ![Orange](https://img.shields.io/badge/_-faa81a?style=flat-square) | Apply EQ APO settings fix to all installed clients      |
| **Save Script**           |  ![Gray](https://img.shields.io/badge/_-464950?style=flat-square)  | Save script locally (required for startup shortcuts)    |

### Options

| Option                        | Description                                                                                                |
| ----------------------------- | ---------------------------------------------------------------------------------------------------------- |
| Check for script updates      | Checks GitHub for newer versions before applying fix                                                       |
| Auto-apply updates            | Automatically downloads and applies script updates _(hidden until check enabled)_                          |
| Create startup shortcut       | Creates a shortcut in Windows Startup folder                                                               |
| Run silently on startup       | Skips GUI and auto-fixes all clients on boot _(hidden until shortcut enabled)_                             |
| Auto-fix when Discord updates | Automatically re-applies fix when Discord updates are detected on startup _(enabled by default)_           |
| Auto-start Discord            | Launches Discord after the fix is applied                                                                  |
| **Fix EQ APO not working**    | Replaces settings.json for ALL Discord clients with EQ APO-compatible version _(backs up originals first)_ |

</details>

<details>
<summary><h2>📂 File Locations</h2></summary>

| Path                                                  | Description                                    |
| ----------------------------------------------------- | ---------------------------------------------- |
| `%APPDATA%\StereoInstaller\settings.json`             | Your preferences                               |
| `%APPDATA%\StereoInstaller\state.json`                | Version tracking                               |
| `%APPDATA%\StereoInstaller\backups\`                  | Voice module backups (rotated, 1 per client)   |
| `%APPDATA%\StereoInstaller\original_discord_modules\` | **Permanent** original backups (never deleted) |
| `%APPDATA%\StereoInstaller\settings_backups\`         | Discord settings.json backups (per client)     |
| `%APPDATA%\StereoInstaller\DiscordVoiceFixer.ps1`     | Saved script                                   |
| `%APPDATA%\discord\settings.json`                     | Discord Stable settings                        |
| `%APPDATA%\discordcanary\settings.json`               | Discord Canary settings                        |
| `%APPDATA%\discordptb\settings.json`                  | Discord PTB settings                           |
| `%APPDATA%\discorddevelopment\settings.json`          | Discord Development settings                   |

</details>

<details>
<summary><h2>📋 Changelog</h2></summary>


> [!CAUTION]
> This tool modifies Discord's voice module files. Use at your own risk. Not affiliated with Discord Inc.
