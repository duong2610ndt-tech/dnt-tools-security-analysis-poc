# Don dep: dung fake server + xoa hosts entry (khoi phuc dntshop.com that)

$ErrorActionPreference = "Continue"
$dir = $PSScriptRoot

# ---- 0) Tu dong elevat neu chua la Admin ----
$principal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
if (-not $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Start-Process powershell -Verb RunAs -ArgumentList "-NoProfile","-ExecutionPolicy","Bypass","-File","`"$PSCommandPath`""
    exit
}

Write-Host "=== Don dep POC ===" -ForegroundColor Cyan

# 1) Dung fake server
$stopped = $false
Get-CimInstance Win32_Process -ErrorAction SilentlyContinue |
    Where-Object { $_.Name -eq 'fake_dntshop.exe' -or ($_.Name -eq 'python.exe' -and $_.CommandLine -match 'fake_dntshop\.py') } |
    ForEach-Object {
        Stop-Process -Id $_.ProcessId -Force -ErrorAction SilentlyContinue
        Write-Host "[-] Da dung fake server PID $($_.ProcessId)"
        $stopped = $true
    }
if (-not $stopped) { Write-Host "[i] Khong thay fake server dang chay." }
Remove-Item (Join-Path $dir "server.pid") -Force -ErrorAction SilentlyContinue

# 2) Xoa hosts entry
Write-Host "[1/2] Xoa hosts entry..."
& "$dir\hosts_toggle.ps1" -Action remove

# 3) Kiem tra lai
Write-Host "[2/2] Kiem tra hosts:"
try {
    $h = Get-Content "C:\Windows\System32\drivers\etc\hosts" | Where-Object { $_ -match 'dntshop' }
    if ($h) { Write-Host "  van con: $h" } else { Write-Host "  hosts sach OK" }
} catch { }

Write-Host ""
Write-Host "Luu y: QLTK.exe dang mo van con license trong RAM. Dong tool la het."
