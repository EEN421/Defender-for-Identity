# Check .NET Framework version
Write-Host "`n=== .NET Framework Check ==="
$netfx = Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\NET Framework Setup\NDP\v4\Full" -ErrorAction SilentlyContinue
if ($netfx.Release -ge 461808) {
    Write-Host "✅ .NET Framework 4.7.2 or later is installed."
} else {
    Write-Host "❌ .NET Framework 4.7.2 or later is NOT installed."
}

# Check for TLS 1.2 enabled
Write-Host "`n=== TLS 1.2 Check ==="
$tlsKey = "HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\TLS 1.2\Client"
if (Test-Path $tlsKey) {
    $enabled = Get-ItemProperty $tlsKey
    if ($enabled.Enabled -eq 1 -and $enabled.DisabledByDefault -eq 0) {
        Write-Host "✅ TLS 1.2 is enabled correctly."
    } else {
        Write-Host "❌ TLS 1.2 is NOT correctly configured."
    }
} else {
    Write-Host "❌ TLS 1.2 registry key not found."
}

# Check "Log on as a service" for NT SERVICE\AATPSensorUpdater
Write-Host "`n=== 'Log on as a service' Rights Check ==="
$account = "NT SERVICE\AATPSensorUpdater"
$secpol = secedit /export /cfg "$env:TEMP\secpol.cfg" | Out-Null
$cfg = Get-Content "$env:TEMP\secpol.cfg"
$right = $cfg | Where-Object { $_ -like "SeServiceLogonRight*" }
if ($right -like "*$account*") {
    Write-Host "✅ $account has 'Log on as a service' rights."
} else {
    Write-Host "❌ $account is missing 'Log on as a service' rights."
}
Remove-Item "$env:TEMP\secpol.cfg" -Force

# Check basic AV/EDR status (Windows Defender)
Write-Host "`n=== AV/EDR Status (Windows Defender) ==="
Try {
    $defender = Get-MpComputerStatus
    Write-Host "Defender is " ($defender.AntispywareEnabled ? "✅ Enabled" : "❌ Disabled")
    Write-Host "Real-time protection is " ($defender.RealTimeProtectionEnabled ? "✅ Enabled" : "❌ Disabled")
} Catch {
    Write-Host "⚠️ Could not query Defender status (non-Windows AV or permissions issue?)"
}

# Test outbound connectivity to key MDI endpoints
Write-Host "`n=== Endpoint Connectivity Check ==="
$targets = @("sensorapi.atp.azure.com", "securitycenter.windows.com")
foreach ($t in $targets) {
    try {
        $r = Test-NetConnection -ComputerName $t -Port 443 -InformationLevel Quiet
        if ($r) {
            Write-Host "✅ Able to reach $t on port 443."
        } else {
            Write-Host "❌ Cannot reach $t on port 443."
        }
    } catch {
        Write-Host "❌ Error testing $t: $_"
    }
}

# Test service creation (optional)
Write-Host "`n=== Service Creation Test (Non-Invasive) ==="
Try {
    sc.exe create AATPSensorTest binPath= "C:\Windows\System32\svchost.exe" start= demand | Out-Null
    Start-Service AATPSensorTest -ErrorAction Stop
    Write-Host "✅ Test service created and started successfully."
    Stop-Service AATPSensorTest
    sc.exe delete AATPSensorTest | Out-Null
} Catch {
    Write-Host "❌ Failed to create/start test service: $_"
}
