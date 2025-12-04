Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# Create the main form
$form = New-Object System.Windows.Forms.Form
$form.Text = "Discord Voice Module Auto-Fixer"
$form.Size = New-Object System.Drawing.Size(500, 500)
$form.StartPosition = "CenterScreen"
$form.FormBorderStyle = "FixedDialog"
$form.MaximizeBox = $false
$form.BackColor = [System.Drawing.Color]::FromArgb(32, 34, 37)  # Discord dark background

# Title Label
$titleLabel = New-Object System.Windows.Forms.Label
$titleLabel.Location = New-Object System.Drawing.Point(10, 10)
$titleLabel.Size = New-Object System.Drawing.Size(460, 30)
$titleLabel.Text = "Discord Voice Module Auto-Fixer"
$titleLabel.Font = New-Object System.Drawing.Font("Segoe UI", 14, [System.Drawing.FontStyle]::Bold)
$titleLabel.TextAlign = "MiddleCenter"
$titleLabel.ForeColor = [System.Drawing.Color]::White
$titleLabel.BackColor = [System.Drawing.Color]::Transparent
$form.Controls.Add($titleLabel)

# Discord Client Selection (moved above options box)
$clientLabel = New-Object System.Windows.Forms.Label
$clientLabel.Location = New-Object System.Drawing.Point(10, 50)
$clientLabel.Size = New-Object System.Drawing.Size(100, 20)
$clientLabel.Text = "Discord Client:"
$clientLabel.ForeColor = [System.Drawing.Color]::White
$form.Controls.Add($clientLabel)

$clientCombo = New-Object System.Windows.Forms.ComboBox
$clientCombo.Location = New-Object System.Drawing.Point(110, 48)
$clientCombo.Size = New-Object System.Drawing.Size(200, 25)
$clientCombo.DropDownStyle = "DropDownList"
$clientCombo.BackColor = [System.Drawing.Color]::FromArgb(47, 49, 54)
$clientCombo.ForeColor = [System.Drawing.Color]::White
$clientCombo.FlatStyle = "Flat"
[void]$clientCombo.Items.Add("Discord (Stable)")
[void]$clientCombo.Items.Add("Discord PTB")
[void]$clientCombo.Items.Add("Discord Canary")
[void]$clientCombo.Items.Add("Discord Development")
[void]$clientCombo.Items.Add("Vencord")
$clientCombo.SelectedIndex = 0
$form.Controls.Add($clientCombo)

# Options GroupBox
$optionsGroup = New-Object System.Windows.Forms.GroupBox
$optionsGroup.Location = New-Object System.Drawing.Point(10, 80)
$optionsGroup.Size = New-Object System.Drawing.Size(460, 140)
$optionsGroup.Text = "Options"
$optionsGroup.ForeColor = [System.Drawing.Color]::White
$optionsGroup.BackColor = [System.Drawing.Color]::Transparent
$form.Controls.Add($optionsGroup)

# Check for updates checkbox
$chkUpdate = New-Object System.Windows.Forms.CheckBox
$chkUpdate.Location = New-Object System.Drawing.Point(20, 30)
$chkUpdate.Size = New-Object System.Drawing.Size(420, 20)
$chkUpdate.Text = "Check for script updates before fixing"
$chkUpdate.Checked = $true
$chkUpdate.ForeColor = [System.Drawing.Color]::White
$optionsGroup.Controls.Add($chkUpdate)

# Auto-apply updates checkbox
$chkAutoUpdate = New-Object System.Windows.Forms.CheckBox
$chkAutoUpdate.Location = New-Object System.Drawing.Point(40, 50)
$chkAutoUpdate.Size = New-Object System.Drawing.Size(400, 20)
$chkAutoUpdate.Text = "Automatically download and apply updates"
$chkAutoUpdate.Checked = $true
$chkAutoUpdate.ForeColor = [System.Drawing.Color]::LightGray
$chkAutoUpdate.Enabled = $true
$optionsGroup.Controls.Add($chkAutoUpdate)

# Create startup shortcut checkbox
$chkShortcut = New-Object System.Windows.Forms.CheckBox
$chkShortcut.Location = New-Object System.Drawing.Point(20, 75)
$chkShortcut.Size = New-Object System.Drawing.Size(420, 20)
$chkShortcut.Text = "Create startup shortcut (run fixer on Windows startup)"
$chkShortcut.Checked = $false
$chkShortcut.ForeColor = [System.Drawing.Color]::White
$optionsGroup.Controls.Add($chkShortcut)

# Auto-start Discord checkbox
$chkAutoStart = New-Object System.Windows.Forms.CheckBox
$chkAutoStart.Location = New-Object System.Drawing.Point(20, 100)
$chkAutoStart.Size = New-Object System.Drawing.Size(420, 20)
$chkAutoStart.Text = "Automatically start Discord after fixing"
$chkAutoStart.Checked = $true
$chkAutoStart.ForeColor = [System.Drawing.Color]::White
$optionsGroup.Controls.Add($chkAutoStart)

# Progress/Status RichTextBox (supports colors)
$statusBox = New-Object System.Windows.Forms.RichTextBox
$statusBox.Location = New-Object System.Drawing.Point(10, 230)
$statusBox.Size = New-Object System.Drawing.Size(460, 150)
$statusBox.ReadOnly = $true
$statusBox.BackColor = [System.Drawing.Color]::FromArgb(47, 49, 54)  # Discord darker background
$statusBox.ForeColor = [System.Drawing.Color]::White
$statusBox.Font = New-Object System.Drawing.Font("Consolas", 9)
$statusBox.DetectUrls = $false
$form.Controls.Add($statusBox)

# Progress Bar
$progressBar = New-Object System.Windows.Forms.ProgressBar
$progressBar.Location = New-Object System.Drawing.Point(10, 390)
$progressBar.Size = New-Object System.Drawing.Size(460, 20)
$progressBar.Style = "Continuous"
$form.Controls.Add($progressBar)

# Start Button
$btnStart = New-Object System.Windows.Forms.Button
$btnStart.Location = New-Object System.Drawing.Point(180, 420)
$btnStart.Size = New-Object System.Drawing.Size(120, 35)
$btnStart.Text = "Start Fix"
$btnStart.Font = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)
$btnStart.BackColor = [System.Drawing.Color]::FromArgb(88, 101, 242)  # Discord blurple
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
                $updateURL = "https://raw.githubusercontent.com/ProdHallow/installer/refs/heads/main/installer.bat"
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
        
        # Determine which Discord processes to kill based on client selection
        $processNames = switch ($clientCombo.SelectedIndex) {
            0 { @("Discord", "Update") }  # Stable
            1 { @("DiscordPTB", "Update") }  # PTB
            2 { @("DiscordCanary", "Update") }  # Canary
            3 { @("DiscordDevelopment", "Update") }  # Development
            4 { @("Vencord", "Discord", "Update") }  # Vencord (may use Discord process)
        }
        
        foreach ($proc in $processNames) {
            Get-Process -Name $proc -ErrorAction SilentlyContinue | Stop-Process -Force
        }
        Start-Sleep -Seconds 1
        Update-Progress 20
        Add-Status "✓ Discord processes closed" "LimeGreen"
        
        # Step 3: Find Discord installation
        Add-Status "Locating Discord installation..." "Blue"
        
        # Determine base path based on client
        $base = switch ($clientCombo.SelectedIndex) {
            0 { "$env:LOCALAPPDATA\Discord" }  # Stable
            1 { "$env:LOCALAPPDATA\DiscordPTB" }  # PTB
            2 { "$env:LOCALAPPDATA\DiscordCanary" }  # Canary
            3 { "$env:LOCALAPPDATA\DiscordDevelopment" }  # Development
            4 { 
                # Vencord can be in multiple locations
                if (Test-Path "$env:LOCALAPPDATA\Vencord") {
                    "$env:LOCALAPPDATA\Vencord"
                } else {
                    "$env:LOCALAPPDATA\Discord"
                }
            }
        }
        
        if (-not (Test-Path $base)) {
            throw "Discord client folder not found at: $base"
        }
        
        $appPath = $null
        
        $appFolders = Get-ChildItem -Path $base -Filter "app-*" -Directory | Sort-Object Name -Descending
        foreach ($folder in $appFolders) {
            $modulesPath = Join-Path $folder.FullName "modules"
            if (Test-Path $modulesPath) {
                $voiceModules = Get-ChildItem -Path $modulesPath -Filter "discord_voice*" -Directory
                if ($voiceModules) {
                    $appPath = $folder.FullName
                    break
                }
            }
        }
        
        if (-not $appPath) {
            throw "No Discord app folder with voice module found"
        }
        
        Add-Status "✓ Found Discord at: $appPath" "LimeGreen"
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
            
            # Determine executable name based on client
            $exeName = switch ($clientCombo.SelectedIndex) {
                0 { "Discord.exe" }
                1 { "DiscordPTB.exe" }
                2 { "DiscordCanary.exe" }
                3 { "DiscordDevelopment.exe" }
                4 { "Vencord.exe" }
            }
            
            $discordExe = Join-Path $appPath $exeName
            if (Test-Path $discordExe) {
                Start-Process $discordExe
                Add-Status "✓ Discord started" "LimeGreen"
            } else {
                Add-Status "⚠ Could not find $exeName" "Orange"
            }
        }
        
        Update-Progress 100
        Add-Status "" "White"
        Add-Status "=== ALL TASKS COMPLETED ===" "LimeGreen"
        [System.Windows.Forms.MessageBox]::Show("Discord voice module fix completed successfully!", "Success", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Information)
        
    } catch {
        Add-Status "" "Black"
        Add-Status "✗ ERROR: $($_.Exception.Message)" "Red"
        [System.Windows.Forms.MessageBox]::Show("An error occurred: $($_.Exception.Message)", "Error", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
    } finally {
        $btnStart.Enabled = $true
    }
})

# Show the form
$form.Add_Shown({$form.Activate()})
[void]$form.ShowDialog()
