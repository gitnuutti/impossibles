@ECHO OFF
rem nuutti date.version 1311.1

rem set ps script execution policy current user
powershell -Command "Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser -Force"

title ASENTAJA User - %~dp0

setlocal EnableExtensions EnableDelayedExpansion
REM Ensure we're working in the script's directory
pushd "%~dp0"

powershell -NoProfile -Command "$Host.UI.RawUI.BackgroundColor='Black';$Host.UI.RawUI.ForegroundColor='Gray';Clear-Host"
color 07

start "" "%~dp0startr_admin.bat"
	
REM Clean up any leftover flag files from previous runs
if exist "%~dp0.asentaja_admin_ready" del "%~dp0.asentaja_admin_ready" 2>nul
if exist "%~dp0.download_complete" del "%~dp0.download_complete" 2>nul

rem set vterm and title to window header
reg add HKCU\Console /v VirtualTerminalLevel /t REG_DWORD /d 1 /f >nul 2>&1

REM set position, size, and show window
set xpos=10
set ypos=20
set width=720
set height=950
powershell -NoProfile -Command "Add-Type -Namespace Native -Name Win32 -MemberDefinition '[DllImport(\"kernel32.dll\")] public static extern IntPtr GetConsoleWindow(); [DllImport(\"user32.dll\")] public static extern bool MoveWindow(IntPtr hWnd, int X, int Y, int nWidth, int nHeight, bool bRepaint); [DllImport(\"user32.dll\")] public static extern bool ShowWindow(IntPtr hWnd, int nCmdShow);'; $hWnd = [Native.Win32]::GetConsoleWindow(); [Native.Win32]::ShowWindow($hWnd, 9) | Out-Null; [Native.Win32]::MoveWindow($hWnd, %xpos%, %ypos%, %width%, %height%, $true) | Out-Null"

REM Ensure we're working in the script's directory
pushd "%~dp0"

rem check if running as admin
net session >nul 2>&1
if %errorlevel% == 0 (
	echo --------------------------------------------------------------------------
	echo.
	echo.
    echo.
	echo   Do not use "run as admin" to start ASENTAJA:
	echo.
	echo   it must be started as a domain user for access to installers in M-drive 
	echo   - after the start, it will ask elevation for an admin tasks
	echo   - press a key to exit
	echo.
	echo.
    echo.
	echo --------------------------------------------------------------------------
    pause >nul
    exit /b 1
)


rem set vterm and title to window header
reg add HKCU\Console /v VirtualTerminalLevel /t REG_DWORD /d 1 /f >nul 2>&1
title ASENTAJA user - %~dp0

REM Clean up any leftover flag files from previous runs
if exist "%~dp0.asentaja_admin_ready" del "%~dp0.asentaja_admin_ready" 2>nul
if exist "%~dp0.download_complete" del "%~dp0.download_complete" 2>nul

rem wait to avoid UAC disturbing user before this script shows.

echo --------------------------------------------------------------------------
echo.
echo.
echo.
echo     Waiting for admin sign-in dialog pops up...
echo.
echo.   
echo --------------------------------------------------------------------------
timeout /t 5 /nobreak >nul
echo. 
cls

REM Ensure we're working in the script's directory
pushd "%~dp0"
:UPCONFIG
REM ============================================================================
REM PHASE 1: LOAD CONFIGURATION
REM ============================================================================
REM Load variables from configuration file
for /f "tokens=1,2 delims==" %%a in ('findstr /OFFLINE /v "^#; " "%~dp0variables.txt"') do (
    set "%%a=%%b"
)

REM Set download folder path with expanded environment variables
call set "abs_download_to=%installers_download_to%"
call set "abs_extract_to=%installers_extract_to%"
REM Create download folder if it doesn't exist
md "%abs_download_to%" >nul 2>nul
set "COMPLETION_FLAG=%~dp0.download_complete"
REM Delete old completion flag
if exist "%~dp0.download_complete" del "%~dp0.download_complete"



REM ============================================================================
REM PHASE 2: START SCREEN
REM ============================================================================

echo.
echo [97;100m                                                                           [0m
echo [97;100m     ASENTAJA  -  Install options and download                             [0m
echo [97;100m                                                                           [0m
echo.
echo.
REM Show latest available versions from network folder
:STARTAGAIN
echo [93;40m Latest installers in network folder:[0m
echo --------------------------------------------------------------------------
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0LATEST.ps1"
echo(
echo [93;40m Installed versions:[0m
echo --------------------------------------------------------------------------
echo. Set by installers - showing in windows control panel/apps:
rem echo.
call "%~dp0ShowApps.bat"
echo.
echo. Exe/jar file versions:
rem echo.
call "%~dp0BinFileVersions-Call.bat"

REM ============================================================================
REM PHASE 3: GET USER'S INSTALL CHOICE
REM ============================================================================
echo.
echo [93;40m Select an installation option: [0m
echo --------------------------------------------------------------------------

echo   NEW install
echo   1. Romexis with DEFAULT options
echo   2. ALL APPS: Romexis, CAD, Smart Lite, Smart Relu and OrthoSim, no Ceph
echo   3. Romexis with all OPTIONS, incl Ceph.
echo.
echo.  UPDATE install
echo   4. Romexis BETA
echo   5. All apps BETA
echo   6. Romexis to a NEW RELEASE - first set new version with option 8
echo.  
echo.  OTHER
echo   7. Uninstall Romexis - CAD and Ceph manually. Restart PC after.
echo   8. SETTINGS: Edit installer version digits in find/download filter
echo   9. EXIT
echo.


CHOICE /C 123456789d /N /M "  Selected option ->"
set choice=%errorlevel%
if %choice%==0 set choice=2
set install_option=%choice%

if "%choice%"=="7" (
    echo.
	echo|set /p="%choice%" > "%~dp0.download_complete"
	goto GOTOADM
)

if "%choice%"=="8" (
    echo.
	echo   Opening SETTINGS in variables.txt for editing in notepad
    echo.     
    echo   Note: Use "save" in notepad file menu after edit before closing it...
	timeout /t 2 /nobreak >nul
    echo __________________________________________________________________________
	echo. 
    start "" /wait notepad "%~dp0variables.txt"
    echo   Showing latest versions matching the new version filter...
	timeout /t 2 /nobreak >nul
	rem cls
	goto UPCONFIG
)

if "%choice%"=="9" (
    echo Exiting
    echo|set /p="EXIT" > "%~dp0.download_complete"
	timeout /t 2 /nobreak >nul
	taskkill /FI "WINDOWTITLE eq ASENTAJA user" /F >nul 2>&1
	taskkill /FI "WINDOWTITLE eq c:\windows\system32\cmd.exe" /F >nul 2>&1
	exit /b
)

if "%choice%"=="d" (
    echo download selected
    goto RETRY_DOWNLOAD
	timeout /t 2 /nobreak >nul
	exit /b
)

echo.
echo.
echo [97;100m                                                                           [0m
echo [97;100m  Installations will complete silently                                     [0m
echo [97;100m                                                                           [0m
echo.

REM ============================================================================
REM PHASE 5: DOWNLOAD INSTALLERS (as domain user with network access)
REM ============================================================================

:RETRY_DOWNLOAD
echo   Downloading to %installers_download_to%
echo --------------------------------------------------------------------------
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0DLNEW.ps1"

REM Check if any zip files exist
dir /b "%abs_download_to%\*.zip" >nul 2>&1
if %errorlevel% GTR 0 (
    echo.
    echo   ERROR: No installer files found in download folder!
	timeout /t 5 /nobreak >nul
    echo.
    echo|set /p="EXIT" > "%~dp0.download_complete"
    exit /b 1
)

echo.
echo   Extracting to %installers_extract_to%
echo --------------------------------------------------------------------------
call "%~dp0extract_installers.bat"
set "extract_result=%errorlevel%"
if %extract_result%==99 (
    rem echo - Retrying download...
    set "FORCE_REEXTRACT=1"
    goto RETRY_DOWNLOAD
)
if %extract_result% GTR 0 (
    echo Installation cancelled.
	timeout /t 5 /nobreak >nul
    exit /b 1
)

:GOTOADM
REM unblock files after extraction complete
powershell -NoProfile -Command "Get-ChildItem '%abs_download_to%' -Recurse | Unblock-File -ErrorAction SilentlyContinue"

echo|set /p="%choice%" > "%~dp0.download_complete"
echo --------------------------------------------------------------------------
echo.
echo   Opening a new window for running the installers as admin... 
rem set title without path for taskkil to find it
title ASENTAJA user
pause >nul
exit /b