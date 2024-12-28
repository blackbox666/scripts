# UI Functions
function Show-Header {
    $width = 60
    $title = "Configure Remote Desktop Port"
    $description = "Default: 3389"
    $line = "=" * $width
    
    Write-Host $line -ForegroundColor Cyan
    Write-Host $title.PadLeft([math]::Floor(($width + $title.Length) / 2)).PadRight($width) -ForegroundColor Cyan
    Write-Host $description.PadLeft([math]::Floor(($width + $description.Length) / 2)).PadRight($width) -ForegroundColor Cyan
    Write-Host $line -ForegroundColor Cyan
}

function Show-Menu {    
    Write-Host "`nOptions:`n" -ForegroundColor Cyan
    Write-Host " [1] Change RDP port"
    Write-Host " [2] Exit"
    return Read-Host "`nSelect option (1-2)"
}

# Helper Functions
function Get-CurrentRdpPort {
    return (Get-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server\WinStations\RDP-Tcp" -Name "PortNumber").PortNumber
}

function Get-TerminalServicesProcess {
    return Get-Process svchost | Where-Object {
        $_.Id -eq (Get-WmiObject Win32_Service | Where-Object { $_.Name -eq "TermService" }).ProcessId
    }
}

function Test-PortAvailability {
    param ([int]$port)
    
    $client = New-Object System.Net.Sockets.TcpClient
    $timeoutMs = 1000
    try {
        $result = $client.BeginConnect("localhost", $port, $null, $null)
        $success = $result.AsyncWaitHandle.WaitOne($timeoutMs)
        if ($success) {
            $client.EndConnect($result)
            Write-Host "-- Port '$port' is already in use." -ForegroundColor Red
            Write-Host "-- Please choose a different port." -ForegroundColor Red
            return $false
        }
        return $true
    }
    finally {
        $client.Close()
    }
}

# Core Functions
function Update-FirewallRule {
    param ([int]$currentPort, [int]$newPort)

    if ($currentPort -ne 3389 -and $currentPort -ne $newPort) {
        Write-Host "-- Removing firewall rule for port '$currentPort'..." -ForegroundColor Cyan
        netsh advfirewall firewall delete rule name="RDP Port $currentPort" protocol=TCP localport=$currentPort | Out-Null
    }

    if ($newPort -ne 3389) {
        Write-Host "-- Adding firewall rule for port '$newPort'..." -ForegroundColor Cyan
        netsh advfirewall firewall add rule name="RDP Port $newPort" profile=any protocol=TCP action=allow dir=in localport=$newPort | Out-Null
    }
}

function Restart-TerminalServices {
    $maxAttempts = 3
    $currentAttempt = 1
    $delaySeconds = 10

    while ($currentAttempt -le $maxAttempts) {
        try {
            Write-Host "-- Restarting Terminal Services (attempt $currentAttempt of $maxAttempts)..." -ForegroundColor Cyan
            
            $process = Get-TerminalServicesProcess
            Stop-Service -Name "TermService" -Force

            if ($process -and -not $process.HasExited) {
                Write-Host "-- Terminating Terminal Services process..." -ForegroundColor Yellow
                $process | Stop-Process -Force
            }
            
            Start-Service -Name "TermService" -ErrorAction Stop
            Write-Host "-- Service restart successful." -ForegroundColor Green
            return $true
        }
        catch {
            if ($currentAttempt -eq $maxAttempts) {
                Write-Host "-- Failed to restart Terminal Services after $maxAttempts attempts." -ForegroundColor Red
                Write-Host "-- Error: $($_.Exception.Message)" -ForegroundColor Red
                return $false
            }

            Write-Host "-- Retry in $delaySeconds seconds..." -ForegroundColor Yellow
            Start-Sleep -Seconds $delaySeconds
            $currentAttempt++
        }
    }
}

function Set-RdpPortConfig {
    $newPort = Read-Host "Port number (1024-65535)"
            
    if (-not ($newPort -as [int]) -or [int]$newPort -lt 1024 -or [int]$newPort -gt 65535) {
        Write-Host "-- Invalid port number. Please enter a number between 1024 and 65535." -ForegroundColor Red
        return
    }

    $newPort = [int]$newPort
    $currentPort = Get-CurrentRdpPort
    
    if ($newPort -eq $currentPort) {
        Write-Host "-- No changes needed." -ForegroundColor Yellow
        return
    }
    
    if (-not (Test-PortAvailability -port $newPort)) {
        return
    }

    Write-Host "Press Enter to change port to '$newPort'..." -NoNewline
    Read-Host

    Write-Host "-- Setting port to '$newPort'..." -ForegroundColor Cyan
    Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server\WinStations\RDP-Tcp" -Name "PortNumber" -Value $newPort

    Update-FirewallRule -currentPort $currentPort -newPort $newPort
    
    if (-not (Restart-TerminalServices)) {
        Write-Host "-- Failed to restart Terminal Services. Restarting computer..." -ForegroundColor Red
        Restart-Computer -Force
    }
    
    Write-Host "-- Port changed to '$newPort'." -ForegroundColor Green
}

# Main Execution
Show-Header

do {
    Write-Host "`n-- Current RDP port: $(Get-CurrentRdpPort)" -ForegroundColor Green
    $selection = Show-Menu
    
    switch ($selection) {
        '1' { Set-RdpPortConfig }
        '2' { return }
        default { Write-Host "-- Invalid option." -ForegroundColor Red }
    }
    
} until ($selection -eq '2')
