# What `installer.ps1` does

**Stereo Installer** is a Windows PowerShell tool that applies a **stereo voice-module fix** for Discord (Stable, Canary, PTB, Development) and several modded clients (Lightcord, BetterDiscord, Vencord, Equicord, BetterVencord). It swaps Discord’s built-in `discord_voice` module files with versions downloaded from a GitHub “voice backup” repo, and keeps **backups** so you can roll back.

---

## If you run it with no switches (normal double-click or `.\installer.ps1`)

1. Opens a **graphical window** (“Stereo Installer”): pick a client, set options, and use the buttons.
2. **Start Fix** / **Fix All**: downloads the replacement voice files from GitHub, **closes Discord-related processes**, **backs up** the current voice folder (the first backup per client is kept as a permanent “original” copy), clears that folder, and copies in the new files. Records version/state under `%APPDATA%\StereoInstaller\`.
3. **Verify**: checks whether the stereo fix looks applied (compares hashes to backups/original).
4. **Rollback**: pick a backup (including **original mono** modules) and restore it after closing Discord.
5. **Check Discord version**: inspects install health; for broken official installs it can offer **automatic reinstall** via Discord’s installer, then you can fix again.
6. **Fix EQ APO** (optional): backs up each client’s Discord `settings.json` in AppData, then replaces it with a downloaded `settings.json` meant to work with EQ APO.
7. Optional behaviors (checkboxes / saved settings): **check for script updates** from GitHub, **auto-apply** script updates, **startup shortcut**, **auto-start Discord** after a fix, **re-prompt to fix** when Discord updates.
8. **Saves settings** when you close the window; writes a **debug log** to `%APPDATA%\StereoInstaller\debug.log`.

---

## Command-line modes

| Switch                  | Behavior                                                                                                                                                                                                                                                                                                  |
| ----------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **`-Help`**             | Prints usage and exits.                                                                                                                                                                                                                                                                                   |
| **`-CheckOnly`**        | No changes. Lists installed clients and whether a fix or Discord update is needed; uses exit codes for automation.                                                                                                                                                                                        |
| **`-Silent`**           | No window. Uses saved settings from `%APPDATA%\StereoInstaller\settings.json` to decide things like auto-fix-after-update, EQ APO, shortcut, and auto-start. Same core flow as the GUI fix: repair badly broken official installs if needed, download voice files, stop Discord, backup, replace modules. |
| **`-FixClient <text>`** | With **`-Silent`**, only clients whose name matches the text (wildcard-style `*text*`).                                                                                                                                                                                                                   |

---

## What it touches on disk

- **Discord install**: the `discord_voice*` module folder under the app’s `modules` directory (files inside that folder are replaced).
- **Data folder**: `%APPDATA%\StereoInstaller\` — backups (`backups\`, `original_discord_modules\`), `state.json`, `settings.json`, optional copy of the script, settings backups for EQ APO.

Requires **network access** to GitHub for voice files, optional `settings.json`, and optional script self-update.

---

## URLs that may be downloaded (or fetched) when `installer.ps1` runs

Only the paths that match what you actually do are used (e.g. **`-Help`** / **`-CheckOnly`** with no fix never downloads these).

### Script update / saved copy of the script

- `https://raw.githubusercontent.com/o9-9/stereo/main/installer.ps1`  
  Used when **checking for a script update** (GUI **Start Fix** with that option enabled) or when **saving the script to AppData** and the running script path is not available (fallback download).

### Stereo voice module files (fix / Fix All / Silent fix)

1. **Listing** (JSON, not saved as the final modules):  
   `https://api.github.com/repos/o9-9/stereo/contents/voice-backup/Discord%20Voice%20Backup`

2. **Each file in that folder** is then downloaded from whatever URL GitHub returns in the API as `download_url` for that file (typically under `raw.githubusercontent.com/o9-9/stereo/main/voice-backup/...`, one URL per file in the repo folder).

### EQ APO fix (`settings.json` replacement)

- `https://raw.githubusercontent.com/o9-9/stereo/main/voice-backup/settings.json`

### Discord Windows installer (corrupted official install repair / reinstall)

The script downloads the **full Discord setup `.exe`** from Discord’s API (channel depends on the client):

- Stable: `https://discord.com/api/downloads/distributions/app/installers/latest?channel=stable&platform=win&arch=x64`
- Canary: `https://discord.com/api/downloads/distributions/app/installers/latest?channel=canary&platform=win&arch=x64`
- PTB: `https://discord.com/api/downloads/distributions/app/installers/latest?channel=ptb&platform=win&arch=x64`
- Development: `https://discord.com/api/downloads/distributions/app/installers/latest?channel=development&platform=win&arch=x64`
