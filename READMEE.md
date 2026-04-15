# Discord Stereo

Monorepo for tools that patch Discord’s native `discord_voice` module for stereo audio on **Windows** and **Linux**.

Scripts and installers load assets from **`o9-9/stereo`** on GitHub (`main` branch). After you push this tree to that repository, raw and API URLs in the packages resolve correctly.

## Layout (`packages/`)

| Package                                          | Role                                                                                                                                        |
| ------------------------------------------------ | ------------------------------------------------------------------------------------------------------------------------------------------- |
| [**system**](packages/system/)                   | Stereo hub: `Updates/` (Windows/Linux installers, patchers, offset finder copy, node bundles), `Voice Node Dump/`, main user-facing README. |
| [**voice-fixer**](packages/voice-fixer/)         | `DiscordVoiceFixer.ps1` — GUI installer for pre-patched voice modules (standalone path).                                                    |
| [**batch-installer**](packages/batch-installer/) | `Stereo Installer.bat` — one-liner bootstrap to `voice-fixer`.                                                                              |
| [**node-patcher**](packages/node-patcher/)       | Windows advanced patcher (`Discord_voice_node_patcher.ps1` + `.BAT`).                                                                       |
| [**offset-finder**](packages/offset-finder/)     | Offset discovery CLI/GUI under [`scripts/`](packages/offset-finder/scripts/).                                                               |
| [**voice-backup**](packages/voice-backup/)       | `settings.json` and `Discord Voice Backup/` consumed by the GitHub API from installers.                                                     |

## Quick links

- **Windows (hub):** [`packages/system/Updates/Windows/Stereo Installer.bat`](packages/system/Updates/Windows/Stereo%20Installer.bat)
- **Linux launcher:** [`packages/system/Updates/Linux/discord-stereo-launcher.sh`](packages/system/Updates/Linux/discord-stereo-launcher.sh)
- **Full documentation:** [`packages/system/README.md`](packages/system/README.md)

## Repository layout note

Older docs referred to separate repos (`discord-stereo-windows`, `discord-stereo-powershell`, etc.). Those trees now live only under `packages/` as above.

### Repos into **Stereo Repo**

- [Stereo](https://github.com/o9-9/stereo) (`https://github.com/o9-9/stereo`)

### Repos

- [Patcher](https://github.com/o9-9/stereo-patcher) (`https://github.com/o9-9/stereo-patcher`)
- [Finder](https://github.com/o9-9/stereo-finder) (`https://github.com/o9-9/stereo-finder`)
- [Batch](https://github.com/o9-9/stereo-batch) (`https://github.com/o9-9/stereo-batch`)
- [Backup](https://github.com/o9-9/stereo-backup) (`https://github.com/o9-9/stereo-backup`)
- [Powershell](https://github.com/o9-9/stereo-powershell) (`https://github.com/o9-9/stereo-powershell`)
- [Windows](https://github.com/o9-9/stereo-windows) (`https://github.com/o9-9/stereo-windows`)
