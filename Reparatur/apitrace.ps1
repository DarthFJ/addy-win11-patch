# Mini-API-Tracer (nur Diagnose): startet ADI4.EXE unter Debugger-Kontrolle und protokolliert
# Aufrufe ausgewaehlter Windows-APIs (Argumente + Rueckgabewert) sowie den Aufrufer von ExitProcess.
# MUSS in 32-Bit-PowerShell laufen:
#   C:\Windows\SysWOW64\WindowsPowerShell\v1.0\powershell.exe -ExecutionPolicy Bypass -File apitrace.ps1
param([string]$Exe = 'C:\COKTEL\ADDY4\ADI4.EXE', [string]$Dir = 'C:\COKTEL\ADDY4', [int]$Seconds = 30,
      [switch]$EmulateWin95Atom, [switch]$Light, [string]$Probe = '', [switch]$Blits, [int]$WatchX = -1, [int]$WatchY = -1, [string]$MemPatch = '')
if ([Environment]::Is64BitProcess) { throw 'Bitte mit 32-Bit-PowerShell (SysWOW64) starten.' }

Add-Type -TypeDefinition @'
using System;
using System.Collections.Generic;
using System.Runtime.InteropServices;
using System.Text;

public static class Tracer {
  [StructLayout(LayoutKind.Sequential, CharSet=CharSet.Ansi)]
  struct SI { public int cb; public string r, d, t; public int x, y, w, h, cx, cy, fa, fl; public short sw, cb2; public IntPtr r2, i, o, e; }
  [StructLayout(LayoutKind.Sequential)] struct PI { public IntPtr hp, ht; public int pid, tid; }
  [DllImport("kernel32.dll", CharSet=CharSet.Ansi, SetLastError=true)]
  static extern bool CreateProcess(string app, string cmd, IntPtr pa, IntPtr ta, bool inh, uint flags, IntPtr env, string dir, ref SI si, out PI pi);
  [DllImport("kernel32.dll")] static extern bool WaitForDebugEvent([Out] byte[] ev, uint ms);
  [DllImport("kernel32.dll")] static extern bool ContinueDebugEvent(int pid, int tid, uint status);
  [DllImport("kernel32.dll")] static extern bool ReadProcessMemory(IntPtr h, IntPtr a, [Out] byte[] b, int n, out int r);
  [DllImport("kernel32.dll")] static extern bool WriteProcessMemory(IntPtr h, IntPtr a, byte[] b, int n, out int w);
  [DllImport("kernel32.dll")] static extern bool FlushInstructionCache(IntPtr h, IntPtr a, int n);
  [DllImport("kernel32.dll")] static extern IntPtr OpenThread(uint acc, bool inh, int tid);
  [DllImport("kernel32.dll")] static extern bool GetThreadContext(IntPtr t, [In, Out] byte[] c);
  [DllImport("kernel32.dll")] static extern bool SetThreadContext(IntPtr t, byte[] c);
  [DllImport("kernel32.dll")] static extern bool TerminateProcess(IntPtr h, uint c);
  [DllImport("kernel32.dll", CharSet=CharSet.Ansi)] static extern IntPtr GetModuleHandle(string n);
  [DllImport("kernel32.dll", CharSet=CharSet.Ansi)] static extern IntPtr LoadLibrary(string n);
  [DllImport("kernel32.dll", CharSet=CharSet.Ansi)] static extern IntPtr GetProcAddress(IntPtr m, string n);
  [DllImport("kernel32.dll", CharSet=CharSet.Unicode)] static extern int GetFinalPathNameByHandleW(IntPtr h, StringBuilder s, int n, int f);

  class Bp { public string Name; public int[] StrArgs; public int NArgs; public byte Orig; public bool OneShot; public string Info; }
  static IntPtr hp; static Dictionary<uint, Bp> bps = new Dictionary<uint, Bp>();
  static Dictionary<int, uint> reinsert = new Dictionary<int, uint>();
  static List<string> log = new List<string>();
  static DateTime t0;

  static void L(string s) { string l = string.Format("{0,6:F2}s {1}", (DateTime.Now - t0).TotalSeconds, s); log.Add(l); Console.WriteLine(l); }
  static uint R32(uint a) { var b = new byte[4]; int r; ReadProcessMemory(hp, (IntPtr)a, b, 4, out r); return BitConverter.ToUInt32(b, 0); }
  static string Str(uint a) {
    if (a < 0x10000) return a == 0 ? "NULL" : "#" + a;
    var b = new byte[300]; int r; if (!ReadProcessMemory(hp, (IntPtr)a, b, 300, out r)) return "?";
    int n = Array.IndexOf(b, (byte)0); if (n < 0) n = 300;
    return "\"" + Encoding.Default.GetString(b, 0, n) + "\"";
  }
  static byte RB(uint a) { var b = new byte[1]; int r; ReadProcessMemory(hp, (IntPtr)a, b, 1, out r); return b[0]; }
  static void WB(uint a, byte v) { int w; WriteProcessMemory(hp, (IntPtr)a, new[] { v }, 1, out w); FlushInstructionCache(hp, (IntPtr)a, 1); }
  static void Set(uint a, Bp b) { if (bps.ContainsKey(a)) return; b.Orig = RB(a); bps[a] = b; WB(a, 0xCC); }

  public static bool Win95Atom, Light;
  static int atomCalls, wogp, wout;
  static Dictionary<string, int> cnt = new Dictionary<string, int>();
  public static bool Blits;
  static void HookBlit(string dll, string fn) {
    IntPtr m = GetModuleHandle(dll); if (m == IntPtr.Zero) m = LoadLibrary(dll);
    IntPtr p = GetProcAddress(m, fn); if (p == IntPtr.Zero) { Console.WriteLine("kein " + fn); return; }
    Set((uint)p, new Bp { Name = "BLIT:" + fn, NArgs = 0, StrArgs = new int[0] });
  }
  static readonly string[] Noisy = { "GetTickCount", "timeGetTime", "PeekMessageA", "GetLastError", "GetCurrentDirectoryA", "_lread", "_llseek",
    "ReadFile", "SetFilePointer", "CloseHandle", "lstrcmpiA", "GetSystemMetrics", "GetDeviceCaps", "GetMessageA", "_lclose" };
  public static string Probe, MemPatch;
  public static int WatchX = -1, WatchY = -1;
  static bool hwSet; static uint hwAddr; static int hwTid; static HashSet<string> hwSeen = new HashSet<string>(); static int hwHits;
  static int probeHits;
  static void HookAddr(uint a) { Set(a, new Bp { Name = "PROBE", NArgs = 0, StrArgs = new int[0] }); }
  static void Hook(string dll, string fn, int nargs, params int[] strArgs) {
    if (Light && Array.IndexOf(Noisy, fn) >= 0) return;
    IntPtr m = GetModuleHandle(dll); if (m == IntPtr.Zero) m = LoadLibrary(dll);
    IntPtr p = GetProcAddress(m, fn); if (p == IntPtr.Zero) { Console.WriteLine("kein " + fn); return; }
    Set((uint)p, new Bp { Name = fn, NArgs = nargs, StrArgs = strArgs });
  }

  public static string[] Run(string exe, string dir, int seconds) {
    t0 = DateTime.Now;
    var si = new SI(); si.cb = Marshal.SizeOf(si); PI pi;
    if (!CreateProcess(exe, "\"" + exe + "\"", IntPtr.Zero, IntPtr.Zero, false, 2, IntPtr.Zero, dir, ref si, out pi))
      throw new Exception("CreateProcess " + Marshal.GetLastWin32Error());
    hp = pi.hp;
    var ev = new byte[96]; var ctx = new byte[716];
    bool hooked = false;
    while ((DateTime.Now - t0).TotalSeconds < seconds) {
      if (!WaitForDebugEvent(ev, 500)) continue;
      int code = BitConverter.ToInt32(ev, 0), pid = BitConverter.ToInt32(ev, 4), tid = BitConverter.ToInt32(ev, 8);
      uint cont = 0x00010002;
      if (code == 1) {
        uint exc = BitConverter.ToUInt32(ev, 12), addr = BitConverter.ToUInt32(ev, 24);
        bool first = BitConverter.ToInt32(ev, 92) != 0;
        if (exc == 0x80000003 && !hooked) {
          hooked = true;
          Hook("kernel32.dll", "CreateFileA", 7, 0); Hook("kernel32.dll", "OpenFile", 3, 0); Hook("kernel32.dll", "_lopen", 2, 0);
          Hook("kernel32.dll", "_lcreat", 2, 0); Hook("kernel32.dll", "FindFirstFileA", 2, 0); Hook("kernel32.dll", "GetFileAttributesA", 1, 0);
          Hook("kernel32.dll", "GetDriveTypeA", 1, 0); Hook("kernel32.dll", "GetVolumeInformationA", 8, 0); Hook("kernel32.dll", "LoadLibraryA", 1, 0);
          Hook("kernel32.dll", "GetPrivateProfileStringA", 6, 0, 1, 2, 5); Hook("kernel32.dll", "GetPrivateProfileIntA", 4, 0, 1, 3);
          Hook("kernel32.dll", "WritePrivateProfileStringA", 4, 0, 1, 2, 3);
          Hook("kernel32.dll", "CreateProcessA", 10, 0, 1); Hook("kernel32.dll", "WinExec", 2, 0); Hook("kernel32.dll", "ExitProcess", 1);
          Hook("kernel32.dll", "SetCurrentDirectoryA", 1, 0); Hook("kernel32.dll", "GetLogicalDrives", 0);
          Hook("kernel32.dll", "CreateMutexA", 3, 2); Hook("kernel32.dll", "GlobalFindAtomA", 1, 0); Hook("kernel32.dll", "GlobalAddAtomA", 1, 0);
          Hook("user32.dll", "MessageBoxA", 4, 1, 2); Hook("user32.dll", "FindWindowA", 2, 0, 1); Hook("user32.dll", "CreateWindowExA", 12, 1, 2);
          Hook("user32.dll", "ChangeDisplaySettingsA", 2); Hook("user32.dll", "GetSystemMetrics", 1);
          Hook("gdi32.dll", "GetDeviceCaps", 2);
          Hook("advapi32.dll", "RegOpenKeyExA", 5, 1); Hook("advapi32.dll", "RegQueryValueExA", 6, 1);
          Hook("winmm.dll", "waveOutGetNumDevs", 0); Hook("winmm.dll", "mciSendStringA", 4, 0);
          Hook("kernel32.dll", "_lread", 3); Hook("kernel32.dll", "_llseek", 3); Hook("kernel32.dll", "_lclose", 1);
          Hook("kernel32.dll", "GlobalDeleteAtom", 1); Hook("kernel32.dll", "GetLastError", 0);
          Hook("kernel32.dll", "FindNextFileA", 2); Hook("kernel32.dll", "GetCurrentDirectoryA", 2);
          Hook("kernel32.dll", "LoadLibraryExA", 3, 0); Hook("kernel32.dll", "GetModuleFileNameA", 3);
          Hook("kernel32.dll", "lstrcmpiA", 2, 0, 1);
          Hook("winmm.dll", "waveOutGetPosition", 3); Hook("winmm.dll", "waveOutOpen", 6); Hook("winmm.dll", "waveOutWrite", 3);
          Hook("winmm.dll", "waveOutReset", 1); Hook("winmm.dll", "waveOutPause", 1); Hook("winmm.dll", "waveOutRestart", 1); Hook("winmm.dll", "waveOutClose", 1);
          Hook("kernel32.dll", "ReadFile", 5); Hook("kernel32.dll", "SetFilePointer", 4); Hook("kernel32.dll", "CloseHandle", 1);
          Hook("kernel32.dll", "GetTickCount", 0); Hook("winmm.dll", "timeGetTime", 0);
          Hook("user32.dll", "EnumDisplaySettingsA", 3, 0); Hook("user32.dll", "ShowWindow", 2); Hook("user32.dll", "PostQuitMessage", 1);
          Hook("user32.dll", "DestroyWindow", 1); Hook("user32.dll", "PeekMessageA", 5); Hook("user32.dll", "GetMessageA", 4);
          if (Blits) {
            foreach (var f in new[] { "BitBlt", "StretchBlt", "StretchDIBits", "SetDIBitsToDevice", "PatBlt" }) HookBlit("gdi32.dll", f);
            foreach (var f in new[] { "InvalidateRect", "UpdateWindow", "RedrawWindow", "GetDC", "ReleaseDC" }) HookBlit("user32.dll", f);
          }
          if (!string.IsNullOrEmpty(MemPatch)) foreach (var mp in MemPatch.Split(',')) {
            var pr = mp.Split(':'); uint pa = Convert.ToUInt32(pr[0].Trim(), 16);
            byte[] nb = new byte[pr[2].Length / 2]; for (int q = 0; q < nb.Length; q++) nb[q] = Convert.ToByte(pr[2].Substring(2 * q, 2), 16);
            byte[] ob = new byte[nb.Length]; int rr; ReadProcessMemory(hp, (IntPtr)pa, ob, ob.Length, out rr);
            string obs = BitConverter.ToString(ob).Replace("-", "").ToLower();
            if (obs != pr[1].ToLower()) { L("SPEICHERPATCH abgelehnt @0x" + pa.ToString("X") + ": erwartet " + pr[1] + ", gefunden " + obs); continue; }
            int ww; WriteProcessMemory(hp, (IntPtr)pa, nb, nb.Length, out ww); FlushInstructionCache(hp, (IntPtr)pa, nb.Length);
            L("SPEICHERPATCH @0x" + pa.ToString("X") + ": " + obs + " -> " + pr[2] + " (nur im Speicher)");
          }
          if (!string.IsNullOrEmpty(Probe)) foreach (var p in Probe.Split(',')) HookAddr(Convert.ToUInt32(p.Trim(), 16));
          L("Hooks gesetzt: " + bps.Count);
        } else if ((exc == 0x80000003 || exc == 0x4000001F) && bps.ContainsKey(addr)) {
          var b = bps[addr];
          IntPtr th = OpenThread(0x1FFFFF, false, tid);
          BitConverter.GetBytes(0x10007).CopyTo(ctx, 0); GetThreadContext(th, ctx);
          uint esp = BitConverter.ToUInt32(ctx, 196), eax = BitConverter.ToUInt32(ctx, 176), ebp = BitConverter.ToUInt32(ctx, 180);
          BitConverter.GetBytes(addr).CopyTo(ctx, 184);
          if (b.OneShot) {
            if (b.Info.StartsWith("WOGP:")) {
              uint mm = uint.Parse(b.Info.Substring(5));
              L("    <- waveOutGetPosition = " + eax + "  MMTIME.wType=" + R32(mm) + " Wert=" + R32(mm + 4));
            } else
            if (b.Info.StartsWith("ATOMFIX:")) {
              uint want = uint.Parse(b.Info.Substring(8));
              BitConverter.GetBytes(want).CopyTo(ctx, 176);
              L("    <- GlobalDeleteAtom: Rueckgabe " + eax + " durch Win95-Verhalten 0x" + want.ToString("X") + " ersetzt (nur im Speicher)");
            } else
            L("    <- " + b.Info + " = 0x" + eax.ToString("X"));
            WB(addr, b.Orig); bps.Remove(addr);
          } else {
            uint ret = R32(esp);
            var sb = new StringBuilder();
            for (int i = 0; i < b.NArgs && i < 6; i++) {
              uint v = R32(esp + 4 + (uint)(4 * i));
              sb.Append(i > 0 ? ", " : "").Append(Array.IndexOf(b.StrArgs, i) >= 0 ? Str(v) : "0x" + v.ToString("X"));
            }
            if (b.Name == "PROBE" && addr != 0x460801 && addr != 0x4608c6 && addr != 0x4608e7) {
              int pc; cnt.TryGetValue("P" + addr, out pc); cnt["P" + addr] = ++pc;
              if ((addr == 0x42bab0 || addr == 0x42b9ff) && (pc <= 30 || pc % 20 == 0)) {
                uint ebxv = BitConverter.ToUInt32(ctx, 164); uint sf = R32(ebxv + 0x16); uint obj = R32(ebp + 8);
                L(string.Format("ZEICHNEN@0x{0:X} #{1}: dirty=({2},{3})-({4},{5}) vmdRect x={6} y={7} w={8} h={9} flaeche B={10} H={11} obj=({12},{13}) vmd=0x{14:X} bild={15}",
                  addr, pc, (int)R32(0x490ab0), (int)R32(0x490ab8), (int)R32(0x490ab4), (int)R32(0x490abc),
                  (short)R32(ebxv + 6), (short)R32(ebxv + 8), (short)R32(ebxv + 0xa), (short)R32(ebxv + 0xc), (int)R32(sf), (int)R32(sf + 4),
                  (short)R32(obj), (short)R32(obj + 2), ebxv, (int)R32(ebxv + 0x33a)));
              } else
              if (addr == 0x42088d || (addr == 0x4208a0 && (pc <= 3 || pc % 20 == 0))) {
                L(string.Format("TAKT@0x{0:X} #{1}: fps484eca={2} periode484ec8={3}ms start484ed0={4} rest484ec4={5}",
                  addr, pc, (short)R32(0x484eca), (short)R32(0x484ec8), (int)R32(0x484ed0), (int)R32(0x484ec4)));
              } else
              if (addr == 0x42b6a0 && (pc <= 5 || pc % 20 == 0)) {
                uint sp = BitConverter.ToUInt32(ctx, 196);
                uint obj = R32(sp + 4); uint vmd = R32(obj + 6);
                L(string.Format("OP42B6A0 #{0}: bildNr={1} param10=0x{2:X} p14={3} p18={4} letztes1C={5} ende20={6} vmd=0x{7:X} vmdFrames={8} aktBild33a={9} flags346=0x{10:X} fl329=0x{11:X} flaeche16=0x{12:X}",
                  pc, (short)R32(sp + 8), R32(sp + 12) & 0xFFFF, (short)R32(sp + 16), (short)R32(sp + 20), (short)R32(sp + 24), (short)R32(sp + 28),
                  vmd, (short)R32(vmd + 4), (int)R32(vmd + 0x33a), R32(vmd + 0x346) & 0xFFFF, R32(vmd + 0x329) & 0xFF, R32(vmd + 0x16)));
              } else
              if (addr == 0x461432 && (pc <= 8 || pc % 10 == 0)) {
                uint ebxv = BitConverter.ToUInt32(ctx, 164); uint sf = R32(ebxv + 0x16);
                L(string.Format("RENDER #{0}: zoom490acc={1} bpp482={2} x={3} y={4} w={5} h={6} flaeche=0x{7:X} (B={8} H={9} flags10=0x{10:X} pix=0x{11:X}) erzwungen8bit={12} typ={13}",
                  pc, R32(0x490acc) & 0xFF, (int)R32(ebxv + 0x482), (short)R32(ebxv + 6), (short)R32(ebxv + 8), (short)R32(ebxv + 0xa), (short)R32(ebxv + 0xc),
                  sf, (int)R32(sf), (int)R32(sf + 4), R32(sf + 0x10) & 0xFF, R32(sf + 0x14), R32(ebp - 0x15) & 0xFF, RB(R32(0x490aa4)).ToString("X2")));
              } else
              if (pc <= 3 || pc % 25 == 0) {
                uint f = ebp; var ch = new StringBuilder();
                for (int k = 0; k < 6 && f > 0x10000 && f < 0x7FFF0000; k++) { ch.Append(" 0x" + R32(f + 4).ToString("X")); f = R32(f); }
                L(string.Format("HIT@0x{0:X} #{1} eax=0x{2:X} ebx=0x{3:X} esi=0x{4:X} edi=0x{5:X} Kette:{6}", addr, pc, eax,
                  BitConverter.ToUInt32(ctx, 164), BitConverter.ToUInt32(ctx, 160), BitConverter.ToUInt32(ctx, 156), ch));
              }
            } else
            if (b.Name == "PROBE") {
              probeHits++;
              if (probeHits <= 20 || probeHits % 300 == 0) {
                uint ebx = BitConverter.ToUInt32(ctx, 164), esi = BitConverter.ToUInt32(ctx, 160);
                if (addr == 0x460801)
                L(string.Format("PROBE@0x{0:X} #{1}: eax(lag_ms)={2} esi(ton_ms)={3} vmdRate={4} globRate={5} flag48a550={6} startT={7} startPos={8} mode48e={9} t={10}",
                  addr, probeHits, (int)eax, (int)esi, R32(ebx + 0x350) & 0xFFFF, R32(0x487c68) & 0xFFFF, R32(0x48a550) & 0xFF,
                  R32(ebx + 0x342), R32(ebx + 0x48a), R32(ebx + 0x48e) & 0xFF, R32(ebx + 0x10)));
                else
                L(string.Format("PROBE@0x{0:X} #{1}: faellig_ms(eax)={2} vergangen_ms(esi)={3} bildNr={4} samplesProBild={5} rate={6} fps366={7} zaehler486={8} flagsF=0x{9:X} vmd=0x{10:X}",
                  addr, probeHits, (int)eax, (int)esi, (short)(R32(ebp - 0x18) & 0xFFFF), (short)(R32(ebx + 0x324) & 0xFFFF), R32(ebx + 0x350) & 0xFFFF,
                  (int)R32(ebx + 0x366), (int)R32(ebx + 0x486), R32(ebx + 0xf) & 0xFF, ebx));
              }
            }
            bool app = (ret < 0x10000000 || b.Name.StartsWith("BLIT:")) && b.Name != "PROBE";
            if (app) {
              string call = b.Name + "(" + sb + ") von 0x" + ret.ToString("X");
              if (b.Name == "CreateWindowExA" || b.Name == "_lopen" || b.Name == "EnumDisplaySettingsA" || b.Name == "ChangeDisplaySettingsA") {
                uint f = ebp; call += "  [Kette:"; for (int k = 0; k < 8 && f > 0x10000 && f < 0x7FFF0000; k++) { call += " 0x" + R32(f + 4).ToString("X"); f = R32(f); } call += "]";
              }
              if (!b.Name.StartsWith("BLIT:") && !b.Name.StartsWith("waveOutGetPosition")) L(call);
              if (b.Name.StartsWith("BLIT:")) {
                int c; cnt.TryGetValue(b.Name, out c); cnt[b.Name] = ++c;
                if (b.Name == "BLIT:DrawDibDraw" && (c <= 5 || c % 5 == 0)) {
                  // Quellpuffer pruefen: BITMAPINFOHEADER (arg7) + Bits (arg8), Hash ueber das Quellrechteck
                  uint lpbi = R32(esp + 28), bits = R32(esp + 32);
                  int xs = (int)R32(esp + 36), ys = (int)R32(esp + 40), ws = (int)R32(esp + 44), hs = (int)R32(esp + 48);
                  int bw = (int)R32(lpbi + 4), bh = (int)R32(lpbi + 8); int bpp = (int)(R32(lpbi + 12) >> 16); uint comp = R32(lpbi + 16);
                  int stride = ((bw * bpp + 31) / 32) * 4; uint hsh = 2166136261; var row = new byte[Math.Max(1, ws * bpp / 8)];
                  for (int yy = ys; yy < ys + hs && yy < Math.Abs(bh); yy++) {
                    int line = bh > 0 ? (bh - 1 - yy) : yy;
                    int rr; ReadProcessMemory(hp, (IntPtr)(bits + (uint)(line * stride + xs * bpp / 8)), row, row.Length, out rr);
                    foreach (var by in row) { hsh ^= by; hsh *= 16777619; }
                  }
                  if (WatchX >= 0 && !hwSet && bw == 640 && bpp == 24) {
                    hwAddr = bits + (uint)((Math.Abs(bh) - 1 - WatchY) * stride + WatchX * 3);
                    hwTid = tid; hwSet = true;
                    var dc = new byte[716]; BitConverter.GetBytes(0x10010).CopyTo(dc, 0);
                    IntPtr th2 = OpenThread(0x1FFFFF, false, tid); GetThreadContext(th2, dc);
                    BitConverter.GetBytes(hwAddr).CopyTo(dc, 4); BitConverter.GetBytes(0u).CopyTo(dc, 20); BitConverter.GetBytes(0x00010001u).CopyTo(dc, 24);
                    SetThreadContext(th2, dc);
                    // auch im aktuellen Kontext (wird gleich zurueckgeschrieben)
                    BitConverter.GetBytes(hwAddr).CopyTo(ctx, 4); BitConverter.GetBytes(0x00010001u).CopyTo(ctx, 24);
                    BitConverter.GetBytes(BitConverter.ToUInt32(ctx, 0) | 0x10010).CopyTo(ctx, 0);
                    L(string.Format("Hardware-Haltepunkt: Pixel ({0},{1}) -> Adresse 0x{2:X} (Thread {3})", WatchX, WatchY, hwAddr, tid));
                  }
                  L(string.Format("DrawDibDraw #{0} dst=({1},{2}) src=({3},{4} {5}x{6}) bild={7}x{8}x{9}bpp comp={10} bits=0x{11:X} lpbi=0x{12:X} HASH=0x{13:X8}",
                    c, (int)R32(esp + 12), (int)R32(esp + 16), xs, ys, ws, hs, bw, bh, bpp, comp, bits, lpbi, hsh));
                } else
                if (c <= 5 || c % (b.Name == "BLIT:DrawDibDraw" ? 10 : 50) == 0) {
                  var sbb = new StringBuilder();
                  for (int i = 0; i < 13; i++) sbb.Append((i > 0 ? "," : "") + (int)R32(esp + 4 + (uint)(4 * i)));
                  L(b.Name.Substring(5) + " #" + c + " von 0x" + ret.ToString("X") + " args=" + sbb);
                }
              } else
              if (b.Name == "waveOutGetPosition") {
                wogp++;
                if (wogp <= 40 || wogp % 500 == 0) {
                  L("waveOutGetPosition #" + wogp + " (hwo=0x" + R32(esp + 4).ToString("X") + ") von 0x" + ret.ToString("X"));
                  if (!bps.ContainsKey(ret)) Set(ret, new Bp { Name = "ret", OneShot = true, Info = "WOGP:" + R32(esp + 8) });
                }
              } else if (b.Name == "waveOutOpen") {
                uint fx = R32(esp + 12);
                L(string.Format("waveOutOpen(dev={0}) Format: Tag={1} Kanaele={2} Rate={3} Bytes/s={4} Bits={5} Flags=0x{6:X} von 0x{7:X}",
                  (int)R32(esp + 8), R32(fx) & 0xFFFF, R32(fx) >> 16, R32(fx + 4), R32(fx + 8), R32(fx + 12) >> 16, R32(esp + 24), ret));
              } else if (b.Name == "waveOutWrite" || b.Name == "waveOutReset" || b.Name == "waveOutPause" || b.Name == "waveOutRestart" || b.Name == "waveOutClose") {
                wout++;
                if (wout <= 30 || wout % 200 == 0) L(b.Name + " #" + wout + " (hwo=0x" + R32(esp + 4).ToString("X") + (b.Name == "waveOutWrite" ? ", Puffer=" + R32(R32(esp + 8) + 4) + " Bytes" : "") + ")");
              } else
              if (b.Name == "GlobalDeleteAtom" && Win95Atom) {
                atomCalls++;
                uint arg = R32(esp + 4) & 0xFFFF;
                L("GlobalDeleteAtom(0x" + arg.ToString("X") + ") Aufruf " + atomCalls + " von 0x" + ret.ToString("X"));
                if (atomCalls >= 2 && !bps.ContainsKey(ret)) Set(ret, new Bp { Name = "ret", OneShot = true, Info = "ATOMFIX:" + arg });
              } else if (b.Name == "GlobalDeleteAtom") {
                var fr = new StringBuilder("    Aufraeumschleife erreicht, Aufrufkette (EBP):");
                uint f = ebp; for (int k = 0; k < 10 && f > 0x10000 && f < 0x7FFF0000; k++) { fr.Append(" 0x" + R32(f + 4).ToString("X")); f = R32(f); }
                L(fr.ToString());
                L("Prozess wird beendet (Endlosschleife unter Windows 11 vermeiden)");
                TerminateProcess(hp, 2);
              }
              if (b.Name == "ExitProcess") {
                var fr = new StringBuilder("    Aufrufkette (EBP):");
                uint f = ebp; for (int k = 0; k < 10 && f > 0x10000 && f < 0x7FFF0000; k++) { fr.Append(" 0x" + R32(f + 4).ToString("X")); f = R32(f); }
                L(fr.ToString());
              } else if (b.Name != "GlobalDeleteAtom" && !b.Name.StartsWith("waveOut") && !b.Name.StartsWith("BLIT:") && !bps.ContainsKey(ret)) {
                Set(ret, new Bp { Name = "ret", OneShot = true, Info = b.Name + "(" + sb + ")" });
              }
            }
            WB(addr, b.Orig);
            uint fl = BitConverter.ToUInt32(ctx, 192) | 0x100; BitConverter.GetBytes(fl).CopyTo(ctx, 192);
            reinsert[tid] = addr;
          }
          SetThreadContext(th, ctx);
        } else if ((exc == 0x80000004 || exc == 0x4000001E) && (reinsert.ContainsKey(tid) || hwSet)) {
          if (reinsert.ContainsKey(tid)) { uint a = reinsert[tid]; reinsert.Remove(tid); if (bps.ContainsKey(a)) WB(a, 0xCC); }
          if (hwSet) {
            IntPtr th3 = OpenThread(0x1FFFFF, false, tid);
            var hc = new byte[716]; BitConverter.GetBytes(0x10017).CopyTo(hc, 0); GetThreadContext(th3, hc);
            uint dr6 = BitConverter.ToUInt32(hc, 20);
            if ((dr6 & 1) != 0) {
              hwHits++;
              uint eip = BitConverter.ToUInt32(hc, 184), ebp2 = BitConverter.ToUInt32(hc, 180);
              var ch = new StringBuilder("0x" + eip.ToString("X"));
              uint f = ebp2; for (int k = 0; k < 7 && f > 0x10000 && f < 0x7FFF0000; k++) { ch.Append(" <- 0x" + R32(f + 4).ToString("X")); f = R32(f); }
              string key = ch.ToString();
              if (hwSeen.Add(key) || hwHits % 200 == 0) L("SCHREIBZUGRIFF #" + hwHits + " Pixel=0x" + R32(hwAddr).ToString("X6") + " " + key);
              BitConverter.GetBytes(0u).CopyTo(hc, 20); SetThreadContext(th3, hc);
            }
          }
        } else if (exc != 0x80000003) {
          L(string.Format("Ausnahme 0x{0:X8} bei 0x{1:X} (first={2})", exc, addr, first));
          cont = 0x80010001;
        }
      } else if (code == 5) {
        L("Prozess beendet, ExitCode " + BitConverter.ToUInt32(ev, 12));
        ContinueDebugEvent(pid, tid, cont); return log.ToArray();
      } else if (code == 6) {
        uint basea = BitConverter.ToUInt32(ev, 16);
        IntPtr hf = (IntPtr)BitConverter.ToInt32(ev, 12);
        var nb = new StringBuilder(520); string dn = "";
        if (hf != IntPtr.Zero && GetFinalPathNameByHandleW(hf, nb, 520, 0) > 0) dn = nb.ToString();
        if (!dn.ToLower().Contains("\\system32\\") || !Light) L("DLL geladen @0x" + basea.ToString("X") + " " + dn);
        if (Blits && dn.ToLower().EndsWith("msvfw32.dll") && hooked) {
          IntPtr lm = LoadLibrary("msvfw32.dll");
          foreach (var f in new[] { "DrawDibDraw", "DrawDibBegin", "DrawDibRealize", "DrawDibStart" }) {
            uint la = (uint)GetProcAddress(lm, f);
            uint ta = basea + (la - (uint)lm);
            Set(ta, new Bp { Name = "BLIT:" + f, NArgs = 0, StrArgs = new int[0] });
          }
          L("DrawDib-Hooks im Zielprozess gesetzt (msvfw32 @0x" + basea.ToString("X") + ")");
        }
      } else if (code == 8) {
        L("DebugString @0x" + BitConverter.ToUInt32(ev, 12).ToString("X") + ": " + Str(BitConverter.ToUInt32(ev, 12)));
      }
      ContinueDebugEvent(pid, tid, cont);
    }
    L("Zeitlimit erreicht - Prozess wird beendet (laeuft also noch)");
    TerminateProcess(hp, 1);
    return log.ToArray();
  }
}
'@
[Tracer]::Win95Atom = [bool]$EmulateWin95Atom
[Tracer]::Light = [bool]$Light
[Tracer]::Probe = $Probe
[Tracer]::MemPatch = $MemPatch
[Tracer]::Blits = [bool]$Blits
[Tracer]::WatchX = $WatchX; [Tracer]::WatchY = $WatchY
[Tracer]::Run($Exe, $Dir, $Seconds) | Out-Null
