$ErrorActionPreference = 'Stop'

$packageName = 'stardust'
$toolsDir = "$(Split-Path -Parent $MyInvocation.MyCommand.Definition)"

Remove-Item -Path "$toolsDir\stardust.exe" -Force -ErrorAction SilentlyContinue
