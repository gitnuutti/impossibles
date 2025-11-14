# dlnew.ps1 – Simplified version using latest_versions.txt
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$scriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Definition
$varFile    = Join-Path $scriptRoot "variables.txt"
$latestFile = Join-Path $scriptRoot "latest_versions.txt"

if (-not (Test-Path $varFile)) { throw "variables.txt not found: $varFile" }
if (-not (Test-Path $latestFile)) { throw "latest_versions.txt not found. Run latest.ps1 first." }

# Load variables
$vars = @{}
Get-Content $varFile | Where-Object { $_ -match '=' -and $_ -notmatch '^\s*[#;]' } | ForEach-Object {
    $name, $value = $_ -split '=', 2
    $expandedValue = [Environment]::ExpandEnvironmentVariables($value.Trim())
    $vars[$name.Trim()] = $expandedValue
}

function Resolve-VariablePath {
    param([string]$BasePath,[string]$RawPath)
    if ([string]::IsNullOrWhiteSpace($RawPath)) { return $null }
    if ([System.IO.Path]::IsPathRooted($RawPath)) { return $RawPath }
    return [System.IO.Path]::GetFullPath((Join-Path -Path $BasePath -ChildPath $RawPath))
}

$SourceDir  = Resolve-VariablePath $scriptRoot ($vars['dl_source_path'])
$DestDirRaw = $vars['installers_download_to']; if ([string]::IsNullOrWhiteSpace($DestDirRaw)) { $DestDirRaw = $vars['download_to'] }
$DestDir    = Resolve-VariablePath $scriptRoot $DestDirRaw

$SourceAvailable = Test-Path $SourceDir
if (-not $SourceAvailable) {
  Write-Host " - Using earlier downloads (if any) since no connection to network."
  return
}

if (-not (Test-Path $SourceDir)) { throw "Source folder not found: $SourceDir" }
if (-not (Test-Path $DestDir))   { New-Item -ItemType Directory -Path $DestDir | Out-Null }

# Read latest versions list (format: filename|size) in order
$latestList = [ordered]@{}
Get-Content $latestFile | Where-Object { $_ -match '\|' } | ForEach-Object {
    $name, $size = $_ -split '\|', 2
    $latestList[$name.Trim()] = [long]$size.Trim()
}

if ($latestList.Count -eq 0) {
    Write-Host "No files in latest_versions.txt"
    return
}

# Filter based on install option
$installOption = $env:install_option
$romexisOnlyOptions = @('1', '3', '4', '6')

if ($romexisOnlyOptions -contains $installOption) {
    # Romexis only - remove other apps from the list
    $filtered = [ordered]@{}
    foreach ($key in $latestList.Keys) {
        if ($key -like "Planmeca_Romexis_*" -and 
            $key -notlike "*Smart*" -and 
            $key -notlike "*OrthoSimulator*") {
            $filtered[$key] = $latestList[$key]
        }
    }
    $latestList = $filtered
}

# Cleanup: Delete files not in latest list or with wrong size
# BUT: Skip files from other apps if this is a Romexis-only option
$existingFiles = Get-ChildItem -Path $DestDir -Filter "*.zip" -File -ErrorAction SilentlyContinue
foreach ($existing in $existingFiles) {
    # Skip Smart/SmartLite/OrthoSimulator files if Romexis-only option
    if ($romexisOnlyOptions -contains $installOption) {
        if ($existing.Name -like "*Smart*" -or $existing.Name -like "*OrthoSimulator*") {
            continue
        }
    }
    
    if (-not $latestList.Contains($existing.Name)) {
        Write-Host ("- {0} - deleted NA version" -f $existing.Name)
        Remove-Item -Path $existing.FullName -Force
    }
    elseif ($existing.Length -ne $latestList[$existing.Name]) {
        Write-Host ("- {0} - deleted (size mismatch)" -f $existing.Name, $existing.Length, $latestList[$existing.Name])
        Remove-Item -Path $existing.FullName -Force
    }
}

# Download missing files with progress tracking
foreach ($filename in $latestList.Keys) {
    $targetPath = Join-Path $DestDir $filename
    $sourcePath = Join-Path $SourceDir $filename
    
    if (-not (Test-Path $sourcePath)) {
        Write-Host ("- {0} - source file not found in network folder" -f $filename)
        continue
    }
    
    if (Test-Path $targetPath) {
        $existingFile = Get-Item $targetPath
        if ($existingFile.Length -eq $latestList[$filename]) {
            Write-Host ("- {0} - exists" -f $filename)
            continue
        }
    }
    
    # Copy with progress tracking
    Write-Host ("- {0}" -f $filename) -NoNewline
    
    $fileSize = $latestList[$filename]
    $bufferSize = 1MB
    $buffer = New-Object byte[] $bufferSize
    
    try {
        $srcStream = [System.IO.File]::OpenRead($sourcePath)
        $dstStream = [System.IO.File]::Create($targetPath)
        $totalRead = 0
        $lastPercent = -1
        
        while (($read = $srcStream.Read($buffer, 0, $buffer.Length)) -gt 0) {
            $dstStream.Write($buffer, 0, $read)
            $totalRead += $read
            $percent = [math]::Floor(($totalRead / $fileSize) * 100)
            
            if ($percent -ne $lastPercent) {
                Write-Host ("`r- {0}% {1}" -f $percent, $filename) -NoNewline
                $lastPercent = $percent
            }
        }
        
        Write-Host "`r- 100% $($filename) - copied"
    }
    finally {
        if ($srcStream) { $srcStream.Close() }
        if ($dstStream) { $dstStream.Close() }
    }
}

$completionFlag = Join-Path $DestDir ".download_complete"
"complete" | Out-File -FilePath $completionFlag -Encoding ASCII