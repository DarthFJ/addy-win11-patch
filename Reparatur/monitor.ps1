# Startet ADI4.EXE und protokolliert alle 200 ms neue Prozesse, sichtbare Fenster (inkl. Dialogtexte) bis zum Ende.
param([int]$Max = 30, [string]$Dest = 'C:\COKTEL\ADDY4', [string]$Args = '')
Add-Type -Namespace U -Name M -MemberDefinition @'
public delegate bool EnumProc(IntPtr h, IntPtr l);
[DllImport("user32.dll")] public static extern bool EnumWindows(EnumProc f, IntPtr l);
[DllImport("user32.dll")] public static extern bool EnumChildWindows(IntPtr p, EnumProc f, IntPtr l);
[DllImport("user32.dll")] public static extern uint GetWindowThreadProcessId(IntPtr h, out uint pid);
[DllImport("user32.dll", CharSet=CharSet.Unicode)] public static extern int GetWindowText(IntPtr h, System.Text.StringBuilder s, int n);
[DllImport("user32.dll", CharSet=CharSet.Unicode)] public static extern int GetClassName(IntPtr h, System.Text.StringBuilder s, int n);
[DllImport("user32.dll")] public static extern bool IsWindowVisible(IntPtr h);
'@
function Txt($h) { $t = New-Object Text.StringBuilder 512; [void][U.M]::GetWindowText($h, $t, 512); $t.ToString() }
function Cls($h) { $c = New-Object Text.StringBuilder 256; [void][U.M]::GetClassName($h, $c, 256); $c.ToString() }
$known = @{}; Get-Process | ForEach-Object { $known[$_.Id] = 1 }
$seen = @{}
$start = Get-Date
$sp = @{ FilePath = (Join-Path $Dest 'ADI4.EXE'); WorkingDirectory = $Dest; PassThru = $true }
if ($Args) { $sp.ArgumentList = $Args }
$p = Start-Process @sp
"{0,6:N1}s Start PID {1}" -f 0, $p.Id
$watch = @{ $p.Id = 'ADI4.EXE' }
while (((Get-Date) - $start).TotalSeconds -lt $Max) {
    $el = ((Get-Date) - $start).TotalSeconds
    foreach ($np in Get-Process) {
        if (-not $known.ContainsKey($np.Id)) {
            $known[$np.Id] = 1
            $path = try { $np.Path } catch { '?' }
            "{0,6:N1}s Neuer Prozess: {1} PID {2} {3}" -f $el, $np.Name, $np.Id, $path
            if ($path -like "$Dest*" -or $path -like '*:\*.EXE' -and $path -notlike 'C:\Windows\*') { $watch[$np.Id] = $np.Name }
        }
    }
    $script:out = @()
    $cb = [U.M+EnumProc] {
        param($h, $l)
        $wp = 0; [void][U.M]::GetWindowThreadProcessId($h, [ref]$wp)
        if ($watch.ContainsKey([int]$wp) -and [U.M]::IsWindowVisible($h)) {
            $key = "$h|$(Txt $h)"
            if (-not $seen.ContainsKey($key)) {
                $seen[$key] = 1
                $kids = New-Object Collections.Generic.List[string]
                $cc = [U.M+EnumProc] { param($c, $x) $t = Txt $c; if ($t) { $kids.Add("[$(Cls $c)] $t") }; $true }
                [void][U.M]::EnumChildWindows($h, $cc, [IntPtr]::Zero)
                $script:out += "Fenster PID $wp Klasse='$(Cls $h)' Titel='$(Txt $h)' Inhalt: $($kids -join ' / ')"
            }
        }
        $true
    }
    [void][U.M]::EnumWindows($cb, [IntPtr]::Zero)
    foreach ($o in $script:out) { "{0,6:N1}s {1}" -f $el, $o }
    $alive = @($watch.Keys | Where-Object { Get-Process -Id $_ -ErrorAction SilentlyContinue })
    if ($alive.Count -eq 0) { "{0,6:N1}s Alle beobachteten Prozesse beendet. ADI4 ExitCode: {1}" -f $el, $p.ExitCode; break }
    Start-Sleep -Milliseconds 200
}
