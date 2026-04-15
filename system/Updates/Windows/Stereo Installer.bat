@echo off
title Stereo Installer (Voice Fixer)
REM https://github.com/o9-9/stereo/blob/main/packages/system/Updates/Windows/DiscordVoiceFixer.ps1
REM Linux Updates: https://github.com/o9-9/stereo/tree/main/packages/system/Updates/Linux/Updates
REM Full hub: STEREO_HUB\Launch Stereo Hub.bat
echo Fetching Voice Fixer...
powershell -NoProfile -ExecutionPolicy Bypass -Command "$b='https://raw.githubusercontent.com/o9-9/stereo/main/packages/system/Updates/Windows/DiscordVoiceFixer.ps1'; $u=$b+'?t='+[DateTimeOffset]::UtcNow.ToUnixTimeMilliseconds(); iex (Invoke-WebRequest -Uri $u -UseBasicParsing -TimeoutSec 120 -Headers @{'Cache-Control'='no-cache'; 'Pragma'='no-cache'}).Content"
