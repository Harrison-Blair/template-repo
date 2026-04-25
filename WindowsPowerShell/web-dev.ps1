<#
web-dev.ps1 — Launch web-dev stack on Windows 11 (3 monitors, left → right)

Monitor 1 (left, horizontal):
  - Firefox            (left 3/5)        -> http://localhost:3000
  - Windows Terminal   (right 2/5, top)  -> Windows PowerShell, cd C:\source
  - Windows Terminal   (right 2/5, bot)  -> Windows PowerShell, cd C:\source
Monitor 2 (middle, main, horizontal):
  - VS Code (maximized)
Monitor 3 (right, vertical):
  - Firefox (top 1/2)    -> https://github.com
  - Firefox (bottom 1/2) -> iCloud, Gmail, Google Calendar (Calendar active)

Background:
  - Docker Desktop launched minimized (no positioning).

Usage:
  powershell.exe -ExecutionPolicy Bypass -File .\web-dev.ps1
  (or pin a shortcut whose Target is the line above)

Snap Layouts note:
  Built-in Snap Layouts requires no registration — any standard top-level
  window is auto-detected on hover/Win+Z. This script positions each window
  at the same fractional coordinates Snap Layouts would, so once placed
  they remain re-snappable from the layouts flyout.
#>

# ---------- Win32 helper ----------
if (-not ('WinApi' -as [type])) {
Add-Type -TypeDefinition @"
using System;
using System.Runtime.InteropServices;
using System.Text;
using System.Collections.Generic;
using System.Diagnostics;

public class WinApi {
    [DllImport("user32.dll")] public static extern bool SetWindowPos(IntPtr h, IntPtr a, int x, int y, int cx, int cy, uint f);
    [DllImport("user32.dll")] public static extern bool ShowWindow(IntPtr h, int cmd);
    [DllImport("user32.dll")] public static extern bool IsWindowVisible(IntPtr h);
    [DllImport("user32.dll")] public static extern bool SetForegroundWindow(IntPtr h);
    [DllImport("user32.dll")] public static extern bool BringWindowToTop(IntPtr h);
    [DllImport("user32.dll")] public static extern int  GetClassName(IntPtr h, StringBuilder s, int n);
    [DllImport("user32.dll")] public static extern uint GetWindowThreadProcessId(IntPtr h, out uint pid);
    [DllImport("user32.dll")] public static extern bool EnumWindows(EnumProc cb, IntPtr lp);
    public delegate bool EnumProc(IntPtr h, IntPtr lp);

    public static IntPtr[] Find(string klass, string procName) {
        var list = new List<IntPtr>();
        EnumWindows((h, l) => {
            if (!IsWindowVisible(h)) return true;
            var sb = new StringBuilder(256);
            GetClassName(h, sb, 256);
            string cls = sb.ToString();
            if (!string.IsNullOrEmpty(klass) && !cls.Contains(klass)) return true;
            if (!string.IsNullOrEmpty(procName)) {
                uint pid; GetWindowThreadProcessId(h, out pid);
                try {
                    var p = Process.GetProcessById((int)pid);
                    if (p.ProcessName.IndexOf(procName, StringComparison.OrdinalIgnoreCase) < 0) return true;
                } catch { return true; }
            }
            list.Add(h);
            return true;
        }, IntPtr.Zero);
        return list.ToArray();
    }
}
"@
}

# ---------- helpers ----------
function Wait-NewWindow {
    param([string]$Class, [string]$Process, [IntPtr[]]$Existing, [int]$TimeoutSec = 20)
    $set = @{}
    foreach ($h in $Existing) { $set[$h.ToInt64()] = $true }
    $deadline = (Get-Date).AddSeconds($TimeoutSec)
    while ((Get-Date) -lt $deadline) {
        Start-Sleep -Milliseconds 300
        foreach ($h in [WinApi]::Find($Class, $Process)) {
            if (-not $set.ContainsKey($h.ToInt64())) { return $h }
        }
    }
    return [IntPtr]::Zero
}

function Move-Window {
    param([IntPtr]$Handle, [int]$X, [int]$Y, [int]$W, [int]$H, [switch]$Maximize)
    if ($Handle -eq [IntPtr]::Zero) { Write-Host "  (window not found, skipping)" -ForegroundColor Yellow; return }
    [WinApi]::ShowWindow($Handle, 9) | Out-Null         # SW_RESTORE
    Start-Sleep -Milliseconds 120
    [WinApi]::SetWindowPos($Handle, [IntPtr]::Zero, $X, $Y, $W, $H, 0x44) | Out-Null  # NOZORDER|SHOWWINDOW
    if ($Maximize) {
        Start-Sleep -Milliseconds 120
        [WinApi]::ShowWindow($Handle, 3) | Out-Null     # SW_MAXIMIZE
    }
}

function Focus-Window {
    param([IntPtr]$Handle)
    if ($Handle -eq [IntPtr]::Zero) { return }
    # Alt-key trick bypasses Windows focus-stealing prevention
    (New-Object -ComObject wscript.shell).SendKeys('%')
    [WinApi]::BringWindowToTop($Handle) | Out-Null
    [WinApi]::SetForegroundWindow($Handle) | Out-Null
    Start-Sleep -Milliseconds 250
}

function Find-First { param([string[]]$Paths) foreach ($p in $Paths) { if (Test-Path $p) { return $p } }; return $null }

# ---------- monitor detection ----------
Add-Type -AssemblyName System.Windows.Forms
$screens = [System.Windows.Forms.Screen]::AllScreens | Sort-Object { $_.Bounds.X }
if ($screens.Count -lt 3) {
    Write-Host "Expected 3 monitors, found $($screens.Count). Aborting." -ForegroundColor Red
    exit 1
}
$M1 = $screens[0].WorkingArea
$M2 = $screens[1].WorkingArea
$M3 = $screens[2].WorkingArea
Write-Host ("Monitor 1 (left) : {0}x{1} @ {2},{3}" -f $M1.Width, $M1.Height, $M1.X, $M1.Y)
Write-Host ("Monitor 2 (main) : {0}x{1} @ {2},{3}" -f $M2.Width, $M2.Height, $M2.X, $M2.Y)
Write-Host ("Monitor 3 (right): {0}x{1} @ {2},{3}" -f $M3.Width, $M3.Height, $M3.X, $M3.Y)

# ---------- resolve binaries ----------
$Firefox = Find-First @(
    "$env:ProgramFiles\Mozilla Firefox\firefox.exe",
    "${env:ProgramFiles(x86)}\Mozilla Firefox\firefox.exe"
)
$VsCode = Find-First @(
    "$env:LOCALAPPDATA\Programs\Microsoft VS Code\Code.exe",
    "$env:ProgramFiles\Microsoft VS Code\Code.exe"
)
$Docker = Find-First @(
    "$env:ProgramFiles\Docker\Docker\Docker Desktop.exe",
    "${env:ProgramFiles(x86)}\Docker\Docker\Docker Desktop.exe"
)
if (-not $Firefox) { Write-Host "Firefox not found." -ForegroundColor Red; exit 1 }
if (-not $VsCode)  { Write-Host "VS Code not found."  -ForegroundColor Red; exit 1 }
if (-not $Docker)  { Write-Host "Docker Desktop not found." -ForegroundColor Yellow }
if (-not (Get-Command wt.exe -ErrorAction SilentlyContinue)) {
    Write-Host "Windows Terminal (wt.exe) not found." -ForegroundColor Red; exit 1
}

# ---------- layout math ----------
$ff1_w = [int]($M1.Width * 3 / 5)
$ps_x  = $M1.X + $ff1_w
$ps_w  = $M1.Width - $ff1_w
$ps_h  = [int]($M1.Height / 2)
$ff3_h = [int]($M3.Height / 2)
$ff3_y = $M3.Y + $ff3_h

# ===== launch & place =====

# Docker Desktop -> launch minimized (no positioning, just start it in the background)
if ($Docker) {
    Write-Host "Launching Docker Desktop (minimized)..."
    $ex = [WinApi]::Find("Chrome_WidgetWin_1", "Docker Desktop")
    Start-Process -FilePath $Docker -WindowStyle Minimized | Out-Null
    $h = Wait-NewWindow "Chrome_WidgetWin_1" "Docker Desktop" $ex
    if ($h -ne [IntPtr]::Zero) {
        [WinApi]::ShowWindow($h, 7) | Out-Null   # SW_SHOWMINNOACTIVE
    }
}

# Firefox -> Monitor 1, left 3/5
Write-Host "Launching Firefox (localhost:3000)..."
$ex = [WinApi]::Find("MozillaWindowClass", "firefox")
Start-Process -FilePath $Firefox -ArgumentList '-new-window','http://localhost:3000' | Out-Null
$h = Wait-NewWindow "MozillaWindowClass" "firefox" $ex
Move-Window -Handle $h -X $M1.X -Y $M1.Y -W $ff1_w -H $M1.Height

# Windows Terminal -> Monitor 1, right 2/5, top half
Write-Host "Launching Windows Terminal (top)..."
$ex = [WinApi]::Find("CASCADIA_HOSTING_WINDOW_CLASS", "WindowsTerminal")
Start-Process -FilePath "wt.exe" -ArgumentList '-w','new','powershell.exe','-NoExit','-NoLogo','-Command','Set-Location C:\source' | Out-Null
$h = Wait-NewWindow "CASCADIA_HOSTING_WINDOW_CLASS" "WindowsTerminal" $ex
Move-Window -Handle $h -X $ps_x -Y $M1.Y -W $ps_w -H $ps_h

# Windows Terminal -> Monitor 1, right 2/5, bottom half
Write-Host "Launching Windows Terminal (bottom)..."
Start-Sleep -Milliseconds 400
$ex = [WinApi]::Find("CASCADIA_HOSTING_WINDOW_CLASS", "WindowsTerminal")
Start-Process -FilePath "wt.exe" -ArgumentList '-w','new','powershell.exe','-NoExit','-NoLogo','-Command','Set-Location C:\source' | Out-Null
$h = Wait-NewWindow "CASCADIA_HOSTING_WINDOW_CLASS" "WindowsTerminal" $ex
Move-Window -Handle $h -X $ps_x -Y ($M1.Y + $ps_h) -W $ps_w -H ($M1.Height - $ps_h)

# VS Code -> Monitor 2, maximized
Write-Host "Launching VS Code..."
$ex = [WinApi]::Find("Chrome_WidgetWin_1", "Code")
Start-Process -FilePath $VsCode -ArgumentList '-n' | Out-Null
$h = Wait-NewWindow "Chrome_WidgetWin_1" "Code" $ex
Move-Window -Handle $h -X $M2.X -Y $M2.Y -W $M2.Width -H $M2.Height -Maximize

# Firefox -> Monitor 3, top 1/2 (GitHub)
Write-Host "Launching Firefox (GitHub)..."
$ex = [WinApi]::Find("MozillaWindowClass", "firefox")
Start-Process -FilePath $Firefox -ArgumentList '-new-window','https://github.com' | Out-Null
$h = Wait-NewWindow "MozillaWindowClass" "firefox" $ex
Move-Window -Handle $h -X $M3.X -Y $M3.Y -W $M3.Width -H $ff3_h

# Firefox -> Monitor 3, bottom 1/2 (iCloud window, then Gmail + Calendar tabs)
Write-Host "Launching Firefox (iCloud / Gmail / Calendar)..."
Start-Sleep -Milliseconds 400
$ex = [WinApi]::Find("MozillaWindowClass", "firefox")
Start-Process -FilePath $Firefox -ArgumentList '-new-window','https://www.icloud.com' | Out-Null
$h = Wait-NewWindow "MozillaWindowClass" "firefox" $ex
Move-Window -Handle $h -X $M3.X -Y $ff3_y -W $M3.Width -H ($M3.Height - $ff3_h)

# Force focus to this window so subsequent -new-tab calls land here
Focus-Window -Handle $h
Start-Process -FilePath $Firefox -ArgumentList '-new-tab','https://mail.google.com' | Out-Null
Start-Sleep -Milliseconds 600
Focus-Window -Handle $h
Start-Process -FilePath $Firefox -ArgumentList '-new-tab','https://calendar.google.com' | Out-Null

Write-Host "Done." -ForegroundColor Green