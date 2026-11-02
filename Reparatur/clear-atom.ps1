# Entfernt das globale Atom "MDOLoaderLaunched", das nach einem Absturz von ADI4.EXE zurueckbleibt
# und jeden weiteren Start stillschweigend beendet. Aendert keine Dateien; wirkt bis zur naechsten Abmeldung.
Add-Type -Namespace K -Name A -MemberDefinition @'
[DllImport("kernel32.dll", CharSet=CharSet.Ansi)] public static extern ushort GlobalFindAtomA(string s);
[DllImport("kernel32.dll")] public static extern ushort GlobalDeleteAtom(ushort a);
'@
$n = 0
while (($a = [K.A]::GlobalFindAtomA('MDOLoaderLaunched')) -ne 0 -and $n -lt 1000) { [void][K.A]::GlobalDeleteAtom($a); $n++ }
"Atom 'MDOLoaderLaunched': $n Referenz(en) entfernt, jetzt vorhanden: $([K.A]::GlobalFindAtomA('MDOLoaderLaunched') -ne 0)"
