@echo off
echo -------------------------------------------------
echo - %~nx0 
echo - 
echo - Allows you to change the RDP port
echo - Note: default RDP port is 3389 (0xd3d in hex)
echo - 
echo - Here is the current port (in hex):
reg query "hklm\SYSTEM\CurrentControlSet\Control\Terminal Server\WinStations\RDP-Tcp" /v "PortNumber"
echo -------------------------------------------------

:: Check admin rights
net session >nul 2>&1
if %errorLevel% == 0 (
    echo [Admin confirmed]
) else (
    echo ERR: Admin denied. Right-click and run as administrator. 
    pause 
    goto :EOF
)

:: Change the RDP port
set /p rdp_port="Change the port to (Press enter for default 3389):"
if "%rdp_port%" EQU "" (
    set rdp_port=3389
)
echo - Continuing will set the RDP port to %rdp_port%
pause
reg add "hklm\SYSTEM\CurrentControlSet\Control\Terminal Server\WinStations\RDP-Tcp" /v "PortNumber" /t REG_DWORD /d %rdp_port% /f
echo - Here is the new port (in hex):
reg query "hklm\SYSTEM\CurrentControlSet\Control\Terminal Server\WinStations\RDP-Tcp" /v "PortNumber"

echo ---------- Next we will add firewall rules, then disconnect any running remote sessions
echo ---------- You should be able to reconnect using the new port (if you get disconnected)
pause

:: Add firewall rules
echo -- Adding firewall rules...
netsh advfirewall firewall add rule name="RDP Port %rdp_port%" profile=any protocol=TCP action=allow dir=in localport=%rdp_port%

:: Restart terminal services
echo -- Stopping and starting terminal services...
net stop termservice /yes
net start termservice

:DONE
echo ---------- Done
pause
