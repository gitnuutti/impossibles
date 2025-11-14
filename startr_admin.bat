@ECHO OFF
rem nuutti date.version 1311.1

REM minimize its window before elevation request
powershell -NoProfile -Command "Add-Type -Namespace Native -Name Win32 -MemberDefinition '[DllImport(\"kernel32.dll\")] public static extern IntPtr GetConsoleWindow(); [DllImport(\"user32.dll\")] public static extern bool ShowWindow(IntPtr hWnd, int nCmdShow);'; $hWnd = [Native.Win32]::GetConsoleWindow(); [Native.Win32]::ShowWindow($hWnd, 6) | Out-Null" 2>nul

REM starts to UAC screen
net session >nul 2>&1 || (
    powershell -NoProfile -WindowStyle Hidden -Command "Start-Process '%~f0' -Verb RunAs" 2>nul
    exit /b
)

rem set ps script execution policy for current user
powershell -Command "Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser -Force"

rem reset colors
color 07 2>nul
cls

rem set the title to avoid being killed as a tmp UAC launcher
title ASENTAJA Admin - %~dp0

rem kill the tmp UAC launcher sessions
rem taskkill /FI "WINDOWTITLE eq c:\windows\system32\cmd.exe" /F >nul 2>&1

rem set vterm
reg add HKCU\Console /v VirtualTerminalLevel /t REG_DWORD /d 1 /f >nul 2>&1

REM minimize its window after user signed the elevation request
REM ============================================================================================
powershell -NoProfile -Command "Add-Type -Namespace Native -Name Win32 -MemberDefinition '[DllImport(\"kernel32.dll\")] public static extern IntPtr GetConsoleWindow(); [DllImport(\"user32.dll\")] public static extern bool ShowWindow(IntPtr hWnd, int nCmdShow);'; $hWnd = [Native.Win32]::GetConsoleWindow(); [Native.Win32]::ShowWindow($hWnd, 6) | Out-Null" 2>nul
REM ============================================================================================

REM Clean up any leftover flag files from previous runs
if exist "%~dp0.asentaja_admin_ready" del "%~dp0.asentaja_admin_ready" 2>nul
if exist "%~dp0.download_complete" del "%~dp0.download_complete" 2>nul

setlocal EnableExtensions EnableDelayedExpansion
REM Loading variables
REM ============================================================================================
for /f "tokens=1,2 delims==" %%a in ('findstr /v "^#; " "%~dp0variables.txt"') do (
    set "%%a=%%b"
)

rem copies paths to abs variables, a remainder from history
call set "abs_download_to=%installers_download_to%"
call set "abs_extract_to=%installers_extract_to%"

set "COMPLETION_FLAG=%~dp0.download_complete"
call set "abs_romexis_extract_to=%Romexis_extract_to%"
call set "abs_smartlite_extract_to=%SmartLite_extract_to%"
call set "abs_smart_extract_to=%Smart_extract_to%"
call set "abs_ortho_extract_to=%OrthoSimulator_extract_to%"


REM Create download and extract folders with admin privileges
REM ============================================================================================
md "%abs_download_to%" >nul 2>nul
md "%abs_extract_to%" >nul 2>nul


REM Grant Everyone full control (so any user can write)
icacls "%abs_download_to%" /grant Everyone:(OI)(CI)F /T /Q >nul 2>nul
icacls "%abs_extract_to%" /grant Everyone:(OI)(CI)F /T /Q >nul 2>nul

REM Grant Users group full control
icacls "%abs_download_to%" /grant Users:(OI)(CI)F /T /Q >nul 2>nul
icacls "%abs_extract_to%" /grant Users:(OI)(CI)F /T /Q >nul 2>nul


REM Polling for completion flag "EXTRACT" from user script. If user choice seleted EXIT then exit
REM ============================================================================================
:WAIT_EXTRACT
if exist "%COMPLETION_FLAG%" (
    set /p choice=<"%COMPLETION_FLAG%"
    if "!choice!"=="EXIT" (
        del "%COMPLETION_FLAG%" 2>nul
        exit /b 0
    )
    del "%COMPLETION_FLAG%" 2>nul
    goto EXTRACT_COMPLETE
)
timeout /t 1 /nobreak >nul
goto WAIT_EXTRACT
:EXTRACT_COMPLETE
timeout /t 1 /nobreak >nul
============================================================================================
rem kill the tmp UAC launcher sessions
taskkill /FI "WINDOWTITLE eq c:\windows\system32\cmd.exe" /F >nul 2>&1

REM Unblock extracted files - zone info
if defined Romexis_extract_to (
    if exist "%Romexis_extract_to%" (
        powershell -NoProfile -Command "Get-ChildItem -LiteralPath '%Romexis_extract_to%' -Recurse -ErrorAction SilentlyContinue | Unblock-File -ErrorAction SilentlyContinue" 2>nul
    )
)

if defined ASENTAJA_DIR (
    if exist "%ASENTAJA_DIR%" (
        powershell -NoProfile -Command "Get-ChildItem -LiteralPath '%ASENTAJA_DIR%' -Recurse -ErrorAction SilentlyContinue | Unblock-File -ErrorAction SilentlyContinue" 2>nul
    )
)

REM ========================================================================
REM Pops up the cript window after receiving the flag installers available
REM ========================================================================
set xpos=730
set ypos=20
set width=720
set height=950

powershell -NoProfile -Command "Add-Type -Namespace Native -Name Win32 -MemberDefinition '[DllImport(\"kernel32.dll\")] public static extern IntPtr GetConsoleWindow(); [DllImport(\"user32.dll\")] public static extern bool MoveWindow(IntPtr hWnd, int X, int Y, int nWidth, int nHeight, bool bRepaint); [DllImport(\"user32.dll\")] public static extern bool ShowWindow(IntPtr hWnd, int nCmdShow);'; $hWnd = [Native.Win32]::GetConsoleWindow(); [Native.Win32]::ShowWindow($hWnd, 9) | Out-Null; [Native.Win32]::MoveWindow($hWnd, %xpos%, %ypos%, %width%, %height%, $true) | Out-Null"  2>nul

echo(
echo(
echo   ASENTAJA - Running installers in background, upto 20 minutes.
echo(                                                   
if "%choice%"=="1" (
    echo   Installing ROMEXIS with default options
	echo __________________________________________________________________________
    copy "%~dp0dpend\Record_ISS\r-new.iss" "%abs_romexis_extract_to%\setup.iss" /y >nul 2>nul
	set "otherup=no"
	set "othernew=no"
    goto CONTINUE_INSTALL
)

if "%choice%"=="2" (
    echo   Installing ALL APPS
	echo __________________________________________________________________________
    echo(
	echo  - Installing Romexis
	copy "%~dp0dpend\Record_ISS\rc-new.iss" "%abs_romexis_extract_to%\setup.iss" /y >nul 2>nul
    certutil -addstore -f "TrustedPublisher" "%~dp0dpend\certificates\planmeca-cad.cer" >nul 2>nul
    certutil -addstore -enterprise -f "TrustedPublisher" "%~dp0dpend\certificates\planmeca-cad.cer" >nul 2>nul
    set "othernew=yes"
	set "othernup=no"
    goto CONTINUE_INSTALL
)

if "%choice%"=="3" (
    echo   Installing Romexis with all OPTIONS
	echo __________________________________________________________________________
    copy "%~dp0dpend\Record_ISS\r-new-all.iss" "%abs_romexis_extract_to%\setup.iss" /y >nul 2>nul
    certutil -addstore -f "TrustedPublisher" "%~dp0dpend\certificates\planmeca-cad.cer" >nul 2>nul
    certutil -addstore -enterprise -f "TrustedPublisher" "%~dp0dpend\certificates\planmeca-cad.cer" >nul 2>nul
    set "othernew=no"
	set "othernup=no"
    goto CONTINUE_INSTALL
)

if "%choice%"=="4" (
    echo   Updating Romexis BETA
	echo __________________________________________________________________________
    copy "%~dp0dpend\Record_ISS\r-up.iss" "%abs_romexis_extract_to%\setup.iss" /y >nul 2>nul
    certutil -addstore -f "TrustedPublisher" "%~dp0dpend\certificates\planmeca-cad.cer" >nul 2>nul
    certutil -addstore -enterprise -f "TrustedPublisher" "%~dp0dpend\certificates\planmeca-cad.cer" >nul 2>nul
	set "otherup=no"
	set "othernew=no"
    goto CONTINUE_INSTALL
)

if "%choice%"=="5" (
    echo   All APPS to latest BETA: Romexis, Smarts and OrthosSimulator 
	echo __________________________________________________________________________
	echo(
	echo  - Updating Romexis
    copy "%~dp0dpend\Record_ISS\rc-up.iss" "%abs_romexis_extract_to%\setup.iss" /y >nul 2>nul
    certutil -addstore -f "TrustedPublisher" "%~dp0dpend\certificates\planmeca-cad.cer" >nul 2>nul
    certutil -addstore -enterprise -f "TrustedPublisher" "%~dp0dpend\certificates\planmeca-cad.cer" >nul 2>nul
    set "otherup=yes"
	set "othernew=no"
    goto CONTINUE_INSTALL
)

if "%choice%"=="6" (
    echo   Upgrading Romexis to a NEW RELEASE 
	echo __________________________________________________________________________
    copy "%~dp0dpend\Record_ISS\r-up-all.iss" "%abs_romexis_extract_to%\setup.iss" /y >nul 2>nul
    certutil -addstore -f "TrustedPublisher" "%~dp0dpend\certificates\planmeca-cad.cer" >nul 2>nul
    certutil -addstore -enterprise -f "TrustedPublisher" "%~dp0dpend\certificates\planmeca-cad.cer" >nul 2>nul
    set "otherup=no"
	set "othernew=no"
    goto CONTINUE_INSTALL
)

if "%choice%"=="7" (
    echo   Uninstalling ROMEXIS -  RESTART PC after unistalled
	echo __________________________________________________________________________
    copy "%~dp0dpend\Record_ISS\r-uninst.iss" "%abs_romexis_extract_to%\setup.iss" /y >nul 2>nul
	rem set "startRaw=%TIME:~0,8%"
	cd /d "%abs_romexis_extract_to%"
	start /wait "" "%abs_romexis_extract_to%\setup.exe" /s /SMS f1"%abs_romexis_extract_to%\setup.iss"
	pushd "%~dp0" 
	echo.
	echo  ROMEXIS uninstalled
	echo.
    taskkill /FI "WINDOWTITLE eq ASENTAJA user" /F >nul 2>&1
	taskkill /FI "WINDOWTITLE eq c:\windows\system32\cmd.exe" /F >nul 2>&1
    goto FINAL
)

REM if "%choice%"=="8" (
    REM echo   Edited release digits in variables for install/update another release
    REM echo.    
    REM echo   Here again if needed: Opening variables.txt for editing...
    REM echo __________________________________________________________________________
    REM start "" /wait notepad "%~dp0variables.txt"
    REM echo   File closed. Press a key to exit.
    REM pause >nul
    REM taskkill /FI "WINDOWTITLE eq ASENTAJA user" /F >nul 2>&1
	REM taskkill /FI "WINDOWTITLE eq c:\windows\system32\cmd.exe" /F >nul 2>&1
    REM exit /b
REM )

:CONTINUE_INSTALL
REM Romexis installer execution - common for all Romexis installs/updates, case specific setup.iss file
REM ===============================================================================================
echo(

REM Check for pending file rename operations
rem echo Checking for pending reboot operations...
reg query "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager" /v PendingFileRenameOperations >nul 2>&1
if %errorlevel% == 0 (
    echo.
	echo.
	echo  Windows requires a reboot before Romexis installation can continue. 
	echo  __________________________________________________________________________  
    pause
    exit /b 1
)
rem echo No pending operations detected. Proceeding with installation...
echo(

set "startRaw=%TIME:~0,8%"
cd /d "%abs_romexis_extract_to%"
start /wait "" "%abs_romexis_extract_to%\setup.exe" /s /SMS f1"%abs_romexis_extract_to%\setup.iss"

rem echo  - Installer completed
pushd "%~dp0" 

REM post install actions
REM ===============================================================================================
rem echo  - Setting debug configuration and license
copy "%~dp0dpend\RMX-License\romexis.lic" "C:\Program Files\Planmeca\Romexis\sconfig\" >nul
timeout 1 >nul
echo  - Setting debug logging and license
echo(
rem reset colors
color 07 2>nul
PowerShell -NoProfile -ExecutionPolicy Bypass -File "%~dp0rmx-post.ps1"
pushd "%~dp0"
set "endRaw=%TIME:~0,8%"
call :GetDuration %startRaw% %endRaw%
echo(
echo  Romexis installation completed in %durationStr% mm:ss
echo __________________________________________________________________________                                  
if "%othernew%"=="no" if "%otherup%"=="no" goto FINAL

if "!othernew!"=="yes" (
	set "startRawOther=!TIME:~0,8!"
	set "showOtherDuration=yes"
	rem echo   SMART LITE, SMART RELU, ORTHOSIMULATOR
	REM echo(
	echo   - Installing Smart Lite
    pushd "%~dp0"
    copy dpend\Record_ISS\new_smartlite.iss "%abs_smartlite_extract_to%\setup.iss" /y >nul 2>nul
    cd /d "%abs_smartlite_extract_to%"
    start /wait "" "%abs_smartlite_extract_to%\Romexis_Smart_Lite_Installer.exe" /s /SMS /f1"%abs_smartlite_extract_to%\setup.iss"
    echo   - Installing Smart Relu
    pushd "%~dp0"
    copy dpend\Record_ISS\new_relusmart.iss "%abs_smart_extract_to%\setup.iss" /y >nul 2>nul
    cd /d "%abs_smart_extract_to%"
    start /wait "" "%abs_smart_extract_to%\Romexis_Smart_Installer.exe" /s /SMS /f1"%abs_smart_extract_to%\setup.iss"
	echo   - Installing OrthoSimulator
    pushd "%~dp0"
    copy dpend\Record_ISS\new_orthosim.iss "%abs_ortho_extract_to%\setup.iss" /y >nul 2>nul
    cd /d "%abs_ortho_extract_to%"
    start /wait "" "%abs_ortho_extract_to%\Romexis_Ortho_Simulator_Installer.exe" /s /SMS /f1"%abs_ortho_extract_to%\setup.iss"
    pushd "%~dp0"
	
	set "endRawOther=!TIME:~0,8!"
	call :GetDurationOther !startRawOther! !endRawOther!
	goto AFTER_OTHER_INSTALLS
)

if "!otherup!"=="yes" (
	set "startRawOther=!TIME:~0,8!"
	set "showOtherDuration=yes" 
	REM echo   SMART LITE, SMART RELU, ORTHOSIMULATOR
	REM echo(
	echo   - Updating Smart Lite
    pushd "%~dp0"
    copy dpend\Record_ISS\up_smartlite.iss "%abs_smartlite_extract_to%\setup.iss" /y >nul 2>nul
    cd /d "%abs_smartlite_extract_to%"
    start /wait "" "%abs_smartlite_extract_to%\Romexis_Smart_Lite_Installer.exe" /s /SMS /f1"%abs_smartlite_extract_to%\setup.iss"
	echo   - Updating Smart Relu
    pushd "%~dp0"
    copy dpend\Record_ISS\up_relusmart.iss "%abs_smart_extract_to%\setup.iss" /y >nul 2>nul
    cd /d "%abs_smart_extract_to%"
    start /wait "" "%abs_smart_extract_to%\Romexis_Smart_Installer.exe" /s /SMS /f1"%abs_smart_extract_to%\setup.iss"
	echo   - Updating OrthoSimulator
    pushd "%~dp0"
    copy dpend\Record_ISS\up_orthosim.iss "%abs_ortho_extract_to%\setup.iss" /y >nul 2>nul
    cd /d "%abs_ortho_extract_to%"
    start /wait "" "%abs_ortho_extract_to%\Romexis_Ortho_Simulator_Installer.exe" /s /SMS /f1"%abs_ortho_extract_to%\setup.iss"
    pushd "%~dp0"
	
	set "endRawOther=!TIME:~0,8!"
	call :GetDurationOther !startRawOther! !endRawOther!
)

:AFTER_OTHER_INSTALLS

:DURAOTHER
if defined showOtherDuration (
	echo(
	echo  Other APPS installation completed in !durationStrOther! mm:ss     
	echo ________________________________________________________________________ 
	echo(
)

regedit.exe /s reset_console_font-colors.reg  >nul
color 07 2>nul

:FINAL
echo  Installed versions:
echo --------------------------------------------------------------------------
echo.
echo. Set by installers:
call "%~dp0ShowApps.bat"
echo.
echo. Exe/jar file versions:
call "%~dp0BinFileVersions-Call.bat"


rem final
echo __________________________________________________________________________
echo(
echo   All Installations completed                                         
echo __________________________________________________________________________

rem optional tasks
echo(
echo  X to exit, C to Start Romexis config, R to Start Romexis
echo(
choice /C RCX /N /M "--- Your choice: "

if errorlevel 3 (
    taskkill /FI "WINDOWTITLE eq ASENTAJA user" /F >nul 2>&1
	taskkill /FI "WINDOWTITLE eq c:\windows\system32\cmd.exe" /F >nul 2>&1
    exit /b
)
if errorlevel 2 goto CONFIG
if errorlevel 1 goto ROMEXIS
echo(

:ROMEXIS
echo(
echo   Starting Romexis
CD /d "C:\Program Files\Planmeca\Romexis\client"
rem reset colors
color 07 2>nul
cls
call Romexis.bat
timeout /t 5 /nobreak >nul
taskkill /FI "WINDOWTITLE eq ASENTAJA user" /F >nul 2>&1
taskkill /FI "WINDOWTITLE eq c:\windows\system32\cmd.exe" /F >nul 2>&1
exit /b

:CONFIG
echo(
echo   Starting Romexis config.  After changes press a key to restart server
echo(
cd /d "C:\Program Files\Planmeca\Romexis\admin\" 
call "C:\Program Files\Planmeca\Romexis\admin\RomexisConfig.bat"
pause >nul
PowerShell -NoProfile -ExecutionPolicy Bypass -File "%~dp0rmx-server-restart.ps1"
pushd "%~dp0"
echo  Server restarted. 
echo  - Press a key to start Romexis client 
pause >nul
echo(
echo   Starting Romexis
CD /d "C:\Program Files\Planmeca\Romexis\client"
rem reset colors
color 07 2>nul
cls
call Romexis.bat
echo(
timeout /t 4 /nobreak >nul
taskkill /FI "WINDOWTITLE eq ASENTAJA user" /F >nul 2>&1
taskkill /FI "WINDOWTITLE eq c:\windows\system32\cmd.exe" /F >nul 2>&1
exit /b



rem duration calculation Romexis 
rem ----------------------------------------------------------------
:GetDuration
setlocal EnableDelayedExpansion
set "start=%~1"
set "end=%~2"

for /f "tokens=1-3 delims=:." %%a in ("%start%") do (
    set /a "h=10%%a %% 100"
    set /a "m=10%%b %% 100"
    set /a "s=10%%c %% 100"
    set /a "startSec = h*3600 + m*60 + s"
)

for /f "tokens=1-3 delims=:." %%a in ("%end%") do (
    set /a "h=10%%a %% 100"
    set /a "m=10%%b %% 100"
    set /a "s=10%%c %% 100"
    set /a "endSec = h*3600 + m*60 + s"
)
set /a "diffSec = endSec - startSec"
if !diffSec! lss 0 set /a "diffSec = diffSec + 86400"

set /a "mm = diffSec / 60"
set /a "ss = diffSec %% 60"

if !mm! lss 10 set "mm=0!mm!"
if !ss! lss 10 set "ss=0!ss!"

endlocal & set "durationStr=%mm%:%ss%"
goto :eof


rem duration calculation Other apps
rem ----------------------------------------------------------------
:GetDurationOther
setlocal EnableDelayedExpansion
set "start=%~1"
set "end=%~2"

for /f "tokens=1-3 delims=:." %%a in ("%start%") do (
    set /a "h=10%%a %% 100"
    set /a "m=10%%b %% 100"
    set /a "s=10%%c %% 100"
    set /a "startSec = h*3600 + m*60 + s"
)

for /f "tokens=1-3 delims=:." %%a in ("%end%") do (
    set /a "h=10%%a %% 100"
    set /a "m=10%%b %% 100"
    set /a "s=10%%c %% 100"
    set /a "endSec = h*3600 + m*60 + s"
)
set /a "diffSec = endSec - startSec"
if !diffSec! lss 0 set /a "diffSec = diffSec + 86400"

set /a "mm = diffSec / 60"
set /a "ss = diffSec %% 60"

if !mm! lss 10 set "mm=0!mm!"
if !ss! lss 10 set "ss=0!ss!"

endlocal & set "durationStrOther=%mm%:%ss%"
goto :eof