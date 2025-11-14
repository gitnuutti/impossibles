# rmx-post.ps1 - Romexis Post-Install Script
# Updated: 2025-06-04

# Write-Host "Configuring Romexis debug logging and settings..."
(Get-Content -Path "C:\Program Files\Planmeca\Romexis\client\Romexis.bat" -Raw) `
  -replace '\\javaw.exe','\java.exe' | `
  Set-Content -Path "C:\Program Files\Planmeca\Romexis\client\Romexis.bat"

# Enable client debug logging
(Get-Content -Path "C:\Program Files\Planmeca\Romexis\client\log4j2_client.xml" -Raw) `
  -replace 'ROMEXIS_CLIENT" level="info"','ROMEXIS_CLIENT" level="debug"' | `
  Set-Content -Path "C:\Program Files\Planmeca\Romexis\client\log4j2_client.xml"

# Enable server debug logging
(Get-Content -Path "C:\Program Files\Planmeca\Romexis\server\log4j2_server.xml" -Raw) `
  -replace 'ROMEXIS_SERVER" level="info"','ROMEXIS_SERVER" level="debug"' | `
  Set-Content -Path "C:\Program Files\Planmeca\Romexis\server\log4j2_server.xml"

# Restart Romexis service
Write-Host " - Restarting RomexisService64..."
Stop-Service RomexisService64 -Force -ErrorAction SilentlyContinue

# Wait until service is fully stopped and then restarted
Start-Service RomexisService64 -ErrorAction Stop

$retries = 0
while ((Get-Service RomexisService64).Status -ne 'Running' -and $retries -lt 10) {
    Start-Sleep -Seconds 4
    $retries++
	# Write-Host "- Waiting for service to start..."
}
Write-Host " - Romexis server running"

