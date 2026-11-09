# Grab a frame of the emulated iDrive display from inside the compositor (works while Windows is locked).
param([int]$Settle = 45, [int]$MaxWait = 600, [string]$Name = "hmi.png")
$emu = "$(& "$PSScriptRoot\repo.ps1")/emu"
$out = "$(& "$PSScriptRoot\repo.ps1")/screenshots/$Name"
wsl.exe -d Ubuntu-24.04 -u root -- bash "$emu/shot.sh" $Settle $MaxWait "$out"
