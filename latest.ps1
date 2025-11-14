# latest.ps1 - Find latest versions and write to latest_versions.txt
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Resolve-VariablePath {
    param([string]$BasePath,[string]$RawPath)
    if ([string]::IsNullOrWhiteSpace($RawPath)) { return $null }
    if ([System.IO.Path]::IsPathRooted($RawPath)) { return $RawPath }
    return [System.IO.Path]::GetFullPath((Join-Path -Path $BasePath -ChildPath $RawPath))
}

function Get-VersionTupleFromName {
    param(
        [Parameter(Mandatory=$true)][string]$FileName,
        [Parameter(Mandatory=$true)][string]$Filter
    )
    $base = [System.IO.Path]::GetFileNameWithoutExtension($FileName)
    $idx  = $base.IndexOf($Filter, [System.StringComparison]::OrdinalIgnoreCase)
    $candidate = $null
    if ($idx -ge 0) {
        $after = $base.Substring($idx + $Filter.Length)
        if ($after -match '^([0-9]+(\.[0-9]+){1,})(?=(_|$))') { $candidate = $Matches[1] }
    }
    if (-not $candidate) {
        $matches = [System.Text.RegularExpressions.Regex]::Matches($base, '([0-9]+(\.[0-9]+){1,})')
        if ($matches.Count -gt 0) {
            $candidate = ($matches | Sort-Object { $_.Value.Length } -Descending | Select-Object -First 1).Value
        } else { $candidate = '0' }
    }
    return ($candidate -split '\.') | ForEach-Object { [int]$_ }
}

function Normalize-VersionTuple {
    param([int[]]$Tuple,[int]$Length = 8)
    $out = New-Object int[] $Length
    for ($i=0; $i -lt $Length; $i++) {
        if ($i -lt $Tuple.Count) { $out[$i] = $Tuple[$i] } else { $out[$i] = 0 }
    }
    return $out
}

function Build-VersionSortKey {
    param([int[]]$Tuple)
    ($Tuple | ForEach-Object { $_.ToString('D6') }) -join '.'
}

$scriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Definition
$varFile    = Join-Path $scriptRoot "variables.txt"
if (-not (Test-Path $varFile)) { throw "variables.txt not found: $varFile" }

$vars = @{}
Get-Content $varFile | Where-Object { $_ -match '=' -and $_ -notmatch '^\s*[#;]' } | ForEach-Object {
    $name, $value = $_ -split '=', 2
    $expandedValue = [Environment]::ExpandEnvironmentVariables($value.Trim())
    $vars[$name.Trim()] = $expandedValue
}

$SourceDir  = Resolve-VariablePath $scriptRoot ($vars['dl_source_path'])
$DestDirRaw = $vars['installers_download_to']; if ([string]::IsNullOrWhiteSpace($DestDirRaw)) { $DestDirRaw = $vars['download_to'] }
$DestDir    = Resolve-VariablePath $scriptRoot $DestDirRaw

$SourceAvailable = Test-Path $SourceDir
if (-not $SourceAvailable) {
  Write-Host " No connection to network folder"
  Write-Host " "
  Write-Host " Showing locally available installers:"
  # Use local downloaded files instead
  $SourceDir = $DestDir
  if (-not (Test-Path $SourceDir)) {
    Write-Host " - No local installers found either"
    return
  }
}

if (-not (Test-Path $SourceDir)) { throw "Source folder not found: $SourceDir" }

$installOption = $env:install_option
# Get filters in numerical order (filter1, filter2, filter3, ...)
$filters = $vars.Keys | 
    Where-Object { $_ -like 'filter*' -and -not [string]::IsNullOrWhiteSpace($vars[$_]) -and $vars[$_] -ne 'NA' } | 
    Sort-Object { [int]($_ -replace 'filter', '') } | 
    ForEach-Object { $vars[$_] }

$latestFiles = @()

foreach ($filter in $filters) {
    $candidates = Get-ChildItem -Path $SourceDir -Filter ("{0}*.zip" -f $filter) -File -ErrorAction SilentlyContinue
    if (-not $candidates) {
        continue
    }

    $scored = foreach ($f in $candidates) {
        $vt    = Get-VersionTupleFromName -FileName $f.Name -Filter $filter
        $norm  = Normalize-VersionTuple -Tuple $vt -Length 8
        $vkey  = Build-VersionSortKey -Tuple $norm
        [PSCustomObject]@{
            File         = $f
            VersionTuple = $norm
            VersionKey   = $vkey
            LastWrite    = $f.LastWriteTimeUtc
        }
    }

    $latest = $scored | Sort-Object -Property @{Expression='VersionKey';Descending=$true}, @{Expression='LastWrite';Descending=$true} | Select-Object -First 1
    
    if ($latest) {
        $latestFiles += $latest.File
        $dateStr = $latest.File.LastWriteTime.ToString("yyyy-MM-dd HH:mm")
        Write-Host (" - {0}  ({1})" -f $latest.File.Name, $dateStr)
    }
}

# Write latest versions to file with name|size format
$outputFile = Join-Path $scriptRoot "latest_versions.txt"
$latestFiles | ForEach-Object {
    "$($_.Name)|$($_.Length)"
} | Set-Content $outputFile