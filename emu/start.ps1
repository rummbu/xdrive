# Start an emulated BMW iDrive (the real MGU22 Hmi8 under qemu-aarch64 in WSL).
#   .\start.ps1            -> xdrive  (iDrive 8.5, BMW theme, i4)
#   .\start.ps1 m3         -> m3      (iDrive 8.5, BMW M theme, G80 LCI M3)
#   .\start.ps1 -List      -> show available profiles
# The "Weston Compositor" window is the car's centre display. Click/drag in it to touch.
# A hidden wsl.exe keeps the WSL session alive while it runs. Stop with stop.ps1.
param([string]$Profile = 'xdrive',
      [int]$Seconds = 0,      # 0 = run until stop.ps1
      [switch]$VerboseLog,    # HMI info-level log in /srv/mgu22/hmi.log (slower)
      [switch]$List)
$emu = "$(& "$PSScriptRoot\repo.ps1")/emu"
if ($List) {
    Get-ChildItem "$PSScriptRoot\profiles\*.conf" | ForEach-Object {
        $d = (Select-String -Path $_.FullName -Pattern '^DESC="(.*)"').Matches.Groups[1].Value
        '{0,-10} {1}' -f $_.BaseName, $d
    }
    return
}
if (-not (Test-Path "$PSScriptRoot\profiles\$Profile.conf")) {
    Write-Host "Unknown profile '$Profile'. Available:"; & $PSCommandPath -List; return
}
$level = if($VerboseLog) { '::4' } else { '::3' }
Start-Process -WindowStyle Hidden -FilePath wsl.exe -ArgumentList @('-d', 'Ubuntu-24.04', '-u', 'root', '--', 'bash', "`"$emu/launch.sh`"", "$Seconds", $level, $Profile)
Write-Host "iDrive '$Profile' booting - UI appears in the Weston window after ~1 min. Click/drag in it to touch."
