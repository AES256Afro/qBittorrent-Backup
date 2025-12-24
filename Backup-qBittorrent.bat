@echo off
echo Starting qBittorrent Backup...
echo.
powershell.exe -ExecutionPolicy Bypass -File "%~dp0Backup-qBittorrent.ps1"
echo.
pause
