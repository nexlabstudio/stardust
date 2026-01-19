$ErrorActionPreference = 'Stop'

$packageName = 'stardust'
$toolsDir = "$(Split-Path -Parent $MyInvocation.MyCommand.Definition)"
$version = '0.1.0'
$url64 = "https://github.com/nexlabstudio/stardust/releases/download/v$version/stardust-windows-x64.zip"
# Checksum will be updated by release workflow
$checksum64 = 'PLACEHOLDER'

$packageArgs = @{
  packageName    = $packageName
  unzipLocation  = $toolsDir
  url64bit       = $url64
  checksum64     = $checksum64
  checksumType64 = 'sha256'
}

Install-ChocolateyZipPackage @packageArgs
