$ErrorActionPreference = 'Stop'

$packageName = 'stardust'
$toolsDir = "$(Split-Path -Parent $MyInvocation.MyCommand.Definition)"
$version = '0.1.1'
$url64 = "https://github.com/nexlabstudio/stardust/releases/download/v$version/stardust-windows-x64.zip"
$checksum64 = '78da88ea6e4a1939a084cfe6132af16807651a57ec880840f307d472dcb22477'

$packageArgs = @{
  packageName    = $packageName
  unzipLocation  = $toolsDir
  url64bit       = $url64
  checksum64     = $checksum64
  checksumType64 = 'sha256'
}

Install-ChocolateyZipPackage @packageArgs
