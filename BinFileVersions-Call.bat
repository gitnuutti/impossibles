@echo off
setlocal
set "LIST=%~dp0files.txt"
set "PS=%~dp0BinFileVersions.ps1"

if not exist "%PS%" (
  echo BinFileVersions.ps1 not found next to this BAT.
  exit /b 1
)
if not exist "%LIST%" (
  echo files.txt not found next to this BAT.
  exit /b 1
)
powershell -NoProfile -ExecutionPolicy Bypass -File "%PS%" -ListFile "%LIST%" -AlignAt 40
endlocal
exit /b
