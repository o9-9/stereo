Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# Create the main form
$form = New-Object System.Windows.Forms.Form
$form.Text = "Stereo Installer"
$form.Size = New-Object System.Drawing.Size(520, 550)
$form.StartPosition = "CenterScreen"
$form.FormBorderStyle = "FixedDialog"
$form.MaximizeBox = $false
$form.BackColor = [System.Drawing.Color]::FromArgb(32, 34, 37)
$form.TopMost = $true

# Title Label
$titleLabel = New-Object System.Windows.Forms.Label
$titleLabel.Location = New-Object System.Drawing.Point(20, 15)
$titleLabel.Size = New-Object System.Drawing.Size(460, 35)
$titleLabel.Text = "Stereo Installer"
$titleLabel.Font = New-Object System.Drawing.Font("Segoe UI", 16, [System.Drawing.FontStyle]::Bold)
$titleLabel.TextAlign = "MiddleCenter"
$titleLabel.ForeColor = [System.Drawing.Color]::White
$titleLabel.BackColor = [System.Drawing.Color]::Transparent
$form.Controls.Add($titleLabel)

# Credits Label
$creditsLabel = New-Object System.Windows.Forms.Label
$creditsLabel.Location = New-Object System.Drawing.Point(20, 52)
$creditsLabel.Size = New-Object System.Drawing.Size(460, 28)
$creditsLabel.Text = "Made by`r`nOracle | Shaun | Terrain | Hallow"
$creditsLabel.Font = New-Object System.Drawing.Font("Segoe UI", 8.5)
$creditsLabel.TextAlign = "MiddleCenter"
$creditsLabel.ForeColor = [System.Drawing.Color]::FromArgb(150, 150, 150)
$creditsLabel.BackColor = [System.Drawing.Color]::Transparent
$form.Controls.Add($creditsLabel)

# Discord Client GroupBox
$clientGroup = New-Object System.Windows.Forms.GroupBox
$clientGroup.Location = New-Object System.Drawing.Point(20, 90)
$clientGroup.Size = New-Object System.Drawing.Size(460, 60)
$clientGroup.Text = "Discord Client"
$clientGroup.ForeColor = [System.Drawing.Color]::White
$clientGroup.BackColor = [System.Drawing.Color]::Transparent
$clientGroup.Font = New-Object System.Drawing.Font("Segoe UI", 9)
$form.Controls.Add($clientGroup)

$clientCombo = New-Object System.Windows.Forms.ComboBox
$clientCombo.Location = New-Object System.Drawing.Point(20, 25)
$clientCombo.Size = New-Object System.Drawing.Size(420, 28)
$clientCombo.DropDownStyle = "DropDownList"
$clientCombo.BackColor = [System.Drawing.Color]::FromArgb(47, 49, 54)
$clientCombo.ForeColor = [System.Drawing.Color]::White
$clientCombo.FlatStyle = "Flat"
$clientCombo.Font = New-Object System.Drawing.Font("Segoe UI", 9)
[void]$clientCombo.Items.Add("Discord (Stable)")
[void]$clientCombo.Items.Add("Discord PTB")
[void]$clientCombo.Items.Add("Discord Canary")
[void]$clientCombo.Items.Add("Discord Development")
[void]$clientCombo.Items.Add("Vencord")
$clientCombo.SelectedIndex = 0
$clientGroup.Controls.Add($clientCombo)

# Options GroupBox
$optionsGroup = New-Object System.Windows.Forms.GroupBox
$optionsGroup.Location = New-Object System.Drawing.Point(20, 160)
$optionsGroup.Size = New-Object System.Drawing.Size(460, 135)
$optionsGroup.Text = "Options"
$optionsGroup.ForeColor = [System.Drawing.Color]::White
$optionsGroup.BackColor = [System.Drawing.Color]::Transparent
$optionsGroup.Font = New-Object System.Drawing.Font("Segoe UI", 9)
$form.Controls.Add($optionsGroup)

# Check for updates checkbox
$chkUpdate = New-Object System.Windows.Forms.CheckBox
$chkUpdate.Location = New-Object System.Drawing.Point(20, 28)
$chkUpdate.Size = New-Object System.Drawing.Size(420, 22)
$chkUpdate.Text = "Check for script updates before fixing"
$chkUpdate.Checked = $true
$chkUpdate.ForeColor = [System.Drawing.Color]::White
$chkUpdate.Font = New-Object System.Drawing.Font("Segoe UI", 9)
$optionsGroup.Controls.Add($chkUpdate)

# Auto-apply updates checkbox
$chkAutoUpdate = New-Object System.Windows.Forms.CheckBox
$chkAutoUpdate.Location = New-Object System.Drawing.Point(40, 52)
$chkAutoUpdate.Size = New-Object System.Drawing.Size(400, 22)
$chkAutoUpdate.Text = "Automatically download and apply updates"
$chkAutoUpdate.Checked = $true
$chkAutoUpdate.ForeColor = [System.Drawing.Color]::FromArgb(180, 180, 180)
$chkAutoUpdate.Font = New-Object System.Drawing.Font("Segoe UI", 9)
$chkAutoUpdate.Enabled = $true
$optionsGroup.Controls.Add($chkAutoUpdate)

# Create startup shortcut checkbox
$chkShortcut = New-Object System.Windows.Forms.CheckBox
$chkShortcut.Location = New-Object System.Drawing.Point(20, 76)
$chkShortcut.Size = New-Object System.Drawing.Size(420, 22)
$chkShortcut.Text = "Create startup shortcut (run fixer on Windows startup)"
$chkShortcut.Checked = $false
$chkShortcut.ForeColor = [System.Drawing.Color]::White
$chkShortcut.Font = New-Object System.Drawing.Font("Segoe UI", 9)
$optionsGroup.Controls.Add($chkShortcut)

# Auto-start Discord checkbox
$chkAutoStart = New-Object System.Windows.Forms.CheckBox
$chkAutoStart.Location = New-Object System.Drawing.Point(20, 100)
$chkAutoStart.Size = New-Object System.Drawing.Size(420, 22)
$chkAutoStart.Text = "Automatically start Discord after fixing"
$chkAutoStart.Checked = $true
$chkAutoStart.ForeColor = [System.Drawing.Color]::White
$chkAutoStart.Font = New-Object System.Drawing.Font("Segoe UI", 9)
$optionsGroup.Controls.Add($chkAutoStart)

# Progress/Status RichTextBox
$statusBox = New-Object System.Windows.Forms.RichTextBox
$statusBox.Location = New-Object System.Drawing.Point(20, 305)
$statusBox.Size = New-Object System.Drawing.Size(460, 110)
$statusBox.ReadOnly = $true
$statusBox.BackColor = [System.Drawing.Color]::FromArgb(47, 49, 54)
$statusBox.ForeColor = [System.Drawing.Color]::White
$statusBox.Font = New-Object System.Drawing.Font("Consolas", 9)
$statusBox.DetectUrls = $false
$statusBox.BorderStyle = "FixedSingle"
$form.Controls.Add($statusBox)

# Progress Bar
$progressBar = New-Object System.Windows.Forms.ProgressBar
$progressBar.Location = New-Object System.Drawing.Point(20, 425)
$progressBar.Size = New-Object System.Drawing.Size(460, 22)
$progressBar.Style = "Continuous"
$form.Controls.Add($progressBar)

# Start Button
$btnStart = New-Object System.Windows.Forms.Button
$btnStart.Location = New-Object System.Drawing.Point(190, 455)
$btnStart.Size = New-Object System.Drawing.Size(120, 38)
$btnStart.Text = "Start Fix"
$btnStart.Font = New-Object System.Drawing.Font("Segoe UI", 11, [System.Drawing.FontStyle]::Bold)
$btnStart.BackColor = [System.Drawing.Color]::FromArgb(88, 101, 242)
$btnStart.ForeColor = [System.Drawing.Color]::White
$btnStart.FlatStyle = "Flat"
$btnStart.FlatAppearance.BorderSize = 0
$btnStart.Cursor = [System.Windows.Forms.Cursors]::Hand
$form.Controls.Add($btnStart)

# Add event to enable/disable auto-update checkbox
$chkUpdate.Add_CheckedChanged({
    $chkAutoUpdate.Enabled = $chkUpdate.Checked
    if (-not $chkUpdate.Checked) {
        $chkAutoUpdate.Checked = $false
    }
})

# Function to add status messages
function Add-Status {
    param($message, $color = "White")
    $timestamp = Get-Date -Format "HH:mm:ss"
    $statusBox.SelectionStart = $statusBox.TextLength
    $statusBox.SelectionLength = 0
    $statusBox.SelectionColor = [System.Drawing.Color]::FromName($color)
    $statusBox.AppendText("[$timestamp] $message`r`n")
    $statusBox.ScrollToCaret()
    $form.Refresh()
}

# Function to update progress
function Update-Progress {
    param($value)
    $progressBar.Value = $value
    $form.Refresh()
}

# Button Click Event
$btnStart.Add_Click({
    $btnStart.Enabled = $false
    $statusBox.Clear()
    $progressBar.Value = 0
    
    try {
        # Step 1: Check for updates if selected
        if ($chkUpdate.Checked) {
            Add-Status "Checking for script updates..." "Blue"
            Update-Progress 5
            
            try {
                $updateURL = "https://raw.githubusercontent.com/ProdHallow/installer/refs/heads/main/installer.ps1"
                $tempFile = "$env:TEMP\stereo_update.tmp"
                $currentScript = $PSCommandPath
                
                Invoke-WebRequest -Uri $updateURL -OutFile $tempFile -UseBasicParsing
                
                if (Compare-Object (Get-Content $tempFile) (Get-Content $currentScript)) {
                    Add-Status "New update found!" "Yellow"
                    
                    if ($chkAutoUpdate.Checked) {
                        Add-Status "Downloading and applying update..." "Cyan"
                        Copy-Item -Path $tempFile -Destination $currentScript -Force
                        Add-Status "✓ Update applied successfully! Please restart the script." "LimeGreen"
                        Remove-Item $tempFile -ErrorAction SilentlyContinue
                        
                        $result = [System.Windows.Forms.MessageBox]::Show(
                            "Script has been updated! The application will now close. Please run the script again to use the new version.",
                            "Update Complete",
                            [System.Windows.Forms.MessageBoxButtons]::OK,
                            [System.Windows.Forms.MessageBoxIcon]::Information
                        )
                        $form.Close()
                        return
                    } else {
                        Add-Status "Please download the update manually from GitHub." "Orange"
                        Remove-Item $tempFile -ErrorAction SilentlyContinue
                    }
                } else {
                    Add-Status "✓ You are on the latest version" "LimeGreen"
                    Remove-Item $tempFile -ErrorAction SilentlyContinue
                }
            } catch {
                Add-Status "⚠ Could not check for updates: $($_.Exception.Message)" "Orange"
            }
        }
        
        Update-Progress 10
        
        # Step 2: Kill Discord
        Add-Status "Closing Discord processes..." "Blue"
        
        $processNames = switch ($clientCombo.SelectedIndex) {
            0 { @("Discord", "Update") }
            1 { @("DiscordPTB", "Update") }
            2 { @("DiscordCanary", "Update") }
            3 { @("DiscordDevelopment", "Update") }
            4 { @("Vencord", "Discord", "Update") }
        }
        
        $killedAny = $false
        foreach ($proc in $processNames) {
            $processes = Get-Process -Name $proc -ErrorAction SilentlyContinue
            if ($processes) {
                $processes | Stop-Process -Force
                Add-Status "  Killed $proc process" "Cyan"
                $killedAny = $true
            }
        }
        
        if (-not $killedAny) {
            Add-Status "  No Discord processes were running" "Yellow"
        }
        
        Start-Sleep -Seconds 1
        Update-Progress 20
        Add-Status "✓ Discord processes closed" "LimeGreen"
        
        # Step 3: Find Discord installation
        Add-Status "Locating Discord installation..." "Blue"
        
        $clientName = $clientCombo.SelectedItem
        
        $base = switch ($clientCombo.SelectedIndex) {
            0 { "$env:LOCALAPPDATA\Discord" }
            1 { "$env:LOCALAPPDATA\DiscordPTB" }
            2 { "$env:LOCALAPPDATA\DiscordCanary" }
            3 { "$env:LOCALAPPDATA\DiscordDevelopment" }
            4 { 
                if (Test-Path "$env:LOCALAPPDATA\Vencord") {
                    "$env:LOCALAPPDATA\Vencord"
                } else {
                    "$env:LOCALAPPDATA\Discord"
                }
            }
        }
        
        Add-Status "Searching in: $base" "Cyan"
        
        if (-not (Test-Path $base)) {
            throw "Discord client folder not found at: $base`r`nPlease verify $clientName is installed."
        }
        
        $appPath = $null
        $appFolders = Get-ChildItem -Path $base -Filter "app-*" -Directory -ErrorAction SilentlyContinue | Sort-Object Name -Descending
        
        if (-not $appFolders) {
            throw "No app-* folders found in $base`r`nPlease verify $clientName is installed correctly."
        }
        
        foreach ($folder in $appFolders) {
            $modulesPath = Join-Path $folder.FullName "modules"
            if (Test-Path $modulesPath) {
                $voiceModules = Get-ChildItem -Path $modulesPath -Filter "discord_voice*" -Directory -ErrorAction SilentlyContinue
                if ($voiceModules) {
                    $appPath = $folder.FullName
                    break
                }
            }
        }
        
        if (-not $appPath) {
            throw "No Discord app folder with voice module found in $base`r`nTried folders: $($appFolders.Name -join ', ')"
        }
        
        Add-Status "✓ Found $clientName at: $appPath" "LimeGreen"
        Update-Progress 30
        
        # Step 4: Find voice module
        Add-Status "Locating voice module..." "Blue"
        $voiceModule = Get-ChildItem -Path "$appPath\modules" -Filter "discord_voice*" -Directory | Select-Object -First 1
        
        if (-not $voiceModule) {
            throw "No discord_voice module found"
        }
        
        $targetVoiceFolder = if (Test-Path "$($voiceModule.FullName)\discord_voice") {
            "$($voiceModule.FullName)\discord_voice"
        } else {
            $voiceModule.FullName
        }
        
        Add-Status "✓ Voice module located" "LimeGreen"
        Update-Progress 40
        
        # Step 5: Clear old files
        Add-Status "Removing old voice module files..." "Blue"
        if (Test-Path $targetVoiceFolder) {
            Remove-Item "$targetVoiceFolder\*" -Recurse -Force -ErrorAction SilentlyContinue
        }
        Add-Status "✓ Old files removed" "LimeGreen"
        Update-Progress 50
        
        # Step 6: Find backup folder
        Add-Status "Searching for backup folder..." "Blue"
        $scriptDir = Split-Path -Parent $PSCommandPath
        $sourceBackup = Get-ChildItem -Path $scriptDir -Filter "Discord*Backup" -Directory | Select-Object -First 1
        
        if (-not $sourceBackup) {
            throw "Backup folder not found next to script"
        }
        
        Add-Status "✓ Backup found: $($sourceBackup.Name)" "LimeGreen"
        Update-Progress 60
        
        # Step 7: Copy files
        Add-Status "Copying updated module files..." "Blue"
        Copy-Item -Path "$($sourceBackup.FullName)\*" -Destination $targetVoiceFolder -Recurse -Force
        Add-Status "✓ Module files copied" "LimeGreen"
        Update-Progress 70
        
        # Step 8: Copy ffmpeg.dll
        Add-Status "Locating and copying ffmpeg.dll..." "Blue"
        $ffmpegSource = Get-ChildItem -Path $scriptDir -Filter "ffmpeg.dll" -Recurse | Select-Object -First 1
        
        if (-not $ffmpegSource) {
            throw "ffmpeg.dll not found"
        }
        
        $ffmpegTarget = Join-Path $appPath "ffmpeg.dll"
        Copy-Item -Path $ffmpegSource.FullName -Destination $ffmpegTarget -Force
        Add-Status "✓ ffmpeg.dll replaced" "LimeGreen"
        Update-Progress 80
        
        # Step 9: Create startup shortcut if selected
        if ($chkShortcut.Checked) {
            Add-Status "Creating startup shortcut..." "Blue"
            $startupFolder = "$env:APPDATA\Microsoft\Windows\Start Menu\Programs\Startup"
            $shortcutPath = Join-Path $startupFolder "DiscordVoiceFixer.lnk"
            
            $WshShell = New-Object -ComObject WScript.Shell
            $Shortcut = $WshShell.CreateShortcut($shortcutPath)
            $Shortcut.TargetPath = $PSCommandPath
            $Shortcut.WorkingDirectory = $scriptDir
            $Shortcut.Save()
            
            Add-Status "✓ Startup shortcut created" "LimeGreen"
        }
        Update-Progress 90
        
        # Step 10: Start Discord if selected
        if ($chkAutoStart.Checked) {
            Add-Status "Starting Discord..." "Blue"
            
            # Vencord uses the regular Discord executable
            $exeName = switch ($clientCombo.SelectedIndex) {
                0 { "Discord.exe" }
                1 { "DiscordPTB.exe" }
                2 { "DiscordCanary.exe" }
                3 { "DiscordDevelopment.exe" }
                4 { "Discord.exe" }  # Vencord uses Discord.exe
            }
            
            $discordExe = Join-Path $appPath $exeName
            if (Test-Path $discordExe) {
                # Launch Discord completely detached using cmd
                Start-Process -FilePath "cmd.exe" -ArgumentList "/c", "start", '""', "`"$discordExe`"" -WindowStyle Hidden
                Add-Status "✓ Discord started" "LimeGreen"
            } else {
                # Try alternate location for Vencord
                if ($clientCombo.SelectedIndex -eq 4) {
                    $altPath = "$env:LOCALAPPDATA\Discord"
                    $appFolders = Get-ChildItem -Path $altPath -Filter "app-*" -Directory | Sort-Object Name -Descending | Select-Object -First 1
                    if ($appFolders) {
                        $altExe = Join-Path $appFolders.FullName "Discord.exe"
                        if (Test-Path $altExe) {
                            Start-Process -FilePath "cmd.exe" -ArgumentList "/c", "start", '""', "`"$altExe`"" -WindowStyle Hidden
                            Add-Status "✓ Discord started (from alternate location)" "LimeGreen"
                        } else {
                            Add-Status "⚠ Could not find Discord.exe for Vencord" "Orange"
                        }
                    } else {
                        Add-Status "⚠ Could not find Discord installation for Vencord" "Orange"
                    }
                } else {
                    Add-Status "⚠ Could not find $exeName" "Orange"
                }
            }
        }
        
        Update-Progress 100
        Add-Status "" "White"
        Add-Status "=== ALL TASKS COMPLETED ===" "LimeGreen"
        
        # Show success message with form as owner to keep it on top
        $result = [System.Windows.Forms.MessageBox]::Show(
            $form,
            "Discord voice module fix completed successfully!",
            "Success",
            [System.Windows.Forms.MessageBoxButtons]::OK,
            [System.Windows.Forms.MessageBoxIcon]::Information
        )
        
        # Close the form after success
        $form.Close()
        
    } catch {
        Add-Status "" "White"
        Add-Status "✗ ERROR: $($_.Exception.Message)" "Red"
        
        # Show error message with form as owner to keep it on top
        [System.Windows.Forms.MessageBox]::Show(
            $form,
            "An error occurred: $($_.Exception.Message)",
            "Error",
            [System.Windows.Forms.MessageBoxButtons]::OK,
            [System.Windows.Forms.MessageBoxIcon]::Error
        )
    } finally {
        $btnStart.Enabled = $true
    }
})

# Show the form
$form.Add_Shown({$form.Activate()})
[void]$form.ShowDialog()
