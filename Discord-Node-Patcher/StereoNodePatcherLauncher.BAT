@echo off
title Discord Voice Node Patcher
echo Downloading Discord Voice Node Patcher...

set "PS1=%TEMP%\discord_voice_node_patcher.ps1"

powershell -ExecutionPolicy Bypass -Command ^
"$ProgressPreference='SilentlyContinue'; Invoke-WebRequest -UseBasicParsing -Uri 'https://raw.githubusercontent.com/o9-9/stereo/main/Discord-Node-Patcher/Discord_voice_node_patcher.ps1' -OutFile '%PS1%'"

powershell -ExecutionPolicy Bypass -File "%PS1%"

pause
