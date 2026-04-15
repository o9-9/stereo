# AI Instructions for discord-stereo Project Restructure

## Overview

- Main Repo Name: **`stereo`**
- Subfolders:
  - **[fixer](https://github.com/o9-9/stereo-powershell)**
  - **[batch](https://github.com/o9-9/stereo-batch)**
  - **[patcher](https://github.com/o9-9/stereo-patcher)**
  - **[finder](https://github.com/o9-9/stereo-finder)**
  - **[backup](https://github.com/o9-9/stereo-backup)**
  - **[system](https://github.com/o9-9/stereo-windows)**
- Primary Languages: **JavaScript, Python, PowerShell, Batchfile, Other**
- Current Structure: **Already modern, but can be optimized per GitHub best practices**

### Structure

```t
stereo/
├── .github/
│   ├── workflows/              CI/CD (GitHub Actions)
│   ├── ISSUE_TEMPLATE/         GitHub issue templates
│   └── PULL_REQUEST_TEMPLATE/  PR template
│
├── .editorconfig               Editor consistency
├── .gitignore
├── README.md                   (Root: what is discord-stereo?)
├── CONTRIBUTING.md             Contribution guidelines
├── CHANGELOG.md                Version history
├── LICENSE                     License file
├── package.json (optional)     For npm integration
├── scripts/                    Repo-level scripts (install deps, build all, etc.)
│
├── packages/
│   ├── voice-fixer/            (PowerShell GUI installer)
│   │   ├── README.md
│   │   ├── src/
│   │   │   └── DiscordVoiceFixer.ps1
│   │   ├── tests/
│   │   └── package.json
│   │
│   ├── batch-installer/        (Bootstrap batch file)
│   │   ├── README.md
│   │   ├── src/
│   │   │   └── Stereo Installer.bat
│   │   └── package.json
│   │
│   ├── node-patcher/           (Advanced Windows patcher)
│   │   ├── README.md
│   │   ├── src/
│   │   │   ├── Discord_voice_node_patcher.ps1
│   │   │   └── Stereo-Node-Patcher-Windows.BAT
│   │   └── package.json
│   │
│   ├── offset-finder/          (CLI/GUI tool for offset discovery)
│   │   ├── README.md
│   │   ├── src/
│   │   │   ├── cli/
│   │   │   └── gui/
│   │   ├── scripts/
│   │   ├── tests/
│   │   └── package.json
│   │
│   ├── backup/           (Backup utilities)
│   │   ├── README.md
│   │   ├── src/
│   │   └── package.json
│   │
│   └── system/           (Hub: assets, docs, releases)
│       ├── README.md
│       ├── docs/               Split docs from assets
│       ├── assets/             Consolidate all assets
│       │   ├── windows/
│       │   ├── linux/
│       │   ├── nodes/
│       │   └── voice-dumps/
│       └── package.json
│
├── docs/                       Root-level documentation
│   ├── ARCHITECTURE.md         (Technical deep dive)
│   ├── SETUP.md                (Development setup)
│   ├── PLATFORMS.md            (Windows/Linux/macOS guides)
│   └── FAQ.md                  (Extracted from READMEs)
│
├── tools/                      Shared repo tools
│   └── verify-structure.sh     (Validation script)
│
└── examples/                   Usage examples & demos
    ├── windows-simple/
    ├── windows-advanced/
    └── linux-patcher/
```

### Create Missing Root-Level Files

```bash
# Create standard GitHub files at root
touch .github/ISSUE_TEMPLATE/bug_report.md
touch .github/ISSUE_TEMPLATE/feature_request.md
touch .github/PULL_REQUEST_TEMPLATE.md
touch .github/workflows/ci.yml           # CI/CD for all packages
touch CONTRIBUTING.md                    # How to contribute
touch CHANGELOG.md                       # Version history
touch .editorconfig                      # Editor consistency
```

#### Files to create

- `CONTRIBUTING.md` – Contributor guide
- `CHANGELOG.md` – Version tracking (reference existing v4.0 entries)
- `.editorconfig` – Shared editor settings
- `.github/workflows/ci.yml` – Lint, test all packages

### Restructure Each Package - For each package in `packages/`, create:

```t
packages/{name}/
├── src/              # Main source files
├── tests/            # Test files (mirror src structure)
├── docs/             # Package-specific docs
├── README.md         # Package overview
└── package.json      # Package metadata
```

### Action Items

1. voice-fixer/ – PowerShell GUI

```t
Move:  (currently at root) → packages/voice-fixer/src/
  DiscordVoiceFixer.ps1
Create:
  packages/voice-fixer/tests/
  packages/voice-fixer/package.json
```

2. batch-installer/ – Bootstrap batch file

```t
Move:  Stereo Installer.bat → packages/batch-installer/src/
Create:
  packages/batch-installer/tests/
  packages/batch-installer/package.json
```

3. node-patcher/ – Advanced Windows patcher

```t
Move:  PowerShell + BAT files → packages/node-patcher/src/
Create:
  packages/node-patcher/tests/
  packages/node-patcher/package.json
```

4. offset-finder/ – Keep structure, add src/ wrapper

```t
Move:  scripts/ → packages/offset-finder/src/
  discord_voice_node_offset_finder_v5.py (and siblings)
Create:
  packages/offset-finder/tests/
  packages/offset-finder/package.json
```

5. backup/ – Backup utilities

```t
Create:
  packages/backup/src/
  packages/backup/tests/
  packages/backup/package.json
```

6. system/ – Consolidate assets

```t
Move:  Updates/ → packages/system/assets/
Move:  Voice Node Dump/ → packages/system/assets/voice-dumps/
Rename folders for clarity:
  assets/Windows/           (keeps name)
  assets/Linux/             (keeps name)
  assets/Nodes/             (was: Offset Finder)
  assets/voice-dumps/       (was: Voice Node Dump)
Create:
  packages/system/docs/    (extracted docs)
  packages/system/package.json
```

#### Create Root Documentation - Root-level `docs/` folder:

```t
docs/
├── ARCHITECTURE.md         # Extract from system/README.md
├── SETUP.md                # Dev environment setup
├── PLATFORMS.md            # Windows/Linux/macOS instructions
├── TROUBLESHOOTING.md      # FAQ extracted from READMEs
└── CONTRIBUTING.md         # Contribution workflow
```

### Update All File References - Critical updates in each file:

1. All **(README.md)**

- Update relative paths from `packages/system/Updates/Windows/...` to `packages/system/assets/windows/...`
- Update package references to new `src/` locations

2. PowerShell scripts **(voice-fixer, node-patcher)**

- Update GitHub raw URLs: `main/packages/voice-fixer/src/...`
- Update relative asset paths if any

3. Bash/Shell scripts **(offset-finder, linux launcher)**

- Update relative paths to point to `assets/` folder
- Update imports/sourcing if used between packages

4. package.json files **(create for each package)**

```json
{
  "name": "@discord-stereo/voice-fixer",
  "version": "4.0.0",
  "description": "GUI installer for stereo audio patching",
  "main": "src/DiscordVoiceFixer.ps1",
  "scripts": {
    "test": "echo 'Tests here'"
  }
}
```

### Create Shared Root Files

- `CONTRIBUTING.md`
- `CHANGELOG.md`
- `.editorconfig`

### After restructuring, verify:

#### Structure Alignment:

- [ ] All packages have `src/`, `tests/`, `README.md`, `package.json`
- [ ] No files exist directly in `packages/{name}/` root (except those 4)
- [ ] `system/assets/` contains Windows/, Linux/, Nodes/, voice-dumps/

#### File Path Updates:

- [ ] All `.md` files reference correct relative paths
- [ ] PowerShell scripts point to new GitHub URLs (`main/packages/...`)
- [ ] Bash scripts reference correct `assets/` locations
- [ ] No broken links in any README

#### Naming Consistency:

- [ ] All folder names use `kebab-case`
- [ ] All script files use `kebab-case` (rename if needed)
- [ ] GitHub paths match folder names exactly

#### Documentation:

- [ ] Root `README.md` explains monorepo structure
- [ ] `docs/ARCHITECTURE.md` contains technical deep-dive
- [ ] `CONTRIBUTING.md` exists at root
- [ ] `CHANGELOG.md` up-to-date
- [ ] Each package has its own `README.md`

#### GitHub Integration:

- [ ] `.github/workflows/` contains CI/CD config
- [ ] `.github/ISSUE_TEMPLATE/` has bug + feature templates
- [ ] `.github/PULL_REQUEST_TEMPLATE.md` exists
- [ ] `.editorconfig` enforces consistency

### Key Benefits

- Monorepo best practice – Matches Vercel/Next.js, Facebook/React patterns
- Clear separation – Each package independent but part of larger project
- Scalability – Easy to add new tools/packages later
- CI/CD ready – `.github/workflows/` can test all packages at once
- Documentation – Root `docs/` + package-level README.md
- Consistency – `.editorconfig`, `CONTRIBUTING.md` enforced
- User-friendly – Scripts/installers still accessible via old GitHub URLs
