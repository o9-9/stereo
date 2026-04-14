@echo off
title Stereo Installer
echo Downloading latest Stereo Installer...
powershell -ExecutionPolicy Bypass -Command "irm https://raw.githubusercontent.com/o9-9/stereo/main/installer/DiscordVoiceFixer.ps1 | iex"
