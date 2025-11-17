@echo off
echo Testing Flutter app startup...
cd /d "%~dp0"
flutter run -d windows --verbose 2>&1 | findstr /C:"Error" /C:"Exception" /C:"Failed"
if %ERRORLEVEL% EQU 0 (
    echo.
    echo ERRORS FOUND - see output above
) else (
    echo.
    echo No obvious errors in output
)
pause

