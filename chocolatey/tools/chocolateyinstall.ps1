$ErrorActionPreference = 'Stop'

$packageName = 'stardust'
$toolsDir = "$(Split-Path -Parent $MyInvocation.MyCommand.Definition)"
$version = '0.2.0'
$url64 = "https://github.com/nexlabstudio/stardust/releases/download/v$version/stardust-windows-x64.zip"
$checksum64 = '76fec55c8979a7e5d2cdfac65a2dea8b0b6c348ad6e06dc777d5981c86d40b4e'

$packageArgs = @{
  packageName    = $packageName
  unzipLocation  = $toolsDir
  url64bit       = $url64
  checksum64     = $checksum64
  checksumType64 = 'sha256'
}

Install-ChocolateyZipPackage @packageArgs
