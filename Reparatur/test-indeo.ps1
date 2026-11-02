# Test R3: oeffnet den Indeo-3.2-Decoder ueber Video for Windows. Muss in 32-Bit-PowerShell laufen:
#   C:\Windows\SysWOW64\WindowsPowerShell\v1.0\powershell.exe -ExecutionPolicy Bypass -File test-indeo.ps1
Add-Type -Namespace VfW -Name Ic -MemberDefinition @'
[StructLayout(LayoutKind.Sequential, CharSet=CharSet.Unicode)]
public struct ICINFO { public uint dwSize, fccType, fccHandler, dwFlags, dwVersion, dwVersionICM;
  [MarshalAs(UnmanagedType.ByValTStr, SizeConst=16)] public string szName;
  [MarshalAs(UnmanagedType.ByValTStr, SizeConst=128)] public string szDescription;
  [MarshalAs(UnmanagedType.ByValTStr, SizeConst=128)] public string szDriver; }
[DllImport("msvfw32.dll")] public static extern IntPtr ICOpen(uint fccType, uint fccHandler, uint mode);
[DllImport("msvfw32.dll")] public static extern int ICGetInfo(IntPtr hic, ref ICINFO info, int cb);
[DllImport("msvfw32.dll")] public static extern int ICClose(IntPtr hic);
'@
"Prozess 64-Bit: $([Environment]::Is64BitProcess)"
$h = [VfW.Ic]::ICOpen(0x63646976, 0x32337669, 2)   # 'vidc', 'iv32', ICMODE_DECOMPRESS
if ($h -eq [IntPtr]::Zero) { 'FEHLER: ICOpen(vidc, iv32) fehlgeschlagen'; exit 1 }
$i = New-Object VfW.Ic+ICINFO
$i.dwSize = [Runtime.InteropServices.Marshal]::SizeOf($i)
[void][VfW.Ic]::ICGetInfo($h, [ref]$i, $i.dwSize)
"OK: Codec geoeffnet - Name='$($i.szName)' Beschreibung='$($i.szDescription)'"
[void][VfW.Ic]::ICClose($h)
