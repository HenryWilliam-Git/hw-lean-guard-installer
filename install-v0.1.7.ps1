[CmdletBinding()]
param(
  [switch]$ServerManagedPolicyConfirmed,
  [switch]$ValidateOnly,
  [Parameter(DontShow = $true)]
  [string]$PackagePath
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version 2.0

$packageVersion = '0.1.7'
$packageName = 'HW-Lean-Guard-v0.1.7-Innessco.zip'
$packageRootName = 'HW-Lean-Guard-v0.1.7-Innessco'
$packageUri = 'https://github.com/HenryWilliam-Git/hw-lean-guard-installer/releases/download/v0.1.7/HW-Lean-Guard-v0.1.7-Innessco.zip'
$expectedPackageSha256 = 'b51546f86bbd090902adcbac08f05632aff4acbe76ef087f4d8c871f33e7d142'

function Assert-SafeLeanGuardArchive {
  param(
    [Parameter(Mandatory = $true)][string]$Path,
    [Parameter(Mandatory = $true)][string]$ExpectedRoot
  )
  Add-Type -AssemblyName System.IO.Compression.FileSystem
  $archive = [IO.Compression.ZipFile]::OpenRead($Path)
  try {
    $entryPaths = [Collections.Generic.HashSet[string]]::new([StringComparer]::OrdinalIgnoreCase)
    foreach ($entry in $archive.Entries) {
      $entryPath = $entry.FullName.Replace('\', '/')
      if ($entryPath.StartsWith('/') -or $entryPath -match '(^|/)\.\.(/|$)' -or $entryPath.Contains(':')) {
        throw "Unsafe ZIP entry: $entryPath"
      }
      if (-not $entryPath.StartsWith($ExpectedRoot + '/', [StringComparison]::Ordinal)) {
        throw "ZIP entry is outside the expected root: $entryPath"
      }
      if (-not $entryPaths.Add($entryPath)) { throw "Duplicate ZIP entry: $entryPath" }
    }
  } finally {
    $archive.Dispose()
  }
}

if (-not $ValidateOnly -and -not $ServerManagedPolicyConfirmed) {
  throw 'Online installation requires -ServerManagedPolicyConfirmed after Claude /status shows Enterprise managed settings (remote).'
}

$temporaryRoot = Join-Path ([IO.Path]::GetTempPath()) ("HWLeanGuard-public-v$packageVersion-" + [Guid]::NewGuid().ToString('N'))
$zipPath = Join-Path $temporaryRoot $packageName
$extractRoot = Join-Path $temporaryRoot 'extract'
try {
  [IO.Directory]::CreateDirectory($temporaryRoot) | Out-Null
  if ([string]::IsNullOrWhiteSpace($PackagePath)) {
    $response = Invoke-WebRequest -Uri $packageUri -UseBasicParsing -OutFile $zipPath -PassThru
    $finalUri = $null
    if ($null -ne $response.BaseResponse.PSObject.Properties['ResponseUri']) {
      $finalUri = $response.BaseResponse.ResponseUri
    } elseif ($null -ne $response.BaseResponse.PSObject.Properties['RequestMessage']) {
      $finalUri = $response.BaseResponse.RequestMessage.RequestUri
    }
    if ($null -eq $finalUri -or $finalUri.Scheme -cne 'https') { throw 'Public package download did not finish over HTTPS.' }
  } else {
    $sourcePackage = [IO.Path]::GetFullPath($PackagePath)
    if (-not (Test-Path -LiteralPath $sourcePackage -PathType Leaf)) { throw 'Supplied test package is missing.' }
    Copy-Item -LiteralPath $sourcePackage -Destination $zipPath -Force
  }

  $actualPackageSha256 = (Get-FileHash -LiteralPath $zipPath -Algorithm SHA256).Hash.ToLowerInvariant()
  if ($actualPackageSha256 -cne $expectedPackageSha256) { throw 'Downloaded package SHA-256 does not match the pinned v0.1.7 artifact.' }
  Assert-SafeLeanGuardArchive -Path $zipPath -ExpectedRoot $packageRootName

  $previousProgressPreference = $ProgressPreference
  try {
    $ProgressPreference = 'SilentlyContinue'
    Expand-Archive -LiteralPath $zipPath -DestinationPath $extractRoot -Force
  } finally {
    $ProgressPreference = $previousProgressPreference
  }

  $installerPath = Join-Path $extractRoot "$packageRootName\Install-HWOSLeanGuard.ps1"
  if (-not (Test-Path -LiteralPath $installerPath -PathType Leaf)) { throw 'Downloaded package installer is missing.' }
  if ($ValidateOnly) {
    & $installerPath -ValidateOnly
  } else {
    & $installerPath -ServerManagedPolicyConfirmed
  }
} finally {
  if (Test-Path -LiteralPath $temporaryRoot) {
    $resolvedRoot = [IO.Path]::GetFullPath($temporaryRoot)
    $tempPrefix = [IO.Path]::GetFullPath([IO.Path]::GetTempPath()).TrimEnd('\') + '\'
    if ($resolvedRoot.StartsWith($tempPrefix, [StringComparison]::OrdinalIgnoreCase) -and (Split-Path -Leaf $resolvedRoot).StartsWith("HWLeanGuard-public-v$packageVersion-", [StringComparison]::Ordinal)) {
      Remove-Item -LiteralPath $resolvedRoot -Recurse -Force
    }
  }
}
