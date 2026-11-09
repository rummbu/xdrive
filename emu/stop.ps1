# Stop the emulated iDrive HMI and its helpers.
$emu = "$(& "$PSScriptRoot\repo.ps1")/emu"
wsl.exe -d Ubuntu-24.04 -u root -- bash "$emu/stop.sh"
