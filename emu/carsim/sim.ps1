# Send commands to the running car simulator (carsim). Examples:
#   .\carsim\sim.ps1 dump
#   .\carsim\sim.ps1 set b09a 0001 8021 0000000e 41b40000 000101 41a80000 000201
#   .\carsim\sim.ps1 -File carsim\scenario.txt
[CmdletBinding(PositionalBinding = $false)]
param([string]$File, [Parameter(ValueFromRemainingArguments = $true)][string[]]$Cmd)
$lines = if ($File) { Get-Content $File } else { @($Cmd -join ' ') }
$tmp = "$env:TEMP\carsim_cmd.txt"
[IO.File]::WriteAllText($tmp, (($lines -join "`n") + "`n"))
$wsl = '/mnt/' + $tmp.Substring(0, 1).ToLower() + ($tmp.Substring(2) -replace '\\', '/')
$sh = "$(& "$PSScriptRoot\..\repo.ps1")/emu/carsim/sim.sh"
wsl.exe -d Ubuntu-24.04 -u root -- bash $sh $wsl
