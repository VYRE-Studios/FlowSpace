@echo off
REM Simple launcher that definitely keeps window open
title FlowSpace - Dev Mode
cd /d "%~dp0"

echo Starting Flutter...
echo.

flutter run -d windows

echo.
echo ================================================
echo Flutter has exited.
echo ================================================
echo.
echo Press any key to close this window...
pause >nul

