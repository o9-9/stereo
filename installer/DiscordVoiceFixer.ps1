param([switch]$Silent, [switch]$CheckOnly, [string]$FixClient, [switch]$Help)

# 1. Performance & Security Setup
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$ProgressPreference = 'SilentlyContinue'

if ($Help) { Write-Host "Discord Voice Fixer`nUsage: .\DiscordVoiceFixer.ps1 [-Silent] [-CheckOnly] [-FixClient <n>] [-Help]"; exit 0 }

# 2. Load Assemblies & Visuals
Add-Type -AssemblyName System.Windows.Forms, System.Drawing

if ([System.Environment]::OSVersion.Version.Major -ge 6) {
    try {
        [System.Windows.Forms.Application]::EnableVisualStyles()
        [System.Windows.Forms.Application]::SetCompatibleTextRenderingDefault($false)
    } catch {}
}

# 3. Theme & Fonts
$Theme = @{
    Background=[System.Drawing.Color]::FromArgb(32,34,37); ControlBg=[System.Drawing.Color]::FromArgb(47,49,54)
    Primary=[System.Drawing.Color]::FromArgb(88,101,242); Secondary=[System.Drawing.Color]::FromArgb(70,73,80)
    Warning=[System.Drawing.Color]::FromArgb(250,168,26); Success=[System.Drawing.Color]::FromArgb(87,158,87)
    TextPrimary=[System.Drawing.Color]::White; TextSecondary=[System.Drawing.Color]::FromArgb(150,150,150)
    TextDim=[System.Drawing.Color]::FromArgb(180,180,180)
}
$Fonts = @{
    Title=New-Object System.Drawing.Font("Segoe UI",16,[System.Drawing.FontStyle]::Bold)
    Normal=New-Object System.Drawing.Font("Segoe UI",9)
    Button=New-Object System.Drawing.Font("Segoe UI",11,[System.Drawing.FontStyle]::Bold)
    ButtonSmall=New-Object System.Drawing.Font("Segoe UI",9,[System.Drawing.FontStyle]::Bold)
    Console=New-Object System.Drawing.Font("Consolas",9)
    Small=New-Object System.Drawing.Font("Segoe UI",8.5)
}

# 4. Discord Clients Database
$DiscordClients = [ordered]@{
    0 = @{Name="Discord - Stable         [Official]"; Path="$env:LOCALAPPDATA\Discord";            RoamingPath="$env:APPDATA\discord";            Processes=@("Discord","Update");            Exe="Discord.exe";            Shortcut="Discord"}
    1 = @{Name="Discord - Canary         [Official]"; Path="$env:LOCALAPPDATA\DiscordCanary";      RoamingPath="$env:APPDATA\discordcanary";      Processes=@("DiscordCanary","Update");      Exe="DiscordCanary.exe";      Shortcut="Discord Canary"}
    2 = @{Name="Discord - PTB            [Official]"; Path="$env:LOCALAPPDATA\DiscordPTB";         RoamingPath="$env:APPDATA\discordptb";         Processes=@("DiscordPTB","Update");         Exe="DiscordPTB.exe";         Shortcut="Discord PTB"}
    3 = @{Name="Discord - Development    [Official]"; Path="$env:LOCALAPPDATA\DiscordDevelopment"; RoamingPath="$env:APPDATA\discorddevelopment"; Processes=@("DiscordDevelopment","Update"); Exe="DiscordDevelopment.exe"; Shortcut="Discord Development"}
    4 = @{Name="Lightcord                [Mod]";      Path="$env:LOCALAPPDATA\Lightcord";          RoamingPath="$env:APPDATA\Lightcord";          Processes=@("Lightcord","Update");          Exe="Lightcord.exe";          Shortcut="Lightcord"}
    5 = @{Name="BetterDiscord            [Mod]";      Path="$env:LOCALAPPDATA\Discord";            RoamingPath="$env:APPDATA\discord";            Processes=@("Discord","Update");            Exe="Discord.exe";            Shortcut="Discord"}
    6 = @{Name="Vencord                  [Mod]";      Path="$env:LOCALAPPDATA\Vencord";            RoamingPath="$env:APPDATA\discord";            FallbackPath="$env:LOCALAPPDATA\Discord"; Processes=@("Vencord","Discord","Update");       Exe="Discord.exe"; Shortcut="Vencord"}
    7 = @{Name="Equicord                 [Mod]";      Path="$env:LOCALAPPDATA\Equicord";           RoamingPath="$env:APPDATA\discord";            FallbackPath="$env:LOCALAPPDATA\Discord"; Processes=@("Equicord","Discord","Update");      Exe="Discord.exe"; Shortcut="Equicord"}
    8 = @{Name="BetterVencord            [Mod]";      Path="$env:LOCALAPPDATA\BetterVencord";      RoamingPath="$env:APPDATA\discord";            FallbackPath="$env:LOCALAPPDATA\Discord"; Processes=@("BetterVencord","Discord","Update"); Exe="Discord.exe"; Shortcut="BetterVencord"}
}

# 5. URLs & Paths
$UPDATE_URL = "https://raw.githubusercontent.com/ProdHallow/installer/main/DiscordVoiceFixer.ps1"
$VOICE_BACKUP_API = "https://api.github.com/repos/ProdHallow/voice-backup/contents/Discord%20Voice%20Backup"
$SETTINGS_JSON_URL = "https://raw.githubusercontent.com/ProdHallow/voice-backup/main/settings.json"
$DISCORD_SETUP_URL = "https://discord.com/api/downloads/distributions/app/installers/latest?channel=stable&platform=win&arch=x64"

$APP_DATA_ROOT = "$env:APPDATA\StereoInstaller"
$BACKUP_ROOT = "$APP_DATA_ROOT\backups"
$ORIGINAL_BACKUP_ROOT = "$APP_DATA_ROOT\original_discord_modules"
$STATE_FILE = "$APP_DATA_ROOT\state.json"
$SETTINGS_FILE = "$APP_DATA_ROOT\settings.json"
$SAVED_SCRIPT_PATH = "$APP_DATA_ROOT\DiscordVoiceFixer.ps1"
$SETTINGS_BACKUP_ROOT = "$APP_DATA_ROOT\settings_backups"

# 6. Core Utility Functions
function EnsureDir($p) { if (-not (Test-Path $p)) { try { [void](New-Item $p -ItemType Directory -Force) } catch { } } }

function Get-DefaultSettings { return [PSCustomObject]@{CheckForUpdates=$true; AutoApplyUpdates=$true; CreateShortcut=$false; AutoStartDiscord=$true; SelectedClientIndex=0; SilentStartup=$false; FixEqApo=$false} }

function Load-Settings {
    $d = Get-DefaultSettings
    if (Test-Path $SETTINGS_FILE) {
        try { 
            $s = Get-Content $SETTINGS_FILE -Raw | ConvertFrom-Json
            foreach ($k in $d.PSObject.Properties.Name) { 
                if ($null -eq $s.$k) { $s | Add-Member -NotePropertyName $k -NotePropertyValue $d.$k -Force } 
            }
            return $s
        } catch { }
    }
    return $d
}

function Save-Settings { param([PSCustomObject]$Settings)
    try { EnsureDir (Split-Path $SETTINGS_FILE -Parent); $Settings | ConvertTo-Json -Depth 5 | Out-File $SETTINGS_FILE -Force } catch { }
}

function Parse-BackupDate {
    param([string]$DateString)
    try { return [DateTime]::Parse($DateString, [System.Globalization.CultureInfo]::InvariantCulture) } catch { }
    try { return [DateTime]::Parse($DateString) } catch { }
    try { return [DateTime]::ParseExact($DateString, "o", [System.Globalization.CultureInfo]::InvariantCulture) } catch { }
    $formats = @("yyyy-MM-ddTHH:mm:ss.fffffffzzz","yyyy-MM-ddTHH:mm:ss.fffzzz","yyyy-MM-ddTHH:mm:sszzz","yyyy-MM-ddTHH:mm:ss","yyyy-MM-dd HH:mm:ss")
    foreach ($fmt in $formats) { try { return [DateTime]::ParseExact($DateString, $fmt, [System.Globalization.CultureInfo]::InvariantCulture) } catch { } }
    return [DateTime]::MinValue
}

function Test-BackupHasContent {
    param([string]$BackupPath)
    $voiceModulePath = Join-Path $BackupPath "voice_module"
    if (-not (Test-Path $voiceModulePath)) { return @{ Valid = $false; Reason = "voice_module folder missing" } }
    $files = Get-ChildItem $voiceModulePath -File -Recurse -ErrorAction SilentlyContinue
    if (-not $files -or $files.Count -eq 0) { return @{ Valid = $false; Reason = "voice_module folder is empty" } }
    $criticalFiles = $files | Where-Object { $_.Extension -in @(".node", ".dll") }
    if (-not $criticalFiles -or $criticalFiles.Count -eq 0) { return @{ Valid = $false; Reason = "voice_module missing critical files (.node/.dll)" } }
    $emptyFiles = $criticalFiles | Where-Object { $_.Length -eq 0 }
    if ($emptyFiles -and $emptyFiles.Count -gt 0) { return @{ Valid = $false; Reason = "voice_module has empty critical files" } }
    return @{ Valid = $true; FileCount = $files.Count; TotalSize = ($files | Measure-Object -Property Length -Sum).Sum }
}

# 7. GUI Elements
function New-StyledLabel {
    param([int]$X, [int]$Y, [int]$Width, [int]$Height, [string]$Text, [System.Drawing.Font]$Font=$Fonts.Normal,
          [System.Drawing.Color]$ForeColor=$Theme.TextPrimary, [string]$TextAlign="MiddleLeft")
    $l = New-Object System.Windows.Forms.Label
    $l.Location = New-Object System.Drawing.Point($X,$Y); $l.Size = New-Object System.Drawing.Size($Width,$Height)
    $l.Text = $Text; $l.Font = $Font; $l.TextAlign = $TextAlign; $l.ForeColor = $ForeColor
    $l.BackColor = [System.Drawing.Color]::Transparent; $l
}

function New-StyledCheckBox {
    param([int]$X, [int]$Y, [int]$Width, [int]$Height, [string]$Text, [bool]$Checked=$false, [System.Drawing.Color]$ForeColor=$Theme.TextPrimary)
    $c = New-Object System.Windows.Forms.CheckBox
    $c.Location = New-Object System.Drawing.Point($X,$Y); $c.Size = New-Object System.Drawing.Size($Width,$Height)
    $c.Text = $Text; $c.Checked = $Checked; $c.ForeColor = $ForeColor; $c.Font = $Fonts.Normal; $c
}

function New-StyledButton {
    param([int]$X, [int]$Y, [int]$Width, [int]$Height, [string]$Text, [System.Drawing.Font]$Font=$Fonts.Button, [System.Drawing.Color]$BackColor=$Theme.Primary)
    $b = New-Object System.Windows.Forms.Button
    $b.Location = New-Object System.Drawing.Point($X,$Y); $b.Size = New-Object System.Drawing.Size($Width,$Height)
    $b.Text = $Text; $b.Font = $Font; $b.BackColor = $BackColor; $b.ForeColor = $Theme.TextPrimary
    $b.FlatStyle = "Flat"; $b.FlatAppearance.BorderSize = 0; $b.Cursor = [System.Windows.Forms.Cursors]::Hand; $b
}

function Add-Status {
    param([System.Windows.Forms.RichTextBox]$StatusBox, [System.Windows.Forms.Form]$Form, [string]$Message, [string]$ColorName="White")
    if ($null -eq $StatusBox) { if ($Silent) { Write-Host $Message }; return }
    $c = try { [System.Drawing.Color]::FromName($ColorName) } catch { [System.Drawing.Color]::White }
    $ts = Get-Date -Format "HH:mm:ss"
    $StatusBox.SelectionStart = $StatusBox.TextLength; $StatusBox.SelectionLength = 0
    $StatusBox.SelectionColor = $c
    $StatusBox.AppendText("[$ts] $Message`r`n"); $StatusBox.ScrollToCaret()
    if ($null -ne $Form) { $Form.Refresh(); [System.Windows.Forms.Application]::DoEvents() }
}

function Play-CompletionSound { param([bool]$Success=$true)
    try { if ($Success) { [System.Media.SystemSounds]::Exclamation.Play() } else { [System.Media.SystemSounds]::Hand.Play() } } catch {}
}

function Update-Progress { param([System.Windows.Forms.ProgressBar]$ProgressBar, [System.Windows.Forms.Form]$Form, [int]$Value)
    if ($null -ne $ProgressBar) { $ProgressBar.Value = [Math]::Min($Value,100) }
    if ($null -ne $Form) { $Form.Refresh(); [System.Windows.Forms.Application]::DoEvents() }
}

# 8. Process & Discord Handling
function Stop-DiscordProcesses { param([string[]]$ProcessNames)
    $p = Get-Process -Name $ProcessNames -ErrorAction SilentlyContinue
    if ($p) {
        $p | Stop-Process -Force -ErrorAction SilentlyContinue
        for ($i=0; $i -lt 20; $i++) {
            if (-not (Get-Process -Name $ProcessNames -ErrorAction SilentlyContinue)) { return $true }
            Start-Sleep -Milliseconds 250
        }
        return $false
    }
    return $true
}

function Find-DiscordAppPath { 
    param([string]$BasePath, [switch]$ReturnDiagnostics)
    
    $af = Get-ChildItem $BasePath -Filter "app-*" -Directory -ErrorAction SilentlyContinue | 
        Sort-Object { $folder = $_; try { if ($folder.Name -match "app-([\d\.]+)") { [Version]$matches[1] } else { $folder.Name } } catch { $folder.Name } } -Descending
    
    $diag = @{ BasePath = $BasePath; AppFoldersFound = @(); ModulesFolderExists = $false; VoiceModuleExists = $false
               LatestAppFolder = $null; LatestAppVersion = $null; ModulesPath = $null; VoiceModulePath = $null; Error = $null }
    
    if (-not $af -or $af.Count -eq 0) { $diag.Error = "NoAppFolders"; if ($ReturnDiagnostics) { return $diag }; return $null }
    
    $diag.AppFoldersFound = @($af | ForEach-Object { $_.Name })
    $diag.LatestAppFolder = $af[0].FullName
    if ($af[0].Name -match "app-([\d\.]+)") { $diag.LatestAppVersion = $matches[1] } else { $diag.LatestAppVersion = $af[0].Name }
    
    foreach ($f in $af) {
        $mp = Join-Path $f.FullName "modules"
        if (Test-Path $mp) { 
            $diag.ModulesFolderExists = $true; $diag.ModulesPath = $mp
            $vm = Get-ChildItem $mp -Filter "discord_voice*" -Directory -ErrorAction SilentlyContinue
            if ($vm) { 
                $diag.VoiceModuleExists = $true; $diag.VoiceModulePath = $vm[0].FullName
                if ($ReturnDiagnostics) { return $diag }; return $f.FullName 
            }
        }
    }
    
    if (-not $diag.ModulesFolderExists) { $diag.Error = "NoModulesFolder" } 
    elseif (-not $diag.VoiceModuleExists) { $diag.Error = "NoVoiceModule" }
    if ($ReturnDiagnostics) { return $diag }; return $null
}

function Get-DiscordAppVersion { param([string]$AppPath)
    if ($AppPath -match "app-([\d\.]+)") { return $matches[1] }
    try { $exe = Get-ChildItem $AppPath -Filter "*.exe" | Select-Object -First 1; if ($exe) { return (Get-Item $exe.FullName).VersionInfo.ProductVersion } } catch {}
    return "Unknown"
}

function Reinstall-DiscordClient {
    param([string]$ClientPath, [hashtable]$ClientInfo, [System.Windows.Forms.RichTextBox]$StatusBox, [System.Windows.Forms.Form]$Form, [switch]$SkipConfirmation)
    
    try {
        $clientName = $ClientInfo.Name
        if ($clientName -notmatch "\[Official\]") {
            Add-Status $StatusBox $Form "[X] Automatic reinstall only supported for official Discord clients" "Red"
            Add-Status $StatusBox $Form "    Please manually reinstall $clientName" "Yellow"
            return $false
        }
        
        $discordVariant = "stable"; $setupUrl = $DISCORD_SETUP_URL
        if ($clientName -match "Canary") { $discordVariant = "canary"; $setupUrl = "https://discord.com/api/downloads/distributions/app/installers/latest?channel=canary&platform=win&arch=x64" }
        elseif ($clientName -match "PTB") { $discordVariant = "ptb"; $setupUrl = "https://discord.com/api/downloads/distributions/app/installers/latest?channel=ptb&platform=win&arch=x64" }
        elseif ($clientName -match "Development") { $discordVariant = "development"; $setupUrl = "https://discord.com/api/downloads/distributions/app/installers/latest?channel=development&platform=win&arch=x64" }
        
        Add-Status $StatusBox $Form "" "White"
        Add-Status $StatusBox $Form "=== DISCORD REINSTALL ($discordVariant) ===" "Magenta"
        Add-Status $StatusBox $Form "Your Discord installation is missing the modules folder." "Yellow"
        Add-Status $StatusBox $Form "This usually means Discord is corrupted or very outdated." "Yellow"
        
        if (-not $SkipConfirmation) {
            $confirmResult = [System.Windows.Forms.MessageBox]::Show($Form, "Your Discord installation appears to be corrupted or outdated (missing modules folder).`n`nWould you like to automatically reinstall Discord?`n`nThis will:`n1. Close Discord completely`n2. Delete the corrupted app folder`n3. Download and run the latest Discord installer`n4. Apply the stereo fix after installation`n`nYour Discord settings and login will be preserved.", "Reinstall Discord?", "YesNo", "Question")
            if ($confirmResult -ne "Yes") { Add-Status $StatusBox $Form "Reinstall cancelled by user" "Yellow"; return $false }
        }
        
        Add-Status $StatusBox $Form "Step 1/4: Closing all Discord processes..." "Blue"
        $allProcs = @("Discord","DiscordCanary","DiscordPTB","DiscordDevelopment","Lightcord","BetterVencord","Equicord","Vencord","Update")
        $stopResult = Stop-DiscordProcesses $allProcs
        if (-not $stopResult) {
            Start-Process "taskkill" -ArgumentList "/F","/IM","Discord*.exe" -WindowStyle Hidden -Wait -ErrorAction SilentlyContinue
            Start-Process "taskkill" -ArgumentList "/F","/IM","Update.exe" -WindowStyle Hidden -Wait -ErrorAction SilentlyContinue
            Start-Sleep -Seconds 2
        }
        Add-Status $StatusBox $Form "[OK] Discord processes terminated" "LimeGreen"
        
        Add-Status $StatusBox $Form "Step 2/4: Removing corrupted Discord files..." "Blue"
        $appFolders = Get-ChildItem $ClientPath -Filter "app-*" -Directory -ErrorAction SilentlyContinue
        $deletedCount = 0
        foreach ($folder in $appFolders) {
            try { Add-Status $StatusBox $Form "  Deleting: $($folder.Name)" "Cyan"; Remove-Item $folder.FullName -Recurse -Force -ErrorAction Stop; $deletedCount++ }
            catch { Add-Status $StatusBox $Form "  [!] Could not delete $($folder.Name): $($_.Exception.Message)" "Orange" }
        }
        $updateExe = Join-Path $ClientPath "Update.exe"
        if (Test-Path $updateExe) { try { Remove-Item $updateExe -Force -ErrorAction Stop; Add-Status $StatusBox $Form "  Deleted: Update.exe" "Cyan" } catch { Add-Status $StatusBox $Form "  [!] Could not delete Update.exe" "Orange" } }
        Add-Status $StatusBox $Form "[OK] Removed $deletedCount app folder(s)" "LimeGreen"
        
        Add-Status $StatusBox $Form "Step 3/4: Downloading Discord installer..." "Blue"
        $installerPath = Join-Path $env:TEMP "DiscordSetup_$(Get-Random).exe"
        try {
            Add-Status $StatusBox $Form "  URL: $setupUrl" "Cyan"
            Invoke-WebRequest -Uri $setupUrl -OutFile $installerPath -UseBasicParsing -TimeoutSec 120
            if (-not (Test-Path $installerPath)) { throw "Installer download failed - file not created" }
            $installerSize = (Get-Item $installerPath).Length / 1MB
            if ($installerSize -lt 1) { throw "Installer file is too small ($([math]::Round($installerSize, 2)) MB) - download may have failed" }
            Add-Status $StatusBox $Form "[OK] Downloaded installer ($([math]::Round($installerSize, 1)) MB)" "LimeGreen"
        } catch {
            Add-Status $StatusBox $Form "[X] Failed to download Discord installer: $($_.Exception.Message)" "Red"
            Add-Status $StatusBox $Form "    Please download Discord manually from https://discord.com/download" "Yellow"
            return $false
        }
        
        Add-Status $StatusBox $Form "Step 4/4: Running Discord installer..." "Blue"
        Add-Status $StatusBox $Form "  Please wait for Discord to install and start..." "Yellow"
        Add-Status $StatusBox $Form "  (This may take 1-2 minutes)" "Yellow"
        try { Start-Process $installerPath -Wait; Add-Status $StatusBox $Form "[OK] Discord installer completed" "LimeGreen" }
        catch { Add-Status $StatusBox $Form "[!] Installer may have encountered an issue: $($_.Exception.Message)" "Orange" }
        Remove-Item $installerPath -Force -ErrorAction SilentlyContinue
        
        Add-Status $StatusBox $Form "" "White"
        Add-Status $StatusBox $Form "Waiting for Discord to initialize..." "Blue"
        Add-Status $StatusBox $Form "  Discord needs to download voice modules (this may take 30-60 seconds)" "Cyan"
        
        $maxWaitSeconds = 90; $waitedSeconds = 0; $voiceModuleFound = $false
        while ($waitedSeconds -lt $maxWaitSeconds) {
            Start-Sleep -Seconds 5; $waitedSeconds += 5
            $newDiag = Find-DiscordAppPath $ClientPath -ReturnDiagnostics
            if ($newDiag.VoiceModuleExists) { $voiceModuleFound = $true; Add-Status $StatusBox $Form "[OK] Voice module detected!" "LimeGreen"; break }
            $progressDots = "." * (($waitedSeconds / 5) % 4 + 1)
            Add-Status $StatusBox $Form "  Waiting for modules$progressDots ($waitedSeconds/$maxWaitSeconds sec)" "Cyan"
        }
        
        if (-not $voiceModuleFound) {
            Add-Status $StatusBox $Form "[!] Voice module not detected after waiting" "Orange"
            Add-Status $StatusBox $Form "    Try joining a voice channel in Discord, then click 'Fix All'" "Yellow"
            return $false
        }
        
        Add-Status $StatusBox $Form "" "White"
        Add-Status $StatusBox $Form "[OK] Discord reinstallation completed successfully!" "LimeGreen"
        return $true
    } catch { Add-Status $StatusBox $Form "[X] Reinstall failed: $($_.Exception.Message)" "Red"; return $false }
}

function Start-DiscordClient { param([string]$ExePath)
    if (Test-Path $ExePath) { Start-Process "cmd.exe" -ArgumentList "/c","start",'""',"`"$ExePath`"" -WindowStyle Hidden; return $true }
    return $false
}

function Get-PathFromProcess { param([string]$ProcessName)
    try { $p = Get-Process -Name $ProcessName -ErrorAction SilentlyContinue | Select-Object -First 1; if ($p) { return (Split-Path (Split-Path $p.MainModule.FileName -Parent) -Parent) } } catch {}
    return $null
}

function Get-PathFromShortcuts { param([string]$ShortcutName)
    if (-not $ShortcutName) { return $null }
    $sm = "$env:APPDATA\Microsoft\Windows\Start Menu\Programs"
    if (!(Test-Path $sm)) { return $null }
    $scs = Get-ChildItem $sm -Filter "$ShortcutName.lnk" -Recurse -ErrorAction SilentlyContinue
    if (-not $scs) { return $null }
    $ws = New-Object -ComObject WScript.Shell
    foreach ($lf in $scs) { try { $sc = $ws.CreateShortcut($lf.FullName); if (Test-Path $sc.TargetPath) { return (Split-Path $sc.TargetPath -Parent) } } catch { } }
    return $null
}

function Get-RealClientPath { param($ClientObj)
    $p = $ClientObj.Path
    if (Test-Path $p) { return $p }
    if ($ClientObj.FallbackPath -and (Test-Path $ClientObj.FallbackPath)) { return $ClientObj.FallbackPath }
    foreach ($pr in $ClientObj.Processes) { if ($pr -eq "Update") { continue }; $pp = Get-PathFromProcess $pr; if ($pp -and (Test-Path $pp)) { return $pp } }
    if ($ClientObj.Shortcut) { $sp = Get-PathFromShortcuts $ClientObj.Shortcut; if ($sp -and (Test-Path $sp)) { return $sp } }
    return $null
}

function Get-InstalledClients {
    $inst = [System.Collections.ArrayList]@()
    $foundPaths = [System.Collections.Generic.HashSet[string]]@()
    foreach ($k in $DiscordClients.Keys) {
        $c = $DiscordClients[$k]; $fp = $null
        if (Test-Path $c.Path) { $fp = $c.Path }
        elseif ($c.FallbackPath -and (Test-Path $c.FallbackPath)) { $fp = $c.FallbackPath }
        else { foreach ($pn in $c.Processes) { if ($pn -eq "Update") { continue }; $dp = Get-PathFromProcess $pn; if ($dp -and (Test-Path $dp)) { $fp = $dp; break } } }
        if (-not $fp -and $c.Shortcut) { $sp = Get-PathFromShortcuts $c.Shortcut; if ($sp -and (Test-Path $sp)) { $fp = $sp } }
        if ($fp) { 
            try { $fp = (Get-Item $fp).FullName } catch {}
            if ($foundPaths.Contains($fp)) { continue }
            $ap = Find-DiscordAppPath $fp
            if ($ap) { [void]$inst.Add(@{Index=$k; Name=$c.Name; Path=$fp; AppPath=$ap; Client=$c}); [void]$foundPaths.Add($fp) } 
        }
    }
    return $inst
}

# 9. Download Logic
function Download-VoiceBackupFiles { param([string]$DestinationPath, [System.Windows.Forms.RichTextBox]$StatusBox, [System.Windows.Forms.Form]$Form)
    try {
        EnsureDir $DestinationPath
        Add-Status $StatusBox $Form "  Fetching file list from GitHub..." "Cyan"
        try { $r = Invoke-RestMethod -Uri $VOICE_BACKUP_API -UseBasicParsing -TimeoutSec 30 }
        catch { if ($_.Exception.Response.StatusCode -eq [System.Net.HttpStatusCode]::Forbidden) { throw "GitHub API Rate Limit exceeded. Please try again later." }; throw $_ }
        $r = @($r)
        if ($r.Count -eq 0) { throw "GitHub repository response is empty." }
        $fc = 0; $failedFiles = @()
        foreach ($f in $r) {
            if ($f.type -eq "file") {
                $fp = Join-Path $DestinationPath $f.name
                Add-Status $StatusBox $Form "  Downloading: $($f.name)" "Cyan"
                try {
                    Invoke-WebRequest -Uri $f.download_url -OutFile $fp -UseBasicParsing -TimeoutSec 30 | Out-Null
                    if (-not (Test-Path $fp)) { throw "File was not created" }
                    $fileInfo = Get-Item $fp
                    if ($fileInfo.Length -eq 0) { throw "Downloaded file is empty" }
                    $ext = [System.IO.Path]::GetExtension($f.name).ToLower()
                    if ($ext -eq ".node" -or $ext -eq ".dll") { if ($fileInfo.Length -lt 1024) { Add-Status $StatusBox $Form "  [!] Warning: $($f.name) seems too small ($($fileInfo.Length) bytes)" "Orange" } }
                    $fc++
                } catch { Add-Status $StatusBox $Form "  [!] Failed to download $($f.name): $($_.Exception.Message)" "Orange"; $failedFiles += $f.name }
            }
        }
        if ($fc -eq 0) { throw "No valid files were downloaded." }
        if ($failedFiles.Count -gt 0) { Add-Status $StatusBox $Form "  [!] Warning: $($failedFiles.Count) file(s) failed to download" "Orange" }
        Add-Status $StatusBox $Form "  Downloaded $fc voice backup files" "Cyan"
        return $true
    } catch { Add-Status $StatusBox $Form "  [X] Failed to download files: $($_.Exception.Message)" "Red"; return $false }
}

# 10. EQ APO Fix
function Apply-EqApoFix {
    param(
        [string]$RoamingPath,
        [string]$ClientName,
        [System.Windows.Forms.RichTextBox]$StatusBox,
        [System.Windows.Forms.Form]$Form,
        [bool]$SkipConfirmation = $false
    )
    try {
        Add-Status $StatusBox $Form "" "White"
        Add-Status $StatusBox $Form "=== EQ APO FIX: $ClientName ===" "Blue"
        
        if (-not (Test-Path $RoamingPath)) {
            Add-Status $StatusBox $Form "[X] Discord roaming folder not found: $RoamingPath" "Red"
            Add-Status $StatusBox $Form "    Please ensure Discord has been run at least once." "Yellow"
            return $false
        }
        
        $targetSettingsPath = Join-Path $RoamingPath "settings.json"
        
        if (-not $SkipConfirmation) {
            $confirmResult = [System.Windows.Forms.MessageBox]::Show($Form, "Replace Discord settings.json to fix EQ APO for $($ClientName)?", "Confirm EQ APO Fix", "YesNo", "Question")
            if ($confirmResult -ne "Yes") { Add-Status $StatusBox $Form "EQ APO fix cancelled by user" "Yellow"; return $false }
        }
        
        Add-Status $StatusBox $Form "Applying EQ APO fix to $ClientName..." "Blue"
        
        if (Test-Path $targetSettingsPath) {
            EnsureDir $SETTINGS_BACKUP_ROOT
            $sanitizedName = $ClientName -replace '\s+','_' -replace '\[|\]','' -replace '-','_'
            $backupTimestamp = Get-Date -Format "yyyy-MM-dd_HHmmss"
            $backupPath = Join-Path $SETTINGS_BACKUP_ROOT "settings_${sanitizedName}_$backupTimestamp.json"
            Add-Status $StatusBox $Form "  Backing up existing settings.json..." "Cyan"
            try { Copy-Item $targetSettingsPath $backupPath -Force; Add-Status $StatusBox $Form "  [OK] Backup created: settings_${sanitizedName}_$backupTimestamp.json" "LimeGreen" }
            catch { Add-Status $StatusBox $Form "  [!] Warning: Could not create backup: $($_.Exception.Message)" "Orange" }
        } else { Add-Status $StatusBox $Form "  No existing settings.json found (will create new)" "Yellow" }
        
        Add-Status $StatusBox $Form "  Downloading settings.json from GitHub..." "Cyan"
        $tempSettingsPath = Join-Path $env:TEMP "discord_settings_$(Get-Random).json"
        try { Invoke-WebRequest -Uri $SETTINGS_JSON_URL -OutFile $tempSettingsPath -UseBasicParsing -TimeoutSec 30 | Out-Null }
        catch { if ($_.Exception.Response.StatusCode -eq [System.Net.HttpStatusCode]::NotFound) { Add-Status $StatusBox $Form "  [X] settings.json not found in repository" "Red"; return $false }; throw $_ }
        
        Add-Status $StatusBox $Form "  Verifying downloaded file..." "Cyan"
        try { $jsonContent = Get-Content $tempSettingsPath -Raw | ConvertFrom-Json; if ($null -eq $jsonContent) { throw "Downloaded file is empty or invalid" }; Add-Status $StatusBox $Form "  [OK] File verified as valid JSON" "LimeGreen" }
        catch { Add-Status $StatusBox $Form "  [X] Downloaded file is not valid JSON: $($_.Exception.Message)" "Red"; Remove-Item $tempSettingsPath -Force -ErrorAction SilentlyContinue; return $false }
        
        if (Test-Path $targetSettingsPath) {
            Add-Status $StatusBox $Form "  Removing old settings.json..." "Cyan"
            try { Remove-Item $targetSettingsPath -Force }
            catch { Add-Status $StatusBox $Form "  [X] Could not remove old settings.json: $($_.Exception.Message)" "Red"; Add-Status $StatusBox $Form "    Make sure Discord is completely closed." "Yellow"; Remove-Item $tempSettingsPath -Force -ErrorAction SilentlyContinue; return $false }
        }
        
        Add-Status $StatusBox $Form "  Installing new settings.json..." "Cyan"
        try { Copy-Item $tempSettingsPath $targetSettingsPath -Force; Add-Status $StatusBox $Form "[OK] EQ APO fix applied successfully for $ClientName!" "LimeGreen" }
        catch { Add-Status $StatusBox $Form "  [X] Could not install new settings.json: $($_.Exception.Message)" "Red"; Remove-Item $tempSettingsPath -Force -ErrorAction SilentlyContinue; return $false }
        
        Remove-Item $tempSettingsPath -Force -ErrorAction SilentlyContinue
        Add-Status $StatusBox $Form "  Settings replaced at: $targetSettingsPath" "Cyan"
        return $true
    } catch { Add-Status $StatusBox $Form "[X] EQ APO fix failed: $($_.Exception.Message)" "Red"; return $false }
}

function Apply-EqApoFixAll {
    param(
        [System.Windows.Forms.RichTextBox]$StatusBox,
        [System.Windows.Forms.Form]$Form,
        [bool]$SkipConfirmation = $false
    )
    
    $processedPaths = [System.Collections.Generic.HashSet[string]]@()
    $successCount = 0
    $failCount = 0
    
    foreach ($k in $DiscordClients.Keys) {
        $client = $DiscordClients[$k]
        $roamingPath = $client.RoamingPath
        
        if ($processedPaths.Contains($roamingPath)) { continue }
        if (-not (Test-Path $roamingPath)) { continue }
        
        [void]$processedPaths.Add($roamingPath)
        
        $result = Apply-EqApoFix -RoamingPath $roamingPath -ClientName $client.Name.Trim() -StatusBox $StatusBox -Form $Form -SkipConfirmation $SkipConfirmation
        if ($result) { $successCount++ } else { $failCount++ }
    }
    
    return @{ Success = $successCount; Failed = $failCount; Total = $processedPaths.Count }
}

# 11. Backup/Restore Logic
function Initialize-BackupDirectory { EnsureDir $BACKUP_ROOT; EnsureDir $ORIGINAL_BACKUP_ROOT; EnsureDir (Split-Path $STATE_FILE -Parent) }
function Get-StateData { if (Test-Path $STATE_FILE) { try { return Get-Content $STATE_FILE -Raw | ConvertFrom-Json } catch { return $null } }; return $null }
function Save-StateData { param([hashtable]$State); $State | ConvertTo-Json -Depth 5 | Out-File $STATE_FILE -Force }
function Get-SanitizedClientKey { param([string]$ClientName); return $ClientName -replace '\s+','_' -replace '\[|\]','' -replace '-','_' }

function Test-OriginalBackupExists { param([string]$ClientName)
    Initialize-BackupDirectory
    $scn = Get-SanitizedClientKey $ClientName
    return (Test-Path (Join-Path $ORIGINAL_BACKUP_ROOT $scn))
}

function Get-OriginalBackup { param([string]$ClientName)
    Initialize-BackupDirectory
    $scn = Get-SanitizedClientKey $ClientName
    $originalPath = Join-Path $ORIGINAL_BACKUP_ROOT $scn
    if (Test-Path $originalPath) {
        $mp = Join-Path $originalPath "metadata.json"
        if (Test-Path $mp) {
            try {
                $m = Get-Content $mp -Raw | ConvertFrom-Json
                $backupDate = Parse-BackupDate $m.BackupDate
                if ($backupDate -eq [DateTime]::MinValue) { $backupDate = (Get-Item $originalPath).CreationTime }
                return @{ Path=$originalPath; Name="Original Discord Modules"; ClientName=$m.ClientName; AppVersion=$m.AppVersion; BackupDate=$backupDate; IsOriginal=$true
                          DisplayName="[ORIGINAL] $($m.ClientName) v$($m.AppVersion) - $($backupDate.ToString('MMM dd, yyyy HH:mm'))" }
            } catch { return $null }
        }
    }
    return $null
}

function Create-OriginalBackup {
    param([string]$VoiceFolderPath, [string]$ClientName, [string]$AppVersion, [System.Windows.Forms.RichTextBox]$StatusBox, [System.Windows.Forms.Form]$Form)
    try {
        Initialize-BackupDirectory
        $scn = Get-SanitizedClientKey $ClientName
        $bp = Join-Path $ORIGINAL_BACKUP_ROOT $scn
        if (Test-Path $bp) { Add-Status $StatusBox $Form "  Original backup already exists, skipping..." "Yellow"; return $bp }
        if (-not (Test-Path $VoiceFolderPath)) { Add-Status $StatusBox $Form "  [!] Source voice folder does not exist: $VoiceFolderPath" "Orange"; return $null }
        $sourceFiles = Get-ChildItem $VoiceFolderPath -File -Recurse -ErrorAction SilentlyContinue
        if (-not $sourceFiles -or $sourceFiles.Count -eq 0) { Add-Status $StatusBox $Form "  [!] Source voice folder is empty, cannot create backup" "Orange"; return $null }
        try { [void](New-Item $bp -ItemType Directory -Force) } catch { }
        $vbp = Join-Path $bp "voice_module"
        Add-Status $StatusBox $Form "  Creating ORIGINAL backup (will never be deleted)..." "Magenta"
        EnsureDir $vbp
        Copy-Item "$VoiceFolderPath\*" $vbp -Recurse -Force
        $validation = Test-BackupHasContent $bp
        if (-not $validation.Valid) { Add-Status $StatusBox $Form "  [!] Backup validation failed: $($validation.Reason)" "Orange"; Remove-Item $bp -Recurse -Force -ErrorAction SilentlyContinue; return $null }
        @{ ClientName=$ClientName; AppVersion=$AppVersion; BackupDate=(Get-Date).ToString("o", [System.Globalization.CultureInfo]::InvariantCulture); VoiceModulePath=$VoiceFolderPath; IsOriginal=$true; Description="Original Discord modules - preserved for reverting to mono audio"; FileCount=$validation.FileCount; TotalSize=$validation.TotalSize } | ConvertTo-Json | Out-File (Join-Path $bp "metadata.json") -Force
        Add-Status $StatusBox $Form "[OK] Original backup created: $scn ($($validation.FileCount) files, $([math]::Round($validation.TotalSize / 1KB, 1)) KB)" "Magenta"
        Add-Status $StatusBox $Form "     This backup will NEVER be deleted automatically" "Cyan"
        return $bp
    } catch { Add-Status $StatusBox $Form "[!] Original backup failed: $($_.Exception.Message)" "Orange"; return $null }
}

function Create-VoiceBackup { 
    param([string]$VoiceFolderPath, [string]$ClientName, [string]$AppVersion, [System.Windows.Forms.RichTextBox]$StatusBox, [System.Windows.Forms.Form]$Form)
    try {
        Initialize-BackupDirectory
        if (-not (Test-OriginalBackupExists $ClientName)) { Create-OriginalBackup $VoiceFolderPath $ClientName $AppVersion $StatusBox $Form | Out-Null }
        if (-not (Test-Path $VoiceFolderPath)) { Add-Status $StatusBox $Form "  [!] Source voice folder does not exist: $VoiceFolderPath" "Orange"; return $null }
        $sourceFiles = Get-ChildItem $VoiceFolderPath -File -Recurse -ErrorAction SilentlyContinue
        if (-not $sourceFiles -or $sourceFiles.Count -eq 0) { Add-Status $StatusBox $Form "  [!] Source voice folder is empty, cannot create backup" "Orange"; return $null }
        $ts = Get-Date -Format "yyyy-MM-dd_HHmmss"
        $scn = Get-SanitizedClientKey $ClientName
        $bn = "${scn}_${AppVersion}_${ts}"
        $bp = Join-Path $BACKUP_ROOT $bn
        try { [void](New-Item $bp -ItemType Directory -Force) } catch { }
        $vbp = Join-Path $bp "voice_module"
        Add-Status $StatusBox $Form "  Backing up voice module..." "Cyan"
        EnsureDir $vbp
        Copy-Item "$VoiceFolderPath\*" $vbp -Recurse -Force
        $validation = Test-BackupHasContent $bp
        if (-not $validation.Valid) { Add-Status $StatusBox $Form "  [!] Backup validation failed: $($validation.Reason)" "Orange"; Remove-Item $bp -Recurse -Force -ErrorAction SilentlyContinue; return $null }
        @{ ClientName=$ClientName; AppVersion=$AppVersion; BackupDate=(Get-Date).ToString("o", [System.Globalization.CultureInfo]::InvariantCulture); VoiceModulePath=$VoiceFolderPath; IsOriginal=$false; FileCount=$validation.FileCount; TotalSize=$validation.TotalSize } | ConvertTo-Json | Out-File (Join-Path $bp "metadata.json") -Force
        Add-Status $StatusBox $Form "[OK] Backup created: $bn ($($validation.FileCount) files)" "LimeGreen"
        return $bp
    } catch { Add-Status $StatusBox $Form "[!] Backup failed: $($_.Exception.Message)" "Orange"; return $null }
}

function Get-AvailableBackups {
    param([System.Windows.Forms.RichTextBox]$StatusBox = $null, [System.Windows.Forms.Form]$Form = $null)
    Initialize-BackupDirectory
    $bks = [System.Collections.ArrayList]@()
    $skippedBackups = [System.Collections.ArrayList]@()
    
    $originals = Get-ChildItem $ORIGINAL_BACKUP_ROOT -Directory -ErrorAction SilentlyContinue
    foreach ($f in $originals) {
        $mp = Join-Path $f.FullName "metadata.json"
        if (Test-Path $mp) {
            try {
                $m = Get-Content $mp -Raw -ErrorAction Stop | ConvertFrom-Json -ErrorAction Stop
                if (-not $m.ClientName -or -not $m.AppVersion) { [void]$skippedBackups.Add(@{ Path = $f.FullName; Reason = "Missing required metadata fields (ClientName or AppVersion)" }); continue }
                $validation = Test-BackupHasContent $f.FullName
                if (-not $validation.Valid) { [void]$skippedBackups.Add(@{ Path = $f.FullName; Reason = $validation.Reason }); continue }
                $backupDate = Parse-BackupDate $m.BackupDate
                if ($backupDate -eq [DateTime]::MinValue) { $backupDate = (Get-Item $f.FullName).CreationTime }
                [void]$bks.Add(@{ Path=$f.FullName; Name=$f.Name; ClientName=$m.ClientName; AppVersion=$m.AppVersion; BackupDate=$backupDate; IsOriginal=$true; DisplayName="[ORIGINAL] $($m.ClientName) v$($m.AppVersion) - $($backupDate.ToString('MMM dd, yyyy HH:mm'))"; FileCount = $validation.FileCount; TotalSize = $validation.TotalSize })
            } catch { [void]$skippedBackups.Add(@{ Path = $f.FullName; Reason = "Corrupted metadata.json: $($_.Exception.Message)" }); continue }
        } else { [void]$skippedBackups.Add(@{ Path = $f.FullName; Reason = "Missing metadata.json" }) }
    }
    
    $bfs = Get-ChildItem $BACKUP_ROOT -Directory -ErrorAction SilentlyContinue | Sort-Object Name -Descending
    foreach ($f in $bfs) {
        $mp = Join-Path $f.FullName "metadata.json"
        if (Test-Path $mp) {
            try {
                $m = Get-Content $mp -Raw -ErrorAction Stop | ConvertFrom-Json -ErrorAction Stop
                if (-not $m.ClientName -or -not $m.AppVersion) { [void]$skippedBackups.Add(@{ Path = $f.FullName; Reason = "Missing required metadata fields (ClientName or AppVersion)" }); continue }
                $validation = Test-BackupHasContent $f.FullName
                if (-not $validation.Valid) { [void]$skippedBackups.Add(@{ Path = $f.FullName; Reason = $validation.Reason }); continue }
                $backupDate = Parse-BackupDate $m.BackupDate
                if ($backupDate -eq [DateTime]::MinValue) { $backupDate = (Get-Item $f.FullName).CreationTime }
                [void]$bks.Add(@{ Path=$f.FullName; Name=$f.Name; ClientName=$m.ClientName; AppVersion=$m.AppVersion; BackupDate=$backupDate; IsOriginal=$false; DisplayName="$($m.ClientName) v$($m.AppVersion) - $($backupDate.ToString('MMM dd, yyyy HH:mm'))"; FileCount = $validation.FileCount; TotalSize = $validation.TotalSize })
            } catch { [void]$skippedBackups.Add(@{ Path = $f.FullName; Reason = "Corrupted metadata.json: $($_.Exception.Message)" }); continue }
        } else { [void]$skippedBackups.Add(@{ Path = $f.FullName; Reason = "Missing metadata.json" }) }
    }
    
    if ($StatusBox -and $skippedBackups.Count -gt 0) {
        Add-Status $StatusBox $Form "  [!] Skipped $($skippedBackups.Count) invalid backup(s):" "Orange"
        foreach ($skip in $skippedBackups) { Add-Status $StatusBox $Form "      - $(Split-Path $skip.Path -Leaf) : $($skip.Reason)" "Orange" }
    }
    if ($bks.Count -eq 0) { return @() }
    return ,$bks.ToArray()
}

function Restore-FromBackup {
    param([hashtable]$Backup, [string]$TargetVoicePath, [System.Windows.Forms.RichTextBox]$StatusBox, [System.Windows.Forms.Form]$Form)
    try {
        if (-not $Backup -or -not $Backup.Path) { Add-Status $StatusBox $Form "[X] Invalid backup: backup data is null or missing path" "Red"; return $false }
        if (-not (Test-Path $Backup.Path)) { Add-Status $StatusBox $Form "[X] Backup folder no longer exists: $($Backup.Path)" "Red"; Add-Status $StatusBox $Form "    The backup may have been deleted or moved." "Yellow"; return $false }
        $vbp = Join-Path $Backup.Path "voice_module"
        if (-not (Test-Path $vbp)) { Add-Status $StatusBox $Form "[X] Backup is corrupted: voice_module folder not found" "Red"; Add-Status $StatusBox $Form "    Path checked: $vbp" "Yellow"; return $false }
        $validation = Test-BackupHasContent $Backup.Path
        if (-not $validation.Valid) { Add-Status $StatusBox $Form "[X] Backup is invalid: $($validation.Reason)" "Red"; Add-Status $StatusBox $Form "    This backup cannot be used for restoration." "Yellow"; return $false }
        if ($Backup.IsOriginal) { Add-Status $StatusBox $Form "  Restoring ORIGINAL voice module (reverting to mono)..." "Magenta" }
        else { Add-Status $StatusBox $Form "  Restoring voice module ($($validation.FileCount) files, $([math]::Round($validation.TotalSize / 1KB, 1)) KB)..." "Cyan" }
        if (Test-Path $TargetVoicePath) { Remove-Item "$TargetVoicePath\*" -Recurse -Force -ErrorAction SilentlyContinue } else { EnsureDir $TargetVoicePath }
        Copy-Item "$vbp\*" $TargetVoicePath -Recurse -Force
        $restoredFiles = Get-ChildItem $TargetVoicePath -File -Recurse -ErrorAction SilentlyContinue
        if (-not $restoredFiles -or $restoredFiles.Count -eq 0) { Add-Status $StatusBox $Form "[X] Restore failed: no files were copied to target" "Red"; return $false }
        Add-Status $StatusBox $Form "  [OK] Restored $($restoredFiles.Count) files to target" "Cyan"
        return $true
    } catch { Add-Status $StatusBox $Form "[X] Restore failed: $($_.Exception.Message)" "Red"; return $false }
}

function Remove-OldBackups {
    $bfs = Get-ChildItem $BACKUP_ROOT -Directory -ErrorAction SilentlyContinue
    $byClient = @{}
    foreach ($f in $bfs) {
        $mp = Join-Path $f.FullName "metadata.json"
        if (Test-Path $mp) {
            try {
                $m = Get-Content $mp -Raw | ConvertFrom-Json
                $clientKey = $m.ClientName
                if (-not $byClient.ContainsKey($clientKey)) { $byClient[$clientKey] = [System.Collections.ArrayList]@() }
                $backupDate = Parse-BackupDate $m.BackupDate
                if ($backupDate -eq [DateTime]::MinValue) { $backupDate = (Get-Item $f.FullName).CreationTime }
                [void]$byClient[$clientKey].Add(@{ Path = $f.FullName; BackupDate = $backupDate })
            } catch { continue }
        }
    }
    foreach ($clientKey in $byClient.Keys) {
        $backups = $byClient[$clientKey] | Sort-Object { $_.BackupDate } -Descending
        $backups | Select-Object -Skip 1 | ForEach-Object { Remove-Item $_.Path -Recurse -Force -ErrorAction SilentlyContinue }
    }
}

function Check-DiscordUpdated { param([string]$ClientPath, [string]$ClientName)
    $st = Get-StateData; if (-not $st) { return $null }
    $ck = $ClientName -replace '\s+','_' -replace '\[|\]',''
    $ap = Find-DiscordAppPath $ClientPath; if (-not $ap) { return $null }
    $cv = Get-DiscordAppVersion $ap
    if ($st.$ck) {
        $lv = $st.$ck.LastFixedVersion; $lfd = $st.$ck.LastFixDate
        if ($lv -and $cv -ne $lv) { return @{Updated=$true; OldVersion=$lv; NewVersion=$cv; LastFixDate=$lfd; CurrentVersion=$cv} }
        return @{Updated=$false; CurrentVersion=$cv; LastFixDate=$lfd}
    }
    return @{Updated=$false; CurrentVersion=$cv; LastFixDate=$null}
}

function Save-FixState { param([string]$ClientName, [string]$Version)
    Initialize-BackupDirectory
    $st = Get-StateData; if (-not $st) { $st = @{} }
    if ($st -is [PSCustomObject]) { $ns = @{}; $st.PSObject.Properties | ForEach-Object { $ns[$_.Name] = $_.Value }; $st = $ns }
    $ck = $ClientName -replace '\s+','_' -replace '\[|\]',''
    $st[$ck] = @{LastFixedVersion=$Version; LastFixDate=(Get-Date).ToString("o", [System.Globalization.CultureInfo]::InvariantCulture)}
    Save-StateData $st
}

function Save-ScriptToAppData { param([System.Windows.Forms.RichTextBox]$StatusBox, [System.Windows.Forms.Form]$Form)
    try {
        EnsureDir (Split-Path $SAVED_SCRIPT_PATH -Parent)
        if (-not [string]::IsNullOrEmpty($PSCommandPath) -and (Test-Path $PSCommandPath)) { Copy-Item $PSCommandPath $SAVED_SCRIPT_PATH -Force; Add-Status $StatusBox $Form "[OK] Script saved to: $SAVED_SCRIPT_PATH" "LimeGreen"; return $SAVED_SCRIPT_PATH }
        Add-Status $StatusBox $Form "Downloading script from GitHub..." "Cyan"
        Invoke-WebRequest -Uri $UPDATE_URL -OutFile $SAVED_SCRIPT_PATH -UseBasicParsing -TimeoutSec 30 | Out-Null
        Add-Status $StatusBox $Form "[OK] Script downloaded and saved" "LimeGreen"; return $SAVED_SCRIPT_PATH
    } catch { Add-Status $StatusBox $Form "[X] Failed to save script: $($_.Exception.Message)" "Red"; return $null }
}

function Create-StartupShortcut { param([string]$ScriptPath, [bool]$RunSilent=$false)
    $sf = "$env:APPDATA\Microsoft\Windows\Start Menu\Programs\Startup"
    $sp = Join-Path $sf "DiscordVoiceFixer.lnk"
    $ws = New-Object -ComObject WScript.Shell; $sc = $ws.CreateShortcut($sp)
    $sc.TargetPath = "powershell.exe"
    $ar = "-ExecutionPolicy Bypass -WindowStyle Hidden -File `"$ScriptPath`""
    if ($RunSilent) { $ar += " -Silent" }
    $sc.Arguments = $ar; $sc.WorkingDirectory = (Split-Path $ScriptPath -Parent); $sc.WindowStyle = 7; $sc.Save()
    return $true
}

function Remove-StartupShortcut {
    $sp = "$env:APPDATA\Microsoft\Windows\Start Menu\Programs\Startup\DiscordVoiceFixer.lnk"
    if (Test-Path $sp) { Remove-Item $sp -Force -ErrorAction SilentlyContinue }
}

function Apply-ScriptUpdate { param([string]$UpdatedScriptPath, [string]$CurrentScriptPath)
    $bf = Join-Path $env:TEMP "StereoInstaller_Update.bat"
    $bc = "@echo off`ntimeout /t 2 /nobreak >nul`ncopy /Y `"$UpdatedScriptPath`" `"$CurrentScriptPath`" >nul`ntimeout /t 1 /nobreak >nul`npowershell.exe -ExecutionPolicy Bypass -File `"$CurrentScriptPath`"`ndel `"$UpdatedScriptPath`" >nul 2>&1`n(goto) 2>nul & del `"%~f0`""
    $bc | Out-File $bf -Encoding ASCII -Force
    Start-Process "cmd.exe" -ArgumentList "/c","`"$bf`"" -WindowStyle Hidden
}

# 12. Silent / Check-Only Mode
if ($Silent -or $CheckOnly) {
    $ic = Get-InstalledClients
    $corruptedClients = @()
    foreach ($k in $DiscordClients.Keys) {
        $c = $DiscordClients[$k]
        if (Test-Path $c.Path) {
            $diag = Find-DiscordAppPath $c.Path -ReturnDiagnostics
            if ($diag.Error -eq "NoModulesFolder" -and $c.Name -match "\[Official\]") {
                $corruptedClients += @{ Key = $k; Client = $c; Path = $c.Path; Diag = $diag }
            }
        }
    }
    
    if ($corruptedClients.Count -gt 0 -and $ic.Count -eq 0) {
        Write-Host "Detected $($corruptedClients.Count) corrupted Discord installation(s)"
        foreach ($corrupt in $corruptedClients) {
            Write-Host "Attempting to repair: $($corrupt.Client.Name.Trim())"
            $reinstallSuccess = $false
            try {
                $allProcs = @("Discord","DiscordCanary","DiscordPTB","DiscordDevelopment","Update")
                Stop-DiscordProcesses $allProcs | Out-Null
                Start-Process "taskkill" -ArgumentList "/F","/IM","Discord*.exe" -WindowStyle Hidden -Wait -ErrorAction SilentlyContinue
                Start-Sleep -Seconds 2
                $appFolders = Get-ChildItem $corrupt.Path -Filter "app-*" -Directory -ErrorAction SilentlyContinue
                foreach ($folder in $appFolders) { Remove-Item $folder.FullName -Recurse -Force -ErrorAction SilentlyContinue }
                $updateExe = Join-Path $corrupt.Path "Update.exe"
                if (Test-Path $updateExe) { Remove-Item $updateExe -Force -ErrorAction SilentlyContinue }
                $setupUrl = $DISCORD_SETUP_URL
                if ($corrupt.Client.Name -match "Canary") { $setupUrl = "https://discord.com/api/downloads/distributions/app/installers/latest?channel=canary&platform=win&arch=x64" }
                elseif ($corrupt.Client.Name -match "PTB") { $setupUrl = "https://discord.com/api/downloads/distributions/app/installers/latest?channel=ptb&platform=win&arch=x64" }
                elseif ($corrupt.Client.Name -match "Development") { $setupUrl = "https://discord.com/api/downloads/distributions/app/installers/latest?channel=development&platform=win&arch=x64" }
                $installerPath = Join-Path $env:TEMP "DiscordSetup_$(Get-Random).exe"
                Write-Host "  Downloading Discord installer..."
                Invoke-WebRequest -Uri $setupUrl -OutFile $installerPath -UseBasicParsing -TimeoutSec 120
                Write-Host "  Running installer..."
                Start-Process $installerPath -Wait
                Remove-Item $installerPath -Force -ErrorAction SilentlyContinue
                Write-Host "  Waiting for Discord to initialize..."
                $waitedSeconds = 0
                while ($waitedSeconds -lt 90) {
                    Start-Sleep -Seconds 5; $waitedSeconds += 5
                    $newDiag = Find-DiscordAppPath $corrupt.Path -ReturnDiagnostics
                    if ($newDiag.VoiceModuleExists) { Write-Host "  [OK] Discord repaired successfully"; $reinstallSuccess = $true; break }
                }
                if (-not $reinstallSuccess) { Write-Host "  [!] Voice module not detected after reinstall" }
            } catch { Write-Host "  [FAIL] Repair failed: $($_.Exception.Message)" }
        }
        $ic = Get-InstalledClients
    }
    
    if ($ic.Count -eq 0) { 
        $noVoiceClients = @(); $noModulesClients = @()
        foreach ($k in $DiscordClients.Keys) {
            $c = $DiscordClients[$k]
            if (Test-Path $c.Path) {
                $diag = Find-DiscordAppPath $c.Path -ReturnDiagnostics
                if ($diag.Error -eq "NoVoiceModule") { $noVoiceClients += $c.Name.Trim() }
                elseif ($diag.Error -eq "NoModulesFolder") { $noModulesClients += $c.Name.Trim() }
            }
        }
        if ($noVoiceClients.Count -gt 0) {
            Write-Host "[!] Discord found but voice module not downloaded yet."
            Write-Host "    The voice module downloads when you first join a voice channel."
            Write-Host ""; Write-Host "    To fix this:"; Write-Host "    1) Open Discord"; Write-Host "    2) Join any voice channel"
            Write-Host "    3) Wait 30 seconds for modules to download"; Write-Host "    4) Run this script again"
            Write-Host ""; Write-Host "    Affected clients: $($noVoiceClients -join ', ')"; exit 1
        }
        if ($noModulesClients.Count -gt 0) {
            Write-Host "[!] Discord installation is corrupted (missing modules folder)."
            Write-Host "    Affected clients: $($noModulesClients -join ', ')"; Write-Host ""
            Write-Host "    Please run the script in GUI mode to auto-repair, or reinstall Discord manually."; exit 1
        }
        Write-Host "No Discord clients found."; exit 1 
    }
    
    if ($CheckOnly) {
        Write-Host "Checking Discord versions..."; $nf = $false
        foreach ($ci in $ic) {
            $uc = Check-DiscordUpdated $ci.Path $ci.Name
            if ($uc -and $uc.Updated) { Write-Host "[UPDATE] $($ci.Name.Trim()): v$($uc.OldVersion) -> v$($uc.NewVersion)"; $nf = $true }
            elseif ($uc -and $uc.LastFixDate) { $lf = [DateTime]::Parse($uc.LastFixDate); Write-Host "[OK] $($ci.Name.Trim()): v$($uc.CurrentVersion) (fixed: $($lf.ToString('MMM dd')))" }
            else { Write-Host "[NEW] $($ci.Name.Trim()): Never fixed"; $nf = $true }
        }
        if ($nf) { exit 1 }; exit 0
    }
    
    if ($FixClient) { $ic = @($ic | Where-Object { $_.Name -like "*$FixClient*" }); if ($ic.Count -eq 0) { Write-Host "Client '$FixClient' not found."; exit 1 } }
    
    $up = @{}; $uc = [System.Collections.ArrayList]@()
    foreach ($c in $ic) { if (-not $up.ContainsKey($c.AppPath)) { $up[$c.AppPath] = $true; [void]$uc.Add($c) } }
    
    Write-Host "Found $($uc.Count) client(s)"
    $td = Join-Path $env:TEMP "StereoInstaller_$(Get-Random)"; EnsureDir $td
    
    try {
        $vbp = Join-Path $td "VoiceBackup"; 
        if (-not (Download-VoiceBackupFiles $vbp $null $null)) { throw "Download Failed" }
        $allProcs = @("Discord","DiscordCanary","DiscordPTB","DiscordDevelopment","Lightcord","BetterVencord","Equicord","Vencord","Update")
        $stopResult = Stop-DiscordProcesses $allProcs
        if (-not $stopResult) { Write-Host "[!] Warning: Some Discord processes may still be running"; Start-Sleep -Seconds 2 }
        Start-Sleep -Seconds 1
        $set = Load-Settings; $fxc = 0
        foreach ($ci in $uc) {
            $cl = $ci.Client; $ap = $ci.AppPath; $av = Get-DiscordAppVersion $ap
            Write-Host "Fixing $($cl.Name.Trim()) v$av..."
            try {
                $vm = Get-ChildItem "$ap\modules" -Filter "discord_voice*" -Directory | Select-Object -First 1
                if (-not $vm) { throw "No voice module found" }
                $tvf = if (Test-Path "$($vm.FullName)\discord_voice") { "$($vm.FullName)\discord_voice" } else { $vm.FullName }
                Create-VoiceBackup $tvf $cl.Name $av $null $null | Out-Null
                if (Test-Path $tvf) { Remove-Item "$tvf\*" -Recurse -Force -ErrorAction SilentlyContinue } else { EnsureDir $tvf }
                Copy-Item "$vbp\*" $tvf -Recurse -Force
                Save-FixState $cl.Name $av; Write-Host "  [OK] Fixed successfully"; $fxc++
            } catch { Write-Host "  [FAIL] $($_.Exception.Message)" }
        }
        Remove-OldBackups
        if ($set.FixEqApo) {
            Write-Host "Applying EQ APO fix to all clients..."
            $processedPaths = [System.Collections.Generic.HashSet[string]]@()
            foreach ($ci in $uc) {
                $roamingPath = $ci.Client.RoamingPath
                if ($processedPaths.Contains($roamingPath)) { continue }
                if (-not (Test-Path $roamingPath)) { continue }
                [void]$processedPaths.Add($roamingPath)
                $result = Apply-EqApoFix -RoamingPath $roamingPath -ClientName $ci.Client.Name.Trim() -StatusBox $null -Form $null -SkipConfirmation $true
                if ($result) { Write-Host "  [OK] EQ APO fix applied to $($ci.Client.Name.Trim())" } else { Write-Host "  [FAIL] EQ APO fix failed for $($ci.Client.Name.Trim())" }
            }
        }
        if ($set.CreateShortcut) { $spt = $SAVED_SCRIPT_PATH; if (!(Test-Path $spt)) { $spt = Save-ScriptToAppData $null $null }; if ($spt) { Create-StartupShortcut $spt $set.SilentStartup; Write-Host "  [OK] Startup shortcut created/updated" } }
        if ($set.AutoStartDiscord -and $fxc -gt 0) { $pc = $uc[0]; $de = Join-Path $pc.AppPath $pc.Client.Exe; Start-DiscordClient $de; Write-Host "Discord started." }
        Write-Host "Fixed $fxc of $($uc.Count) client(s)"; exit 0
    } finally { if (Test-Path $td) { Remove-Item $td -Recurse -Force -ErrorAction SilentlyContinue } }
}

# 13. GUI Mode
$settings = Load-Settings

$form = New-Object System.Windows.Forms.Form
$form.Text = "Stereo Installer"; $form.Size = New-Object System.Drawing.Size(520,700)
$form.StartPosition = "CenterScreen"; $form.FormBorderStyle = "FixedDialog"; $form.MaximizeBox = $false
$form.BackColor = $Theme.Background; $form.TopMost = $true

$titleLabel = New-StyledLabel 20 15 460 35 "Stereo Installer" $Fonts.Title $Theme.TextPrimary "MiddleCenter"
$form.Controls.Add($titleLabel)
$creditsLabel = New-StyledLabel 20 52 460 28 "Made by`r`nOracle | Shaun | Hallow | Ascend | Sentry | Sikimzo | Cypher" $Fonts.Small $Theme.TextSecondary "MiddleCenter"
$form.Controls.Add($creditsLabel)

$updateStatusLabel = New-StyledLabel 20 82 460 18 "" $Fonts.Small $Theme.Warning "MiddleCenter"; $form.Controls.Add($updateStatusLabel)
$discordRunningLabel = New-StyledLabel 20 100 460 18 "" $Fonts.Small $Theme.Warning "MiddleCenter"; $form.Controls.Add($discordRunningLabel)

$clientGroup = New-Object System.Windows.Forms.GroupBox
$clientGroup.Location = New-Object System.Drawing.Point(20,120); $clientGroup.Size = New-Object System.Drawing.Size(460,60)
$clientGroup.Text = "Discord Client"; $clientGroup.ForeColor = $Theme.TextPrimary
$clientGroup.BackColor = [System.Drawing.Color]::Transparent; $clientGroup.Font = $Fonts.Normal
$form.Controls.Add($clientGroup)

$clientCombo = New-Object System.Windows.Forms.ComboBox
$clientCombo.Location = New-Object System.Drawing.Point(20,25); $clientCombo.Size = New-Object System.Drawing.Size(420,28)
$clientCombo.DropDownStyle = "DropDownList"; $clientCombo.BackColor = $Theme.ControlBg; $clientCombo.ForeColor = $Theme.TextPrimary
$clientCombo.FlatStyle = "Flat"; $clientCombo.Font = New-Object System.Drawing.Font("Consolas",9)
foreach ($c in $DiscordClients.Values) { [void]$clientCombo.Items.Add($c.Name) }
$clientCombo.SelectedIndex = [Math]::Min($settings.SelectedClientIndex, $clientCombo.Items.Count - 1)
$clientGroup.Controls.Add($clientCombo)

$optionsGroup = New-Object System.Windows.Forms.GroupBox
$optionsGroup.Location = New-Object System.Drawing.Point(20,190); $optionsGroup.Size = New-Object System.Drawing.Size(460,185)
$optionsGroup.Text = "Options"; $optionsGroup.ForeColor = $Theme.TextPrimary
$optionsGroup.BackColor = [System.Drawing.Color]::Transparent; $optionsGroup.Font = $Fonts.Normal
$form.Controls.Add($optionsGroup)

$chkUpdate = New-StyledCheckBox 20 25 420 22 "Check for script updates before fixing" $settings.CheckForUpdates; $optionsGroup.Controls.Add($chkUpdate)
$chkAutoUpdate = New-StyledCheckBox 40 47 400 22 "Automatically download and apply updates" $settings.AutoApplyUpdates $Theme.TextPrimary
$chkAutoUpdate.Enabled = $chkUpdate.Checked; $chkAutoUpdate.Visible = $chkUpdate.Checked; $optionsGroup.Controls.Add($chkAutoUpdate)
$chkShortcut = New-StyledCheckBox 20 69 280 22 "Create startup shortcut" $settings.CreateShortcut; $optionsGroup.Controls.Add($chkShortcut)
$btnSaveScript = New-StyledButton 305 69 135 22 "Save Script" $Fonts.ButtonSmall $Theme.Secondary; $optionsGroup.Controls.Add($btnSaveScript)
$chkSilentStartup = New-StyledCheckBox 40 91 400 22 "Run silently on startup (no GUI, auto-fix all)" $settings.SilentStartup $Theme.TextPrimary
$chkSilentStartup.Enabled = $chkShortcut.Checked; $chkSilentStartup.Visible = $chkShortcut.Checked; $optionsGroup.Controls.Add($chkSilentStartup)
$chkAutoStart = New-StyledCheckBox 20 113 420 22 "Automatically start Discord after fixing" $settings.AutoStartDiscord; $optionsGroup.Controls.Add($chkAutoStart)
$chkFixEqApo = New-StyledCheckBox 20 135 420 22 "Fix EQ APO not working (replaces settings.json)" $settings.FixEqApo $Theme.Warning; $optionsGroup.Controls.Add($chkFixEqApo)
$lblScriptStatus = New-StyledLabel 20 159 420 18 "" $Fonts.Small $Theme.TextSecondary "MiddleLeft"; $optionsGroup.Controls.Add($lblScriptStatus)

$statusBox = New-Object System.Windows.Forms.RichTextBox
$statusBox.Location = New-Object System.Drawing.Point(20,385); $statusBox.Size = New-Object System.Drawing.Size(460,145)
$statusBox.ReadOnly = $true; $statusBox.BackColor = $Theme.ControlBg; $statusBox.ForeColor = $Theme.TextPrimary
$statusBox.Font = $Fonts.Console; $statusBox.DetectUrls = $false; $statusBox.BorderStyle = "FixedSingle"
$form.Controls.Add($statusBox)

$progressBar = New-Object System.Windows.Forms.ProgressBar
$progressBar.Location = New-Object System.Drawing.Point(20,540); $progressBar.Size = New-Object System.Drawing.Size(460,22)
$progressBar.Style = "Continuous"; $form.Controls.Add($progressBar)

$btnStart = New-StyledButton 20 575 100 38 "Start Fix"; $form.Controls.Add($btnStart)
$btnFixAll = New-StyledButton 125 575 100 38 "Fix All" $Fonts.Button $Theme.Success; $form.Controls.Add($btnFixAll)
$btnRollback = New-StyledButton 230 575 70 38 "Rollback" $Fonts.ButtonSmall $Theme.Secondary; $form.Controls.Add($btnRollback)
$btnOpenBackups = New-StyledButton 305 575 70 38 "Backups" $Fonts.ButtonSmall $Theme.Secondary; $form.Controls.Add($btnOpenBackups)
$btnCheckUpdate = New-StyledButton 380 575 100 38 "Check" $Fonts.ButtonSmall $Theme.Warning; $form.Controls.Add($btnCheckUpdate)
$btnFixEqApo = New-StyledButton 20 620 220 32 "Apply EQ APO Fix Only" $Fonts.ButtonSmall $Theme.Warning; $form.Controls.Add($btnFixEqApo)

# 14. GUI Helper Functions
function Update-ScriptStatusLabel {
    if (Test-Path $SAVED_SCRIPT_PATH) { $lm = (Get-Item $SAVED_SCRIPT_PATH).LastWriteTime.ToString("MMM dd, HH:mm"); $lblScriptStatus.Text = "Script saved: $lm"; $lblScriptStatus.ForeColor = $Theme.TextSecondary }
    else { $lblScriptStatus.Text = "Script not saved locally (required for startup shortcut)"; $lblScriptStatus.ForeColor = $Theme.Warning }
}

function Update-DiscordRunningWarning {
    $dp = @("Discord","DiscordCanary","DiscordPTB","DiscordDevelopment","Lightcord")
    $r = Get-Process -Name $dp -ErrorAction SilentlyContinue
    if ($r) { $discordRunningLabel.Text = "[!] Discord is running - it will be closed when you apply the fix"; $discordRunningLabel.Visible = $true }
    else { $discordRunningLabel.Text = ""; $discordRunningLabel.Visible = $false }
}

function Save-CurrentSettings {
    $cs = [PSCustomObject]@{CheckForUpdates=$chkUpdate.Checked; AutoApplyUpdates=$chkAutoUpdate.Checked; CreateShortcut=$chkShortcut.Checked
        AutoStartDiscord=$chkAutoStart.Checked; SilentStartup=$chkSilentStartup.Checked; SelectedClientIndex=$clientCombo.SelectedIndex; FixEqApo=$chkFixEqApo.Checked}
    Save-Settings $cs
}

# 15. Event Handlers
$chkUpdate.Add_CheckedChanged({ $chkAutoUpdate.Enabled = $chkUpdate.Checked; $chkAutoUpdate.Visible = $chkUpdate.Checked; if (-not $chkUpdate.Checked) { $chkAutoUpdate.Checked = $false } })
$chkShortcut.Add_CheckedChanged({ $chkSilentStartup.Enabled = $chkShortcut.Checked; $chkSilentStartup.Visible = $chkShortcut.Checked; if (-not $chkShortcut.Checked) { $chkSilentStartup.Checked = $false } })
$btnSaveScript.Add_Click({ $statusBox.Clear(); $sp = Save-ScriptToAppData $statusBox $form; if ($sp) { Update-ScriptStatusLabel; [System.Windows.Forms.MessageBox]::Show($form,"Script saved to:`n$sp`n`nYou can now create a startup shortcut.","Script Saved","OK","Information") } })
$btnOpenBackups.Add_Click({ Initialize-BackupDirectory; Start-Process "explorer.exe" $APP_DATA_ROOT })

$btnFixEqApo.Add_Click({
    $btnFixEqApo.Enabled = $false; $statusBox.Clear(); $progressBar.Value = 0
    try {
        Update-Progress $progressBar $form 10
        $dp = @("Discord","DiscordCanary","DiscordPTB","DiscordDevelopment","Lightcord")
        $r = Get-Process -Name $dp -ErrorAction SilentlyContinue
        if ($r) {
            $closeResult = [System.Windows.Forms.MessageBox]::Show($form, "Discord is currently running. It needs to be closed to apply the EQ APO fix.`n`nClose Discord now?", "Discord Running", "YesNo", "Question")
            if ($closeResult -eq "Yes") {
                Add-Status $statusBox $form "Closing Discord processes..." "Blue"
                $allProcs = @("Discord","DiscordCanary","DiscordPTB","DiscordDevelopment","Lightcord","BetterVencord","Equicord","Vencord","Update")
                $stopResult = Stop-DiscordProcesses $allProcs
                if ($stopResult) { Add-Status $statusBox $form "[OK] Discord processes closed" "LimeGreen" }
                else { Add-Status $statusBox $form "[!] Warning: Some processes may still be running, waiting..." "Orange"; Start-Sleep -Seconds 2 }
                Start-Sleep -Seconds 1
            } else { Add-Status $statusBox $form "EQ APO fix cancelled - Discord must be closed" "Yellow"; return }
        }
        Update-Progress $progressBar $form 30
        $result = Apply-EqApoFixAll $statusBox $form $true
        Update-Progress $progressBar $form 90
        if ($result.Success -gt 0) {
            if ($chkAutoStart.Checked) {
                $sc = $DiscordClients[$clientCombo.SelectedIndex]; $bp = Get-RealClientPath $sc
                if ($bp) { $ap = Find-DiscordAppPath $bp; if ($ap) { Add-Status $statusBox $form "Starting Discord..." "Blue"; $de = Join-Path $ap $sc.Exe; if (Start-DiscordClient $de) { Add-Status $statusBox $form "[OK] Discord started" "LimeGreen" } } }
            }
            Update-Progress $progressBar $form 100; Play-CompletionSound $true
            [System.Windows.Forms.MessageBox]::Show($form, "EQ APO fix applied to $($result.Success) client(s)!", "Success", "OK", "Information")
        } else { Update-Progress $progressBar $form 100; Play-CompletionSound $false }
    } catch { Add-Status $statusBox $form "[X] ERROR: $($_.Exception.Message)" "Red"; Play-CompletionSound $false }
    finally { $btnFixEqApo.Enabled = $true }
})

$clientCombo.Add_SelectedIndexChanged({
    $sc = $DiscordClients[$clientCombo.SelectedIndex]; $bp = Get-RealClientPath $sc
    if (-not $bp) { $updateStatusLabel.Text = "Client not found"; $updateStatusLabel.ForeColor = $Theme.TextDim; return }
    $uc = Check-DiscordUpdated $bp $sc.Name
    if ($uc -and $uc.Updated) { $updateStatusLabel.Text = "Discord updated! v$($uc.OldVersion) -> v$($uc.NewVersion) - Fix recommended"; $updateStatusLabel.ForeColor = $Theme.Warning }
    elseif ($uc -and $uc.LastFixDate) { $lf = [DateTime]::Parse($uc.LastFixDate); $updateStatusLabel.Text = "Last fixed: $($lf.ToString('MMM dd, yyyy HH:mm')) (v$($uc.CurrentVersion))"; $updateStatusLabel.ForeColor = $Theme.TextSecondary }
    else { $updateStatusLabel.Text = "" }
})

$btnCheckUpdate.Add_Click({
    $statusBox.Clear(); $sc = $DiscordClients[$clientCombo.SelectedIndex]
    Add-Status $statusBox $form "Checking Discord version..." "Blue"
    $bp = Get-RealClientPath $sc
    if (-not $bp) { Add-Status $statusBox $form "[X] Discord client not found (checked Default, Process, and Shortcuts)" "Red"; Add-Status $statusBox $form "    Try opening Discord first so we can detect the path." "Yellow"; return }
    Add-Status $statusBox $form "Found installation at: $bp" "Cyan"
    $diag = Find-DiscordAppPath $bp -ReturnDiagnostics
    if ($diag.Error) {
        switch ($diag.Error) {
            "NoAppFolders" { Add-Status $statusBox $form "[X] No Discord app folders found (app-*)" "Red"; Add-Status $statusBox $form "    Discord may not be fully installed." "Yellow"; Add-Status $statusBox $form "    Try running Discord once to complete installation." "Yellow" }
            "NoModulesFolder" {
                Add-Status $statusBox $form "[X] No 'modules' folder found in Discord" "Red"
                Add-Status $statusBox $form "    Found app folder: $($diag.LatestAppVersion)" "Cyan"
                Add-Status $statusBox $form "    Your Discord version is corrupted or severely outdated." "Yellow"
                Add-Status $statusBox $form "" "White"
                if ($sc.Name -match "\[Official\]") {
                    Add-Status $statusBox $form "[?] Would you like to automatically reinstall Discord?" "Magenta"
                    $reinstallResult = Reinstall-DiscordClient -ClientPath $bp -ClientInfo $sc -StatusBox $statusBox -Form $form
                    if ($reinstallResult) { Add-Status $statusBox $form "" "White"; Add-Status $statusBox $form "Discord reinstalled! Now applying the stereo fix..." "Blue"; $form.Refresh(); Start-Sleep -Seconds 2; $btnFixAll.PerformClick() }
                } else { Add-Status $statusBox $form "    Please manually reinstall $($sc.Name.Trim())" "Yellow" }
            }
            "NoVoiceModule" {
                Add-Status $statusBox $form "[X] No 'discord_voice' module found" "Red"
                Add-Status $statusBox $form "    Found app folder: $($diag.LatestAppVersion)" "Cyan"
                Add-Status $statusBox $form "    Modules path: $($diag.ModulesPath)" "Cyan"
                Add-Status $statusBox $form "    The voice module may not have been downloaded yet." "Yellow"
                Add-Status $statusBox $form "    Try: 1) Join a voice channel in Discord  2) Wait 30 seconds  3) Check again" "Yellow"
            }
            default { Add-Status $statusBox $form "[X] Unknown error finding Discord installation" "Red" }
        }
        return
    }
    $ap = $diag.LatestAppFolder; $cv = Get-DiscordAppVersion $ap
    Add-Status $statusBox $form "Current version: $cv" "Cyan"
    Add-Status $statusBox $form "Voice module: $($diag.VoiceModulePath | Split-Path -Leaf)" "Cyan"
    $uc = Check-DiscordUpdated $bp $sc.Name
    if ($uc -and $uc.Updated) {
        Add-Status $statusBox $form "[!] Discord has been updated!" "Yellow"
        Add-Status $statusBox $form "    Previous: v$($uc.OldVersion)" "Orange"; Add-Status $statusBox $form "    Current:  v$($uc.NewVersion)" "Orange"
        Add-Status $statusBox $form "    Re-applying the fix is recommended." "Yellow"
        $updateStatusLabel.Text = "Discord updated! v$($uc.OldVersion) -> v$($uc.NewVersion) - Fix recommended"; $updateStatusLabel.ForeColor = $Theme.Warning
    } elseif ($uc -and $uc.LastFixDate) {
        $lf = [DateTime]::Parse($uc.LastFixDate)
        Add-Status $statusBox $form "[OK] No update detected since last fix" "LimeGreen"
        Add-Status $statusBox $form "    Last fixed: $($lf.ToString('MMM dd, yyyy HH:mm'))" "Cyan"
        $updateStatusLabel.Text = "Last fixed: $($lf.ToString('MMM dd, yyyy HH:mm')) (v$($uc.CurrentVersion))"; $updateStatusLabel.ForeColor = $Theme.TextSecondary
    } else { Add-Status $statusBox $form "[!] No previous fix recorded for this client" "Yellow"; Add-Status $statusBox $form "    Run 'Start Fix' to apply the fix." "Cyan"; $updateStatusLabel.Text = "" }
    if (Test-OriginalBackupExists $sc.Name) {
        $orig = Get-OriginalBackup $sc.Name
        if ($orig) { Add-Status $statusBox $form "" "White"; Add-Status $statusBox $form "[ORIGINAL BACKUP] Preserved from: $($orig.BackupDate.ToString('MMM dd, yyyy HH:mm'))" "Magenta" }
    } else { Add-Status $statusBox $form "" "White"; Add-Status $statusBox $form "[INFO] No original backup yet - will be created on first fix" "Yellow" }
})

$btnRollback.Add_Click({
    $statusBox.Clear(); $sc = $DiscordClients[$clientCombo.SelectedIndex]
    Add-Status $statusBox $form "Loading available backups..." "Blue"
    if (-not (Test-Path $BACKUP_ROOT) -and -not (Test-Path $ORIGINAL_BACKUP_ROOT)) {
        Add-Status $statusBox $form "[X] No backup directories found" "Red"; Add-Status $statusBox $form "" "White"
        Add-Status $statusBox $form "You need to run the installer (Start Fix or Fix All) first." "Yellow"
        Add-Status $statusBox $form "The installer creates a backup before applying the stereo fix." "Yellow"
        Add-Status $statusBox $form "" "White"; Add-Status $statusBox $form "Backup location: $APP_DATA_ROOT" "Cyan"
        [System.Windows.Forms.MessageBox]::Show($form,"No backups available.`n`nYou need to run 'Start Fix' or 'Fix All' first to create a backup.`n`nThe installer automatically backs up your original Discord modules before applying the stereo fix.","No Backups Found","OK","Information")
        return
    }
    $bks = @(Get-AvailableBackups $statusBox $form)
    if ($bks.Count -eq 0) { 
        Add-Status $statusBox $form "[X] No valid backups found" "Red"; Add-Status $statusBox $form "" "White"
        Add-Status $statusBox $form "Possible causes:" "Yellow"
        Add-Status $statusBox $form "  1. You haven't run the installer yet (Start Fix or Fix All)" "Yellow"
        Add-Status $statusBox $form "  2. Backup files were deleted or corrupted" "Yellow"
        Add-Status $statusBox $form "  3. Backup metadata.json files are missing or invalid" "Yellow"
        Add-Status $statusBox $form "" "White"; Add-Status $statusBox $form "Backup locations checked:" "Cyan"
        Add-Status $statusBox $form "  Regular backups: $BACKUP_ROOT" "Cyan"
        Add-Status $statusBox $form "  Original backups: $ORIGINAL_BACKUP_ROOT" "Cyan"
        if (Test-Path $BACKUP_ROOT) {
            $existingBackups = Get-ChildItem $BACKUP_ROOT -Directory -ErrorAction SilentlyContinue
            if ($existingBackups) {
                Add-Status $statusBox $form "" "White"; Add-Status $statusBox $form "Found $($existingBackups.Count) folder(s) in backup directory but none are valid:" "Orange"
                foreach ($eb in $existingBackups | Select-Object -First 5) { Add-Status $statusBox $form "  - $($eb.Name)" "Orange" }
            }
        }
        [System.Windows.Forms.MessageBox]::Show($form,"No valid backups available.`n`nRun 'Start Fix' or 'Fix All' first to create a backup.`n`nCheck the status window for more details.","No Valid Backups","OK","Information")
        return 
    }
    Add-Status $statusBox $form "[OK] Found $($bks.Count) valid backup(s)" "LimeGreen"
    $rf = New-Object System.Windows.Forms.Form
    $rf.Text = "Select Backup to Restore"; $rf.Size = New-Object System.Drawing.Size(500,350); $rf.StartPosition = "CenterParent"
    $rf.FormBorderStyle = "FixedDialog"; $rf.MaximizeBox = $false; $rf.MinimizeBox = $false; $rf.BackColor = $Theme.Background; $rf.TopMost = $true
    $infoLabel = New-StyledLabel 20 10 445 40 "[ORIGINAL] backups are preserved forever and let you revert to mono audio.`nRegular backups are rotated (1 kept per client)." $Fonts.Small $Theme.TextSecondary "TopLeft"
    $rf.Controls.Add($infoLabel)
    $lb = New-Object System.Windows.Forms.ListBox
    $lb.Location = New-Object System.Drawing.Point(20,55); $lb.Size = New-Object System.Drawing.Size(445,180)
    $lb.BackColor = $Theme.ControlBg; $lb.ForeColor = $Theme.TextPrimary; $lb.Font = $Fonts.Normal
    foreach ($b in $bks) { [void]$lb.Items.Add($b.DisplayName) }; $lb.SelectedIndex = 0; $rf.Controls.Add($lb)
    $br = New-StyledButton 145 250 100 35 "Restore"; $bc = New-StyledButton 255 250 100 35 "Cancel" $Fonts.Button $Theme.Secondary
    $rf.Controls.Add($br); $rf.Controls.Add($bc)
    $bc.Add_Click({ $rf.DialogResult = "Cancel"; $rf.Close() }); $br.Add_Click({ $rf.DialogResult = "OK"; $rf.Close() })
    $res = $rf.ShowDialog($form)
    if ($res -eq "OK" -and $lb.SelectedIndex -ge 0) {
        $sb = $bks[$lb.SelectedIndex]
        if (-not $sb) { Add-Status $statusBox $form "[X] Invalid selection: backup data is null" "Red"; return }
        if (-not $sb.Path) { Add-Status $statusBox $form "[X] Invalid selection: backup path is missing" "Red"; return }
        if (-not (Test-Path $sb.Path)) { Add-Status $statusBox $form "[X] Backup folder no longer exists: $($sb.Path)" "Red"; Add-Status $statusBox $form "    The backup may have been deleted since the list was loaded." "Yellow"; return }
        if ($sb.IsOriginal) {
            $confirmOrig = [System.Windows.Forms.MessageBox]::Show($form, "You are about to restore the ORIGINAL backup.`n`nThis will revert Discord to MONO audio (pre-stereo fix).`n`nAre you sure you want to continue?", "Restore Original (Mono)?", "YesNo", "Warning")
            if ($confirmOrig -ne "Yes") { Add-Status $statusBox $form "Restore cancelled by user" "Yellow"; return }
        }
        Add-Status $statusBox $form "Starting rollback..." "Blue"
        Add-Status $statusBox $form "  Selected: $($sb.DisplayName)" "Cyan"
        Add-Status $statusBox $form "  Backup path: $($sb.Path)" "Cyan"
        Add-Status $statusBox $form "Closing Discord processes..." "Blue"
        $stopResult = Stop-DiscordProcesses $sc.Processes
        if (-not $stopResult) { Add-Status $statusBox $form "[!] Warning: Some processes may still be running" "Orange"; Start-Sleep -Seconds 2 }
        $bp = Get-RealClientPath $sc
        if (-not $bp) { Add-Status $statusBox $form "[X] Could not find Discord installation" "Red"; Add-Status $statusBox $form "    Ensure Discord is installed or run Discord first." "Yellow"; return }
        $ap = Find-DiscordAppPath $bp
        if (-not $ap) { Add-Status $statusBox $form "[X] Could not find Discord app folder" "Red"; Add-Status $statusBox $form "    Discord may need to be reinstalled." "Yellow"; return }
        $vm = Get-ChildItem "$ap\modules" -Filter "discord_voice*" -Directory | Select-Object -First 1
        if (-not $vm) { Add-Status $statusBox $form "[X] Could not find voice module in Discord installation" "Red"; Add-Status $statusBox $form "    Try joining a voice channel first to download the module." "Yellow"; return }
        $tvf = if (Test-Path "$($vm.FullName)\discord_voice") { "$($vm.FullName)\discord_voice" } else { $vm.FullName }
        Add-Status $statusBox $form "  Target voice folder: $tvf" "Cyan"
        $suc = Restore-FromBackup $sb $tvf $statusBox $form
        if ($suc) {
            if ($sb.IsOriginal) { Add-Status $statusBox $form "[OK] Restored to ORIGINAL (mono audio)" "Magenta" }
            else { Add-Status $statusBox $form "[OK] Rollback completed successfully" "LimeGreen" }
            if ($chkAutoStart.Checked) { Add-Status $statusBox $form "Starting Discord..." "Blue"; $de = Join-Path $ap $sc.Exe; Start-DiscordClient $de; Add-Status $statusBox $form "[OK] Discord started" "LimeGreen" }
            Play-CompletionSound $true; [System.Windows.Forms.MessageBox]::Show($form,"Rollback completed successfully!","Success","OK","Information")
        } else { Play-CompletionSound $false }
    }
})

$btnStart.Add_Click({
    $btnStart.Enabled = $false; $btnFixAll.Enabled = $false; $btnRollback.Enabled = $false; $btnCheckUpdate.Enabled = $false; $btnFixEqApo.Enabled = $false
    $statusBox.Clear(); $progressBar.Value = 0; $td = Join-Path $env:TEMP "StereoInstaller_$(Get-Random)"
    try {
        $sc = $DiscordClients[$clientCombo.SelectedIndex]
        if ($chkUpdate.Checked) {
            Add-Status $statusBox $form "Checking for script updates..." "Blue"; Update-Progress $progressBar $form 5
            try {
                $cs = $PSCommandPath
                if ([string]::IsNullOrEmpty($cs)) { Add-Status $statusBox $form "[OK] Running latest version from web" "LimeGreen" }
                else {
                    $uf = "$env:TEMP\StereoInstaller_Update_$(Get-Random).ps1"
                    Invoke-WebRequest -Uri $UPDATE_URL -OutFile $uf -UseBasicParsing -TimeoutSec 10 | Out-Null
                    $ucontent = (Get-Content $uf -Raw) -replace "`r`n","`n" -replace "`r","`n"
                    $ccontent = (Get-Content $cs -Raw) -replace "`r`n","`n" -replace "`r","`n"
                    if ($ucontent -and $ccontent) {
                        $ucontent = $ucontent.Trim(); $ccontent = $ccontent.Trim()
                        if ($ucontent -ne $ccontent) {
                            Add-Status $statusBox $form "New update found!" "Yellow"
                            if ($chkAutoUpdate.Checked) {
                                Add-Status $statusBox $form "Update will be applied after script closes..." "Cyan"
                                Add-Status $statusBox $form "[OK] Update prepared! Restarting in 3 seconds..." "LimeGreen"
                                Start-Sleep -Seconds 3; Apply-ScriptUpdate $uf $cs; $form.Close(); return
                            } else { Add-Status $statusBox $form "Update downloaded to: $uf" "Orange"; Add-Status $statusBox $form "Please manually replace the script file to update." "Orange" }
                        } else { Add-Status $statusBox $form "[OK] You are on the latest version" "LimeGreen"; Remove-Item $uf -ErrorAction SilentlyContinue }
                    } else { Add-Status $statusBox $form "[!] Could not read script files for comparison" "Orange"; Remove-Item $uf -ErrorAction SilentlyContinue }
                }
            } catch { Add-Status $statusBox $form "[!] Could not check for updates: $($_.Exception.Message)" "Orange" }
        }
        Update-Progress $progressBar $form 10; Add-Status $statusBox $form "Downloading required files from GitHub..." "Blue"; EnsureDir $td
        $vbp = Join-Path $td "VoiceBackup"
        $vds = Download-VoiceBackupFiles $vbp $statusBox $form
        if (-not $vds) { throw "Failed to download voice backup files from GitHub" }
        Add-Status $statusBox $form "[OK] Files downloaded successfully" "LimeGreen"; Update-Progress $progressBar $form 30
        Add-Status $statusBox $form "Locating Discord installation..." "Blue"
        $bp = Get-RealClientPath $sc; if (-not $bp) { throw "Discord client folder not found. Please ensure it is installed or run Discord so we can detect the path." }
        Add-Status $statusBox $form "Path detected: $bp" "Cyan"
        $diag = Find-DiscordAppPath $bp -ReturnDiagnostics
        if ($diag.Error) {
            switch ($diag.Error) {
                "NoAppFolders" { throw "No Discord app folders found. Discord may not be fully installed. Try running Discord once." }
                "NoModulesFolder" { 
                    if ($sc.Name -match "\[Official\]") {
                        Add-Status $statusBox $form "[X] No 'modules' folder found - Discord is corrupted" "Red"; Add-Status $statusBox $form "" "White"
                        $reinstallResult = Reinstall-DiscordClient -ClientPath $bp -ClientInfo $sc -StatusBox $statusBox -Form $form
                        if ($reinstallResult) { $diag = Find-DiscordAppPath $bp -ReturnDiagnostics; if ($diag.Error) { throw "Discord reinstalled but still has issues. Please try again or reinstall Discord manually." }; Add-Status $statusBox $form "" "White"; Add-Status $statusBox $form "Continuing with stereo fix..." "Blue" }
                        else { throw "Discord reinstallation was cancelled or failed. Please reinstall Discord manually." }
                    } else { throw "No 'modules' folder found in Discord ($($diag.LatestAppVersion)). Please reinstall $($sc.Name.Trim()) manually." }
                }
                "NoVoiceModule" { throw "No 'discord_voice' module found. Try joining a voice channel first, then run this fix again." }
                default { throw "Could not find Discord installation structure." }
            }
        }
        $ap = $diag.LatestAppFolder; $av = Get-DiscordAppVersion $ap
        Add-Status $statusBox $form "[OK] Found $($sc.Name) v$av" "LimeGreen"
        Add-Status $statusBox $form "Closing Discord processes..." "Blue"
        $ka = Stop-DiscordProcesses $sc.Processes
        if ($ka) { Add-Status $statusBox $form "  Discord processes terminated" "Cyan" } else { Add-Status $statusBox $form "  [!] Some processes may still be running, waiting..." "Orange"; Start-Sleep -Seconds 2 }
        Update-Progress $progressBar $form 40; Add-Status $statusBox $form "[OK] Discord processes closed" "LimeGreen"; Update-Progress $progressBar $form 50
        Add-Status $statusBox $form "Locating voice module..." "Blue"
        $vm = Get-ChildItem "$ap\modules" -Filter "discord_voice*" -Directory | Select-Object -First 1
        if (-not $vm) { throw "No discord_voice module found" }
        $tvf = if (Test-Path "$($vm.FullName)\discord_voice") { "$($vm.FullName)\discord_voice" } else { $vm.FullName }
        Add-Status $statusBox $form "[OK] Voice module located" "LimeGreen"; Update-Progress $progressBar $form 55
        Add-Status $statusBox $form "Creating backup of current files..." "Blue"
        Create-VoiceBackup $tvf $sc.Name $av $statusBox $form | Out-Null
        Remove-OldBackups; Update-Progress $progressBar $form 60
        Add-Status $statusBox $form "Removing old voice module files..." "Blue"
        if (Test-Path $tvf) { Remove-Item "$tvf\*" -Recurse -Force -ErrorAction SilentlyContinue } else { EnsureDir $tvf }
        Add-Status $statusBox $form "[OK] Old files removed" "LimeGreen"; Update-Progress $progressBar $form 70
        Add-Status $statusBox $form "Copying updated module files..." "Blue"
        Copy-Item "$vbp\*" $tvf -Recurse -Force; Add-Status $statusBox $form "[OK] Module files copied" "LimeGreen"; Update-Progress $progressBar $form 80
        Save-FixState $sc.Name $av
        if ($chkFixEqApo.Checked) {
            Update-Progress $progressBar $form 82
            $roamingPath = $sc.RoamingPath
            $eqApoResult = Apply-EqApoFix -RoamingPath $roamingPath -ClientName $sc.Name.Trim() -StatusBox $statusBox -Form $form -SkipConfirmation $false
            if (-not $eqApoResult) { Add-Status $statusBox $form "[!] EQ APO fix was not applied (cancelled or failed)" "Orange" }
        }
        Update-Progress $progressBar $form 85
        if ($chkShortcut.Checked) {
            Add-Status $statusBox $form "Creating startup shortcut..." "Blue"
            $spt = $SAVED_SCRIPT_PATH; if (!(Test-Path $spt)) { $spt = Save-ScriptToAppData $statusBox $form }
            if ($spt) { Create-StartupShortcut $spt $chkSilentStartup.Checked; Add-Status $statusBox $form "[OK] Startup shortcut created" "LimeGreen" }
            else { Add-Status $statusBox $form "[!] Could not save script - shortcut not created" "Orange" }
        } else { Remove-StartupShortcut }
        Update-Progress $progressBar $form 90
        if ($chkAutoStart.Checked) {
            Add-Status $statusBox $form "Starting Discord..." "Blue"; $de = Join-Path $ap $sc.Exe; $st = Start-DiscordClient $de
            if (-not $st -and $sc.FallbackPath) { $fa = Find-DiscordAppPath $sc.FallbackPath; if ($fa) { $ae = Join-Path $fa $sc.Exe; $st = Start-DiscordClient $ae; if ($st) { Add-Status $statusBox $form "[OK] Discord started (from alternate location)" "LimeGreen" } } }
            elseif ($st) { Add-Status $statusBox $form "[OK] Discord started" "LimeGreen" }
            if (-not $st) { Add-Status $statusBox $form "[!] Could not find Discord executable" "Orange" }
        }
        Update-Progress $progressBar $form 100
        $updateStatusLabel.Text = "Last fixed: $(Get-Date -Format 'MMM dd, yyyy HH:mm') (v$av)"; $updateStatusLabel.ForeColor = $Theme.TextSecondary
        Add-Status $statusBox $form "" "White"; Add-Status $statusBox $form "=== ALL TASKS COMPLETED ===" "LimeGreen"
        Play-CompletionSound $true; Save-CurrentSettings
        [System.Windows.Forms.MessageBox]::Show($form,"Discord voice module fix completed successfully!`n`nA backup was created in case you need to rollback.`nYour ORIGINAL modules are preserved permanently.","Success","OK","Information")
        $form.Close()
    } catch {
        Add-Status $statusBox $form "" "White"; Add-Status $statusBox $form "[X] ERROR: $($_.Exception.Message)" "Red"
        Play-CompletionSound $false; [System.Windows.Forms.MessageBox]::Show($form,"An error occurred: $($_.Exception.Message)","Error","OK","Error")
    } finally {
        if (Test-Path $td) { Remove-Item $td -Recurse -Force -ErrorAction SilentlyContinue }
        $btnStart.Enabled = $true; $btnFixAll.Enabled = $true; $btnRollback.Enabled = $true; $btnCheckUpdate.Enabled = $true; $btnFixEqApo.Enabled = $true
    }
})

$btnFixAll.Add_Click({
    $btnStart.Enabled = $false; $btnFixAll.Enabled = $false; $btnRollback.Enabled = $false; $btnCheckUpdate.Enabled = $false; $btnFixEqApo.Enabled = $false
    $statusBox.Clear(); $progressBar.Value = 0; $td = Join-Path $env:TEMP "StereoInstaller_$(Get-Random)"
    try {
        Add-Status $statusBox $form "Scanning for installed Discord clients..." "Blue"
        $ic = Get-InstalledClients
        if ($ic.Count -eq 0) { Add-Status $statusBox $form "[X] No Discord clients found!" "Red"; Add-Status $statusBox $form "    Ensure Discord is installed or currently running." "Yellow"; [System.Windows.Forms.MessageBox]::Show($form,"No Discord clients were found on this system.","No Clients Found","OK","Warning"); return }
        $up = @{}; $uc = [System.Collections.ArrayList]@()
        foreach ($c in $ic) { if (-not $up.ContainsKey($c.AppPath)) { $up[$c.AppPath] = $true; [void]$uc.Add($c) } }
        Add-Status $statusBox $form "[OK] Found $($uc.Count) client(s):" "LimeGreen"
        foreach ($c in $uc) { $v = Get-DiscordAppVersion $c.AppPath; Add-Status $statusBox $form "    - $($c.Name.Trim()) (v$v)" "Cyan" }
        Update-Progress $progressBar $form 5
        $cr = [System.Windows.Forms.MessageBox]::Show($form,"Found $($uc.Count) Discord client(s). Apply fix to all?","Confirm Fix All","YesNo","Question")
        if ($cr -ne "Yes") { Add-Status $statusBox $form "Operation cancelled by user" "Yellow"; return }
        Add-Status $statusBox $form "" "White"; Add-Status $statusBox $form "Downloading required files from GitHub..." "Blue"; EnsureDir $td
        $vbp = Join-Path $td "VoiceBackup"; 
        if (-not (Download-VoiceBackupFiles $vbp $statusBox $form)) { throw "Failed to download voice backup files" }
        Update-Progress $progressBar $form 20
        Add-Status $statusBox $form "" "White"; Add-Status $statusBox $form "Closing all Discord processes..." "Blue"
        $allProcs = @("Discord","DiscordCanary","DiscordPTB","DiscordDevelopment","Lightcord","BetterVencord","Equicord","Vencord","Update")
        $stopResult = Stop-DiscordProcesses $allProcs
        if (-not $stopResult) { Add-Status $statusBox $form "[!] Warning: Some processes may still be running, waiting..." "Orange"; Start-Sleep -Seconds 2 }
        Add-Status $statusBox $form "[OK] Discord processes closed" "LimeGreen"; Update-Progress $progressBar $form 30
        $ppc = 50 / $uc.Count; $cp = 30; $fxc = 0; $fc = @()
        foreach ($ci in $uc) {
            Add-Status $statusBox $form "" "White"; Add-Status $statusBox $form "=== Fixing: $($ci.Name.Trim()) ===" "Blue"
            try {
                $ap = $ci.AppPath; $av = Get-DiscordAppVersion $ap
                $vm = Get-ChildItem "$ap\modules" -Filter "discord_voice*" -Directory | Select-Object -First 1
                if (-not $vm) { throw "No discord_voice module found" }
                $tvf = if (Test-Path "$($vm.FullName)\discord_voice") { "$($vm.FullName)\discord_voice" } else { $vm.FullName }
                Add-Status $statusBox $form "  Creating backup..." "Cyan"
                Create-VoiceBackup $tvf $ci.Name $av $statusBox $form | Out-Null
                if (Test-Path $tvf) { Remove-Item "$tvf\*" -Recurse -Force -ErrorAction SilentlyContinue } else { EnsureDir $tvf }
                Add-Status $statusBox $form "  Copying module files..." "Cyan"; Copy-Item "$vbp\*" $tvf -Recurse -Force
                Save-FixState $ci.Name $av; Add-Status $statusBox $form "[OK] $($ci.Name.Trim()) fixed successfully" "LimeGreen"; $fxc++
            } catch { Add-Status $statusBox $form "[X] Failed to fix $($ci.Name.Trim()): $($_.Exception.Message)" "Red"; $fc += $ci.Name }
            $cp += $ppc; Update-Progress $progressBar $form ([int]$cp)
        }
        Remove-OldBackups; Update-Progress $progressBar $form 85
        if ($chkFixEqApo.Checked) {
            $eqResult = Apply-EqApoFixAll $statusBox $form $true
            if ($eqResult.Success -eq 0) { Add-Status $statusBox $form "[!] EQ APO fix was not applied to any clients" "Orange" }
            else { Add-Status $statusBox $form "[OK] EQ APO fix applied to $($eqResult.Success) client(s)" "LimeGreen" }
        }
        Update-Progress $progressBar $form 90
        if ($chkShortcut.Checked) {
            Add-Status $statusBox $form "Creating startup shortcut..." "Blue"
            $spt = $SAVED_SCRIPT_PATH; if (!(Test-Path $spt)) { $spt = Save-ScriptToAppData $statusBox $form }
            if ($spt) { Create-StartupShortcut $spt $chkSilentStartup.Checked; Add-Status $statusBox $form "[OK] Startup shortcut created" "LimeGreen" }
            else { Add-Status $statusBox $form "[!] Could not save script - shortcut not created" "Orange" }
        } else { Remove-StartupShortcut }
        if ($chkAutoStart.Checked -and $fxc -gt 0) {
            Add-Status $statusBox $form "" "White"; Add-Status $statusBox $form "Starting Discord..." "Blue"
            $pc = $uc[0]; $de = Join-Path $pc.AppPath $pc.Client.Exe
            if (Start-DiscordClient $de) { Add-Status $statusBox $form "[OK] Discord started" "LimeGreen" }
        }
        Update-Progress $progressBar $form 100
        Add-Status $statusBox $form "" "White"; Add-Status $statusBox $form "=== FIX ALL COMPLETED ===" "LimeGreen"
        Add-Status $statusBox $form "Fixed: $fxc / $($uc.Count) clients" "Cyan"; Save-CurrentSettings
        if ($fc.Count -gt 0) { Play-CompletionSound $false; [System.Windows.Forms.MessageBox]::Show($form,"Fixed $fxc of $($uc.Count) clients.`n`nFailed: $($fc -join ', ')","Completed with Errors","OK","Warning") }
        else { Play-CompletionSound $true; [System.Windows.Forms.MessageBox]::Show($form,"Successfully fixed all $fxc Discord client(s)!`n`nOriginal modules preserved for each client.","Success","OK","Information") }
    } catch {
        Add-Status $statusBox $form "" "White"; Add-Status $statusBox $form "[X] ERROR: $($_.Exception.Message)" "Red"
        Play-CompletionSound $false; [System.Windows.Forms.MessageBox]::Show($form,"An error occurred: $($_.Exception.Message)","Error","OK","Error")
    } finally {
        if (Test-Path $td) { Remove-Item $td -Recurse -Force -ErrorAction SilentlyContinue }
        $btnStart.Enabled = $true; $btnFixAll.Enabled = $true; $btnRollback.Enabled = $true; $btnCheckUpdate.Enabled = $true; $btnFixEqApo.Enabled = $true
    }
})

# 16. Timer & Form Events
$timer = New-Object System.Windows.Forms.Timer; $timer.Interval = 5000
$timer.Add_Tick({ Update-DiscordRunningWarning }); $timer.Start()

$form.Add_Shown({
    $form.Activate(); Update-DiscordRunningWarning; Update-ScriptStatusLabel
    $sc = $DiscordClients[$clientCombo.SelectedIndex]; $bp = Get-RealClientPath $sc
    if ($bp) {
        $uc = Check-DiscordUpdated $bp $sc.Name
        if ($uc -and $uc.Updated) { $updateStatusLabel.Text = "Discord updated! v$($uc.OldVersion) -> v$($uc.NewVersion) - Fix recommended"; $updateStatusLabel.ForeColor = $Theme.Warning }
        elseif ($uc -and $uc.LastFixDate) { $lf = [DateTime]::Parse($uc.LastFixDate); $updateStatusLabel.Text = "Last fixed: $($lf.ToString('MMM dd, yyyy HH:mm')) (v$($uc.CurrentVersion))"; $updateStatusLabel.ForeColor = $Theme.TextSecondary }
    }
})

$form.Add_FormClosing({ Save-CurrentSettings })
$form.Add_FormClosed({ $timer.Stop(); $timer.Dispose() })

[void]$form.ShowDialog()
