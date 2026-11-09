# Send scripted touch input to the running iDrive HMI. Coordinates are HMI pixels (1920x640).
#   .\tap.ps1 tap 960 600
#   .\tap.ps1 swipe 1500 300 400 300 400
#   .\tap.ps1 down 100 100 ; .\tap.ps1 move 200 100 ; .\tap.ps1 up
$cmd = ($args -join ' ')
wsl.exe -d Ubuntu-24.04 -u root -- bash -c "echo '$cmd' > /srv/mgu22/input.fifo"
