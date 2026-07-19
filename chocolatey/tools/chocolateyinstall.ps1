$ErrorActionPreference = 'Stop'

$packageName = 'stardust'
$toolsDir = "$(Split-Path -Parent $MyInvocation.MyCommand.Definition)"
$version = '0.6.4'
$url64 = "https://github.com/nexlabstudio/stardust/releases/download/v$version/stardust-windows-x64.zip"
$checksum64 = '4987208b5eb773b1f034ffc25b6ec62ac26dd0d371a9260e1cb70fae0ef18078'

$packageArgs = @{
  packageName    = $packageName
  unzipLocation  = $toolsDir
  url64bit       = $url64
  checksum64     = $checksum64
  checksumType64 = 'sha256'
}

Install-ChocolateyZipPackage @packageArgs
