@echo off
setlocal
:: read list from apps.txt (one app name per line)
set "APPFILE=%~dp0apps.txt"
if not exist "%APPFILE%" (
  echo apps.txt not found in "%~dp0"
  exit /b 1
)
powershell -NoProfile -ExecutionPolicy Bypass ^
  "$names = Get-Content -Path '%APPFILE%' | Where-Object { $_ -and -not $_.StartsWith('#') };" ^
  "$roots = @('HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall','HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall','HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall');" ^
  "$items = foreach($r in $roots){ if(Test-Path $r){ Get-ItemProperty -Path (Join-Path $r '*') -ErrorAction SilentlyContinue } };" ^
  "foreach ($n in $names) {" ^
  "  $rx = '^' + [regex]::Escape($n) + '$';" ^
  "  $hit = $items | Where-Object { $_.DisplayName -and ($_.DisplayName -match $rx) } | Select-Object -First 1;" ^
  "  if ($hit) {" ^
  "    $disp = $hit.DisplayName;" ^
  "    $ver  = $hit.DisplayVersion; if (-not $ver) { $ver='' };" ^
  "    if ($disp.Length -gt 38) { $disp = $disp.Substring(0,38) };" ^
  "    $line = ' - {0}{1}' -f $disp.PadRight(39), $ver;" ^
  "    Write-Output $line" ^
  "  } else {" ^
  "    $line = ' - {0}{1}' -f $n.PadRight(39), 'not found';" ^
  "    Write-Output $line" ^
  "  }" ^
  "}"
endlocal
exit /b