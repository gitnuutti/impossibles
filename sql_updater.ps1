$IsAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()
).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $env:ADMIN_WORKER -and -not $IsAdmin) {
  Write-Error "[ERR] Run this via the launcher (requires elevation)."
  exit 122
}


# Write-Host "-----------------------------------------------------" #>
# Installing SQL Cumulative Update patch
Start-Process -FilePath "abs_sqlupdater\SQL-CU.exe" -ArgumentList "/quiet /action=patch /instancename=SQLEXPRESS /IAcceptSQLServerLicenseTerms" -Wait
Start-Process -FilePath "abs_sqlupdater\SQL-HOTFIX-1.exe" -ArgumentList "/quiet /action=patch /instancename=SQLEXPRESS /IAcceptSQLServerLicenseTerms" -Wait

# Installing security updates for SQL ODBC Driver
Start-Process -FilePath "msiexec.exe" -ArgumentList "/i `abs_sqlupdater\"ODBC-driver-updater.msi`" /quiet /norestart" -Wait

# Installing security updates for SQL OLE DB driver
Start-Process -FilePath "msiexec.exe" -ArgumentList "/i `abs_sqlupdater\"OLE-DB-driver-updater.msi`" /quiet /norestart" -Wait
	
# Write-Host "- SQL server updates completed"
