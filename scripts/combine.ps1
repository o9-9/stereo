# combine-repos.ps1

$targetRepo = "https://github.com/o9-9/stereo"

$repos = @(
    "https://github.com/o9-9/system",
    "https://github.com/o9-9/Discord-Node-Patcher",
    "https://github.com/o9-9/Discord-Voice-Node-Offset-Finder",
    "https://github.com/o9-9/stereo-Installer"
)

$tempDir = Join-Path ([System.IO.Path]::GetTempPath()) ("combine_repos_" + [guid]::NewGuid().ToString("N"))
New-Item -ItemType Directory -Path $tempDir | Out-Null

function Combine-Repo {
    param (
        [Parameter(Mandatory)]
        [string]$RepoUrl
    )

    $repoName = Split-Path $RepoUrl -Leaf
    $repoName = $repoName -replace '\.git$', ''

    $repoPath = Join-Path $tempDir $repoName
    git clone $RepoUrl $repoPath
    if ($LASTEXITCODE -ne 0) { throw "Failed to clone $RepoUrl" }

    Push-Location $repoPath
    try {
        git format-patch --stdout HEAD~1..HEAD > (Join-Path $tempDir "$repoName.patch")
    }
    finally {
        Pop-Location
    }
}

try {
    foreach ($repo in $repos) {
        Combine-Repo -RepoUrl $repo
    }

    $targetPath = Join-Path $tempDir "target"
    git clone $targetRepo $targetPath
    if ($LASTEXITCODE -ne 0) { throw "Failed to clone target repo: $targetRepo" }

    Push-Location $targetPath
    try {
        foreach ($patch in Get-ChildItem -Path $tempDir -Filter "*.patch" | Sort-Object Name) {
            git apply --index $patch.FullName
            if ($LASTEXITCODE -ne 0) { throw "Failed to apply patch: $($patch.Name)" }

            git commit -m "Consolidated changes from $($patch.BaseName)"
            if ($LASTEXITCODE -ne 0) { throw "Failed to commit patch: $($patch.Name)" }
        }
    }
    finally {
        Pop-Location
    }
}
finally {
    Remove-Item $tempDir -Recurse -Force
}
