@echo off
REM Force window to stay open using cmd /k
title FlowSpace - Dev Mode
cd /d "%~dp0"

cmd /k "flutter run -d windows && echo. && echo ================================================ && echo Flutter exited. Check output above for errors. && echo ================================================ && pause"

