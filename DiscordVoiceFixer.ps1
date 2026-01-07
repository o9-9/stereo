param([switch]$Silent, [switch]$CheckOnly, [string]$FixClient, [switch]$Help)

# 1. Performance & Security Setup
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$ProgressPreference = 'SilentlyContinue'

if ($Help) { Write-Host "Discord Voice Fixer`nUsage: .\DiscordVoiceFixer.ps1 [-Silent] [-CheckOnly] [-FixClient <n>] [-Help]"; exit 0 }

# 2. Load Assemblies & Visuals
Add-Type -AssemblyName System.Windows.Forms, System.Drawing

# Enable High DPI Support
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
# Ordered: Officials first to prevent mods (that share folders) from mislabeling the client.
$DiscordClients = [ordered]@{
    0 = @{Name="Discord - Stable         [Official]"; Path="$env:LOCALAPPDATA\Discord";            Processes=@("Discord","Update");            Exe="Discord.exe";            Shortcut="Discord"}
    1 = @{Name="Discord - Canary         [Official]"; Path="$env:LOCALAPPDATA\DiscordCanary";      Processes=@("DiscordCanary","Update");      Exe="DiscordCanary.exe";      Shortcut="Discord Canary"}
    2 = @{Name="Discord - PTB            [Official]"; Path="$env:LOCALAPPDATA\DiscordPTB";         Processes=@("DiscordPTB","Update");         Exe="DiscordPTB.exe";         Shortcut="Discord PTB"}
    3 = @{Name="Discord - Development    [Official]"; Path="$env:LOCALAPPDATA\DiscordDevelopment"; Processes=@("DiscordDevelopment","Update"); Exe="DiscordDevelopment.exe"; Shortcut="Discord Development"}
    4 = @{Name="Lightcord                [Mod]";      Path="$env:LOCALAPPDATA\Lightcord";          Processes=@("Lightcord","Update");          Exe="Lightcord.exe";          Shortcut="Lightcord"}
    5 = @{Name="BetterDiscord            [Mod]";      Path="$env:LOCALAPPDATA\Discord";            Processes=@("Discord","Update");            Exe="Discord.exe";            Shortcut="Discord"}
    6 = @{Name="Vencord                  [Mod]";      Path="$env:LOCALAPPDATA\Vencord";            FallbackPath="$env:LOCALAPPDATA\Discord"; Processes=@("Vencord","Discord","Update");       Exe="Discord.exe"; Shortcut="Vencord"}
    7 = @{Name="Equicord                 [Mod]";      Path="$env:LOCALAPPDATA\Equicord";           FallbackPath="$env:LOCALAPPDATA\Discord"; Processes=@("Equicord","Discord","Update");      Exe="Discord.exe"; Shortcut="Equicord"}
    8 = @{Name="BetterVencord            [Mod]";      Path="$env:LOCALAPPDATA\BetterVencord";      FallbackPath="$env:LOCALAPPDATA\Discord"; Processes=@("BetterVencord","Discord","Update"); Exe="Discord.exe"; Shortcut="BetterVencord"}
}

# 5. URLs & Paths
$UPDATE_URL = "https://raw.githubusercontent.com/ProdHallow/installer/main/DiscordVoiceFixer.ps1"
$VOICE_BACKUP_API = "https://api.github.com/repos/ProdHallow/voice-backup/contents/Discord%20Voice%20Backup"

$APP_DATA_ROOT = "$env:APPDATA\StereoInstaller"
$BACKUP_ROOT = "$APP_DATA_ROOT\backups"
$STATE_FILE = "$APP_DATA_ROOT\state.json"
$SETTINGS_FILE = "$APP_DATA_ROOT\settings.json"
$SAVED_SCRIPT_PATH = "$APP_DATA_ROOT\DiscordVoiceFixer.ps1"

# 6. Core Logic Functions
function EnsureDir($p) { if (-not (Test-Path $p)) { try { [void](New-Item $p -ItemType Directory -Force) } catch { } } }

function Get-DefaultSettings { return [PSCustomObject]@{CheckForUpdates=$true; AutoApplyUpdates=$true; CreateShortcut=$false; AutoStartDiscord=$true; SelectedClientIndex=0; SilentStartup=$false} }

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
    $p = Get-Process -Name $ProcessNames -EA SilentlyContinue
    if ($p) {
        $p | Stop-Process -Force -EA SilentlyContinue
        for ($i=0; $i -lt 20; $i++) {
            if (-not (Get-Process -Name $ProcessNames -EA SilentlyContinue)) { return $true }
            Start-Sleep -Milliseconds 250
        }
        return $true
    }
    return $false
}

function Find-DiscordAppPath { param([string]$BasePath)
    $af = gci $BasePath -Filter "app-*" -Directory -EA SilentlyContinue | 
        Sort-Object { 
            try { if ($_ -match "app-([\d\.]+)") { [Version]$matches[1] } else { $_.Name } } catch { $_.Name }
        } -Descending
    
    foreach ($f in $af) {
        $mp = Join-Path $f.FullName "modules"
        if (Test-Path $mp) { 
            $vm = gci $mp -Filter "discord_voice*" -Directory -EA SilentlyContinue
            if ($vm) { return $f.FullName } 
        }
    }
    return $null
}

function Get-DiscordAppVersion { param([string]$AppPath)
    if ($AppPath -match "app-([\d\.]+)") { return $matches[1] }
    try {
        $exe = gci $AppPath -Filter "*.exe" | Select-Object -First 1
        if ($exe) { return (Get-Item $exe.FullName).VersionInfo.ProductVersion }
    } catch {}
    return "Unknown"
}

function Start-DiscordClient { param([string]$ExePath)
    # Using 'cmd /c start' detaches the process, preventing Electron log spam in the console.
    if (Test-Path $ExePath) { 
        Start-Process "cmd.exe" -ArgumentList "/c","start",'""',"`"$ExePath`"" -WindowStyle Hidden
        return $true 
    }
    return $false
}

function Get-PathFromProcess { param([string]$ProcessName)
    try {
        $p = Get-Process -Name $ProcessName -EA SilentlyContinue | Select-Object -First 1
        if ($p) { return (Split-Path (Split-Path $p.MainModule.FileName -Parent) -Parent) }
    } catch {}
    return $null
}

function Get-PathFromShortcuts { param([string]$ShortcutName)
    if (-not $ShortcutName) { return $null }
    $sm = "$env:APPDATA\Microsoft\Windows\Start Menu\Programs"
    if (!(Test-Path $sm)) { return $null }
    $scs = gci $sm -Filter "$ShortcutName.lnk" -Recurse -EA SilentlyContinue
    if (-not $scs) { return $null }
    $ws = New-Object -ComObject WScript.Shell
    foreach ($lf in $scs) { try { $sc = $ws.CreateShortcut($lf.FullName); if (Test-Path $sc.TargetPath) { return (Split-Path $sc.TargetPath -Parent) } } catch { } }
    return $null
}

function Get-RealClientPath { param($ClientObj)
    $p = $ClientObj.Path
    if (Test-Path $p) { return $p }
    if ($ClientObj.FallbackPath -and (Test-Path $ClientObj.FallbackPath)) { return $ClientObj.FallbackPath }
    
    foreach ($pr in $ClientObj.Processes) {
        if ($pr -eq "Update") { continue }
        $pp = Get-PathFromProcess $pr; if ($pp -and (Test-Path $pp)) { return $pp }
    }
    
    if ($ClientObj.Shortcut) { $sp = Get-PathFromShortcuts $ClientObj.Shortcut; if ($sp -and (Test-Path $sp)) { return $sp } }
    return $null
}

function Get-InstalledClients {
    $inst = [System.Collections.ArrayList]@()
    # HashSet allows us to ignore duplicates (e.g. Vencord in the Discord folder)
    $foundPaths = [System.Collections.Generic.HashSet[string]]@()

    foreach ($k in $DiscordClients.Keys) {
        $c = $DiscordClients[$k]; $fp = $null
        
        if (Test-Path $c.Path) { $fp = $c.Path }
        elseif ($c.FallbackPath -and (Test-Path $c.FallbackPath)) { $fp = $c.FallbackPath }
        else { 
            foreach ($pn in $c.Processes) { 
                if ($pn -eq "Update") { continue }
                $dp = Get-PathFromProcess $pn
                if ($dp -and (Test-Path $dp)) { $fp = $dp; break } 
            } 
        }
        if (-not $fp -and $c.Shortcut) { $sp = Get-PathFromShortcuts $c.Shortcut; if ($sp -and (Test-Path $sp)) { $fp = $sp } }
        
        if ($fp) { 
            try { $fp = (Get-Item $fp).FullName } catch {}

            # DEDUPLICATION: If we already found this exact folder, skip it.
            if ($foundPaths.Contains($fp)) { continue }

            $ap = Find-DiscordAppPath $fp
            if ($ap) { 
                [void]$inst.Add(@{Index=$k; Name=$c.Name; Path=$fp; AppPath=$ap; Client=$c})
                [void]$foundPaths.Add($fp)
            } 
        }
    }
    return $inst
}

# 9. Download Logic (Output Silenced)
function Download-VoiceBackupFiles { param([string]$DestinationPath, [System.Windows.Forms.RichTextBox]$StatusBox, [System.Windows.Forms.Form]$Form)
    try {
        EnsureDir $DestinationPath
        Add-Status $StatusBox $Form "  Fetching file list from GitHub..." "Cyan"
        
        try {
            $r = Invoke-RestMethod -Uri $VOICE_BACKUP_API -UseBasicParsing -TimeoutSec 30
        } catch {
            if ($_.Exception.Response.StatusCode -eq [System.Net.HttpStatusCode]::Forbidden) {
                throw "GitHub API Rate Limit exceeded. Please try again later."
            }
            throw $_
        }
        
        $r = @($r)
        
        if ($r.Count -eq 0) { throw "GitHub repository response is empty." }

        $fc = 0
        foreach ($f in $r) {
            if ($f.type -eq "file") {
                $fp = Join-Path $DestinationPath $f.name
                Add-Status $StatusBox $Form "  Downloading: $($f.name)" "Cyan"
                Invoke-WebRequest -Uri $f.download_url -OutFile $fp -UseBasicParsing -TimeoutSec 30 | Out-Null
                $fc++
            }
        }
        if ($fc -eq 0) { throw "No valid files found in repository." }
        Add-Status $StatusBox $Form "  Downloaded $fc voice backup files" "Cyan"; return $true
    } catch { Add-Status $StatusBox $Form "  [X] Failed to download files: $($_.Exception.Message)" "Red"; return $false }
}

# 10. Backup/Restore Logic
function Initialize-BackupDirectory { EnsureDir $BACKUP_ROOT; EnsureDir (Split-Path $STATE_FILE -Parent) }
function Get-StateData { if (Test-Path $STATE_FILE) { try { return Get-Content $STATE_FILE -Raw | ConvertFrom-Json } catch { return $null } }; return $null }
function Save-StateData { param([hashtable]$State); $State | ConvertTo-Json -Depth 5 | Out-File $STATE_FILE -Force }

function Create-VoiceBackup { 
    param([string]$VoiceFolderPath, [string]$ClientName, [string]$AppVersion,
          [System.Windows.Forms.RichTextBox]$StatusBox, [System.Windows.Forms.Form]$Form)
    try {
        Initialize-BackupDirectory
        $ts = Get-Date -Format "yyyy-MM-dd_HHmmss"
        $scn = $ClientName -replace '\s+','_' -replace '\[|\]',''
        $bn = "${scn}_${AppVersion}_${ts}"
        $bp = Join-Path $BACKUP_ROOT $bn; try { [void](New-Item $bp -ItemType Directory -Force) } catch { }
        $vbp = Join-Path $bp "voice_module"
        Add-Status $StatusBox $Form "  Backing up voice module..." "Cyan"
        
        EnsureDir $vbp
        if (Test-Path $VoiceFolderPath) {
            Copy-Item "$VoiceFolderPath\*" $vbp -Recurse -Force
        }
        
        @{ClientName=$ClientName; AppVersion=$AppVersion; BackupDate=(Get-Date).ToString("o"); VoiceModulePath=$VoiceFolderPath} | ConvertTo-Json | Out-File (Join-Path $bp "metadata.json") -Force
        Add-Status $StatusBox $Form "[OK] Backup created: $bn" "LimeGreen"; return $bp
    } catch { Add-Status $StatusBox $Form "[!] Backup failed: $($_.Exception.Message)" "Orange"; return $null }
}

function Get-AvailableBackups {
    Initialize-BackupDirectory
    $bks = [System.Collections.ArrayList]@()
    $bfs = gci $BACKUP_ROOT -Directory -EA SilentlyContinue | Sort-Object Name -Descending
    foreach ($f in $bfs) {
        $mp = Join-Path $f.FullName "metadata.json"
        if (Test-Path $mp) {
            try {
                $m = Get-Content $mp -Raw | ConvertFrom-Json
                [void]$bks.Add(@{
                    Path=$f.FullName; 
                    Name=$f.Name; 
                    ClientName=$m.ClientName; 
                    AppVersion=$m.AppVersion;
                    BackupDate=[DateTime]::Parse($m.BackupDate);
                    DisplayName="$($m.ClientName) v$($m.AppVersion) - $(([DateTime]::Parse($m.BackupDate)).ToString('MMM dd, yyyy HH:mm'))"
                })
            } catch { continue }
        }
    }
    return @($bks)  # FIX: Force array output to prevent single-item unwrapping
}

function Restore-FromBackup {
    param([hashtable]$Backup, [string]$TargetVoicePath,
          [System.Windows.Forms.RichTextBox]$StatusBox, [System.Windows.Forms.Form]$Form)
    try {
        $vbp = Join-Path $Backup.Path "voice_module"
        if (Test-Path $vbp) {
            Add-Status $StatusBox $Form "  Restoring voice module..." "Cyan"
            if (Test-Path $TargetVoicePath) { Remove-Item "$TargetVoicePath\*" -Recurse -Force -EA SilentlyContinue } else { EnsureDir $TargetVoicePath }
            Copy-Item "$vbp\*" $TargetVoicePath -Recurse -Force
        }
        return $true
    } catch { Add-Status $StatusBox $Form "[X] Restore failed: $($_.Exception.Message)" "Red"; return $false }
}

function Remove-OldBackups {
    $bks = @(Get-AvailableBackups)  # FIX: Ensure array
    $byClient = $bks | Group-Object { $_.ClientName }
    foreach ($group in $byClient) {
        $sorted = $group.Group | Sort-Object { $_.BackupDate } -Descending
        $sorted | Select-Object -Skip 1 | % { Remove-Item $_.Path -Recurse -Force -EA SilentlyContinue }
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
    if ($st -is [PSCustomObject]) { $ns = @{}; $st.PSObject.Properties | % { $ns[$_.Name] = $_.Value }; $st = $ns }
    $ck = $ClientName -replace '\s+','_' -replace '\[|\]',''
    $st[$ck] = @{LastFixedVersion=$Version; LastFixDate=(Get-Date).ToString("o")}
    Save-StateData $st
}

function Save-ScriptToAppData { param([System.Windows.Forms.RichTextBox]$StatusBox, [System.Windows.Forms.Form]$Form)
    try {
        EnsureDir (Split-Path $SAVED_SCRIPT_PATH -Parent)
        if (-not [string]::IsNullOrEmpty($PSCommandPath) -and (Test-Path $PSCommandPath)) {
            Copy-Item $PSCommandPath $SAVED_SCRIPT_PATH -Force
            Add-Status $StatusBox $Form "[OK] Script saved to: $SAVED_SCRIPT_PATH" "LimeGreen"; return $SAVED_SCRIPT_PATH
        }
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
    if (Test-Path $sp) { Remove-Item $sp -Force -EA SilentlyContinue }
}

function Apply-ScriptUpdate { param([string]$UpdatedScriptPath, [string]$CurrentScriptPath)
    $bf = Join-Path $env:TEMP "StereoInstaller_Update.bat"
    $bc = "@echo off`ntimeout /t 2 /nobreak >nul`ncopy /Y `"$UpdatedScriptPath`" `"$CurrentScriptPath`" >nul`ntimeout /t 1 /nobreak >nul`npowershell.exe -ExecutionPolicy Bypass -File `"$CurrentScriptPath`"`ndel `"$UpdatedScriptPath`" >nul 2>&1`n(goto) 2>nul & del `"%~f0`""
    $bc | Out-File $bf -Encoding ASCII -Force
    Start-Process "cmd.exe" -ArgumentList "/c","`"$bf`"" -WindowStyle Hidden
}

# === SILENT / CHECK-ONLY MODE ===
if ($Silent -or $CheckOnly) {
    $ic = Get-InstalledClients
    if ($ic.Count -eq 0) { Write-Host "No Discord clients found."; exit 1 }
    
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
    
    if ($FixClient) { $ic = @($ic | ? { $_.Name -like "*$FixClient*" }); if ($ic.Count -eq 0) { Write-Host "Client '$FixClient' not found."; exit 1 } }
    
    $up = @{}; $uc = [System.Collections.ArrayList]@()
    foreach ($c in $ic) { if (-not $up.ContainsKey($c.AppPath)) { $up[$c.AppPath] = $true; [void]$uc.Add($c) } }
    
    Write-Host "Found $($uc.Count) client(s)"
    $td = Join-Path $env:TEMP "StereoInstaller_$(Get-Random)"; EnsureDir $td
    
    try {
        $vbp = Join-Path $td "VoiceBackup"; 
        if (-not (Download-VoiceBackupFiles $vbp $null $null)) { throw "Download Failed" }
        
        $allProcs = @("Discord","DiscordCanary","DiscordPTB","DiscordDevelopment","Lightcord","BetterVencord","Equicord","Vencord","Update")
        Stop-DiscordProcesses $allProcs; Start-Sleep -Seconds 1
        $set = Load-Settings; $fxc = 0
        
        foreach ($ci in $uc) {
            $cl = $ci.Client; $ap = $ci.AppPath; $av = Get-DiscordAppVersion $ap
            Write-Host "Fixing $($cl.Name.Trim()) v$av..."
            try {
                $vm = gci "$ap\modules" -Filter "discord_voice*" -Directory | Select-Object -First 1
                if (-not $vm) { throw "No voice module found" }
                $tvf = if (Test-Path "$($vm.FullName)\discord_voice") { "$($vm.FullName)\discord_voice" } else { $vm.FullName }
                
                Create-VoiceBackup $tvf $cl.Name $av $null $null | Out-Null
                if (Test-Path $tvf) { Remove-Item "$tvf\*" -Recurse -Force -EA SilentlyContinue } else { EnsureDir $tvf }
                Copy-Item "$vbp\*" $tvf -Recurse -Force
                Save-FixState $cl.Name $av; Write-Host "  [OK] Fixed successfully"; $fxc++
            } catch { Write-Host "  [FAIL] $($_.Exception.Message)" }
        }
        
        Remove-OldBackups
        if ($set.AutoStartDiscord -and $fxc -gt 0) { $pc = $uc[0]; $de = Join-Path $pc.AppPath $pc.Client.Exe; Start-DiscordClient $de; Write-Host "Discord started." }
        Write-Host "Fixed $fxc of $($uc.Count) client(s)"; exit 0
    } finally { if (Test-Path $td) { Remove-Item $td -Recurse -Force -EA SilentlyContinue } }
}

# === GUI MODE ===
$settings = Load-Settings

# Main Form
$form = New-Object System.Windows.Forms.Form
$form.Text = "Stereo Installer"; $form.Size = New-Object System.Drawing.Size(520,650)
$form.StartPosition = "CenterScreen"; $form.FormBorderStyle = "FixedDialog"; $form.MaximizeBox = $false
$form.BackColor = $Theme.Background; $form.TopMost = $true

# Title & Credits
$titleLabel = New-StyledLabel 20 15 460 35 "Stereo Installer" $Fonts.Title $Theme.TextPrimary "MiddleCenter"
$form.Controls.Add($titleLabel)
$creditsLabel = New-StyledLabel 20 52 460 28 "Made by`r`nOracle | Shaun | Hallow | Ascend | Sentry | Sikimzo | Cypher" $Fonts.Small $Theme.TextSecondary "MiddleCenter"
$form.Controls.Add($creditsLabel)

# Status Labels
$updateStatusLabel = New-StyledLabel 20 82 460 18 "" $Fonts.Small $Theme.Warning "MiddleCenter"; $form.Controls.Add($updateStatusLabel)
$discordRunningLabel = New-StyledLabel 20 100 460 18 "" $Fonts.Small $Theme.Warning "MiddleCenter"; $form.Controls.Add($discordRunningLabel)

# Client Selection Group
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

# Options Group
$optionsGroup = New-Object System.Windows.Forms.GroupBox
$optionsGroup.Location = New-Object System.Drawing.Point(20,190); $optionsGroup.Size = New-Object System.Drawing.Size(460,160)
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
$lblScriptStatus = New-StyledLabel 20 137 420 18 "" $Fonts.Small $Theme.TextSecondary "MiddleLeft"; $optionsGroup.Controls.Add($lblScriptStatus)

# Status Box & Progress
$statusBox = New-Object System.Windows.Forms.RichTextBox
$statusBox.Location = New-Object System.Drawing.Point(20,360); $statusBox.Size = New-Object System.Drawing.Size(460,130)
$statusBox.ReadOnly = $true; $statusBox.BackColor = $Theme.ControlBg; $statusBox.ForeColor = $Theme.TextPrimary
$statusBox.Font = $Fonts.Console; $statusBox.DetectUrls = $false; $statusBox.BorderStyle = "FixedSingle"
$form.Controls.Add($statusBox)

$progressBar = New-Object System.Windows.Forms.ProgressBar
$progressBar.Location = New-Object System.Drawing.Point(20,500); $progressBar.Size = New-Object System.Drawing.Size(460,22)
$progressBar.Style = "Continuous"; $form.Controls.Add($progressBar)

# Buttons
$btnStart = New-StyledButton 20 535 100 38 "Start Fix"; $form.Controls.Add($btnStart)
$btnFixAll = New-StyledButton 125 535 100 38 "Fix All" $Fonts.Button $Theme.Success; $form.Controls.Add($btnFixAll)
$btnRollback = New-StyledButton 230 535 70 38 "Rollback" $Fonts.ButtonSmall $Theme.Secondary; $form.Controls.Add($btnRollback)
$btnOpenBackups = New-StyledButton 305 535 70 38 "Backups" $Fonts.ButtonSmall $Theme.Secondary; $form.Controls.Add($btnOpenBackups)
$btnCheckUpdate = New-StyledButton 380 535 100 38 "Check" $Fonts.ButtonSmall $Theme.Warning; $form.Controls.Add($btnCheckUpdate)

# Helper Functions for GUI
function Update-ScriptStatusLabel {
    if (Test-Path $SAVED_SCRIPT_PATH) {
        $lm = (Get-Item $SAVED_SCRIPT_PATH).LastWriteTime.ToString("MMM dd, HH:mm")
        $lblScriptStatus.Text = "Script saved: $lm"; $lblScriptStatus.ForeColor = $Theme.TextSecondary
    } else {
        $lblScriptStatus.Text = "Script not saved locally (required for startup shortcut)"; $lblScriptStatus.ForeColor = $Theme.Warning
    }
}

function Update-DiscordRunningWarning {
    $dp = @("Discord","DiscordCanary","DiscordPTB","DiscordDevelopment","Lightcord")
    $r = Get-Process -Name $dp -EA SilentlyContinue
    if ($r) { $discordRunningLabel.Text = "[!] Discord is running - it will be closed when you apply the fix"; $discordRunningLabel.Visible = $true }
    else { $discordRunningLabel.Text = ""; $discordRunningLabel.Visible = $false }
}

function Save-CurrentSettings {
    $cs = [PSCustomObject]@{CheckForUpdates=$chkUpdate.Checked; AutoApplyUpdates=$chkAutoUpdate.Checked; CreateShortcut=$chkShortcut.Checked
        AutoStartDiscord=$chkAutoStart.Checked; SilentStartup=$chkSilentStartup.Checked; SelectedClientIndex=$clientCombo.SelectedIndex}
    Save-Settings $cs
}

# Event Handlers
$chkUpdate.Add_CheckedChanged({ $chkAutoUpdate.Enabled = $chkUpdate.Checked; $chkAutoUpdate.Visible = $chkUpdate.Checked; if (-not $chkUpdate.Checked) { $chkAutoUpdate.Checked = $false } })
$chkShortcut.Add_CheckedChanged({ $chkSilentStartup.Enabled = $chkShortcut.Checked; $chkSilentStartup.Visible = $chkShortcut.Checked; if (-not $chkShortcut.Checked) { $chkSilentStartup.Checked = $false } })
$btnSaveScript.Add_Click({ $statusBox.Clear(); $sp = Save-ScriptToAppData $statusBox $form; if ($sp) { Update-ScriptStatusLabel; [System.Windows.Forms.MessageBox]::Show($form,"Script saved to:`n$sp`n`nYou can now create a startup shortcut.","Script Saved","OK","Information") } })
$btnOpenBackups.Add_Click({ Initialize-BackupDirectory; Start-Process "explorer.exe" $BACKUP_ROOT })

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
    $ap = Find-DiscordAppPath $bp; if (-not $ap) { Add-Status $statusBox $form "[X] No Discord installation found" "Red"; return }
    $cv = Get-DiscordAppVersion $ap; Add-Status $statusBox $form "Current version: $cv" "Cyan"
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
})

$btnRollback.Add_Click({
    $statusBox.Clear(); $sc = $DiscordClients[$clientCombo.SelectedIndex]
    Add-Status $statusBox $form "Loading available backups..." "Blue"
    $bks = @(Get-AvailableBackups)  # FIX: Ensure array at call site too
    if ($bks.Count -eq 0) { Add-Status $statusBox $form "[X] No backups found" "Red"; [System.Windows.Forms.MessageBox]::Show($form,"No backups available. Run 'Start Fix' first to create a backup.","No Backups","OK","Information"); return }
    
    $rf = New-Object System.Windows.Forms.Form
    $rf.Text = "Select Backup to Restore"; $rf.Size = New-Object System.Drawing.Size(450,300); $rf.StartPosition = "CenterParent"
    $rf.FormBorderStyle = "FixedDialog"; $rf.MaximizeBox = $false; $rf.MinimizeBox = $false; $rf.BackColor = $Theme.Background; $rf.TopMost = $true
    
    $lb = New-Object System.Windows.Forms.ListBox
    $lb.Location = New-Object System.Drawing.Point(20,20); $lb.Size = New-Object System.Drawing.Size(395,180)
    $lb.BackColor = $Theme.ControlBg; $lb.ForeColor = $Theme.TextPrimary; $lb.Font = $Fonts.Normal
    foreach ($b in $bks) { [void]$lb.Items.Add($b.DisplayName) }; $lb.SelectedIndex = 0; $rf.Controls.Add($lb)
    
    $br = New-StyledButton 120 210 100 35 "Restore"; $bc = New-StyledButton 230 210 100 35 "Cancel" $Fonts.Button $Theme.Secondary
    $rf.Controls.Add($br); $rf.Controls.Add($bc)
    $bc.Add_Click({ $rf.DialogResult = "Cancel"; $rf.Close() }); $br.Add_Click({ $rf.DialogResult = "OK"; $rf.Close() })
    
    $res = $rf.ShowDialog($form)
    if ($res -eq "OK" -and $lb.SelectedIndex -ge 0) {
        $sb = $bks[$lb.SelectedIndex]
        if (-not $sb -or -not $sb.Path) { Add-Status $statusBox $form "[X] Invalid backup selection" "Red"; return }
        Add-Status $statusBox $form "Starting rollback..." "Blue"; Add-Status $statusBox $form "  Selected: $($sb.DisplayName)" "Cyan"
        Add-Status $statusBox $form "Closing Discord processes..." "Blue"; Stop-DiscordProcesses $sc.Processes
        $bp = Get-RealClientPath $sc; if (-not $bp) { Add-Status $statusBox $form "[X] Could not find Discord installation" "Red"; return }
        $ap = Find-DiscordAppPath $bp; if (-not $ap) { Add-Status $statusBox $form "[X] Could not find Discord installation" "Red"; return }
        $vm = gci "$ap\modules" -Filter "discord_voice*" -Directory | Select-Object -First 1
        if (-not $vm) { Add-Status $statusBox $form "[X] Could not find voice module in Discord installation" "Red"; return }
        $tvf = if (Test-Path "$($vm.FullName)\discord_voice") { "$($vm.FullName)\discord_voice" } else { $vm.FullName }
        
        $suc = Restore-FromBackup $sb $tvf $statusBox $form
        if ($suc) {
            Add-Status $statusBox $form "[OK] Rollback completed successfully" "LimeGreen"
            if ($chkAutoStart.Checked) { Add-Status $statusBox $form "Starting Discord..." "Blue"; $de = Join-Path $ap $sc.Exe; Start-DiscordClient $de; Add-Status $statusBox $form "[OK] Discord started" "LimeGreen" }
            Play-CompletionSound $true; [System.Windows.Forms.MessageBox]::Show($form,"Rollback completed successfully!","Success","OK","Information")
        }
    }
})

$btnStart.Add_Click({
    $btnStart.Enabled = $false; $btnFixAll.Enabled = $false; $btnRollback.Enabled = $false; $btnCheckUpdate.Enabled = $false
    $statusBox.Clear(); $progressBar.Value = 0; $td = Join-Path $env:TEMP "StereoInstaller_$(Get-Random)"
    
    try {
        $sc = $DiscordClients[$clientCombo.SelectedIndex]
        
        # Check for updates
        if ($chkUpdate.Checked) {
            Add-Status $statusBox $form "Checking for script updates..." "Blue"; Update-Progress $progressBar $form 5
            try {
                $cs = $PSCommandPath
                if ([string]::IsNullOrEmpty($cs)) { Add-Status $statusBox $form "[OK] Running latest version from web" "LimeGreen" }
                else {
                    $uf = "$env:TEMP\StereoInstaller_Update_$(Get-Random).ps1"
                    Invoke-WebRequest -Uri $UPDATE_URL -OutFile $uf -UseBasicParsing -TimeoutSec 10 | Out-Null
                    $uc = (Get-Content $uf -Raw) -replace "`r`n","`n" -replace "`r","`n"; $cc = (Get-Content $cs -Raw) -replace "`r`n","`n" -replace "`r","`n"
                    $uc = $uc.Trim(); $cc = $cc.Trim()
                    if ($uc -ne $cc) {
                        Add-Status $statusBox $form "New update found!" "Yellow"
                        if ($chkAutoUpdate.Checked) {
                            Add-Status $statusBox $form "Update will be applied after script closes..." "Cyan"
                            Add-Status $statusBox $form "[OK] Update prepared! Restarting in 3 seconds..." "LimeGreen"
                            Start-Sleep -Seconds 3; Apply-ScriptUpdate $uf $cs; $form.Close(); return
                        } else { Add-Status $statusBox $form "Update downloaded to: $uf" "Orange"; Add-Status $statusBox $form "Please manually replace the script file to update." "Orange" }
                    } else { Add-Status $statusBox $form "[OK] You are on the latest version" "LimeGreen"; Remove-Item $uf -EA SilentlyContinue }
                }
            } catch { Add-Status $statusBox $form "[!] Could not check for updates: $($_.Exception.Message)" "Orange" }
        }
        
        # Download files
        Update-Progress $progressBar $form 10; Add-Status $statusBox $form "Downloading required files from GitHub..." "Blue"; EnsureDir $td
        $vbp = Join-Path $td "VoiceBackup"
        $vds = Download-VoiceBackupFiles $vbp $statusBox $form
        if (-not $vds) { throw "Failed to download voice backup files from GitHub" }
        Add-Status $statusBox $form "[OK] Files downloaded successfully" "LimeGreen"; Update-Progress $progressBar $form 30
        
        # Locate Discord
        Add-Status $statusBox $form "Locating Discord installation..." "Blue"
        $bp = Get-RealClientPath $sc; if (-not $bp) { throw "Discord client folder not found. Please ensure it is installed or run Discord so we can detect the path." }
        Add-Status $statusBox $form "Path detected: $bp" "Cyan"
        $ap = Find-DiscordAppPath $bp; if (-not $ap) { throw "No Discord app folder with voice module found in $bp" }
        $av = Get-DiscordAppVersion $ap; Add-Status $statusBox $form "[OK] Found $($sc.Name) v$av" "LimeGreen"
        
        # Stop Discord
        Add-Status $statusBox $form "Closing Discord processes..." "Blue"
        $ka = Stop-DiscordProcesses $sc.Processes
        if ($ka) { Add-Status $statusBox $form "  Discord processes terminated" "Cyan" } else { Add-Status $statusBox $form "  No Discord processes were running" "Yellow" }
        Update-Progress $progressBar $form 40; Add-Status $statusBox $form "[OK] Discord processes closed" "LimeGreen"; Update-Progress $progressBar $form 50
        
        # Locate voice module
        Add-Status $statusBox $form "Locating voice module..." "Blue"
        $vm = gci "$ap\modules" -Filter "discord_voice*" -Directory | Select-Object -First 1
        if (-not $vm) { throw "No discord_voice module found" }
        $tvf = if (Test-Path "$($vm.FullName)\discord_voice") { "$($vm.FullName)\discord_voice" } else { $vm.FullName }
        Add-Status $statusBox $form "[OK] Voice module located" "LimeGreen"; Update-Progress $progressBar $form 55
        
        # Backup & Apply fix
        Add-Status $statusBox $form "Creating backup of current files..." "Blue"
        Create-VoiceBackup $tvf $sc.Name $av $statusBox $form | Out-Null; Remove-OldBackups; Update-Progress $progressBar $form 60
        
        Add-Status $statusBox $form "Removing old voice module files..." "Blue"
        if (Test-Path $tvf) { Remove-Item "$tvf\*" -Recurse -Force -EA SilentlyContinue } else { EnsureDir $tvf }
        Add-Status $statusBox $form "[OK] Old files removed" "LimeGreen"; Update-Progress $progressBar $form 70
        
        Add-Status $statusBox $form "Copying updated module files..." "Blue"
        Copy-Item "$vbp\*" $tvf -Recurse -Force; Add-Status $statusBox $form "[OK] Module files copied" "LimeGreen"; Update-Progress $progressBar $form 85
        
        Save-FixState $sc.Name $av
        
        # Startup shortcut
        if ($chkShortcut.Checked) {
            Add-Status $statusBox $form "Creating startup shortcut..." "Blue"
            $spt = $SAVED_SCRIPT_PATH; if (!(Test-Path $spt)) { $spt = Save-ScriptToAppData $statusBox $form }
            if ($spt) { Create-StartupShortcut $spt $chkSilentStartup.Checked; Add-Status $statusBox $form "[OK] Startup shortcut created" "LimeGreen" }
            else { Add-Status $statusBox $form "[!] Could not save script - shortcut not created" "Orange" }
        } else { Remove-StartupShortcut }
        Update-Progress $progressBar $form 90
        
        # Start Discord
        if ($chkAutoStart.Checked) {
            Add-Status $statusBox $form "Starting Discord..." "Blue"; $de = Join-Path $ap $sc.Exe; $st = Start-DiscordClient $de
            if (-not $st -and $sc.FallbackPath) { $fa = Find-DiscordAppPath $sc.FallbackPath; if ($fa) { $ae = Join-Path $fa $sc.Exe; $st = Start-DiscordClient $ae; if ($st) { Add-Status $statusBox $form "[OK] Discord started (from alternate location)" "LimeGreen" } } }
            elseif ($st) { Add-Status $statusBox $form "[OK] Discord started" "LimeGreen" }
            if (-not $st) { Add-Status $statusBox $form "[!] Could not find Discord executable" "Orange" }
        }
        
        # Complete
        Update-Progress $progressBar $form 100
        $updateStatusLabel.Text = "Last fixed: $(Get-Date -Format 'MMM dd, yyyy HH:mm') (v$av)"; $updateStatusLabel.ForeColor = $Theme.TextSecondary
        Add-Status $statusBox $form "" "White"; Add-Status $statusBox $form "=== ALL TASKS COMPLETED ===" "LimeGreen"
        Play-CompletionSound $true; Save-CurrentSettings
        [System.Windows.Forms.MessageBox]::Show($form,"Discord voice module fix completed successfully!`n`nA backup was created in case you need to rollback.","Success","OK","Information")
        $form.Close()
    } catch {
        Add-Status $statusBox $form "" "White"; Add-Status $statusBox $form "[X] ERROR: $($_.Exception.Message)" "Red"
        Play-CompletionSound $false; [System.Windows.Forms.MessageBox]::Show($form,"An error occurred: $($_.Exception.Message)","Error","OK","Error")
    } finally {
        if (Test-Path $td) { Remove-Item $td -Recurse -Force -EA SilentlyContinue }
        $btnStart.Enabled = $true; $btnFixAll.Enabled = $true; $btnRollback.Enabled = $true; $btnCheckUpdate.Enabled = $true
    }
})

$btnFixAll.Add_Click({
    $btnStart.Enabled = $false; $btnFixAll.Enabled = $false; $btnRollback.Enabled = $false; $btnCheckUpdate.Enabled = $false
    $statusBox.Clear(); $progressBar.Value = 0; $td = Join-Path $env:TEMP "StereoInstaller_$(Get-Random)"
    
    try {
        Add-Status $statusBox $form "Scanning for installed Discord clients..." "Blue"
        $ic = Get-InstalledClients
        if ($ic.Count -eq 0) {
            Add-Status $statusBox $form "[X] No Discord clients found!" "Red"; Add-Status $statusBox $form "    Ensure Discord is installed or currently running." "Yellow"
            [System.Windows.Forms.MessageBox]::Show($form,"No Discord clients were found on this system.","No Clients Found","OK","Warning"); return
        }
        
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
        Stop-DiscordProcesses $allProcs; Add-Status $statusBox $form "[OK] Discord processes closed" "LimeGreen"; Update-Progress $progressBar $form 30
        
        $ppc = 60 / $uc.Count; $cp = 30; $fxc = 0; $fc = @()
        foreach ($ci in $uc) {
            Add-Status $statusBox $form "" "White"; Add-Status $statusBox $form "=== Fixing: $($ci.Name.Trim()) ===" "Blue"
            try {
                $ap = $ci.AppPath; $av = Get-DiscordAppVersion $ap
                $vm = gci "$ap\modules" -Filter "discord_voice*" -Directory | Select-Object -First 1
                if (-not $vm) { throw "No discord_voice module found" }
                $tvf = if (Test-Path "$($vm.FullName)\discord_voice") { "$($vm.FullName)\discord_voice" } else { $vm.FullName }
                
                Add-Status $statusBox $form "  Creating backup..." "Cyan"; Create-VoiceBackup $tvf $ci.Name $av $statusBox $form | Out-Null
                if (Test-Path $tvf) { Remove-Item "$tvf\*" -Recurse -Force -EA SilentlyContinue } else { EnsureDir $tvf }
                Add-Status $statusBox $form "  Copying module files..." "Cyan"; Copy-Item "$vbp\*" $tvf -Recurse -Force
                
                Save-FixState $ci.Name $av; Add-Status $statusBox $form "[OK] $($ci.Name.Trim()) fixed successfully" "LimeGreen"; $fxc++
            } catch { Add-Status $statusBox $form "[X] Failed to fix $($ci.Name.Trim()): $($_.Exception.Message)" "Red"; $fc += $ci.Name }
            $cp += $ppc; Update-Progress $progressBar $form ([int]$cp)
        }
        
        Remove-OldBackups; Update-Progress $progressBar $form 95

        # Startup shortcut logic
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
        else { Play-CompletionSound $true; [System.Windows.Forms.MessageBox]::Show($form,"Successfully fixed all $fxc Discord client(s)!","Success","OK","Information") }
    } catch {
        Add-Status $statusBox $form "" "White"; Add-Status $statusBox $form "[X] ERROR: $($_.Exception.Message)" "Red"
        Play-CompletionSound $false; [System.Windows.Forms.MessageBox]::Show($form,"An error occurred: $($_.Exception.Message)","Error","OK","Error")
    } finally {
        if (Test-Path $td) { Remove-Item $td -Recurse -Force -EA SilentlyContinue }
        $btnStart.Enabled = $true; $btnFixAll.Enabled = $true; $btnRollback.Enabled = $true; $btnCheckUpdate.Enabled = $true
    }
})

# Timer & Form Events
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
