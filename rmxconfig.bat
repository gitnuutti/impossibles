@echo off
echo [97;40m [0m 
:: --- Self-elevate if not admin ---
net session >nul 2>&1 || (powershell -NoProfile -WindowStyle Hidden -Command "Start-Process -FilePath '%ComSpec%' -ArgumentList '/c','\"\"%~f0\"\" %*' -Verb RunAs" & exit /b)
	pushd "%~dp0"
	
reg add HKCU\Console /v VirtualTerminalLevel /t REG_DWORD /d 1 /f >nul 2>&1

rem config tool
	rem echo Press a key to start config tool and wait for opening... 
	rem echo --------------------------------------------------------------------------
	echo [97;40m Romexis config tool is starting...[0m 
	echo [97;40m - After changes click in this window and press a key to restart server [0m 
	cd /d "C:\Program Files\Planmeca\Romexis\admin\" 
	call "C:\Program Files\Planmeca\Romexis\admin\RomexisConfig.bat"
	echo [97;40m [0m 
	pause >nul
	pushd "%~dp0"
	PowerShell -NoProfile -ExecutionPolicy Bypass -File "%~dp0rmx-server-restart.ps1"
	pushd "%~dp0"

rem starting Romexis
	echo [97;40m Press a key to start Romexis client - or close this window to exit. [0m 
	pause >nul
	CD /d C:\Program Files\Planmeca\Romexis\client
	echo [97;40m [0m 
	call Romexis.bat
    exit /b