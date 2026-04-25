@echo off
REM web-dev.cmd — double-click to launch web-dev stack.
REM Runs web-dev.ps1 with execution policy bypass and closes itself.
start "" powershell.exe -NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File "C:\source\template-repo\WindowsPowerShell\web-dev.ps1"
exit
