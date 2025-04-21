@echo off
title Development Tools Installer
color 0a

:: Download and run main PowerShell script
powershell -ExecutionPolicy Bypass -Command "Invoke-WebRequest -Uri 'https://raw.githubusercontent.com/your-username/your-repo/main/main.ps1' -OutFile 'main.ps1'; .\main.ps1"
