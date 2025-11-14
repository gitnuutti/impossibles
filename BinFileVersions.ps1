param(
  [string] $ListFile,
  [string[]] $Paths,
  [int] $AlignAt = 40
)

# ---------- helpers ----------
function Format-Line {
  param([string]$Label, [string]$Value, [int]$AlignAt)
  if ([string]::IsNullOrWhiteSpace($Label)) { $Label = '' }
  if ($Label.Length -gt ($AlignAt - 2)) {
    $Label = $Label.Substring(0, $AlignAt - 2)
  }
  $pad = $AlignAt - 1
  ' - {0}{1}' -f $Label.PadRight($pad), $Value
}

function Get-JavaVersion {
  param([string]$JavaExe)
  if (-not (Test-Path $JavaExe)) { return 'not found' }
  try {
    # java -version writes to stderr
    $out = & $JavaExe -version 2>&1 | Out-String
    $out = $out -replace '\r',''
    $lines = $out.Trim().Split("`n")

    # 1) Plain numeric version from the first line:  openjdk version "11.0.26" ...
    $num = $null
    if ($out -match 'version\s+"?([0-9][^"\s]*)') { $num = $matches[1].Trim() }

    # 2) Vendor/build tag from the Runtime Environment line (e.g., "Zulu11.78+15-CA")
    # Typical line: "OpenJDK Runtime Environment Zulu11.78+15-CA (build 11.0.26+4-LTS)"
    $vendorTag = $null
    foreach ($ln in $lines) {
      if ($ln -match 'Runtime Environment\s+([^\(]+?)\s*\(build') {
        $vendorTag = $matches[1].Trim()
        break
      }
    }

    if ($num -and $vendorTag) { return "$num build: $vendorTag" }
    if ($num) { return $num }
    if ($vendorTag) { return $vendorTag }
    # Fallback: first line if nothing matched
    return ($lines | Select-Object -First 1).Trim()
  } catch { 'unknown' }
}

function Get-JarVersion {
  param([string]$JarPath)
  if (-not (Test-Path $JarPath)) { return 'not found' }
  try {
    $tempDir = Join-Path $env:TEMP "jar_extract_$(Get-Random)"
    $null = New-Item -ItemType Directory -Path $tempDir -Force
    
    # Extract manifest
    tar -xf $JarPath -C $tempDir META-INF/MANIFEST.MF 2>$null
    $manifestPath = Join-Path $tempDir "META-INF\MANIFEST.MF"
    
    if (Test-Path $manifestPath) {
      $content = Get-Content $manifestPath -Raw
      if ($content -match 'Implementation-Version:\s*(.+)') {
        $ver = $matches[1].Trim()
        Remove-Item -Recurse -Force $tempDir
        return $ver
      }
    }
    Remove-Item -Recurse -Force $tempDir
    'unknown'
  } catch { 'unknown' }
}

function Get-RomexisServerVersion {
  param([string]$JarPath, [string]$JavaExe)
  if (-not (Test-Path $JarPath)) { return 'not found' }
  if (-not (Test-Path $JavaExe)) { return 'java.exe not found' }
  try {
    $out = & $JavaExe -jar $JarPath -version 2>&1 | Out-String
    
    # Method 1: Look for "Romexis Server version:" pattern
    if ($out -match 'Romexis Server version:\s*(.+)') {
      return $matches[1].Trim()
    }
    
    # Method 2: Extract last line that contains "version:"
    $lines = $out -split "`n" | Where-Object { $_.Trim() -match 'version:' }
    if ($lines) {
      $lastLine = $lines[-1].Trim()
      if ($lastLine -match 'version:\s*(.+)') {
        return $matches[1].Trim()
      }
    }
    
    # Method 3: Fall back to manifest
    return Get-JarVersion -JarPath $JarPath
  } catch { 
    # Fall back to manifest on error
    return Get-JarVersion -JarPath $JarPath
  }
}

function Get-FileProductVersion {
  param([string]$FilePath)
  if (-not (Test-Path $FilePath)) { return 'not found' }
  try {
    $vi = (Get-Item -LiteralPath $FilePath).VersionInfo
    $ver = $vi.FileVersion
    if (-not $ver) { $ver = $vi.ProductVersion }
    if ($ver) { return $ver }
    'unknown'
  } catch { 'unknown' }
}

# ---------- build worklist ----------
$entries = [System.Collections.Generic.List[object]]::new()

if ($ListFile) {
  if (-not (Test-Path $ListFile)) {
    Write-Error "ListFile not found: $ListFile"
    exit 1
  }
  foreach ($line in Get-Content -LiteralPath $ListFile) {
    if (-not $line) { continue }
    if ($line.Trim().StartsWith('#')) { continue }
    # support "Label=Path" OR "Label|Path" OR just "Path"
    if ($line -match '^\s*([^=|]+)\s*[=|]\s*(.+?)\s*$') {
      $label = $matches[1].Trim()
      $path  = $matches[2].Trim()
    } else {
      $path  = $line.Trim()
      $label = [IO.Path]::GetFileNameWithoutExtension($path)
    }
    if ($path) {
      $entries.Add([pscustomobject]@{ Label=$label; Path=$path })
    }
  }
}

if ($Paths) {
  foreach ($p in $Paths) {
    $entries.Add([pscustomobject]@{
      Label = [IO.Path]::GetFileNameWithoutExtension($p)
      Path  = $p
    })
  }
}

if ($entries.Count -eq 0) {
  Write-Error "No inputs provided. Use -ListFile or -Paths."
  exit 1
}

# ---------- evaluate ----------
$javaExe = "C:\Program Files\Planmeca\Romexis\tools\jre_x64\bin\java.exe"

foreach ($e in $entries) {
  $path = $e.Path
  $label = $e.Label
  $exeName = [IO.Path]::GetFileName($path)
  $ext = [IO.Path]::GetExtension($path).ToLower()

  $ver =
    if ($exeName -and $exeName.ToLower() -eq 'java.exe') {
      Get-JavaVersion -JavaExe $path
    } elseif ($ext -eq '.jar' -and $exeName -eq 'RomexisServer.jar') {
      Get-RomexisServerVersion -JarPath $path -JavaExe $javaExe
    } elseif ($ext -eq '.jar') {
      Get-JarVersion -JarPath $path
    } else {
      Get-FileProductVersion -FilePath $path
    }

  Format-Line -Label $label -Value $ver -AlignAt $AlignAt
}