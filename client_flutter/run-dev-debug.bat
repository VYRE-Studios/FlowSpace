@echo off
REM Development mode launcher with full error output
title FlowSpace - Development Mode (Debug)
color 0C
cls

echo.
echo ================================================
echo   FlowSpace - Development Mode (Debug)
echo ================================================
echo.
echo This will show all errors and keep window open
echo Output will be saved to: run-output.log
echo.

cd /d "%~dp0"

REM Check if Flutter is available
where flutter >nul 2>&1
if %ERRORLEVEL% NEQ 0 (
    echo ERROR: Flutter is not in your PATH!
    echo.
    pause
    exit /b 1
)

echo Checking Flutter setup...
flutter doctor -v > run-output.log 2>&1
type run-output.log
echo.
echo ================================================
echo.

echo Checking for Windows devices...
flutter devices >> run-output.log 2>&1
type run-output.log | findstr /V "Doctor"
echo.
echo ================================================
echo.

echo Running Flutter app...
echo (All output will be shown below and saved to run-output.log)
echo.
echo ================================================
echo.

REM Run Flutter and capture ALL output to file AND screen
flutter run -d windows -v >> run-output.log 2>&1
set FLUTTER_EXIT_CODE=%ERRORLEVEL%

echo.
echo ================================================
echo   Flutter exited with code: %FLUTTER_EXIT_CODE%
echo ================================================
echo.
echo Showing last 50 lines of output:
echo.
powershell -Command "Get-Content run-output.log -Tail 50"
echo.
echo ================================================
echo Full output saved to: %CD%\run-output.log
echo.
echo Press any key to exit...
pause >nul
exit /b %FLUTTER_EXIT_CODE%

