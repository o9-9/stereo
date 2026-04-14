You are restructuring the discord-stereo monorepo for optimal maintainability.

TASK: Refactor using the structure above. For each action:

1. **Move files** – Use exact paths (preserve file content)
2. **Rename folders** – Update=all references in all files
3. **Create files** – Use templates provided above
4. **Update imports** – Verify all relative paths work
5. **Test links** – Ensure GitHub raw URLs are correct

NAMING RULES:
- Folders: kebab-case (voice-fixer, offset-finder)
- Scripts: kebab-case (discord-voice-fixer.ps1)
- Docs: UPPERCASE.md (README.md, CONTRIBUTING.md)

VERIFICATION:
After each change, run:
  grep -r "packages/distribution/Updates/" . 
  (should return only .git/ files)
  
Check all relative paths work by opening in VS Code.

Keep Discord Stereo functionality 100% intact.
