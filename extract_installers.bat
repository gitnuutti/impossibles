@echo off
setlocal enabledelayedexpansion
:: Load paths from variables.txt
for /f "usebackq tokens=1,* delims== " %%A in ("%~dp0variables.txt") do (
    if %%A==installers_download_to set "download_to=%%B"
    if %%A==installers_extract_to set "extract_to=%%B"
)
:: Expand environment variables in paths
call set "DOWNLOAD_PATH=%download_to%"
call set "EXTRACT_PATH=%extract_to%"
if not exist "!EXTRACT_PATH!" mkdir "!EXTRACT_PATH!"

:: Prepare extracted_to.txt
set "EXTRACTED_LIST=%~dp0extracted_to.txt"
echo. > "!EXTRACTED_LIST!"

:: Clear corruption flag at start
set "corruption_found="

:: Process all ZIP files
for %%Z in ("!DOWNLOAD_PATH!\*.zip") do (
    set "NAME=%%~nZ"
    set "BASE="
    set "done="
    :: Find base string before version digits
    for /l %%i in (0,1,254) do (
        set "pair=!NAME:~%%i,2!"
        for %%d in (0 1 2 3 4 5 6 7 8 9) do (
            if "!pair!"=="_%%d" (
                if "!done!"=="" (
                    set "BASE=!NAME:~0,%%i!"
                    set "done=1"
                )
            )
        )
    )
    if "!BASE!"=="" set "BASE=!NAME!"

    set "VARNAME=!BASE!_ipath"
    echo !VARNAME!=!EXTRACT_PATH!\!BASE!>>"!EXTRACTED_LIST!"

    REM Create/clean target folder
    if exist "!EXTRACT_PATH!\!BASE!" rmdir /s /q "!EXTRACT_PATH!\!BASE!" 2>nul
    mkdir "!EXTRACT_PATH!\!BASE!"
    
    echo - %%~nxZ
    
    REM Extract with error detection
    "%~dp07za.exe" x "%%Z" -o"!EXTRACT_PATH!\!BASE!" -y >nul 2>nul
    
    if errorlevel 1 (
        echo.
        echo   Deleting CORRUPTED: "%%~nxZ"
        del "%%Z" /Q 2>nul
        if exist "%%Z" (
            echo.
            echo - ERROR: "%%~nxZ" - file may be locked
        )
        set "corruption_found=1"
    ) else (
        REM Flatten for non-Romexis installers
        if /I not "!BASE!"=="Planmeca_Romexis" (
            pushd "!EXTRACT_PATH!\!BASE!" >nul
            set "subfolder="
            for /d %%D in ("*") do (
                if defined subfolder (
                    set "multi=Y"
                ) else (
                    set "subfolder=%%~nxD"
                )
            )
            if defined subfolder if not defined multi (
                xcopy "!subfolder!\*" ".\" /s /e /h /q /y >nul
                rmdir /s /q "!subfolder!"
            )
            popd >nul
        )
    )
)

echo.

REM Handle corruption - auto-retry without prompting user
if "!corruption_found!"=="1" (
    timeout /t 2 /nobreak >nul
    exit /b 99
)

endlocal
exit /b