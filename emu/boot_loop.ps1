# Boot the HMI N times; report time-to-UI and any qemu crashes/restarts per boot.
param([int]$N = 4)
$emu = "$(& "$PSScriptRoot\repo.ps1")/emu"
for ($i = 1; $i -le $N; $i++) {
    & "$PSScriptRoot\stop.ps1" | Out-Null
    Start-Sleep 2
    & "$PSScriptRoot\start.ps1" | Out-Null
    Start-Sleep 4
    $r = wsl.exe -d Ubuntu-24.04 -u root -- bash -c "tr -d '\r' < '$emu/time_to_ui.sh' | bash; grep -E 'attempt' /srv/mgu22/run.log | tr '\n' ' '; grep -m1 interpreter /proc/sys/fs/binfmt_misc/qemu-aarch64"
    "--- boot $i ---"
    $r
}
