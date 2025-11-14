@echo off
pushd "%~dp0"
cls
REM folders
set "EXTRACT_TO=%USERPROFILE%\AppData\Local"
set "ASENTAJA_DIR=%USERPROFILE%\AppData\Local\ASENTAJA"
echo.
rem echo   ASENTAJA tool installer 


setlocal EnableExtensions EnableDelayedExpansion
REM Source archive - same location as this batch file

set "SOURCE=%~dp0ASENTAJA.zip"
if not exist "%SOURCE%" set "SOURCE=\\pmgroup.local\Data\Tuotekehitys\SW\Applics\Romexis\tools\ASENTAJA\ASENTAJA.zip"


REM Extract to
set "EXTRACT_TO=%USERPROFILE%\AppData\Local"
set "ASENTAJA_DIR=%USERPROFILE%\AppData\Local\ASENTAJA"

REM Check if source exists
if not exist "%SOURCE%" (
     echo    [ERROR] Cannot access installer archive
     echo    Source: %SOURCE%
    pause
    exit /b 1
)

REM Delete old installation folder if it exists
if exist "%ASENTAJA_DIR%" (
rd /s /q "%ASENTAJA_DIR%" >nul 2>nul


    REM Check if deletion failed
    if exist "%USERPROFILE%\ASENTAJA" (
        echo.
        echo    - Cannot delete old ASENTAJA folder - files are in use
        echo    - Close any app/cmd that may be accessing the files
        echo    - Then press any key to retry 
        pause >nul
        
        REM Retry deletion
        rd /s /q "%USERPROFILE%\ASENTAJA" >nul 2>nul
        
        if exist "%USERPROFILE%\ASENTAJA" (
            echo.
            echo   Still cannot delete folder.
            echo    - logout-login to windows and rerun "click to get it"
            pause
            exit /b 1
        )
    )
)
echo.
echo.
echo.
echo.
echo.
echo.
echo.
echo   ================================================================================
echo.
echo.  Starting ASENTAJA after extract completed
echo.
echo   - Shortcut is created to desktop
echo. 
echo   - Do not use "run as admin" when starting from shortcut later.
echo.
echo   ================================================================================
echo.
echo.
powershell -NoProfile -Command "Expand-Archive -Path '%SOURCE%' -DestinationPath '"%EXTRACT_TO%"' -Force"
echo.
echo.

if errorlevel 1 (
echo   [ERROR] Extraction failed
    pause
    exit /b 1
)

REM Unblock all extracted files

rem powershell -NoProfile -Command "Get-ChildItem '%ASENTAJA_DIR%' -Recurse | Unblock-File -ErrorAction SilentlyContinue"

set "SCRIPT_DIR=%ASENTAJA_DIR%\ROMEXIN\scripts"

powershell -NoProfile -ExecutionPolicy Bypass -Command "$Desktop = [Environment]::GetFolderPath('Desktop'); $s=(New-Object -COM WScript.Shell).CreateShortcut([System.IO.Path]::Combine($Desktop, 'ASENTAJA Starter.lnk')); $s.TargetPath='%SCRIPT_DIR%\startr_user.bat'; $s.IconLocation='%SCRIPT_DIR%\startr-ico.ico'; $s.WorkingDirectory='%SCRIPT_DIR%'; $s.WindowStyle=7; $s.Save()"

if errorlevel 1 (
echo   [WARNING] Failed to create shortcut
) else (
    rem - Extracted 
)
echo.
echo.
rem timeout /t 2 >nul
if exist "%SCRIPT_DIR%\startr_user.bat" (
	popd
    start "" /MIN ""%SCRIPT_DIR%\startr_user.bat"
) else (
    echo    [ERROR] ASENTAJA files not found
    pause
	popd
    exit /b 1
)
