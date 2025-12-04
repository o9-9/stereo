@echo off
setlocal enabledelayedexpansion

set "COLOR_UPDATE=UPDATE"
set "COLOR_ERROR=ERROR"
set "COLOR_SUCCESS=SUCCESS"
set "COLOR_PROCESS=PROCESS"
set "COLOR_DONE=DONE"
set "RESET="

echo [%COLOR_UPDATE%] Checking for updates...

set "updateURL=https://raw.githubusercontent.com/ProdHallow/StereoInstaller/refs/heads/main/installer"
set "tempFile=%temp%\stereo_update.tmp"

echo [%COLOR_UPDATE%] Downloading latest script from GitHub...
powershell -Command "try { Invoke-WebRequest -Uri '%updateURL%' -OutFile '%tempFile%' -UseBasicParsing } catch { exit 1 }"

if not exist "%tempFile%" (
    echo [%COLOR_ERROR%] Failed to download update info.
    pause
    exit /b
)

echo [%COLOR_UPDATE%] Comparing local script to GitHub version...
fc "%tempFile%" "%~f0" >nul
if %errorlevel% NEQ 0 (
    echo [%COLOR_SUCCESS%] New update found! Applying update...
    copy /y "%tempFile%" "%~f0" >nul
    echo [%COLOR_SUCCESS%] Script updated! Restarting...
    del "%tempFile%" >nul 2>&1
    timeout /t 1 >nul
    start "" "%~f0"
    exit /b
) else (
    echo [%COLOR_SUCCESS%] You are already on the latest version.
    del "%tempFile%" >nul 2>&1
)

cls
echo [%COLOR_PROCESS%] ============================
echo [%COLOR_PROCESS%]      Discord Voice Module Auto-Fixer
echo [%COLOR_PROCESS%] ============================%RESET%
echo.

echo [%COLOR_PROCESS%] Quitting Discord...
taskkill /F /IM discord.exe >nul 2>&1
taskkill /F /IM Update.exe >nul 2>&1
timeout /t 1 >nul

set "base=%LOCALAPPDATA%\Discord"
set "appPath="
for /f "delims=" %%A in ('dir "%base%\app-*" /b /ad-h /o-n') do (
    if exist "%base%\%%A\modules" (
        for /d %%B in ("%base%\%%A\modules\discord_voice*") do (
            set "appPath=%base%\%%A"
            goto :foundApp
        )
    )
)
if not defined appPath (
    echo [%COLOR_ERROR%] No app-* folder with voice module found.
    pause
    exit /b
)
:foundApp
echo [%COLOR_SUCCESS%] Using Discord folder: %CYAN%%appPath%%RESET%
echo.

set "voiceModule="
for /D %%C in ("%appPath%\modules\discord_voice*") do (
    set "voiceModule=%%C"
    goto :foundVoice
)
if not defined voiceModule (
    echo [%COLOR_ERROR%] No discord_voice module found.
    pause
    exit /b
)
:foundVoice
if exist "%voiceModule%\discord_voice" (
    set "targetVoiceFolder=%voiceModule%\discord_voice"
) else (
    set "targetVoiceFolder=%voiceModule%"
)

echo [%COLOR_PROCESS%] Removing old voice module files...
if exist "%targetVoiceFolder%" (
    del /q "%targetVoiceFolder%\*" >nul 2>&1
    for /d %%D in ("%targetVoiceFolder%\*") do rd /s /q "%%D" >nul 2>&1
)
timeout /t 1 >nul

set "scriptDir=%~dp0"
set "sourceBackup="
for /d %%F in ("%scriptDir%Discord*Backup") do (
    set "sourceBackup=%%F"
    goto :foundBackup
)
echo [%COLOR_ERROR%] Backup folder not found next to the script.
pause
exit /b
:foundBackup
echo [%COLOR_SUCCESS%] Backup folder: %sourceBackup%
echo.

echo [%COLOR_PROCESS%] Copying updated module files...
robocopy "%sourceBackup%" "%targetVoiceFolder%" /MIR /COPY:DAT /R:2 /W:2 /NJH /NJS /NFL /NDL /NC /NS >nul 2>&1
call :progressBar "Updating module files..."

set "ffmpegSource="
for /r "%scriptDir%" %%F in (ffmpeg.dll) do (
    set "ffmpegSource=%%F"
    goto :foundFFMPEG
)
echo [%COLOR_ERROR%] ffmpeg.dll not found.
pause
exit /b
:foundFFMPEG
echo [%COLOR_SUCCESS%] ffmpeg.dll found at %ffmpegSource%
set "ffmpegTarget=%appPath%\ffmpeg.dll"
copy /y "%ffmpegSource%" "%ffmpegTarget%" >nul
if %errorlevel%==0 (
    echo [%COLOR_SUCCESS%] ffmpeg.dll replaced.
) else (
    echo [%COLOR_ERROR%] Failed to copy ffmpeg.dll.
)

echo [%COLOR_PROCESS%] Creating startup shortcut...
set "startupFolder=%APPDATA%\Microsoft\Windows\Start Menu\Programs\Startup"
set "shortcutPath=%startupFolder%\DiscordVoiceFixer.lnk"
set "batchPath=%~f0"

set "vbsFile=%temp%\createShortcut.vbs"
(
echo Set WshShell = WScript.CreateObject("WScript.Shell"^)
echo Set Shortcut = WshShell.CreateShortcut("%shortcutPath%"^)
echo Shortcut.TargetPath = "%batchPath%"
echo Shortcut.WorkingDirectory = "%~dp0"
echo Shortcut.WindowStyle = 1
echo Shortcut.Save
) > "%vbsFile%"

cscript //nologo "%vbsFile%" >nul
del "%vbsFile%" >nul

echo [%COLOR_SUCCESS%] Startup shortcut created.
echo.

echo [%COLOR_PROCESS%] Starting Discord...
start "" /b "%appPath%\Discord.exe"

echo [%COLOR_DONE%] All tasks completed.
timeout /t 2 >nul
exit /b

:progressBar
setlocal
set "msg=%~1"
if "%msg%"=="" set "msg=Working..."
set "bar="
for /l %%A in (1,1,25) do (
    set "bar=!bar!█"
    <nul set /p "= %COLOR_PROCESS%[!bar!] %RESET% %msg%`r"
    ping -n 1 -w 50 127.0.0.1 >nul
)
echo.
endlocal
exit /b
