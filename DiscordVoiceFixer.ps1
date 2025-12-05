Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

#region Theme & Constants
$Theme = @{
    Background = [System.Drawing.Color]::FromArgb(32, 34, 37)
    ControlBg  = [System.Drawing.Color]::FromArgb(47, 49, 54)
    Primary    = [System.Drawing.Color]::FromArgb(88, 101, 242)
    TextPrimary = [System.Drawing.Color]::White
    TextSecondary = [System.Drawing.Color]::FromArgb(150, 150, 150)
    TextDim = [System.Drawing.Color]::FromArgb(180, 180, 180)
}

$Fonts = @{
    Title = New-Object System.Drawing.Font("Segoe UI", 16, [System.Drawing.FontStyle]::Bold)
    Normal = New-Object System.Drawing.Font("Segoe UI", 9)
    Button = New-Object System.Drawing.Font("Segoe UI", 11, [System.Drawing.FontStyle]::Bold)
    Console = New-Object System.Drawing.Font("Consolas", 9)
    Small = New-Object System.Drawing.Font("Segoe UI", 8.5)
}

$DiscordClients = @{
    0 = @{ Name = "Discord (Stable)"; Path = "$env:LOCALAPPDATA\Discord"; Processes = @("Discord", "Update"); Exe = "Discord.exe" }
    1 = @{ Name = "Discord PTB"; Path = "$env:LOCALAPPDATA\DiscordPTB"; Processes = @("DiscordPTB", "Update"); Exe = "DiscordPTB.exe" }
    2 = @{ Name = "Discord Canary"; Path = "$env:LOCALAPPDATA\DiscordCanary"; Processes = @("DiscordCanary", "Update"); Exe = "DiscordCanary.exe" }
    3 = @{ Name = "Discord Development"; Path = "$env:LOCALAPPDATA\DiscordDevelopment"; Processes = @("DiscordDevelopment", "Update"); Exe = "DiscordDevelopment.exe" }
    4 = @{ Name = "Vencord"; Path = "$env:LOCALAPPDATA\Vencord"; FallbackPath = "$env:LOCALAPPDATA\Discord"; Processes = @("Vencord", "Discord", "Update"); Exe = "Discord.exe" }
}

$UPDATE_URL = "https://raw.githubusercontent.com/ProdHallow/installer/refs/heads/main/DiscordVoiceFixer.ps1"
$VOICE_BACKUP_API = "https://api.github.com/repos/ProdHallow/voice-backup/contents/Discord%20Voice%20Backup?ref=c23e2fdc4916bf9c2ad7b8c479e590727bf84c11"
$FFMPEG_URL = "https://github.com/ProdHallow/voice-backup/raw/refs/heads/main/ffmpeg.dll"
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
    
    $killedAny = $false
    foreach ($procName in $ProcessNames) {
        $processes = Get-Process -Name $procName -ErrorAction SilentlyContinue
        if ($processes) {
            $processes | Stop-Process -Force -ErrorAction SilentlyContinue
            $killedAny = $true
            Start-Sleep -Milliseconds 100
        }
    }
    return $killedAny
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
        Add-Status $StatusBox $Form "  âœ— Failed to download voice backup files: $($_.Exception.Message)" "Red"
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
        Add-Status $StatusBox $Form "  âœ— Failed to download ffmpeg.dll: $($_.Exception.Message)" "Red"
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
copy /Y "$UpdatedScriptPath" "$CurrentScriptPath" >nul
if errorlevel 1 (
    echo Update failed!
    pause
) else (
    echo Update applied successfully!
    echo Starting updated script...
    timeout /t 1 /nobreak >nul
    start "" powershell.exe -ExecutionPolicy Bypass -File "$CurrentScriptPath"
)
del "$UpdatedScriptPath" >nul 2>&1
del "%~f0" >nul 2>&1
"@
    
    $batchContent | Out-File -FilePath $batchFile -Encoding ASCII -Force
    Start-Process -FilePath "cmd.exe" -ArgumentList "/c", "`"$batchFile`"" -WindowStyle Hidden
}
#endregion

#region UI Creation
$form = New-Object System.Windows.Forms.Form
$form.Text = "Stereo Installer"
$form.Size = New-Object System.Drawing.Size(520, 550)
$form.StartPosition = "CenterScreen"
$form.FormBorderStyle = "FixedDialog"
$form.MaximizeBox = $false
$form.BackColor = $Theme.Background
$form.TopMost = $true

$titleLabel = New-StyledLabel -X 20 -Y 15 -Width 460 -Height 35 -Text "Stereo Installer" -Font $Fonts.Title -TextAlign "MiddleCenter"
$form.Controls.Add($titleLabel)

$creditsLabel = New-StyledLabel -X 20 -Y 52 -Width 460 -Height 28 `
    -Text "Made by`r`nOracle | Shaun | Terrain | Hallow | Ascend" `
    -Font $Fonts.Small -ForeColor $Theme.TextSecondary -TextAlign "MiddleCenter"
$form.Controls.Add($creditsLabel)

$clientGroup = New-Object System.Windows.Forms.GroupBox
$clientGroup.Location = New-Object System.Drawing.Point(20, 90)
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
$clientCombo.Font = $Fonts.Normal
foreach ($client in $DiscordClients.Values) {
    [void]$clientCombo.Items.Add($client.Name)
}
$clientCombo.SelectedIndex = 0
$clientGroup.Controls.Add($clientCombo)

$optionsGroup = New-Object System.Windows.Forms.GroupBox
$optionsGroup.Location = New-Object System.Drawing.Point(20, 160)
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
$statusBox.Location = New-Object System.Drawing.Point(20, 305)
$statusBox.Size = New-Object System.Drawing.Size(460, 110)
$statusBox.ReadOnly = $true
$statusBox.BackColor = $Theme.ControlBg
$statusBox.ForeColor = $Theme.TextPrimary
$statusBox.Font = $Fonts.Console
$statusBox.DetectUrls = $false
$statusBox.BorderStyle = "FixedSingle"
$form.Controls.Add($statusBox)

$progressBar = New-Object System.Windows.Forms.ProgressBar
$progressBar.Location = New-Object System.Drawing.Point(20, 425)
$progressBar.Size = New-Object System.Drawing.Size(460, 22)
$progressBar.Style = "Continuous"
$form.Controls.Add($progressBar)

$btnStart = New-Object System.Windows.Forms.Button
$btnStart.Location = New-Object System.Drawing.Point(190, 455)
$btnStart.Size = New-Object System.Drawing.Size(120, 38)
$btnStart.Text = "Start Fix"
$btnStart.Font = $Fonts.Button
$btnStart.BackColor = $Theme.Primary
$btnStart.ForeColor = $Theme.TextPrimary
$btnStart.FlatStyle = "Flat"
$btnStart.FlatAppearance.BorderSize = 0
$btnStart.Cursor = [System.Windows.Forms.Cursors]::Hand
$form.Controls.Add($btnStart)
#endregion

#region Event Handlers
$chkUpdate.Add_CheckedChanged({
    $chkAutoUpdate.Enabled = $chkUpdate.Checked
    if (-not $chkUpdate.Checked) {
        $chkAutoUpdate.Checked = $false
    }
})

$btnStart.Add_Click({
    $btnStart.Enabled = $false
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
                $updateFile = "$env:TEMP\StereoInstaller_Update_$(Get-Random).ps1"
                $currentScript = $PSCommandPath
                
                Invoke-WebRequest -Uri $UPDATE_URL -OutFile $updateFile -UseBasicParsing -TimeoutSec 10
                
                $updateContent = Get-Content $updateFile -Raw
                $currentContent = Get-Content $currentScript -Raw
                
                if ($updateContent -ne $currentContent) {
                    Add-Status $statusBox $form "New update found!" "Yellow"
                    
                    if ($chkAutoUpdate.Checked) {
                        Add-Status $statusBox $form "Update will be applied after script closes..." "Cyan"
                        Add-Status $statusBox $form "âœ“ Update prepared! Restarting in 3 seconds..." "LimeGreen"
                        
                        Start-Sleep -Seconds 3
                        
                        Apply-ScriptUpdate -UpdatedScriptPath $updateFile -CurrentScriptPath $currentScript
                        
                        $form.Close()
                        return
                    } else {
                        Add-Status $statusBox $form "Update downloaded to: $updateFile" "Orange"
                        Add-Status $statusBox $form "Please manually replace the script file to update." "Orange"
                    }
                } else {
                    Add-Status $statusBox $form "âœ“ You are on the latest version" "LimeGreen"
                    Remove-Item $updateFile -ErrorAction SilentlyContinue
                }
            } catch {
                Add-Status $statusBox $form "âš  Could not check for updates: $($_.Exception.Message)" "Orange"
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
        
        Add-Status $statusBox $form "âœ“ All files downloaded successfully" "LimeGreen"
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
        Add-Status $statusBox $form "âœ“ Discord processes closed" "LimeGreen"
        
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
        
        Add-Status $statusBox $form "âœ“ Found $($selectedClient.Name) at: $appPath" "LimeGreen"
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
        
        Add-Status $statusBox $form "âœ“ Voice module located" "LimeGreen"
        Update-Progress $progressBar $form 60
        
        # Step 6: Clear Old Files
        Add-Status $statusBox $form "Removing old voice module files..." "Blue"
        if (Test-Path $targetVoiceFolder) {
            Remove-Item "$targetVoiceFolder\*" -Recurse -Force -ErrorAction SilentlyContinue
        }
        Add-Status $statusBox $form "âœ“ Old files removed" "LimeGreen"
        Update-Progress $progressBar $form 70
        
        # Step 7: Copy Module Files
        Add-Status $statusBox $form "Copying updated module files..." "Blue"
        Copy-Item -Path "$voiceBackupPath\*" -Destination $targetVoiceFolder -Recurse -Force
        Add-Status $statusBox $form "âœ“ Module files copied" "LimeGreen"
        Update-Progress $progressBar $form 80
        
        # Step 8: Copy ffmpeg.dll
        Add-Status $statusBox $form "Copying ffmpeg.dll..." "Blue"
        $ffmpegTarget = Join-Path $appPath "ffmpeg.dll"
        Copy-Item -Path $ffmpegPath -Destination $ffmpegTarget -Force
        Add-Status $statusBox $form "âœ“ ffmpeg.dll replaced" "LimeGreen"
        Update-Progress $progressBar $form 85
        
        # Step 9: Create Startup Shortcut
        if ($chkShortcut.Checked) {
            Add-Status $statusBox $form "Creating startup shortcut..." "Blue"
            $startupFolder = "$env:APPDATA\Microsoft\Windows\Start Menu\Programs\Startup"
            $shortcutPath = Join-Path $startupFolder "DiscordVoiceFixer.lnk"
            
            $WshShell = New-Object -ComObject WScript.Shell
            $Shortcut = $WshShell.CreateShortcut($shortcutPath)
            $Shortcut.TargetPath = $PSCommandPath
            $Shortcut.WorkingDirectory = (Split-Path -Parent $PSCommandPath)
            $Shortcut.Save()
            
            Add-Status $statusBox $form "âœ“ Startup shortcut created" "LimeGreen"
        }
        Update-Progress $progressBar $form 90
        
        # Step 10: Start Discord
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
                        Add-Status $statusBox $form "âœ“ Discord started (from alternate location)" "LimeGreen"
                    }
                }
            } elseif ($started) {
                Add-Status $statusBox $form "âœ“ Discord started" "LimeGreen"
            }
            
            if (-not $started) {
                Add-Status $statusBox $form "âš  Could not find Discord executable" "Orange"
            }
        }
        
        Update-Progress $progressBar $form 100
        Add-Status $statusBox $form "" "White"
        Add-Status $statusBox $form "=== ALL TASKS COMPLETED ===" "LimeGreen"
        
        [System.Windows.Forms.MessageBox]::Show(
            $form,
            "Discord voice module fix completed successfully!",
            "Success",
            [System.Windows.Forms.MessageBoxButtons]::OK,
            [System.Windows.Forms.MessageBoxIcon]::Information
        )
        
        $form.Close()
        
    } catch {
        Add-Status $statusBox $form "" "White"
        Add-Status $statusBox $form "âœ— ERROR: $($_.Exception.Message)" "Red"
        
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
    }
})
#endregion

$form.Add_Shown({$form.Activate()})
[void]$form.ShowDialog()
