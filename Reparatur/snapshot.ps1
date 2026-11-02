# Zustandsaufnahme fuer Vorher/Nachher-Vergleich bei Starttests.
param([Parameter(Mandatory)][string]$Out, [string]$Dest = 'C:\COKTEL\ADDY4')
$r = [ordered]@{}
Get-ChildItem $Dest -Recurse -File -Force | ForEach-Object { $r["FILE " + $_.FullName] = "{0} {1:yyyy-MM-dd HH:mm:ss}" -f $_.Length, $_.LastWriteTime }
Get-ChildItem C:\ -File -Force -ErrorAction SilentlyContinue | ForEach-Object { $r["ROOT " + $_.FullName] = "{0} {1:yyyy-MM-dd HH:mm:ss}" -f $_.Length, $_.LastWriteTime }
Get-ChildItem "$env:LOCALAPPDATA\VirtualStore" -Recurse -File -Force -ErrorAction SilentlyContinue | ForEach-Object { $r["VSTORE " + $_.FullName] = $_.Length }
foreach ($k in 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Run', 'HKCU:\Software\Microsoft\Windows\CurrentVersion\RunOnce') {
    (Get-ItemProperty $k -ErrorAction SilentlyContinue).PSObject.Properties | Where-Object Name -notlike 'PS*' | ForEach-Object { $r["REG $k\$($_.Name)"] = $_.Value }
}
Get-ChildItem HKCU:\Software -ErrorAction SilentlyContinue | ForEach-Object { $r["REGKEY " + $_.Name] = '' }
Get-ChildItem 'HKCU:\Software\Classes\VirtualStore\MACHINE\SOFTWARE' -Recurse -ErrorAction SilentlyContinue | ForEach-Object { $r["REGVS " + $_.Name] = '' }
$r.GetEnumerator() | ForEach-Object { "$($_.Key)`t$($_.Value)" } | Set-Content -Path $Out -Encoding UTF8
