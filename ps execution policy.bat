:: --- Elevate if not admin ---
net session >nul 2>&1 || (
  echo Requesting administrative privileges...
  powershell -NoProfile -Command ^
    "Start-Process cmd -ArgumentList '/c','\"%~f0\"' -Verb RunAs"
  exit /b
)


# powershell -Command "Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser -Force"
powershell -Command Set-ExecutionPolicy ByPass -force

cmd
