# 🎙️ Discord Voice Node Patcher

**Studio-grade audio for Discord: 48kHz • 400kbps • True Stereo**

![Version](https://img.shields.io/badge/Version-5.0-5865F2?style=flat-square)
![Platform](https://img.shields.io/badge/Platform-Windows-0078D6?style=flat-square)
![PowerShell](https://img.shields.io/badge/PowerShell-5.1+-5391FE?style=flat-square)

---
## ⚠️ YES I AM AWARE THAT 3X AND ABOVE IS BROKEN WILL BE FIXING IT TONIGHT!!!

## ⬇️ Download & Run

### Option 1: One-Click BAT (Recommended)

[**📥 Download DiscordVoicePatcher.bat**](https://github.com/ProdHallow/Discord-Node-Patcher-Feb-9-2026/releases/latest)

Just download and double-click. Always runs the latest version.

---

### Option 2: One-Liner (No Download)

> ⚠️ This one-liner is **PowerShell**. It will **not** work in **Command Prompt (cmd.exe)**.
>
> If you pasted it into cmd.exe, use the cmd.exe version below (it launches PowerShell for you).

#### PowerShell (recommended)
```powershell
$ProgressPreference='SilentlyContinue'; $p = Join-Path $env:TEMP 'dvp.ps1'; Invoke-WebRequest -Uri 'https://raw.githubusercontent.com/ProdHallow/Discord-Node-Patcher-Feb-9-2026/main/Discord_voice_node_patcher.ps1' -OutFile $p; powershell -NoProfile -ExecutionPolicy Bypass -File $p
```

#### Command Prompt (cmd.exe)
```bat
powershell -NoProfile -ExecutionPolicy Bypass -Command "$ProgressPreference='SilentlyContinue'; $p = Join-Path $env:TEMP 'dvp.ps1'; Invoke-WebRequest -Uri 'https://raw.githubusercontent.com/ProdHallow/Discord-Node-Patcher-Feb-9-2026/main/Discord_voice_node_patcher.ps1' -OutFile $p; & $p"
```

Paste into the matching shell and press Enter.

---

## ⚠️ Requirement

**You need a C++ compiler.** Install one of these first:

| Compiler | Download |
|----------|----------|
| **Visual Studio** (Recommended) | [Download](https://visualstudio.microsoft.com/downloads/) — Select "Desktop development with C++" |
| MinGW-w64 | [Download](https://www.mingw-w64.org/downloads/) |
| LLVM/Clang | [Download](https://releases.llvm.org/download.html) |

---

## ✨ What It Does

| Before | After |
|:------:|:-----:|
| 24 kHz | **48 kHz** |
| ~64 kbps | **400 kbps** |
| Mono | **True Stereo** |
| Fixed gain | **1x-10x Adjustable** |

Works with: **Discord Stable, Canary, PTB, Development, BetterDiscord, Vencord, Equicord, BetterVencord, Lightcord**

> 🎚️ Gain note: `1x` now uses stereo normalization, so duplicated mono-to-stereo audio does not add the common +3 dB jump.

---

## 🆕 What's New in v5.0

| Feature | Description |
|---------|-------------|
| **400kbps Bitrate** | Upgraded from 382kbps to 400kbps — matches the maximum Opus bitrate used by the reference encoder |
| **Duplicate Bitrate Path Patched** | Discovered and patched a parallel bitrate calculation function (`0x53D750`) that the original patcher missed — eliminates a leak path where the old 32kbps value could persist |
| **Encoder Config Hot-Start** | Two Opus encoder config constructors (`0x3A737E`, `0x3A6C87`) now initialize at 400kbps instead of 32kbps — closes the window between encoder creation and the first `SetBitrate` call |
| **18 Total Offsets** | Up from 15 — patcher updated for full coverage |

---

<details>
<summary><h2>📖 Full Documentation</h2></summary>

### GUI Features

- **Client Dropdown** — Auto-detects all installed Discord variants
- **Gain Slider** — Adjust volume from 1x to 10x
- **Auto-Relaunch** — Automatically restart Discord after patching (enabled by default)
- **Patch All** — Fix every client with one click
- **Backup/Restore** — Automatic backups before patching

### Command Line

```powershell
.\script.ps1                      # Open GUI
.\script.ps1 -FixAll              # Patch all clients (no GUI)
.\script.ps1 -FixClient "Canary"  # Patch specific client
.\script.ps1 -Restore             # Restore from backup
.\script.ps1 -ListBackups         # Show backups
.\script.ps1 -AudioGainMultiplier 3  # Set gain level
.\script.ps1 -SkipUpdateCheck     # Skip auto-update check
```

### Gain Guide

| Level | Use Case | Safety |
|:-----:|----------|:------:|
| 1-2x | Normal use | ✅ Safe |
| 3-4x | Quiet sources | ⚠️ Caution |
| 5-10x | Maximum boost | ❌ May distort |

### File Locations

| Path | Purpose |
|------|---------|
| `%TEMP%\DiscordVoicePatcher\` | Logs, config, compiled patcher |
| `%TEMP%\DiscordVoicePatcher\Backups\` | Auto-backups (max 10) |

</details>

<details>
<summary><h2>🔧 Troubleshooting</h2></summary>

| Problem | Solution |
|---------|----------|
| "No compiler found" | Install Visual Studio with C++ workload |
| "I have VS Code but compile still fails" | VS Code is an editor, not a compiler. Install Visual Studio (or Visual Studio Build Tools) with the **Desktop development with C++** workload and Windows SDK |
| "Discord not found" | Make sure Discord is running |
| "Access denied" | Script auto-elevates, just accept the prompt |
| "1x still sounds boosted" | Re-run the latest patcher. `1x` now applies stereo normalization for neutral baseline loudness |
| Audio distorted | Lower gain to 1-2x |
| No effect after patch | Restart Discord completely |
| "Binary validation failed" | Your discord_voice.node doesn't match the Feb 2026 build — wait for a patcher update or restore from backup |

### View Logs
```powershell
notepad "$env:TEMP\DiscordVoicePatcher\patcher.log"
```

### Restore Original
```powershell
# (PowerShell) Run the patcher again, then select "Restore" in the GUI
$ProgressPreference='SilentlyContinue'; $p = Join-Path $env:TEMP 'dvp.ps1'; Invoke-WebRequest -Uri 'https://raw.githubusercontent.com/ProdHallow/Discord-Node-Patcher-Feb-9-2026/main/Discord_voice_node_patcher.ps1' -OutFile $p; powershell -NoProfile -ExecutionPolicy Bypass -File $p
# Then select "Restore" in the GUI
```

</details>

<details>
<summary><h2>📋 Changelog</h2></summary>

### v5.0 (Current) — 400kbps + Full Bitrate Coverage
- 🚀 **NEW:** Bitrate upgraded from 382kbps to 400kbps across all patch sites
- 🚀 **NEW:** `DuplicateEmulateBitrateModified` (`0x53D750`) — patches the parallel bitrate calculation function that bypassed the original `SetBitrate` path, preventing 32kbps leakthrough
- 🚀 **NEW:** `EncoderConfigInit1` (`0x3A737E`) and `EncoderConfigInit2` (`0x3A6C87`) — patches both Opus encoder config constructors to initialize at 400kbps instead of 32kbps default
- 🔀 **CHANGED:** All bitrate bytes updated: `\xF0\xD4\x05` (382kbps) → `\x80\x1A\x06` (400kbps / 0x61A80)
- 🧹 **CLEANUP:** Section comment blocks converted to `# region` / `# endregion` style

### v4.0 — February 2026 Build
- 🚀 **NEW:** All 15 offsets updated for Feb 9, 2026 discord_voice.node build
- 🚀 **NEW:** Pre-patch binary validation — checks original bytes at 3 sites across different PE sections before writing anything
- 🚀 **NEW:** Already-patched detection — recognizes patched signatures and re-applies safely (e.g. for gain changes)
- 🚀 **NEW:** Bounds-checked `PatchBytes` — every write validates `offset + length ≤ fileSize` and aborts on overflow
- 🚀 **NEW:** File size gate (12–18 MB) rejects obviously wrong binaries before any patches are attempted
- 🚀 **NEW:** Dynamic HighPassFilter stub — `mov rax, IMAGE_BASE + HighpassCutoffFilter; ret` computed at compile time from offset constants, no more hardcoded byte strings
- 🛡️ **SECURITY:** Auto-updater now compares `[version]` objects and refuses downgrades (prevents v4.0 → v3.1 regression from stale remote)
- 🔀 **CHANGED:** Repository moved to [Discord-Node-Patcher-Feb-9-2026](https://github.com/ProdHallow/Discord-Node-Patcher-Feb-9-2026)
- 🔀 **CHANGED:** Voice backup files hosted in new repo's `discord_voice/` directory
- 🛠️ **FIXED:** `char` signedness — HighPassFilter stub uses `unsigned char` array instead of signed `char` casts

### v3.1 — Bugfix Release
- 🐛 **FIXED:** Mod clients (BetterDiscord, Vencord, Equicord, BetterVencord) showing "This client is not installed" when they share the same install path as Discord Stable
- 🐛 **FIXED:** C++ generated code missing `Process32First` call — could silently skip the first process in the snapshot
- 🐛 **FIXED:** MSVC compilation could deadlock when reading stdout/stderr; now redirects to log file with 120-second timeout
- 🐛 **FIXED:** MSVC build path parsing broken for usernames containing spaces
- 🐛 **FIXED:** `$args` variable shadowing in MinGW/Clang compilation
- 🐛 **FIXED:** `-SkipUpdateCheck` flag not passed through during auto-elevation
- ✨ Added `DetectPath` for mod clients — checks for mod-specific folders (e.g. `%APPDATA%\BetterDiscord`) before listing as installed
- ✨ Added config file validation for out-of-range gain values
- ✨ Added `Cleanup-TempFiles` — removes compiler artifacts after patching
- 🧹 Removed comment blocks; replaced `#region`/`#endregion` with numbered section headers

### v3.0 — Major Release
- 🚀 **NEW:** Automatic voice module replacement from GitHub
- 🚀 **NEW:** Auto-relaunch checkbox — automatically restart Discord after patching
- 🐛 **FIXED:** Gain slider now responds to all input types (click, drag, keyboard)
- 🐛 **FIXED:** Replaced minified C++ code with clean original code (fixes Discord crash on voice join)
- ⚠️ **Breaking Change:** Patches are now applied to known-compatible module files rather than arbitrary Discord versions

### v2.6.2
- 🐛 Fixed MSVC compilation error ("Cannot open source file")
- ✨ Added auto-update system
- ✨ Added BAT launcher

### v2.6.1
- 🐛 Fixed empty string parameter error
- 🐛 Fixed array handling issues
- 🐛 Fixed GUI variable scoping

### v2.6.0
- ✨ Multi-client detection (9 Discord variants)
- ✨ "Patch All" button
- ✨ CLI batch mode (`-FixAll`, `-FixClient`)

### v2.5
- ✨ Disk-based detection (no voice channel needed)
- ✨ Auto-elevation

[View full changelog →](https://github.com/ProdHallow/Discord-Node-Patcher-Feb-9-2026/releases)

</details>

<details>
<summary><h2>🔬 Technical Details</h2></summary>

### How It Works (v5.0)

1. Downloads compatible voice module files from GitHub backup repository
2. Closes Discord processes
3. Backs up existing voice module (for rollback)
4. Replaces voice module files with compatible versions
5. **Validates binary** — checks original bytes at 3 code sections to confirm correct build
6. PowerShell generates C++ patcher code with your settings
7. Compiles to an executable using your C++ compiler
8. Applies **bounds-checked** binary patches at 18 specific memory offsets
9. Cleans up temporary compiler artifacts
10. Optionally relaunches Discord

### What Gets Patched

| Component | Change |
|-----------|--------|
| Stereo | Disables mono downmix |
| Bitrate | Removes 64kbps cap → 400kbps |
| Sample Rate | Bypasses 24kHz limit → 48kHz |
| Duplicate Bitrate Path | Patches parallel calculation function |
| Encoder Init | Hot-starts both constructors at 400kbps |
| Audio Processing | Replaces filters with gain control |
| Error Handler | Disabled to prevent patch-related throws |

### Offset Table (Feb 9, 2026 Build)

```
0x53840B  EmulateStereoSuccess1            → 02
0x538417  EmulateStereoSuccess2            → EB (JMP)
0x118C41  CreateAudioFrameStereo           → 49 89 C5 90
0x3A7374  OpusConfigChannels               → 02
0x0D7E49  MonoDownmixer                    → NOP sled + JMP
0x53886A  EmulateBitrateModified           → 80 1A 06 (400kbps)
0x53A691  SetsBitrateBitrateValue          → 80 1A 06 00 00
0x53A699  SetsBitrateBitwiseOr             → 90 90 90
0x53D750  DuplicateEmulateBitrateModified  → 80 1A 06 (400kbps)
0x538573  Emulate48Khz                     → 90 90 90
0x544680  HighPassFilter                   → mov rax, <HPC VA>; ret
0x8BD4C0  HighpassCutoffFilter             → injected hp_cutoff()
0x8BD6A0  DcReject                         → injected dc_reject()
0x8B9830  DownmixFunc                      → C3 (ret)
0x3A7610  ConfigIsOk                       → return 1
0x2C0040  ThrowError                       → C3 (ret)
0x3A737E  EncoderConfigInit1               → 80 1A 06 00 (400kbps default)
0x3A6C87  EncoderConfigInit2               → 80 1A 06 00 (400kbps default)
```

### Safety Features

| Check | What It Catches |
|-------|----------------|
| File size gate (12–18 MB) | Completely wrong file type |
| Pre-patch byte probes (3 sections) | Wrong build / wrong Discord version |
| Already-patched detection | Re-patching safely for gain changes |
| Per-write bounds check | Offset overflow from build mismatch |
| Version-aware auto-update | Prevents downgrade to older offsets |

</details>

---

## 👥 Credits

**Offsets & Research** — Cypher · Oracle  
**Script & GUI** — Claude (Anthropic)  
**Enhancements** — ProdHallow

---

> ⚠️ **Disclaimer:** Modifies Discord files. Use at your own risk. Re-run after Discord updates. Not affiliated with Discord Inc.

<div align="center">

**[Report Issue](https://github.com/ProdHallow/Discord-Node-Patcher-Feb-9-2026/issues)** · **[Releases](https://github.com/ProdHallow/Discord-Node-Patcher-Feb-9-2026/releases)** · **[Source Code](https://github.com/ProdHallow/Discord-Node-Patcher-Feb-9-2026)**

</div>
