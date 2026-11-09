# Prints this repo's root as a WSL path (e.g. /mnt/d/src/idrive-emu), wherever it was cloned.
$p = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
'/mnt/' + $p.Substring(0, 1).ToLower() + ($p.Substring(2) -replace '\\', '/')
