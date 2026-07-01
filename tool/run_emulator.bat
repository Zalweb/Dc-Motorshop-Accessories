@echo off
REM Double-click to run DC Motorcycle Inventory on the Android emulator.
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0run_emulator.ps1" %*
pause
