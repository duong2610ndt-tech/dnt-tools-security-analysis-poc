# POC license Tool Check Info - ban don gian (port 80 trong)
# hosts 127.0.0.1 dntshop.com + fake server nghe thang port 80 + mo QLTK.exe

param(
    [string]$ToolPath = "",
    [int]$Port = 80
)

$ErrorActionPreference = "Continue"
$dir = $PSScriptRoot
if (-not $ToolPath) { $ToolPath = Join-Path $dir "QLTK.exe" }
$logFile = Join-Path $dir "server.log"

# ---- 0) Tu dong elevat neu chua la Admin (UAC hien 1 lan) ----
$principal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
if (-not $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Start-Process powershell -Verb RunAs -ArgumentList "-NoProfile","-ExecutionPolicy","Bypass","-File","`"$PSCommandPath`"","-Port","$Port"
    exit
}

Write-Host "=== POC License Tool Check Info - Fake dntshop.com ===" -ForegroundColor Cyan

# 1) Kiem tra fake_dntshop.exe
$srvExe = Join-Path $dir "fake_dntshop.exe"
if (-not (Test-Path $srvExe)) {
    Write-Host "[!] Khong thay fake_dntshop.exe trong thu muc nay." -ForegroundColor Red
    exit 1
}

# 2) Kiem tra port 80: neu fake server cu dang chay thi dung lai, con app khac thi bao loi
$reuseServer = $false
if (Get-NetTCPConnection -LocalPort $Port -State Listen -ErrorAction SilentlyContinue) {
    if (Get-Process fake_dntshop -ErrorAction SilentlyContinue) {
        Write-Host "[i] Fake server dang chon san o port $Port - dung lai." -ForegroundColor Cyan
        $reuseServer = $true
    } else {
        Write-Host "[!] Port $Port dang bi chiem boi ung dung khac. Hay tat no roi chay lai." -ForegroundColor Red
        exit 1
    }
}

# 3) Them hosts entry
Write-Host "[1/3] Them hosts entry..."
& "$dir\hosts_toggle.ps1" -Action add -Target 127.0.0.1

# 4) Chay fake server nghe thang port $Port
if ($reuseServer) {
    Write-Host "[2/3] Bo qua khoi dong server (da chay san)."
} else {
    Write-Host "[2/3] Chay fake server port $Port ..."
    $server = Start-Process $srvExe -ArgumentList "$Port" -PassThru
    Start-Sleep -Milliseconds 1500
    if ($server.HasExited) {
        Write-Host "[!] Fake server thoat ngay - xem server.log." -ForegroundColor Red
        Get-Content $logFile -ErrorAction SilentlyContinue
        exit 1
    }
    Write-Host "[+] Fake server PID $($server.Id), log: $logFile"
}

# 5) Kiem tra duong di day du
Write-Host "[3/3] Kiem tra DNS + fake server ..."
Clear-DnsClientCache -ErrorAction SilentlyContinue
try {
    $r = Invoke-WebRequest -Uri "http://dntshop.com/api/verify_license.php" -Method Post `
        -Body '{"license_key":"TOOL8-selftest"}' -ContentType "application/json" -UseBasicParsing -TimeoutSec 5
    Write-Host "[+] OK -> $($r.Content)" -ForegroundColor Green
} catch {
    Write-Host "[!] Chua toi duoc fake server: $($_.Exception.Message)" -ForegroundColor Red
}

# 6) Mo tool
if (Test-Path $ToolPath) { Start-Process $ToolPath } else { Write-Host "[!] Khong thay QLTK.exe." -ForegroundColor Yellow }

Write-Host ""
Write-Host "Bam 'Kiem tra lai' trong hop kich hoat." -ForegroundColor Cyan
Write-Host "Title thanh '... | Client POC-VERIFIED | HSD 31/12/2099' = thanh cong." -ForegroundColor Cyan
Write-Host "KHI XONG: chay stop_poc.bat de don dep." -ForegroundColor Yellow
if (-not $reuseServer) { Set-Content (Join-Path $dir "server.pid") $server.Id }
