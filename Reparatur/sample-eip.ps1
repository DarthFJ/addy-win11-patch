# Diagnose: nimmt Stichproben der Befehlszeiger (EIP) aller Threads eines laufenden 32-Bit-Prozesses.
# In 32-Bit-PowerShell starten. Haelt jeden Thread nur fuer Mikrosekunden an.
param([string]$Name = 'ADI4', [int]$Samples = 40)
Add-Type -Namespace T -Name S -MemberDefinition @'
[DllImport("kernel32.dll")] public static extern IntPtr OpenThread(uint a, bool i, int id);
[DllImport("kernel32.dll")] public static extern uint SuspendThread(IntPtr h);
[DllImport("kernel32.dll")] public static extern uint ResumeThread(IntPtr h);
[DllImport("kernel32.dll")] public static extern bool GetThreadContext(IntPtr h, [In, Out] byte[] c);
[DllImport("kernel32.dll")] public static extern bool CloseHandle(IntPtr h);
[DllImport("kernel32.dll")] public static extern IntPtr OpenProcess(uint a, bool i, int id);
[DllImport("kernel32.dll")] public static extern bool ReadProcessMemory(IntPtr h, IntPtr a, [Out] byte[] b, int n, out int r);
'@
$p = Get-Process $Name -ErrorAction Stop
$hp = [T.S]::OpenProcess(0x0410, $false, $p.Id)   # QUERY_INFORMATION|VM_READ
$exe = $p.Modules | Where-Object ModuleName -eq "$Name.EXE" | Select-Object -First 1
$eb = [int64]$exe.BaseAddress; $ee = $eb + $exe.ModuleMemorySize
$mods = $p.Modules | ForEach-Object { [pscustomobject]@{ N = $_.ModuleName; B = [int64]$_.BaseAddress; E = [int64]$_.BaseAddress + $_.ModuleMemorySize } }
$hits = @{}
for ($k = 0; $k -lt $Samples; $k++) {
    foreach ($t in (Get-Process -Id $p.Id).Threads) {
        $h = [T.S]::OpenThread(0x005A, $false, $t.Id)   # SUSPEND_RESUME|GET_CONTEXT|QUERY_INFORMATION
        if ($h -eq [IntPtr]::Zero) { continue }
        $c = New-Object byte[] 716; [BitConverter]::GetBytes(0x10001).CopyTo($c, 0)
        [void][T.S]::SuspendThread($h); $ok = [T.S]::GetThreadContext($h, $c); [void][T.S]::ResumeThread($h); [void][T.S]::CloseHandle($h)
        if (-not $ok) { continue }
        $eip = [BitConverter]::ToUInt32($c, 184)
        $m = $mods | Where-Object { $eip -ge $_.B -and $eip -lt $_.E } | Select-Object -First 1
        $key = 'T{0,-6} {1}+0x{2:X}' -f $t.Id, $(if ($m) { $m.N } else { '?' }), $(if ($m) { $eip - $m.B } else { $eip })
        # Rueckspruenge in die EXE auf dem Stack (Heuristik: Stackwoerter im Bereich der EXE)
        $esp = [BitConverter]::ToUInt32($c, 196); $buf = New-Object byte[] 8192; $r = 0
        if ([T.S]::ReadProcessMemory($hp, [IntPtr][int64]$esp, $buf, 8192, [ref]$r)) {
            $rets = @(); for ($o = 0; $o -lt $r -and $rets.Count -lt 10; $o += 4) { $v = [BitConverter]::ToUInt32($buf, $o); if ($v -ge $eb -and $v -lt $ee) { $rets += ('0x{0:X}' -f $v) } }
            $key += '  <- ' + ($rets -join ' ')
        }
        $hits[$key]++
    }
    Start-Sleep -Milliseconds 50
}
$hits.GetEnumerator() | Sort-Object Value -Descending | Select-Object -First 25 | ForEach-Object { '{0,4}x  {1}' -f $_.Value, $_.Key }
