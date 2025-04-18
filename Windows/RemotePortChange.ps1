# Display header
function Show-Header {
    Write-Host "-------------------------------------------------" -ForegroundColor Cyan
    Write-Host "- This script allows you to change the RDP port." -ForegroundColor Cyan
    Write-Host "- Note: The default RDP port is 3389." -ForegroundColor Cyan
    Write-Host "-------------------------------------------------" -ForegroundColor Cyan
}

function Test-AdminRights {
    $isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
    
    if (-not $isAdmin) {
        Write-Host "ERROR: You lack the necessary permissions to rename the Administrator account." -ForegroundColor Red
        Write-Host "Please right-click and run as administrator." -ForegroundColor Red
        Read-Host "Press Enter to exit..."
        exit
    }
    else {
        Write-Host "[Admin rights confirmed]" -ForegroundColor Green
    }
}

function Get-CurrentRdpPort {
    $currentPort = Get-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server\WinStations\RDP-Tcp" -Name "PortNumber"
    Write-Host "Current RDP port:" $currentPort.PortNumber -ForegroundColor Yellow
    return $currentPort.PortNumber
}

function Set-NewRdpPort {
    param (
        [int]$newPort
    )

    Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server\WinStations\RDP-Tcp" -Name "PortNumber" -Value $newPort
    Write-Host "-- RDP port updated to $newPort" -ForegroundColor Green
}

function Update-FirewallRule {
    param (
        [int]$oldPort,
        [int]$newPort
    )

    if ($oldPort -ne 3389 -and $oldPort -ne $newPort) {
        Write-Host "-- Removing old firewall rule for port $oldPort..." -ForegroundColor Cyan
        netsh advfirewall firewall delete rule name="RDP Port $oldPort" protocol=TCP localport=$oldPort | Out-Null
    }

    if ($newPort -ne 3389) {
        Write-Host "-- Adding firewall rule for port $newPort..." -ForegroundColor Cyan
        netsh advfirewall firewall add rule name="RDP Port $newPort" profile=any protocol=TCP action=allow dir=in localport=$newPort | Out-Null
    }
}

function Restart-TerminalServices {
    Write-Host "-- Restarting Terminal Services..." -ForegroundColor Cyan
    Stop-Service -Name TermService -Force
    Start-Service -Name TermService
}

# Main script execution
Show-Header
Test-AdminRights
$oldPort = Get-CurrentRdpPort

do {
    $rdp_port = Read-Host "Enter the desired RDP port (default is 3389, range 1024-65535)"
    if (-not $rdp_port) { $rdp_port = 3389 }

    if ($rdp_port -lt 1024 -or $rdp_port -gt 65535) {
        Write-Host "Invalid port number. Please enter a value between 1024 and 65535." -ForegroundColor Red
    }
} until ($rdp_port -ge 1024 -and $rdp_port -le 65535)

if ($rdp_port -ne $oldPort) {
    Read-Host "Press Enter to change RDP port to $rdp_port..."
    Set-NewRdpPort -newPort $rdp_port
    Write-Host "-- Updating firewall rules..." -ForegroundColor Cyan
    Update-FirewallRule -oldPort $oldPort -newPort $rdp_port
    Restart-TerminalServices
    Write-Host "-- Done --" -ForegroundColor Green
}
else {
    Write-Host "The new RDP port is the same as the current port. No changes made." -ForegroundColor Yellow
}

Read-Host "Press Enter to exit..."
