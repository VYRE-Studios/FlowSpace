@echo off
REM This script will definitely keep the window open
title FlowSpace - Dev Mode (Error Capture)
cd /d "%~dp0"

echo ================================================
echo   FlowSpace Development Mode
echo ================================================
echo.
echo All output will be saved to: flutter-error.log
echo.
echo Starting Flutter app...
echo.

REM Redirect all output to log file AND console
flutter run -d windows 2>&1 | tee flutter-error.log

echo.
echo ================================================
echo Flutter has stopped.
echo ================================================
echo.
echo Check flutter-error.log for full output
echo.
echo Press any key to view the error log...
pause >nul

REM Show the error log
type flutter-error.log
echo.
echo ================================================
echo.
echo Press any key to close...
pause >nul

