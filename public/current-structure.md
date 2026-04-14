discord-stereo/
├── .github/
│ ├── workflows/ CI/CD (GitHub Actions)
│ ├── ISSUE_TEMPLATE/ GitHub issue templates
│ └── PULL_REQUEST_TEMPLATE/ PR template
│
├── .editorconfig Editor consistency
├── .gitignore
├── README.md (Root: what is discord-stereo?)
├── CONTRIBUTING.md Contribution guidelines
├── CHANGELOG.md Version history
├── LICENSE License file
├── package.json (optional) For npm integration
├── scripts/ Repo-level scripts (install deps, build all, etc.)
│
├── packages/
│ ├── voice-fixer/ (PowerShell GUI installer)
│ │ ├── README.md
│ │ ├── src/
│ │ │ └── DiscordVoiceFixer.ps1
│ │ ├── tests/
│ │ └── package.json
│ │
│ ├── batch-installer/ (Bootstrap batch file)
│ │ ├── README.md
│ │ ├── src/
│ │ │ └── Stereo Installer.bat
│ │ └── package.json
│ │
│ ├── node-patcher/ (Advanced Windows patcher)
│ │ ├── README.md
│ │ ├── src/
│ │ │ ├── Discord_voice_node_patcher.ps1
│ │ │ └── Stereo-Node-Patcher-Windows.BAT
│ │ └── package.json
│ │
│ ├── offset-finder/ (CLI/GUI tool for offset discovery)
│ │ ├── README.md
│ │ ├── src/
│ │ │ ├── cli/
│ │ │ └── gui/
│ │ ├── scripts/
│ │ ├── tests/
│ │ └── package.json
│ │
│ ├── backup/ (Backup utilities)
│ │ ├── README.md
│ │ ├── src/
│ │ └── package.json
│ │
│ └── distribution/ (Hub: assets, docs, releases)
│ ├── README.md
│ ├── docs/ Split docs from assets
│ ├── assets/ Consolidate all assets
│ │ ├── windows/
│ │ ├── linux/
│ │ ├── nodes/
│ │ └── voice-dumps/
│ └── package.json
│
├── docs/ Root-level documentation
│ ├── ARCHITECTURE.md (Technical deep dive)
│ ├── SETUP.md (Development setup)
│ ├── PLATFORMS.md (Windows/Linux/macOS guides)
│ └── FAQ.md (Extracted from READMEs)
│
├── tools/ Shared repo tools
│ └── verify-structure.sh (Validation script)
│
└── examples/ Usage examples & demos
├── windows-simple/
├── windows-advanced/
└── linux-patcher/
