# Trigger check-control warnings on the emulated iDrive (via the car simulator).
# Warnings STACK: each call adds to what's already active.
#   .\warn.ps1 misfire              add one warning
#   .\warn.ps1 misfire oil tyre     add several at once
#   .\warn.ps1 "77:Custom text"     add your own (CC number : text)
#   .\warn.ps1 remove oil 77        remove some (preset name or CC number)
#   .\warn.ps1 active               show what's currently active
#   .\warn.ps1 clear                remove all warnings
#   .\warn.ps1 list                 show presets
# Open them in: Apps > Live Vehicle > Vehicle status > Check Control
param([Parameter(ValueFromRemainingArguments = $true)][string[]]$Items)
$presets = @{
    misfire  = '30:Drivetrain malfunction. Engine misfire detected. Drive moderately.'
    engine   = '31:Engine malfunction. Have the vehicle checked.'
    oil      = '32:Engine oil level low. Top up engine oil.'
    oilpress = '33:Engine oil pressure low. Stop carefully and switch off engine.'
    coolant  = '34:Coolant temperature high. Drive moderately.'
    tyre     = '35:Tyre pressure low. Check tyre pressures.'
    brake    = '36:Brake fluid low. Stop carefully.'
    battery  = '37:Increased battery discharge.'
    washer   = '38:Washer fluid low. Top up washer fluid.'
    service  = '39:Service due. Contact your service partner.'
}
if (-not $Items -or $Items[0] -eq 'list') { $presets.GetEnumerator() | Sort-Object Name | ForEach-Object { '{0,-9} {1}' -f $_.Name, $_.Value }; return }

$state = Join-Path $PSScriptRoot 'carsim\cc_active.txt'   # one "ID:text" per line
$active = [ordered]@{}
if (Test-Path $state) {
    Get-Content $state -Encoding UTF8 | Where-Object { $_ -match '^\d+:' } | ForEach-Object {
        $i, $t = $_ -split ':', 2; $active["$([int]$i)"] = $t
    }
}
function IdOf($x) { if ($presets.ContainsKey($x)) { [int]($presets[$x] -split ':', 2)[0] } elseif ($x -match '^\d+') { [int]$Matches[0] } else { throw "unknown warning '$x' (try .\warn.ps1 list)" } }

switch ($Items[0]) {
    'clear'  { $active.Clear() }
    'active' { if ($active.Count) { $active.GetEnumerator() | ForEach-Object { '{0,3}  {1}' -f $_.Key, $_.Value } } else { 'no active warnings' }; return }
    'remove' { $Items | Select-Object -Skip 1 | ForEach-Object { $active.Remove("$(IdOf $_)") } }
    default  {
        foreach ($x in $Items) {
            $e = if ($presets.ContainsKey($x)) { $presets[$x] } else { $x }
            if ($e -notmatch '^\d+:') { throw "unknown warning '$x' (try .\warn.ps1 list)" }
            $i, $t = $e -split ':', 2; $active["$([int]$i)"] = $t
        }
    }
}

$lines = @($active.GetEnumerator() | ForEach-Object { '{0}:{1}' -f $_.Key, $_.Value })
[IO.File]::WriteAllLines($state, [string[]]$lines)
$py = "$(& "$PSScriptRoot\repo.ps1")/emu/carsim/ccmsg.py"
if ($lines.Count -eq 0) { $hex = wsl.exe -d Ubuntu-24.04 -u root -- python3 -I $py clear }
else {
    # hex-encode each item: wsl.exe mangles spaces in argv, so items go over stdin
    $enc = $lines | ForEach-Object { 'hex=' + (([Text.Encoding]::UTF8.GetBytes($_) | ForEach-Object { $_.ToString('x2') }) -join '') }
    $hex = ($enc -join "`n") | wsl.exe -d Ubuntu-24.04 -u root -- python3 -I $py list -
}
& "$PSScriptRoot\carsim\sim.ps1" set b011 0001 8002 $hex
"$($lines.Count) warning(s) active"
