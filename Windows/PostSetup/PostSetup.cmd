@echo off
setlocal EnableDelayedExpansion
cd /d "%~dp0"

:menu
cls
echo ============================================================
echo                   Post-Installation Setup
echo ============================================================
echo.
echo  [1] Manage Built-in Administrator
echo  [2] Configure Remote Desktop Port
echo  [3] Configure Fixed DPI Scaling
echo  [4] Open Server Configuration
echo  [5] Configure Autologon
echo  [6] Download MoonBot
echo  [7] Log Off User
echo  [8] Restart Server
echo  [9] Exit
echo.
echo ============================================================
echo.

set /p choice="Enter your choice (1-8): "
echo.

if "%choice%"=="1" (
    powershell -ExecutionPolicy Bypass -File "Set-AdminCredentials.ps1"
    pause
    goto menu
) else if "%choice%"=="2" (
    powershell -ExecutionPolicy Bypass -File "Set-CustomRdpPort.ps1"
    pause
    goto menu
) else if "%choice%"=="3" (
    powershell -ExecutionPolicy Bypass -File "Set-FixedDpiMode.ps1"
    pause
    goto menu
) else if "%choice%"=="4" (
    cmd /c start /wait sconfig.cmd
    goto menu
) else if "%choice%"=="5" (
    start /wait "" "Autologon.exe" "/accepteula"
    goto menu    
) else if "%choice%"=="6" (
    powershell -ExecutionPolicy Bypass -File "Get-MoonBot.ps1"
    pause
    goto menu
) else if "%choice%"=="7" (
    set /p confirm="Are you sure you want to log off? (Y/N): "
    if /I "!confirm!"=="Y" (
        shutdown /l
    ) else (
        goto menu
    )
) else if "%choice%"=="8" (
    set /p confirm="Are you sure you want to restart? (Y/N): "
    if /I "!confirm!"=="Y" (
        shutdown /r /t 0
    ) else (
        goto menu
    )
) else if "%choice%"=="9" (
    set /p confirm="Are you sure you want to exit? (Y/N): "
    if /I "!confirm!"=="Y" (
        exit /b 0
    ) else (
        goto menu
    )
) else (
    echo Invalid option. Please enter a number between 1 and 8.
    timeout /t 2 >nul
    goto menu
)

endlocal