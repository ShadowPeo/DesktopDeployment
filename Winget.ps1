Import-Module wingetposh
$currentInstalls = Get-WGPackage | Out-Object
$currentInstalls | ft
