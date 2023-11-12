# Display header
function Display-Header {
    Write-Host "-------------------------------------------------" -ForegroundColor Cyan
    Write-Host "- This script allows you to change the RDP port." -ForegroundColor Cyan
    Write-Host "- Note: The default RDP port is 3389 (0xd3d in hex)." -ForegroundColor Cyan
    Write-Host "-------------------------------------------------" -ForegroundColor Cyan
}

function Check-AdminRights {
    $isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
    
    if (-not $isAdmin) {
        Write-Host "ERROR: You lack the necessary permissions to change the RDP port. Please right-click and run as administrator." -ForegroundColor Red
        Read-Host "Press Enter to exit..."
        exit
    } else {
        Write-Host "[Admin rights confirmed]" -ForegroundColor Green
    }
}

function Get-CurrentRdpPort {
    $currentPort = Get-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server\WinStations\RDP-Tcp" -Name "PortNumber"
    Write-Host "- Current RDP port (in hex):" $currentPort.PortNumber.ToString("X") -ForegroundColor Yellow
}

function Set-NewRdpPort {
    param (
        [int]$newPort
    )

    Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server\WinStations\RDP-Tcp" -Name "PortNumber" -Value $newPort
    Write-Host "-- RDP port updated to $newPort" -ForegroundColor Green
}

function Add-FirewallRule {
    param (
        [int]$port
    )

    Write-Host "-- Adding firewall rule for port $port..." -ForegroundColor Cyan
    netsh advfirewall firewall add rule name="RDP Port $port" profile=any protocol=TCP action=allow dir=in localport=$port | Out-Null
}

function Restart-TerminalServices {
    Write-Host "-- Restarting Terminal Services..." -ForegroundColor Cyan
    Stop-Service -Name TermService -Force
    Start-Service -Name TermService
}

# Main script execution
Display-Header
Check-AdminRights
Get-CurrentRdpPort

do {
    $rdp_port = Read-Host "Enter the desired port (Press Enter for the default 3389)"
    if (-not $rdp_port) { $rdp_port = 3389 }

    if ($rdp_port -lt 1 -or $rdp_port -gt 65535) {
        Write-Host "Invalid port number. Please enter a value between 1 and 65535." -ForegroundColor Red
    }
} until ($rdp_port -ge 1 -and $rdp_port -le 65535)

Read-Host "Press Enter to change RDP port to $rdp_port..."

Set-NewRdpPort -newPort $rdp_port
Get-CurrentRdpPort
Write-Host "---------- Adding firewall rules and restarting services..." -ForegroundColor Cyan
Read-Host "Press Enter to continue..."

Add-FirewallRule -port $rdp_port
Restart-TerminalServices

Write-Host "---------- Done ----------" -ForegroundColor Cyan
Read-Host "Press Enter to exit..."
