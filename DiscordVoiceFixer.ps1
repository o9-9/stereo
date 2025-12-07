Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

#region Theme & Constants
$Theme = @{
    Background = [System.Drawing.Color]::FromArgb(32, 34, 37)
    ControlBg  = [System.Drawing.Color]::FromArgb(47, 49, 54)
    Primary    = [System.Drawing.Color]::FromArgb(88, 101, 242)
    Secondary  = [System.Drawing.Color]::FromArgb(70, 73, 80)
    Warning    = [System.Drawing.Color]::FromArgb(250, 168, 26)
    TextPrimary = [System.Drawing.Color]::White
    TextSecondary = [System.Drawing.Color]::FromArgb(150, 150, 150)
    TextDim = [System.Drawing.Color]::FromArgb(180, 180, 180)
}

$Fonts = @{
    Title = New-Object System.Drawing.Font("Segoe UI", 16, [System.Drawing.FontStyle]::Bold)
    Normal = New-Object System.Drawing.Font("Segoe UI", 9)
    Button = New-Object System.Drawing.Font("Segoe UI", 11, [System.Drawing.FontStyle]::Bold)
    ButtonSmall = New-Object System.Drawing.Font("Segoe UI", 9, [System.Drawing.FontStyle]::Bold)
    Console = New-Object System.Drawing.Font("Consolas", 9)
    Small = New-Object System.Drawing.Font("Segoe UI", 8.5)
}

$DiscordClients = [ordered]@{
    0 = @{ Name = "BetterDiscord            [Mod]"; Path = "$env:LOCALAPPDATA\Discord"; Processes = @("Discord", "Update"); Exe = "Discord.exe" }
    1 = @{ Name = "Discord - Canary         [Official]"; Path = "$env:LOCALAPPDATA\DiscordCanary"; Processes = @("DiscordCanary", "Update"); Exe = "DiscordCanary.exe" }
    2 = @{ Name = "Discord - Development    [Official]"; Path = "$env:LOCALAPPDATA\DiscordDevelopment"; Processes = @("DiscordDevelopment", "Update"); Exe = "DiscordDevelopment.exe" }
    3 = @{ Name = "Discord - PTB            [Official]"; Path = "$env:LOCALAPPDATA\DiscordPTB"; Processes = @("DiscordPTB", "Update"); Exe = "DiscordPTB.exe" }
    4 = @{ Name = "Discord - Stable         [Official]"; Path = "$env:LOCALAPPDATA\Discord"; Processes = @("Discord", "Update"); Exe = "Discord.exe" }
    5 = @{ Name = "Equicord                 [Mod]"; Path = "$env:LOCALAPPDATA\Equicord"; FallbackPath = "$env:LOCALAPPDATA\Discord"; Processes = @("Equicord", "Discord", "Update"); Exe = "Discord.exe" }
    6 = @{ Name = "Vencord                  [Mod]"; Path = "$env:LOCALAPPDATA\Vencord"; FallbackPath = "$env:LOCALAPPDATA\Discord"; Processes = @("Vencord", "Discord", "Update"); Exe = "Discord.exe" }
}

$UPDATE_URL = "https://raw.githubusercontent.com/ProdHallow/installer/refs/heads/main/DiscordVoiceFixer.ps1"
$VOICE_BACKUP_API = "https://api.github.com/repos/ProdHallow/voice-backup/contents/Discord%20Voice%20Backup?ref=c23e2fdc4916bf9c2ad7b8c479e590727bf84c11"
$FFMPEG_URL = "https://github.com/ProdHallow/voice-backup/raw/refs/heads/main/ffmpeg.dll"

$BACKUP_ROOT = "$env:APPDATA\StereoInstaller\backups"
$STATE_FILE = "$env:APPDATA\StereoInstaller\state.json"
#endregion

#region Helper Functions
function New-StyledLabel {
    param(
        [int]$X, [int]$Y, [int]$Width, [int]$Height,
        [string]$Text,
        [System.Drawing.Font]$Font = $Fonts.Normal,
        [System.Drawing.Color]$ForeColor = $Theme.TextPrimary,
        [string]$TextAlign = "MiddleLeft"
    )
    $label = New-Object System.Windows.Forms.Label
    $label.Location = New-Object System.Drawing.Point($X, $Y)
    $label.Size = New-Object System.Drawing.Size($Width, $Height)
    $label.Text = $Text
    $label.Font = $Font
    $label.TextAlign = $TextAlign
    $label.ForeColor = $ForeColor
    $label.BackColor = [System.Drawing.Color]::Transparent
    return $label
}

function New-StyledCheckBox {
    param(
        [int]$X, [int]$Y, [int]$Width, [int]$Height,
        [string]$Text,
        [bool]$Checked = $false,
        [System.Drawing.Color]$ForeColor = $Theme.TextPrimary
    )
    $checkbox = New-Object System.Windows.Forms.CheckBox
    $checkbox.Location = New-Object System.Drawing.Point($X, $Y)
    $checkbox.Size = New-Object System.Drawing.Size($Width, $Height)
    $checkbox.Text = $Text
    $checkbox.Checked = $Checked
    $checkbox.ForeColor = $ForeColor
    $checkbox.Font = $Fonts.Normal
    return $checkbox
}

function New-StyledButton {
    param(
        [int]$X, [int]$Y, [int]$Width, [int]$Height,
        [string]$Text,
        [System.Drawing.Font]$Font = $Fonts.Button,
        [System.Drawing.Color]$BackColor = $Theme.Primary
    )
    $button = New-Object System.Windows.Forms.Button
    $button.Location = New-Object System.Drawing.Point($X, $Y)
    $button.Size = New-Object System.Drawing.Size($Width, $Height)
    $button.Text = $Text
    $button.Font = $Font
    $button.BackColor = $BackColor
    $button.ForeColor = $Theme.TextPrimary
    $button.FlatStyle = "Flat"
    $button.FlatAppearance.BorderSize = 0
    $button.Cursor = [System.Windows.Forms.Cursors]::Hand
    return $button
}

function Add-Status {
    param(
        [System.Windows.Forms.RichTextBox]$StatusBox,
        [System.Windows.Forms.Form]$Form,
        [string]$Message, 
        [string]$Color = "White"
    )
    $timestamp = Get-Date -Format "HH:mm:ss"
    $StatusBox.SelectionStart = $StatusBox.TextLength
    $StatusBox.SelectionLength = 0
    $StatusBox.SelectionColor = [System.Drawing.Color]::FromName($Color)
    $StatusBox.AppendText("[$timestamp] $Message`r`n")
    $StatusBox.ScrollToCaret()
    $Form.Refresh()
}

function Play-CompletionSound {
    param([bool]$Success = $true)
    
    if ($Success) {
        [System.Media.SystemSounds]::Exclamation.Play()
    } else {
        [System.Media.SystemSounds]::Hand.Play()
    }
}

function Update-Progress {
    param(
        [System.Windows.Forms.ProgressBar]$ProgressBar,
        [System.Windows.Forms.Form]$Form,
        [int]$Value
    )
    $ProgressBar.Value = $Value
    $Form.Refresh()
}

function Stop-DiscordProcesses {
    param([string[]]$ProcessNames)
    
    $processes = Get-Process -Name $ProcessNames -ErrorAction SilentlyContinue
    if ($processes) {
        $processes | Stop-Process -Force -ErrorAction SilentlyContinue
        Start-Sleep -Milliseconds 300
        return $true
    }
    return $false
}

function Find-DiscordAppPath {
    param([string]$BasePath)
    
    $appFolders = Get-ChildItem -Path $BasePath -Filter "app-*" -Directory -ErrorAction SilentlyContinue | 
                  Sort-Object Name -Descending
    
    foreach ($folder in $appFolders) {
        $modulesPath = Join-Path $folder.FullName "modules"
        if (Test-Path $modulesPath) {
            $voiceModules = Get-ChildItem -Path $modulesPath -Filter "discord_voice*" -Directory -ErrorAction SilentlyContinue
            if ($voiceModules) {
                return $folder.FullName
            }
        }
    }
    return $null
}

function Get-DiscordAppVersion {
    param([string]$AppPath)
    
    if ($AppPath -match "app-(\d+\.\d+\.\d+)") {
        return $matches[1]
    }
    return $null
}

function Start-DiscordClient {
    param([string]$ExePath)
    
    if (Test-Path $ExePath) {
        Start-Process -FilePath "cmd.exe" -ArgumentList "/c", "start", '""', "`"$ExePath`"" -WindowStyle Hidden
        return $true
    }
    return $false
}

function Download-VoiceBackupFiles {
    param(
        [string]$DestinationPath,
        [System.Windows.Forms.RichTextBox]$StatusBox,
        [System.Windows.Forms.Form]$Form
    )
    
    try {
        if (-not (Test-Path $DestinationPath)) {
            New-Item -Path $DestinationPath -ItemType Directory -Force | Out-Null
        }
        
        Add-Status $StatusBox $Form "  Fetching file list from GitHub..." "Cyan"
        $response = Invoke-RestMethod -Uri $VOICE_BACKUP_API -UseBasicParsing -TimeoutSec 30
        
        $fileCount = 0
        foreach ($file in $response) {
            if ($file.type -eq "file") {
                $fileName = $file.name
                $downloadUrl = $file.download_url
                $filePath = Join-Path $DestinationPath $fileName
                
                Add-Status $StatusBox $Form "  Downloading: $fileName" "Cyan"
                Invoke-WebRequest -Uri $downloadUrl -OutFile $filePath -UseBasicParsing -TimeoutSec 30
                $fileCount++
            }
        }
        
        Add-Status $StatusBox $Form "  Downloaded $fileCount voice backup files" "Cyan"
        return $true
    }
    catch {
        Add-Status $StatusBox $Form "  [X] Failed to download voice backup files: $($_.Exception.Message)" "Red"
        return $false
    }
}

function Download-FFmpeg {
    param(
        [string]$DestinationPath,
        [System.Windows.Forms.RichTextBox]$StatusBox,
        [System.Windows.Forms.Form]$Form
    )
    
    try {
        Add-Status $StatusBox $Form "  Downloading ffmpeg.dll from GitHub..." "Cyan"
        Invoke-WebRequest -Uri $FFMPEG_URL -OutFile $DestinationPath -UseBasicParsing -TimeoutSec 30
        Add-Status $StatusBox $Form "  ffmpeg.dll downloaded successfully" "Cyan"
        return $true
    }
    catch {
        Add-Status $StatusBox $Form "  [X] Failed to download ffmpeg.dll: $($_.Exception.Message)" "Red"
        return $false
    }
}

function Apply-ScriptUpdate {
    param(
        [string]$UpdatedScriptPath,
        [string]$CurrentScriptPath
    )
    
    $batchFile = Join-Path $env:TEMP "StereoInstaller_Update.bat"
    
    $batchContent = @"
@echo off
echo Waiting for script to close...
timeout /t 2 /nobreak >nul
echo Applying update...
copy /Y `"$UpdatedScriptPath`" `"$CurrentScriptPath`" >nul
if errorlevel 1 (
    echo Update failed!
    pause
    exit /b 1
)
echo Update applied successfully!
echo Starting updated script...
timeout /t 1 /nobreak >nul
powershell.exe -ExecutionPolicy Bypass -File `"$CurrentScriptPath`"
del `"$UpdatedScriptPath`" >nul 2>&1
(goto) 2>nul & del `"%~f0`"
"@
    
    $batchContent | Out-File -FilePath $batchFile -Encoding ASCII -Force
    Start-Process -FilePath "cmd.exe" -ArgumentList "/c", "`"$batchFile`"" -WindowStyle Hidden
}

#region Backup Functions
function Initialize-BackupDirectory {
    if (-not (Test-Path $BACKUP_ROOT)) {
        New-Item -Path $BACKUP_ROOT -ItemType Directory -Force | Out-Null
    }
    $stateDir = Split-Path $STATE_FILE -Parent
    if (-not (Test-Path $stateDir)) {
        New-Item -Path $stateDir -ItemType Directory -Force | Out-Null
    }
}

function Get-StateData {
    if (Test-Path $STATE_FILE) {
        try {
            return Get-Content $STATE_FILE -Raw | ConvertFrom-Json
        } catch {
            return $null
        }
    }
    return $null
}

function Save-StateData {
    param([hashtable]$State)
    $State | ConvertTo-Json -Depth 5 | Out-File $STATE_FILE -Force
}

function Create-VoiceBackup {
    param(
        [string]$VoiceFolderPath,
        [string]$FfmpegPath,
        [string]$ClientName,
        [string]$AppVersion,
        [System.Windows.Forms.RichTextBox]$StatusBox,
        [System.Windows.Forms.Form]$Form
    )
    
    try {
        Initialize-BackupDirectory
        
        $timestamp = Get-Date -Format "yyyy-MM-dd_HHmmss"
        $safeClientName = $ClientName -replace '\s+', '_' -replace '\[|\]', ''
        $backupName = "${safeClientName}_${AppVersion}_${timestamp}"
        $backupPath = Join-Path $BACKUP_ROOT $backupName
        
        New-Item -Path $backupPath -ItemType Directory -Force | Out-Null
        
        # Backup voice module
        $voiceBackupPath = Join-Path $backupPath "voice_module"
        Add-Status $StatusBox $Form "  Backing up voice module..." "Cyan"
        Copy-Item -Path $VoiceFolderPath -Destination $voiceBackupPath -Recurse -Force
        
        # Backup ffmpeg.dll if it exists
        if (Test-Path $FfmpegPath) {
            Add-Status $StatusBox $Form "  Backing up ffmpeg.dll..." "Cyan"
            Copy-Item -Path $FfmpegPath -Destination (Join-Path $backupPath "ffmpeg.dll") -Force
        }
        
        # Save metadata
        $metadata = @{
            ClientName = $ClientName
            AppVersion = $AppVersion
            BackupDate = (Get-Date).ToString("o")
            VoiceModulePath = $VoiceFolderPath
            FfmpegPath = $FfmpegPath
        }
        $metadata | ConvertTo-Json | Out-File (Join-Path $backupPath "metadata.json") -Force
        
        Add-Status $StatusBox $Form "[OK] Backup created: $backupName" "LimeGreen"
        return $backupPath
    }
    catch {
        Add-Status $StatusBox $Form "[!] Backup failed: $($_.Exception.Message)" "Orange"
        return $null
    }
}

function Get-AvailableBackups {
    Initialize-BackupDirectory
    
    $backups = [System.Collections.ArrayList]@()
    $backupFolders = Get-ChildItem -Path $BACKUP_ROOT -Directory -ErrorAction SilentlyContinue | Sort-Object Name -Descending
    
    foreach ($folder in $backupFolders) {
        $metadataPath = Join-Path $folder.FullName "metadata.json"
        if (Test-Path $metadataPath) {
            try {
                $metadata = Get-Content $metadataPath -Raw | ConvertFrom-Json
                [void]$backups.Add(@{
                    Path = $folder.FullName
                    Name = $folder.Name
                    ClientName = $metadata.ClientName
                    AppVersion = $metadata.AppVersion
                    BackupDate = [DateTime]::Parse($metadata.BackupDate)
                    DisplayName = "$($metadata.ClientName) v$($metadata.AppVersion) - $(([DateTime]::Parse($metadata.BackupDate)).ToString('MMM dd, yyyy HH:mm'))"
                })
            } catch {
                continue
            }
        }
    }
    
    return $backups
}

function Restore-FromBackup {
    param(
        [hashtable]$Backup,
        [string]$TargetVoicePath,
        [string]$TargetFfmpegPath,
        [System.Windows.Forms.RichTextBox]$StatusBox,
        [System.Windows.Forms.Form]$Form
    )
    
    try {
        $voiceBackupPath = Join-Path $Backup.Path "voice_module"
        $ffmpegBackupPath = Join-Path $Backup.Path "ffmpeg.dll"
        
        # Restore voice module
        if (Test-Path $voiceBackupPath) {
            Add-Status $StatusBox $Form "  Restoring voice module..." "Cyan"
            if (Test-Path $TargetVoicePath) {
                Remove-Item "$TargetVoicePath\*" -Recurse -Force -ErrorAction SilentlyContinue
            }
            Copy-Item -Path "$voiceBackupPath\*" -Destination $TargetVoicePath -Recurse -Force
        }
        
        # Restore ffmpeg.dll
        if (Test-Path $ffmpegBackupPath) {
            Add-Status $StatusBox $Form "  Restoring ffmpeg.dll..." "Cyan"
            Copy-Item -Path $ffmpegBackupPath -Destination $TargetFfmpegPath -Force
        }
        
        return $true
    }
    catch {
        Add-Status $StatusBox $Form "[X] Restore failed: $($_.Exception.Message)" "Red"
        return $false
    }
}

function Remove-OldBackups {
    param([int]$KeepCount = 5)
    
    $backups = Get-AvailableBackups | Sort-Object { $_.BackupDate } -Descending
    
    if ($backups.Count -gt $KeepCount) {
        $toRemove = $backups | Select-Object -Skip $KeepCount
        foreach ($backup in $toRemove) {
            Remove-Item $backup.Path -Recurse -Force -ErrorAction SilentlyContinue
        }
    }
}

function Get-InstalledClients {
    $installed = [System.Collections.ArrayList]@()
    
    foreach ($key in $DiscordClients.Keys) {
        $client = $DiscordClients[$key]
        $basePath = $client.Path
        
        # Check primary path
        if (Test-Path $basePath) {
            $appPath = Find-DiscordAppPath -BasePath $basePath
            if ($appPath) {
                [void]$installed.Add(@{
                    Index = $key
                    Name = $client.Name
                    Path = $basePath
                    AppPath = $appPath
                    Client = $client
                })
                continue
            }
        }
        
        # Check fallback path
        if ($client.FallbackPath -and (Test-Path $client.FallbackPath)) {
            $appPath = Find-DiscordAppPath -BasePath $client.FallbackPath
            if ($appPath) {
                [void]$installed.Add(@{
                    Index = $key
                    Name = $client.Name
                    Path = $client.FallbackPath
                    AppPath = $appPath
                    Client = $client
                })
            }
        }
    }
    
    return $installed
}
#endregion

#region Discord Update Detection
function Check-DiscordUpdated {
    param(
        [string]$ClientPath,
        [string]$ClientName
    )
    
    $state = Get-StateData
    if (-not $state) { return $null }
    
    $clientKey = $ClientName -replace '\s+', '_' -replace '\[|\]', ''
    
    $appPath = Find-DiscordAppPath -BasePath $ClientPath
    if (-not $appPath) { return $null }
    
    $currentVersion = Get-DiscordAppVersion -AppPath $appPath
    if (-not $currentVersion) { return $null }
    
    $lastVersion = $state.$clientKey.LastFixedVersion
    $lastFixDate = $state.$clientKey.LastFixDate
    
    if ($lastVersion -and $currentVersion -ne $lastVersion) {
        return @{
            Updated = $true
            OldVersion = $lastVersion
            NewVersion = $currentVersion
            LastFixDate = $lastFixDate
        }
    }
    
    return @{
        Updated = $false
        CurrentVersion = $currentVersion
        LastFixDate = $lastFixDate
    }
}

function Save-FixState {
    param(
        [string]$ClientName,
        [string]$Version
    )
    
    Initialize-BackupDirectory
    
    $state = Get-StateData
    if (-not $state) { $state = @{} }
    if ($state -is [PSCustomObject]) {
        $newState = @{}
        $state.PSObject.Properties | ForEach-Object { $newState[$_.Name] = $_.Value }
        $state = $newState
    }
    
    $clientKey = $ClientName -replace '\s+', '_' -replace '\[|\]', ''
    
    $state[$clientKey] = @{
        LastFixedVersion = $Version
        LastFixDate = (Get-Date).ToString("o")
    }
    
    Save-StateData -State $state
}
#endregion
#endregion

#region UI Creation
$form = New-Object System.Windows.Forms.Form
$form.Text = "Stereo Installer"
$form.Size = New-Object System.Drawing.Size(520, 600)
$form.StartPosition = "CenterScreen"
$form.FormBorderStyle = "FixedDialog"
$form.MaximizeBox = $false
$form.BackColor = $Theme.Background
$form.TopMost = $true

$titleLabel = New-StyledLabel -X 20 -Y 15 -Width 460 -Height 35 -Text "Stereo Installer" -Font $Fonts.Title -TextAlign "MiddleCenter"
$form.Controls.Add($titleLabel)

$creditsLabel = New-StyledLabel -X 20 -Y 52 -Width 460 -Height 28 `
    -Text "Made by`r`nOracle | Shaun | Terrain | Hallow | Ascend | Sentry" `
    -Font $Fonts.Small -ForeColor $Theme.TextSecondary -TextAlign "MiddleCenter"
$form.Controls.Add($creditsLabel)

# Update status label (for Discord update detection)
$updateStatusLabel = New-StyledLabel -X 20 -Y 82 -Width 460 -Height 18 -Text "" -Font $Fonts.Small -ForeColor $Theme.Warning -TextAlign "MiddleCenter"
$form.Controls.Add($updateStatusLabel)

# Discord running warning label
$discordRunningLabel = New-StyledLabel -X 20 -Y 98 -Width 460 -Height 18 -Text "" -Font $Fonts.Small -ForeColor ([System.Drawing.Color]::FromArgb(250, 168, 26)) -TextAlign "MiddleCenter"
$form.Controls.Add($discordRunningLabel)

$clientGroup = New-Object System.Windows.Forms.GroupBox
$clientGroup.Location = New-Object System.Drawing.Point(20, 118)
$clientGroup.Size = New-Object System.Drawing.Size(460, 60)
$clientGroup.Text = "Discord Client"
$clientGroup.ForeColor = $Theme.TextPrimary
$clientGroup.BackColor = [System.Drawing.Color]::Transparent
$clientGroup.Font = $Fonts.Normal
$form.Controls.Add($clientGroup)

$clientCombo = New-Object System.Windows.Forms.ComboBox
$clientCombo.Location = New-Object System.Drawing.Point(20, 25)
$clientCombo.Size = New-Object System.Drawing.Size(420, 28)
$clientCombo.DropDownStyle = "DropDownList"
$clientCombo.BackColor = $Theme.ControlBg
$clientCombo.ForeColor = $Theme.TextPrimary
$clientCombo.FlatStyle = "Flat"
$clientCombo.Font = New-Object System.Drawing.Font("Consolas", 9)
foreach ($client in $DiscordClients.Values) {
    [void]$clientCombo.Items.Add($client.Name)
}
$clientCombo.SelectedIndex = 4
$clientGroup.Controls.Add($clientCombo)

$optionsGroup = New-Object System.Windows.Forms.GroupBox
$optionsGroup.Location = New-Object System.Drawing.Point(20, 188)
$optionsGroup.Size = New-Object System.Drawing.Size(460, 135)
$optionsGroup.Text = "Options"
$optionsGroup.ForeColor = $Theme.TextPrimary
$optionsGroup.BackColor = [System.Drawing.Color]::Transparent
$optionsGroup.Font = $Fonts.Normal
$form.Controls.Add($optionsGroup)

$chkUpdate = New-StyledCheckBox -X 20 -Y 28 -Width 420 -Height 22 `
    -Text "Check for script updates before fixing" -Checked $true
$optionsGroup.Controls.Add($chkUpdate)

$chkAutoUpdate = New-StyledCheckBox -X 40 -Y 52 -Width 400 -Height 22 `
    -Text "Automatically download and apply updates" -Checked $true -ForeColor $Theme.TextDim
$optionsGroup.Controls.Add($chkAutoUpdate)

$chkShortcut = New-StyledCheckBox -X 20 -Y 76 -Width 420 -Height 22 `
    -Text "Create startup shortcut (run fixer on Windows startup)" -Checked $false
$optionsGroup.Controls.Add($chkShortcut)

$chkAutoStart = New-StyledCheckBox -X 20 -Y 100 -Width 420 -Height 22 `
    -Text "Automatically start Discord after fixing" -Checked $true
$optionsGroup.Controls.Add($chkAutoStart)

$statusBox = New-Object System.Windows.Forms.RichTextBox
$statusBox.Location = New-Object System.Drawing.Point(20, 333)
$statusBox.Size = New-Object System.Drawing.Size(460, 120)
$statusBox.ReadOnly = $true
$statusBox.BackColor = $Theme.ControlBg
$statusBox.ForeColor = $Theme.TextPrimary
$statusBox.Font = $Fonts.Console
$statusBox.DetectUrls = $false
$statusBox.BorderStyle = "FixedSingle"
$form.Controls.Add($statusBox)

$progressBar = New-Object System.Windows.Forms.ProgressBar
$progressBar.Location = New-Object System.Drawing.Point(20, 463)
$progressBar.Size = New-Object System.Drawing.Size(460, 22)
$progressBar.Style = "Continuous"
$form.Controls.Add($progressBar)

# Button panel - Row 1
$btnStart = New-StyledButton -X 20 -Y 498 -Width 100 -Height 38 -Text "Start Fix"
$form.Controls.Add($btnStart)

$btnFixAll = New-StyledButton -X 125 -Y 498 -Width 100 -Height 38 -Text "Fix All" -Font $Fonts.Button -BackColor ([System.Drawing.Color]::FromArgb(87, 158, 87))
$form.Controls.Add($btnFixAll)

$btnRollback = New-StyledButton -X 230 -Y 498 -Width 70 -Height 38 -Text "Rollback" -Font $Fonts.ButtonSmall -BackColor $Theme.Secondary
$form.Controls.Add($btnRollback)

$btnOpenBackups = New-StyledButton -X 305 -Y 498 -Width 70 -Height 38 -Text "Backups" -Font $Fonts.ButtonSmall -BackColor $Theme.Secondary
$form.Controls.Add($btnOpenBackups)

$btnCheckUpdate = New-StyledButton -X 380 -Y 498 -Width 100 -Height 38 -Text "Check" -Font $Fonts.ButtonSmall -BackColor $Theme.Warning
$form.Controls.Add($btnCheckUpdate)
#endregion

#region Event Handlers
$chkUpdate.Add_CheckedChanged({
    $chkAutoUpdate.Enabled = $chkUpdate.Checked
    if (-not $chkUpdate.Checked) {
        $chkAutoUpdate.Checked = $false
    }
})

# Open backups folder button
$btnOpenBackups.Add_Click({
    Initialize-BackupDirectory
    Start-Process "explorer.exe" -ArgumentList $BACKUP_ROOT
})

# Function to check if Discord is running and update warning
function Update-DiscordRunningWarning {
    $discordProcesses = @("Discord", "DiscordCanary", "DiscordPTB", "DiscordDevelopment")
    $running = Get-Process -Name $discordProcesses -ErrorAction SilentlyContinue
    
    if ($running) {
        $discordRunningLabel.Text = "⚠ Discord is running — it will be closed when you apply the fix"
        $discordRunningLabel.Visible = $true
    } else {
        $discordRunningLabel.Text = ""
        $discordRunningLabel.Visible = $false
    }
}

# Check Discord update on client selection change
$clientCombo.Add_SelectedIndexChanged({
    $selectedClient = $DiscordClients[$clientCombo.SelectedIndex]
    $basePath = $selectedClient.Path
    if (-not (Test-Path $basePath) -and $selectedClient.FallbackPath) {
        $basePath = $selectedClient.FallbackPath
    }
    
    $updateCheck = Check-DiscordUpdated -ClientPath $basePath -ClientName $selectedClient.Name
    
    if ($updateCheck -and $updateCheck.Updated) {
        $updateStatusLabel.Text = "Discord updated! v$($updateCheck.OldVersion) -> v$($updateCheck.NewVersion) - Fix recommended"
        $updateStatusLabel.ForeColor = $Theme.Warning
    } elseif ($updateCheck -and $updateCheck.LastFixDate) {
        $lastFix = [DateTime]::Parse($updateCheck.LastFixDate)
        $updateStatusLabel.Text = "Last fixed: $($lastFix.ToString('MMM dd, yyyy HH:mm')) (v$($updateCheck.CurrentVersion))"
        $updateStatusLabel.ForeColor = $Theme.TextSecondary
    } else {
        $updateStatusLabel.Text = ""
    }
})

# Check Discord Update button
$btnCheckUpdate.Add_Click({
    $statusBox.Clear()
    $selectedClient = $DiscordClients[$clientCombo.SelectedIndex]
    
    Add-Status $statusBox $form "Checking Discord version..." "Blue"
    
    $basePath = $selectedClient.Path
    if (-not (Test-Path $basePath) -and $selectedClient.FallbackPath) {
        $basePath = $selectedClient.FallbackPath
    }
    
    if (-not (Test-Path $basePath)) {
        Add-Status $statusBox $form "[X] Discord client not found at: $basePath" "Red"
        return
    }
    
    $appPath = Find-DiscordAppPath -BasePath $basePath
    if (-not $appPath) {
        Add-Status $statusBox $form "[X] No Discord installation found" "Red"
        return
    }
    
    $currentVersion = Get-DiscordAppVersion -AppPath $appPath
    Add-Status $statusBox $form "Current version: $currentVersion" "Cyan"
    
    $updateCheck = Check-DiscordUpdated -ClientPath $basePath -ClientName $selectedClient.Name
    
    if ($updateCheck -and $updateCheck.Updated) {
        Add-Status $statusBox $form "[!] Discord has been updated!" "Yellow"
        Add-Status $statusBox $form "    Previous: v$($updateCheck.OldVersion)" "Orange"
        Add-Status $statusBox $form "    Current:  v$($updateCheck.NewVersion)" "Orange"
        Add-Status $statusBox $form "    Re-applying the fix is recommended." "Yellow"
        $updateStatusLabel.Text = "Discord updated! v$($updateCheck.OldVersion) -> v$($updateCheck.NewVersion) - Fix recommended"
        $updateStatusLabel.ForeColor = $Theme.Warning
    } elseif ($updateCheck -and $updateCheck.LastFixDate) {
        $lastFix = [DateTime]::Parse($updateCheck.LastFixDate)
        Add-Status $statusBox $form "[OK] No update detected since last fix" "LimeGreen"
        Add-Status $statusBox $form "    Last fixed: $($lastFix.ToString('MMM dd, yyyy HH:mm'))" "Cyan"
        $updateStatusLabel.Text = "Last fixed: $($lastFix.ToString('MMM dd, yyyy HH:mm')) (v$($updateCheck.CurrentVersion))"
        $updateStatusLabel.ForeColor = $Theme.TextSecondary
    } else {
        Add-Status $statusBox $form "[!] No previous fix recorded for this client" "Yellow"
        Add-Status $statusBox $form "    Run 'Start Fix' to apply the fix." "Cyan"
        $updateStatusLabel.Text = ""
    }
})

# Rollback button
$btnRollback.Add_Click({
    $statusBox.Clear()
    $selectedClient = $DiscordClients[$clientCombo.SelectedIndex]
    
    Add-Status $statusBox $form "Loading available backups..." "Blue"
    
    $backups = Get-AvailableBackups
    
    if ($backups.Count -eq 0) {
        Add-Status $statusBox $form "[X] No backups found" "Red"
        [System.Windows.Forms.MessageBox]::Show(
            $form,
            "No backups available. Run 'Start Fix' first to create a backup.",
            "No Backups",
            [System.Windows.Forms.MessageBoxButtons]::OK,
            [System.Windows.Forms.MessageBoxIcon]::Information
        )
        return
    }
    
    # Create backup selection dialog
    $rollbackForm = New-Object System.Windows.Forms.Form
    $rollbackForm.Text = "Select Backup to Restore"
    $rollbackForm.Size = New-Object System.Drawing.Size(450, 300)
    $rollbackForm.StartPosition = "CenterParent"
    $rollbackForm.FormBorderStyle = "FixedDialog"
    $rollbackForm.MaximizeBox = $false
    $rollbackForm.MinimizeBox = $false
    $rollbackForm.BackColor = $Theme.Background
    $rollbackForm.TopMost = $true
    
    $listBox = New-Object System.Windows.Forms.ListBox
    $listBox.Location = New-Object System.Drawing.Point(20, 20)
    $listBox.Size = New-Object System.Drawing.Size(395, 180)
    $listBox.BackColor = $Theme.ControlBg
    $listBox.ForeColor = $Theme.TextPrimary
    $listBox.Font = $Fonts.Normal
    
    foreach ($backup in $backups) {
        [void]$listBox.Items.Add($backup.DisplayName)
    }
    $listBox.SelectedIndex = 0
    $rollbackForm.Controls.Add($listBox)
    
    $btnRestore = New-StyledButton -X 120 -Y 210 -Width 100 -Height 35 -Text "Restore"
    $btnCancel = New-StyledButton -X 230 -Y 210 -Width 100 -Height 35 -Text "Cancel" -BackColor $Theme.Secondary
    
    $rollbackForm.Controls.Add($btnRestore)
    $rollbackForm.Controls.Add($btnCancel)
    
    $btnCancel.Add_Click({ $rollbackForm.DialogResult = "Cancel"; $rollbackForm.Close() })
    $btnRestore.Add_Click({ $rollbackForm.DialogResult = "OK"; $rollbackForm.Close() })
    
    $result = $rollbackForm.ShowDialog($form)
    
    if ($result -eq "OK" -and $listBox.SelectedIndex -ge 0) {
        $selectedBackup = $backups[$listBox.SelectedIndex]
        
        if (-not $selectedBackup -or -not $selectedBackup.Path) {
            Add-Status $statusBox $form "[X] Invalid backup selection" "Red"
            return
        }
        
        Add-Status $statusBox $form "Starting rollback..." "Blue"
        Add-Status $statusBox $form "  Selected: $($selectedBackup.DisplayName)" "Cyan"
        
        # Kill Discord
        Add-Status $statusBox $form "Closing Discord processes..." "Blue"
        Stop-DiscordProcesses -ProcessNames $selectedClient.Processes
        Start-Sleep -Seconds 1
        
        # Find paths
        $basePath = $selectedClient.Path
        if (-not (Test-Path $basePath) -and $selectedClient.FallbackPath) {
            $basePath = $selectedClient.FallbackPath
        }
        
        $appPath = Find-DiscordAppPath -BasePath $basePath
        if (-not $appPath) {
            Add-Status $statusBox $form "[X] Could not find Discord installation" "Red"
            return
        }
        
        $voiceModule = Get-ChildItem -Path "$appPath\modules" -Filter "discord_voice*" -Directory | Select-Object -First 1
        
        if (-not $voiceModule) {
            Add-Status $statusBox $form "[X] Could not find voice module in Discord installation" "Red"
            return
        }
        
        $targetVoiceFolder = if (Test-Path "$($voiceModule.FullName)\discord_voice") {
            "$($voiceModule.FullName)\discord_voice"
        } else {
            $voiceModule.FullName
        }
        $ffmpegTarget = Join-Path $appPath "ffmpeg.dll"
        
        # Restore
        $success = Restore-FromBackup -Backup $selectedBackup -TargetVoicePath $targetVoiceFolder -TargetFfmpegPath $ffmpegTarget -StatusBox $statusBox -Form $form
        
        if ($success) {
            Add-Status $statusBox $form "[OK] Rollback completed successfully" "LimeGreen"
            
            if ($chkAutoStart.Checked) {
                Add-Status $statusBox $form "Starting Discord..." "Blue"
                $discordExe = Join-Path $appPath $selectedClient.Exe
                Start-DiscordClient -ExePath $discordExe
                Add-Status $statusBox $form "[OK] Discord started" "LimeGreen"
            }
            
            Play-CompletionSound -Success $true
            
            [System.Windows.Forms.MessageBox]::Show(
                $form,
                "Rollback completed successfully!",
                "Success",
                [System.Windows.Forms.MessageBoxButtons]::OK,
                [System.Windows.Forms.MessageBoxIcon]::Information
            )
        }
    }
})

$btnStart.Add_Click({
    $btnStart.Enabled = $false
    $btnFixAll.Enabled = $false
    $btnRollback.Enabled = $false
    $btnCheckUpdate.Enabled = $false
    $statusBox.Clear()
    $progressBar.Value = 0
    
    $tempDir = Join-Path $env:TEMP "StereoInstaller_$(Get-Random)"
    
    try {
        $selectedClient = $DiscordClients[$clientCombo.SelectedIndex]
        
        # Step 1: Update Check
        if ($chkUpdate.Checked) {
            Add-Status $statusBox $form "Checking for script updates..." "Blue"
            Update-Progress $progressBar $form 5
            
            try {
                $currentScript = $PSCommandPath
                
                if ([string]::IsNullOrEmpty($currentScript)) {
                    Add-Status $statusBox $form "[OK] Running latest version from web" "LimeGreen"
                } else {
                    $updateFile = "$env:TEMP\StereoInstaller_Update_$(Get-Random).ps1"
                    
                    Invoke-WebRequest -Uri $UPDATE_URL -OutFile $updateFile -UseBasicParsing -TimeoutSec 10
                    
                    $updateContent = (Get-Content $updateFile -Raw) -replace "`r`n", "`n" -replace "`r", "`n"
                    $currentContent = (Get-Content $currentScript -Raw) -replace "`r`n", "`n" -replace "`r", "`n"
                    $updateContent = $updateContent.Trim()
                    $currentContent = $currentContent.Trim()
                    
                    if ($updateContent -ne $currentContent) {
                        Add-Status $statusBox $form "New update found!" "Yellow"
                        
                        if ($chkAutoUpdate.Checked) {
                            Add-Status $statusBox $form "Update will be applied after script closes..." "Cyan"
                            Add-Status $statusBox $form "[OK] Update prepared! Restarting in 3 seconds..." "LimeGreen"
                            
                            Start-Sleep -Seconds 3
                            
                            Apply-ScriptUpdate -UpdatedScriptPath $updateFile -CurrentScriptPath $currentScript
                            
                            $form.Close()
                            return
                        } else {
                            Add-Status $statusBox $form "Update downloaded to: $updateFile" "Orange"
                            Add-Status $statusBox $form "Please manually replace the script file to update." "Orange"
                        }
                    } else {
                        Add-Status $statusBox $form "[OK] You are on the latest version" "LimeGreen"
                        Remove-Item $updateFile -ErrorAction SilentlyContinue
                    }
                }
            } catch {
                Add-Status $statusBox $form "[!] Could not check for updates: $($_.Exception.Message)" "Orange"
            }
        }
        
        Update-Progress $progressBar $form 10
        
        # Step 2: Download Required Files
        Add-Status $statusBox $form "Downloading required files from GitHub..." "Blue"
        New-Item -Path $tempDir -ItemType Directory -Force | Out-Null
        
        $voiceBackupPath = Join-Path $tempDir "VoiceBackup"
        $voiceDownloadSuccess = Download-VoiceBackupFiles -DestinationPath $voiceBackupPath -StatusBox $statusBox -Form $form
        
        if (-not $voiceDownloadSuccess) {
            throw "Failed to download voice backup files from GitHub"
        }
        
        Update-Progress $progressBar $form 20
        
        $ffmpegPath = Join-Path $tempDir "ffmpeg.dll"
        $ffmpegDownloadSuccess = Download-FFmpeg -DestinationPath $ffmpegPath -StatusBox $statusBox -Form $form
        
        if (-not $ffmpegDownloadSuccess) {
            throw "Failed to download ffmpeg.dll from GitHub"
        }
        
        Add-Status $statusBox $form "[OK] All files downloaded successfully" "LimeGreen"
        Update-Progress $progressBar $form 30
        
        # Step 3: Kill Discord Processes
        Add-Status $statusBox $form "Closing Discord processes..." "Blue"
        $killedAny = Stop-DiscordProcesses -ProcessNames $selectedClient.Processes
        
        if ($killedAny) {
            Add-Status $statusBox $form "  Discord processes terminated" "Cyan"
        } else {
            Add-Status $statusBox $form "  No Discord processes were running" "Yellow"
        }
        
        Start-Sleep -Seconds 1
        Update-Progress $progressBar $form 40
        Add-Status $statusBox $form "[OK] Discord processes closed" "LimeGreen"
        
        # Step 4: Locate Installation
        Add-Status $statusBox $form "Locating Discord installation..." "Blue"
        
        $basePath = $selectedClient.Path
        if (-not (Test-Path $basePath) -and $selectedClient.FallbackPath) {
            $basePath = $selectedClient.FallbackPath
        }
        
        Add-Status $statusBox $form "Searching in: $basePath" "Cyan"
        
        if (-not (Test-Path $basePath)) {
            throw "Discord client folder not found at: $basePath`r`nPlease verify $($selectedClient.Name) is installed."
        }
        
        $appPath = Find-DiscordAppPath -BasePath $basePath
        
        if (-not $appPath) {
            throw "No Discord app folder with voice module found in $basePath"
        }
        
        $appVersion = Get-DiscordAppVersion -AppPath $appPath
        Add-Status $statusBox $form "[OK] Found $($selectedClient.Name) v$appVersion" "LimeGreen"
        Update-Progress $progressBar $form 50
        
        # Step 5: Locate Voice Module
        Add-Status $statusBox $form "Locating voice module..." "Blue"
        $voiceModule = Get-ChildItem -Path "$appPath\modules" -Filter "discord_voice*" -Directory | Select-Object -First 1
        
        if (-not $voiceModule) {
            throw "No discord_voice module found"
        }
        
        $targetVoiceFolder = if (Test-Path "$($voiceModule.FullName)\discord_voice") {
            "$($voiceModule.FullName)\discord_voice"
        } else {
            $voiceModule.FullName
        }
        
        $ffmpegTarget = Join-Path $appPath "ffmpeg.dll"
        
        Add-Status $statusBox $form "[OK] Voice module located" "LimeGreen"
        Update-Progress $progressBar $form 55
        
        # Step 6: Create Backup
        Add-Status $statusBox $form "Creating backup of current files..." "Blue"
        $backupResult = Create-VoiceBackup -VoiceFolderPath $targetVoiceFolder -FfmpegPath $ffmpegTarget `
            -ClientName $selectedClient.Name -AppVersion $appVersion -StatusBox $statusBox -Form $form
        
        # Cleanup old backups (keep last 5)
        Remove-OldBackups -KeepCount 5
        
        Update-Progress $progressBar $form 60
        
        # Step 7: Clear Old Files
        Add-Status $statusBox $form "Removing old voice module files..." "Blue"
        if (Test-Path $targetVoiceFolder) {
            Remove-Item "$targetVoiceFolder\*" -Recurse -Force -ErrorAction SilentlyContinue
        }
        Add-Status $statusBox $form "[OK] Old files removed" "LimeGreen"
        Update-Progress $progressBar $form 70
        
        # Step 8: Copy Module Files
        Add-Status $statusBox $form "Copying updated module files..." "Blue"
        Copy-Item -Path "$voiceBackupPath\*" -Destination $targetVoiceFolder -Recurse -Force
        Add-Status $statusBox $form "[OK] Module files copied" "LimeGreen"
        Update-Progress $progressBar $form 80
        
        # Step 9: Copy ffmpeg.dll
        Add-Status $statusBox $form "Copying ffmpeg.dll..." "Blue"
        Copy-Item -Path $ffmpegPath -Destination $ffmpegTarget -Force
        Add-Status $statusBox $form "[OK] ffmpeg.dll replaced" "LimeGreen"
        Update-Progress $progressBar $form 85
        
        # Step 10: Save state for update detection
        Save-FixState -ClientName $selectedClient.Name -Version $appVersion
        
        # Step 11: Create Startup Shortcut
        if ($chkShortcut.Checked) {
            Add-Status $statusBox $form "Creating startup shortcut..." "Blue"
            $startupFolder = "$env:APPDATA\Microsoft\Windows\Start Menu\Programs\Startup"
            $shortcutPath = Join-Path $startupFolder "DiscordVoiceFixer.lnk"
            
            $WshShell = New-Object -ComObject WScript.Shell
            $Shortcut = $WshShell.CreateShortcut($shortcutPath)
            $Shortcut.TargetPath = $PSCommandPath
            $Shortcut.WorkingDirectory = (Split-Path -Parent $PSCommandPath)
            $Shortcut.Save()
            
            Add-Status $statusBox $form "[OK] Startup shortcut created" "LimeGreen"
        }
        Update-Progress $progressBar $form 90
        
        # Step 12: Start Discord
        if ($chkAutoStart.Checked) {
            Add-Status $statusBox $form "Starting Discord..." "Blue"
            
            $discordExe = Join-Path $appPath $selectedClient.Exe
            $started = Start-DiscordClient -ExePath $discordExe
            
            if (-not $started -and $selectedClient.FallbackPath) {
                $fallbackApp = Find-DiscordAppPath -BasePath $selectedClient.FallbackPath
                if ($fallbackApp) {
                    $altExe = Join-Path $fallbackApp $selectedClient.Exe
                    $started = Start-DiscordClient -ExePath $altExe
                    if ($started) {
                        Add-Status $statusBox $form "[OK] Discord started (from alternate location)" "LimeGreen"
                    }
                }
            } elseif ($started) {
                Add-Status $statusBox $form "[OK] Discord started" "LimeGreen"
            }
            
            if (-not $started) {
                Add-Status $statusBox $form "[!] Could not find Discord executable" "Orange"
            }
        }
        
        Update-Progress $progressBar $form 100
        
        # Update the version label
        $updateStatusLabel.Text = "Last fixed: $(Get-Date -Format 'MMM dd, yyyy HH:mm') (v$appVersion)"
        $updateStatusLabel.ForeColor = $Theme.TextSecondary
        
        Add-Status $statusBox $form "" "White"
        Add-Status $statusBox $form "=== ALL TASKS COMPLETED ===" "LimeGreen"
        
        Play-CompletionSound -Success $true
        
        [System.Windows.Forms.MessageBox]::Show(
            $form,
            "Discord voice module fix completed successfully!`n`nA backup was created in case you need to rollback.",
            "Success",
            [System.Windows.Forms.MessageBoxButtons]::OK,
            [System.Windows.Forms.MessageBoxIcon]::Information
        )
        
        $form.Close()
        
    } catch {
        Add-Status $statusBox $form "" "White"
        Add-Status $statusBox $form "[X] ERROR: $($_.Exception.Message)" "Red"
        
        Play-CompletionSound -Success $false
        
        [System.Windows.Forms.MessageBox]::Show(
            $form,
            "An error occurred: $($_.Exception.Message)",
            "Error",
            [System.Windows.Forms.MessageBoxButtons]::OK,
            [System.Windows.Forms.MessageBoxIcon]::Error
        )
    } finally {
        if (Test-Path $tempDir) {
            Remove-Item $tempDir -Recurse -Force -ErrorAction SilentlyContinue
        }
        $btnStart.Enabled = $true
        $btnFixAll.Enabled = $true
        $btnRollback.Enabled = $true
        $btnCheckUpdate.Enabled = $true
    }
})

# Fix All Clients button
$btnFixAll.Add_Click({
    $btnStart.Enabled = $false
    $btnFixAll.Enabled = $false
    $btnRollback.Enabled = $false
    $btnCheckUpdate.Enabled = $false
    $statusBox.Clear()
    $progressBar.Value = 0
    
    $tempDir = Join-Path $env:TEMP "StereoInstaller_$(Get-Random)"
    
    try {
        # Step 1: Detect installed clients
        Add-Status $statusBox $form "Scanning for installed Discord clients..." "Blue"
        $installedClients = Get-InstalledClients
        
        if ($installedClients.Count -eq 0) {
            Add-Status $statusBox $form "[X] No Discord clients found!" "Red"
            [System.Windows.Forms.MessageBox]::Show(
                $form,
                "No Discord clients were found on this system.",
                "No Clients Found",
                [System.Windows.Forms.MessageBoxButtons]::OK,
                [System.Windows.Forms.MessageBoxIcon]::Warning
            )
            return
        }
        
        # Remove duplicates (mods pointing to same Discord folder)
        $uniquePaths = @{}
        $uniqueClients = [System.Collections.ArrayList]@()
        foreach ($client in $installedClients) {
            if (-not $uniquePaths.ContainsKey($client.AppPath)) {
                $uniquePaths[$client.AppPath] = $true
                [void]$uniqueClients.Add($client)
            }
        }
        
        Add-Status $statusBox $form "[OK] Found $($uniqueClients.Count) client(s):" "LimeGreen"
        foreach ($client in $uniqueClients) {
            $version = Get-DiscordAppVersion -AppPath $client.AppPath
            Add-Status $statusBox $form "    - $($client.Name.Trim()) (v$version)" "Cyan"
        }
        
        Update-Progress $progressBar $form 5
        
        # Confirm with user
        $confirmResult = [System.Windows.Forms.MessageBox]::Show(
            $form,
            "Found $($uniqueClients.Count) Discord client(s). Apply fix to all?",
            "Confirm Fix All",
            [System.Windows.Forms.MessageBoxButtons]::YesNo,
            [System.Windows.Forms.MessageBoxIcon]::Question
        )
        
        if ($confirmResult -ne "Yes") {
            Add-Status $statusBox $form "Operation cancelled by user" "Yellow"
            return
        }
        
        # Step 2: Download files (once)
        Add-Status $statusBox $form "" "White"
        Add-Status $statusBox $form "Downloading required files from GitHub..." "Blue"
        New-Item -Path $tempDir -ItemType Directory -Force | Out-Null
        
        $voiceBackupPath = Join-Path $tempDir "VoiceBackup"
        $voiceDownloadSuccess = Download-VoiceBackupFiles -DestinationPath $voiceBackupPath -StatusBox $statusBox -Form $form
        
        if (-not $voiceDownloadSuccess) {
            throw "Failed to download voice backup files from GitHub"
        }
        
        $ffmpegPath = Join-Path $tempDir "ffmpeg.dll"
        $ffmpegDownloadSuccess = Download-FFmpeg -DestinationPath $ffmpegPath -StatusBox $statusBox -Form $form
        
        if (-not $ffmpegDownloadSuccess) {
            throw "Failed to download ffmpeg.dll from GitHub"
        }
        
        Add-Status $statusBox $form "[OK] All files downloaded" "LimeGreen"
        Update-Progress $progressBar $form 20
        
        # Step 3: Kill ALL Discord processes
        Add-Status $statusBox $form "" "White"
        Add-Status $statusBox $form "Closing all Discord processes..." "Blue"
        $allProcesses = @("Discord", "DiscordCanary", "DiscordPTB", "DiscordDevelopment", "Equicord", "Vencord", "Update")
        Stop-DiscordProcesses -ProcessNames $allProcesses
        Start-Sleep -Seconds 1
        Add-Status $statusBox $form "[OK] Discord processes closed" "LimeGreen"
        Update-Progress $progressBar $form 30
        
        # Step 4: Fix each client
        $progressPerClient = 60 / $uniqueClients.Count
        $currentProgress = 30
        $fixedCount = 0
        $failedClients = @()
        
        foreach ($clientInfo in $uniqueClients) {
            Add-Status $statusBox $form "" "White"
            Add-Status $statusBox $form "=== Fixing: $($clientInfo.Name.Trim()) ===" "Blue"
            
            try {
                $appPath = $clientInfo.AppPath
                $appVersion = Get-DiscordAppVersion -AppPath $appPath
                
                # Locate voice module
                $voiceModule = Get-ChildItem -Path "$appPath\modules" -Filter "discord_voice*" -Directory | Select-Object -First 1
                
                if (-not $voiceModule) {
                    throw "No discord_voice module found"
                }
                
                $targetVoiceFolder = if (Test-Path "$($voiceModule.FullName)\discord_voice") {
                    "$($voiceModule.FullName)\discord_voice"
                } else {
                    $voiceModule.FullName
                }
                
                $ffmpegTarget = Join-Path $appPath "ffmpeg.dll"
                
                # Create backup
                Add-Status $statusBox $form "  Creating backup..." "Cyan"
                Create-VoiceBackup -VoiceFolderPath $targetVoiceFolder -FfmpegPath $ffmpegTarget `
                    -ClientName $clientInfo.Name -AppVersion $appVersion -StatusBox $statusBox -Form $form | Out-Null
                
                # Clear old files
                if (Test-Path $targetVoiceFolder) {
                    Remove-Item "$targetVoiceFolder\*" -Recurse -Force -ErrorAction SilentlyContinue
                }
                
                # Copy new files
                Add-Status $statusBox $form "  Copying module files..." "Cyan"
                Copy-Item -Path "$voiceBackupPath\*" -Destination $targetVoiceFolder -Recurse -Force
                
                # Copy ffmpeg
                Add-Status $statusBox $form "  Copying ffmpeg.dll..." "Cyan"
                Copy-Item -Path $ffmpegPath -Destination $ffmpegTarget -Force
                
                # Save state
                Save-FixState -ClientName $clientInfo.Name -Version $appVersion
                
                Add-Status $statusBox $form "[OK] $($clientInfo.Name.Trim()) fixed successfully" "LimeGreen"
                $fixedCount++
            }
            catch {
                Add-Status $statusBox $form "[X] Failed to fix $($clientInfo.Name.Trim()): $($_.Exception.Message)" "Red"
                $failedClients += $clientInfo.Name
            }
            
            $currentProgress += $progressPerClient
            Update-Progress $progressBar $form ([int]$currentProgress)
        }
        
        # Cleanup old backups
        Remove-OldBackups -KeepCount 10
        
        Update-Progress $progressBar $form 95
        
        # Step 5: Start Discord (optional - start the first/primary client)
        if ($chkAutoStart.Checked -and $fixedCount -gt 0) {
            Add-Status $statusBox $form "" "White"
            Add-Status $statusBox $form "Starting Discord..." "Blue"
            $primaryClient = $uniqueClients[0]
            $discordExe = Join-Path $primaryClient.AppPath $primaryClient.Client.Exe
            if (Start-DiscordClient -ExePath $discordExe) {
                Add-Status $statusBox $form "[OK] Discord started" "LimeGreen"
            }
        }
        
        Update-Progress $progressBar $form 100
        Add-Status $statusBox $form "" "White"
        Add-Status $statusBox $form "=== FIX ALL COMPLETED ===" "LimeGreen"
        Add-Status $statusBox $form "Fixed: $fixedCount / $($uniqueClients.Count) clients" "Cyan"
        
        if ($failedClients.Count -gt 0) {
            Play-CompletionSound -Success $false
            [System.Windows.Forms.MessageBox]::Show(
                $form,
                "Fixed $fixedCount of $($uniqueClients.Count) clients.`n`nFailed: $($failedClients -join ', ')",
                "Completed with Errors",
                [System.Windows.Forms.MessageBoxButtons]::OK,
                [System.Windows.Forms.MessageBoxIcon]::Warning
            )
        } else {
            Play-CompletionSound -Success $true
            [System.Windows.Forms.MessageBox]::Show(
                $form,
                "Successfully fixed all $fixedCount Discord client(s)!",
                "Success",
                [System.Windows.Forms.MessageBoxButtons]::OK,
                [System.Windows.Forms.MessageBoxIcon]::Information
            )
        }
    }
    catch {
        Add-Status $statusBox $form "" "White"
        Add-Status $statusBox $form "[X] ERROR: $($_.Exception.Message)" "Red"
        
        Play-CompletionSound -Success $false
        
        [System.Windows.Forms.MessageBox]::Show(
            $form,
            "An error occurred: $($_.Exception.Message)",
            "Error",
            [System.Windows.Forms.MessageBoxButtons]::OK,
            [System.Windows.Forms.MessageBoxIcon]::Error
        )
    }
    finally {
        if (Test-Path $tempDir) {
            Remove-Item $tempDir -Recurse -Force -ErrorAction SilentlyContinue
        }
        $btnStart.Enabled = $true
        $btnFixAll.Enabled = $true
        $btnRollback.Enabled = $true
        $btnCheckUpdate.Enabled = $true
    }
})
#endregion

# Initial update check on form load
$form.Add_Shown({
    $form.Activate()
    
    # Check if Discord is running
    Update-DiscordRunningWarning
    
    # Trigger initial Discord update check
    $selectedClient = $DiscordClients[$clientCombo.SelectedIndex]
    $basePath = $selectedClient.Path
    if (-not (Test-Path $basePath) -and $selectedClient.FallbackPath) {
        $basePath = $selectedClient.FallbackPath
    }
    
    $updateCheck = Check-DiscordUpdated -ClientPath $basePath -ClientName $selectedClient.Name
    
    if ($updateCheck -and $updateCheck.Updated) {
        $updateStatusLabel.Text = "Discord updated! v$($updateCheck.OldVersion) -> v$($updateCheck.NewVersion) - Fix recommended"
        $updateStatusLabel.ForeColor = $Theme.Warning
    } elseif ($updateCheck -and $updateCheck.LastFixDate) {
        $lastFix = [DateTime]::Parse($updateCheck.LastFixDate)
        $updateStatusLabel.Text = "Last fixed: $($lastFix.ToString('MMM dd, yyyy HH:mm')) (v$($updateCheck.CurrentVersion))"
        $updateStatusLabel.ForeColor = $Theme.TextSecondary
    }
})

[void]$form.ShowDialog()
