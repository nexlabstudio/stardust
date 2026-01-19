$ErrorActionPreference = 'Stop'

$packageName = 'stardust'
$toolsDir = "$(Split-Path -Parent $MyInvocation.MyCommand.Definition)"
$version = '0.2.1'
$url64 = "https://github.com/nexlabstudio/stardust/releases/download/v$version/stardust-windows-x64.zip"
$checksum64 = '604350696dbc512dd507784de6095cdbe0e191c612300b9159323a8cb057cfd8'

$packageArgs = @{
  packageName    = $packageName
  unzipLocation  = $toolsDir
  url64bit       = $url64
  checksum64     = $checksum64
  checksumType64 = 'sha256'
}

Install-ChocolateyZipPackage @packageArgs
