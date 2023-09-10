# Display header
Write-Host "-------------------------------------------------"
Write-Host "- $($MyInvocation.MyCommand.Name)"
Write-Host "- "
Write-Host "- This script allows you to change the RDP port."
Write-Host "- Note: The default RDP port is 3389 (0xd3d in hex)."
Write-Host "- "
Write-Host "- Here's the current port (in hex):"
Get-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server\WinStations\RDP-Tcp" -Name "PortNumber"
Write-Host "-------------------------------------------------"

# Check for admin rights
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

if (-not $isAdmin) {
    Write-Host "ERROR: You lack the necessary permissions to change the RDP port. Please right-click and run as administrator." -ForegroundColor Red
    Read-Host "Press Enter to exit..."
    exit
}
else {
    Write-Host "[Admin rights confirmed]"
}

# Input port
do {
    $rdp_port = Read-Host "Enter the desired port (Press Enter for the default 3389)"
    if (-not $rdp_port) { $rdp_port = 3389 }

    if ($rdp_port -lt 1 -or $rdp_port -gt 65535) {
        Write-Host "Invalid port number. Please enter a value between 1 and 65535." -ForegroundColor Red
    }
} until ($rdp_port -ge 1 -and $rdp_port -le 65535)

Write-Host "- Proceeding will set the RDP port to $rdp_port"
Read-Host "Press Enter to continue..."

# Update the RDP port
Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server\WinStations\RDP-Tcp" -Name "PortNumber" -Value $rdp_port

# Confirm the port update
Write-Host "- Here's the new port (in hex):"
Get-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server\WinStations\RDP-Tcp" -Name "PortNumber"

Write-Host "---------- The script will now add firewall rules and then disconnect any active remote sessions."
Write-Host "---------- You should be able to reconnect using the new port (if disconnected)."
Read-Host "Press Enter to continue..."

# Firewall and services
Write-Host "-- Adding firewall rules..."
netsh advfirewall firewall add rule name="RDP Port $rdp_port" profile=any protocol=TCP action=allow dir=in localport=$rdp_port
Write-Host "-- Stopping and starting terminal services..."
Stop-Service -Name TermService -Force
Start-Service -Name TermService

# Done
Write-Host "---------- Done"
Read-Host "Press Enter to exit..."
