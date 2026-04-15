# Move 6 repos into the `stereo` monorepo

## Target structure

```text
stereo/
├─ repos/
│  ├─ discord-stereo-patcher/
│  ├─ discord-stereo-finder/
│  ├─ discord-stereo-batch/
│  ├─ discord-stereo-backup/
│  ├─ discord-stereo-powershell/
│  └─ discord-stereo-windows/
```

## Best approach

### 1. Use the `stereo` monorepo

[`stereo`](https://github.com/o9-9/stereo)

### 2. Clone the repo

```bash
git clone https://github.com/o9-9/stereo.git
cd stereo
```

### 3. Add the 6 repos as remotes

```bash
git remote add discord-stereo-patcher https://github.com/o9-9/stereo-patcher.git
git remote add discord-stereo-finder https://github.com/o9-9/stereo-finder.git
git remote add discord-stereo-batch https://github.com/o9-9/stereo-batch.git
git remote add discord-stereo-backup https://github.com/o9-9/stereo-backup.git
git remote add discord-stereo-powershell https://github.com/o9-9/stereo-powershell.git
git remote add discord-stereo-windows https://github.com/o9-9/stereo-windows.git
```

### 4. Pull the 6 repos with `git subtree`

```bash
git fetch discord-stereo-patcher
git subtree add --prefix=repos/discord-stereo-patcher discord-stereo-patcher main --squash

git fetch discord-stereo-finder
git subtree add --prefix=repos/discord-stereo-finder discord-stereo-finder main --squash

git fetch discord-stereo-batch
git subtree add --prefix=repos/discord-stereo-batch discord-stereo-batch main --squash

git fetch discord-stereo-backup
git subtree add --prefix=repos/discord-stereo-backup discord-stereo-backup main --squash

git fetch discord-stereo-powershell
git subtree add --prefix=repos/discord-stereo-powershell discord-stereo-powershell main --squash

git fetch discord-stereo-windows
git subtree add --prefix=repos/discord-stereo-windows discord-stereo-windows main --squash
```

### 5. Push the `stereo` repo

```bash
git push origin main
```

---

```bash
git clone https://github.com/o9-9/stereo.git
cd stereo

git remote add discord-stereo-patcher https://github.com/o9-9/stereo-patcher.git
git remote add discord-stereo-finder https://github.com/o9-9/stereo-finder.git
git remote add discord-stereo-batch https://github.com/o9-9/stereo-batch.git
git remote add discord-stereo-backup https://github.com/o9-9/stereo-backup.git
git remote add discord-stereo-powershell https://github.com/o9-9/stereo-powershell.git
git remote add discord-stereo-windows https://github.com/o9-9/stereo-windows.git

git subtree add --prefix=repos/discord-stereo-patcher discord-stereo-patcher main --squash
git subtree add --prefix=repos/discord-stereo-finder discord-stereo-finder main --squash
git subtree add --prefix=repos/discord-stereo-batch discord-stereo-batch main --squash
git subtree add --prefix=repos/discord-stereo-backup discord-stereo-backup main --squash
git subtree add --prefix=repos/discord-stereo-powershell discord-stereo-powershell main --squash
git subtree add --prefix=repos/discord-stereo-windows discord-stereo-windows main --squash

git push origin main
```

---

## Bash Script

```bash
#!/usr/bin/env bash
set -euo pipefail

BRANCH="main"
MONOREPO="stereo"
WORKDIR="$(pwd)/.tmp-repos"
PATCH_DIR="$(pwd)/.patches"

REPOS=(
  "https://github.com/o9-9/stereo-patcher.git"
  "https://github.com/o9-9/stereo-finder.git"
  "https://github.com/o9-9/stereo-batch.git"
  "https://github.com/o9-9/stereo-backup.git"
  "https://github.com/o9-9/stereo-powershell.git"
  "https://github.com/o9-9/stereo-windows.git"
)

rm -rf "$WORKDIR" "$PATCH_DIR" "$MONOREPO"
mkdir -p "$WORKDIR" "$PATCH_DIR"

# 1. clone all repos
for repo in "${REPOS[@]}"; do
  name=$(basename "$repo" .git)
  git clone --quiet "$repo" "$WORKDIR/$name"
done

# 2. collect commits (timestamp + sha + repo)
TMP=$(mktemp)

for dir in "$WORKDIR"/*; do
  name=$(basename "$dir")
  (
    cd "$dir"
    git log "$BRANCH" --reverse --format="%ct %H $name"
  )
done > "$TMP"

# 3. sort chronologically
sort -n "$TMP" > "$TMP.sorted"

# 4. generate patches with folder prefix
while read -r ts sha repo; do
  (
    cd "$WORKDIR/$repo"
    git format-patch -1 "$sha" --stdout \
      | sed "s|^--- a/|--- a/repos/$repo/|; s|^+++ b/|+++ b/repos/$repo/|" \
      > "$PATCH_DIR/${ts}-${repo}-${sha}.patch"
  )
done < "$TMP.sorted"

# 5. create monorepo and apply patches
git init "$MONOREPO"
cd "$MONOREPO"

git commit --allow-empty -m "init"

git am "$PATCH_DIR"/*.patch
```

### Explanation

- Clones all repos
- Extracts all commits with timestamps
- Sorts them globally
- Converts each commit into a patch
- Rewrites paths → `repos/<repo>/...`
- Applies patches in order → **single linear history**

* [Script to combine multiple git repos | jsloop](https://jsloop.net/2026/01/04/script-to-combine-multiple-git-repos)
* [combine two git repos into a monorepo](https://gist.github.com/acg/a4cfd3cc139704a8801827c60b8fecee)
* [combine repositories in Git](https://coreui.io/answers/how-to-combine-repositories-in-git)

---

## PowerShell script

> combine-repos.ps1

```powershell
$ErrorActionPreference = "Stop"

$Branch = "main"
$WorkDir = "$PWD\.tmp-repos"
$PatchDir = "$PWD\.patches"
$MonoRepo = "$PWD\stereo"

$Repos = @(
  "https://github.com/o9-9/stereo-patcher.git",
  "https://github.com/o9-9/stereo-finder.git",
  "https://github.com/o9-9/stereo-batch.git",
  "https://github.com/o9-9/stereo-backup.git",
  "https://github.com/o9-9/stereo-powershell.git",
  "https://github.com/o9-9/stereo-windows.git"
)

Remove-Item $WorkDir,$PatchDir,$MonoRepo -Recurse -Force -ErrorAction SilentlyContinue
New-Item -ItemType Directory -Path $WorkDir,$PatchDir | Out-Null

# 1. clone repos
foreach ($repo in $Repos) {
  $name = [System.IO.Path]::GetFileNameWithoutExtension($repo)
  git clone --quiet $repo "$WorkDir\$name"
}

# 2. collect commits
$tmp = New-TemporaryFile

foreach ($dir in Get-ChildItem $WorkDir -Directory) {
  Push-Location $dir.FullName
  git log $Branch --reverse --format="%ct %H $($dir.Name)" | Out-File -Append -Encoding ASCII $tmp
  Pop-Location
}

# 3. sort commits
$sorted = "$tmp.sorted"
Get-Content $tmp | Sort-Object { [int64]($_.Split()[0]) } | Set-Content $sorted

# 4. generate patches
Get-Content $sorted | ForEach-Object {
  $parts = $_ -split " "
  $ts = $parts[0]
  $sha = $parts[1]
  $repo = $parts[2]

  Push-Location "$WorkDir\$repo"

  $patch = git format-patch -1 $sha --stdout
  $patch = $patch `
    -replace "^--- a/", "--- a/repos/$repo/" `
    -replace "^\+\+\+ b/", "+++ b/repos/$repo/"

  $file = "$PatchDir\$ts-$repo-$sha.patch"
  $patch | Out-File -Encoding ASCII $file

  Pop-Location
}

# 5. apply patches
git init $MonoRepo | Out-Null
Push-Location $MonoRepo

git commit --allow-empty -m "init" | Out-Null

Get-ChildItem "$PatchDir\*.patch" | Sort-Object Name | ForEach-Object {
  git am $_.FullName
}

Pop-Location
```

## 2. Explanation

- Uses `git format-patch` to convert each commit into a patch ([Git][1])
- Sorts all commits globally by timestamp
- Rewrites paths → `repos/<repo>/...`
- Applies patches via `git am` to rebuild history ([DevTut][2])

* [git-format-patch Documentation](https://git-scm.com/docs/git-format-patch)
* [Git Patch](https://devtut.github.io/git/git-patch.html)
* [git apply patch command not working in powershell](https://stackoverflow.com/questions/39099288/why-is-git-apply-patch-command-not-working-in-powershell?noredirect=1)
