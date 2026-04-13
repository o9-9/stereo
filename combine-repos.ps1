# combine-repos.ps1
param (
    [string[]]$repos,  # Array of repository URLs to combine
    [string]$targetRepo  # The target repository where repositories will be combined
)

# Create a temporary directory
tempDir = New-TemporaryFile -Prefix "combine_repos_" -Directory
Remove-Item $tempDir -Recurse -Force
New-Item -ItemType Directory -Path $tempDir

# Function to clone repositories and generate patches
function Combine-Repo {
    param (
        [string]$repoUrl
    )
    $repoName = $repoUrl.Split('/')[-1].Replace('.git', '')
    git clone $repoUrl "$tempDir\$repoName"
    Push-Location "$tempDir\$repoName"
    git format-patch --stdout > "$tempDir\$repoName.patch"
    Pop-Location
}

# Combine each repository
foreach ($repo in $repos) {
    Combine-Repo -repoUrl $repo
}

# Create or update the target repository
Push-Location $targetRepo
foreach ($patch in Get-ChildItem "$tempDir\*.patch") {
    git apply --index $patch.FullName
    git commit -m "Consolidated changes from $($patch.Name)"
}
Pop-Location

# Cleanup
Remove-Item $tempDir -Recurse -Force
