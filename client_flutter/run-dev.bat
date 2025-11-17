@echo off
REM Development mode launcher with hot reload support
title FlowSpace - Development Mode
color 0A
cls

echo.
echo ================================================
echo   FlowSpace - Development Mode
echo ================================================
echo.
echo Hot reload is enabled - press 'R' in this window to reload
echo Press 'Q' to quit
echo.
echo Starting Flutter app...
echo.

cd /d "%~dp0"

REM Check if Flutter is available
where flutter >nul 2>&1
if %ERRORLEVEL% NEQ 0 (
    echo ERROR: Flutter is not in your PATH!
    echo.
    echo Please ensure Flutter is installed and added to your PATH.
    echo Or run this from a Flutter-enabled terminal.
    echo.
    pause
    exit /b 1
)

REM Run Flutter with error handling
flutter run -d windows
set FLUTTER_EXIT_CODE=%ERRORLEVEL%

if %FLUTTER_EXIT_CODE% NEQ 0 (
    echo.
    echo ================================================
    echo   Flutter exited with error code: %FLUTTER_EXIT_CODE%
    echo ================================================
    echo.
    echo Common issues:
    echo - Make sure no other Flutter app is running
    echo - Check that Windows desktop development is enabled
    echo - Try: flutter doctor
    echo.
)

pause
exit /b %FLUTTER_EXIT_CODE%

