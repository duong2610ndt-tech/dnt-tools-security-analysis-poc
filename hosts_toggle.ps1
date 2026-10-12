param(
    [ValidateSet("add", "remove")]
    [string]$Action = "add",
    [string]$Target = "127.0.0.1"
)

<#
    Them/xoa dong "<Target> dntshop.com" trong file hosts.
    - Target mac dinh 127.0.0.1 (fake server chay tai may).
    - Truyen IP VPS de tro sang server trung tam: -Target 203.0.113.10
    Tu dong nang quyen (UAC) khi can.
#>

$hostsFile = "C:\Windows\System32\drivers\etc\hosts"
$entry = "$Target dntshop.com"

$principal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
$isAdmin = $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

if (-not $isAdmin) {
    $argList = "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`" -Action $Action -Target `"$Target`""
    $p = Start-Process powershell -Verb RunAs -ArgumentList $argList -Wait -PassThru
    exit $p.ExitCode
}

if ($Action -eq "add") {
    $content = @(Get-Content $hostsFile -ErrorAction SilentlyContinue)
    $existing = @($content | Where-Object { $_ -match 'dntshop' })
    if ($existing.Count -gt 0) {
        if (@($existing | Where-Object { $_ -match "^\s*$([regex]::Escape($Target))\s+dntshop\.com" }).Count -gt 0) {
            Write-Host "[i] hosts da co san: $entry"
        } else {
            # doi target cu bang target moi (vd tu 127.0.0.1 sang IP VPS)
            $content = @($content | Where-Object { $_ -notmatch 'dntshop' })
            $content += $entry
            Set-Content $hostsFile $content
            Write-Host "[+] Da thay the thanh: $entry"
        }
    } else {
        Add-Content $hostsFile "`n$entry"
        Write-Host "[+] Da them: $entry"
    }
} else {
    $content = Get-Content $hostsFile -ErrorAction SilentlyContinue
    $filtered = $content | Where-Object { $_ -notmatch 'dntshop' }
    if ($filtered.Count -ne $content.Count) {
        Set-Content $hostsFile $filtered
        Write-Host "[-] Da xoa dong dntshop trong hosts"
    } else {
        Write-Host "[i] Khong co dong dntshop trong hosts"
    }
}
