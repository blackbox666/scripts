@echo off
echo -------------------------------------------------
echo - %~nx0 
echo - 
echo - Allows you to rename the Administrator account
echo - 
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

:: Rename the Administrator account
set /p new_name="Change the username to (Press enter for default Administrator):"
if "%new_name%" EQU "" (
    set new_name=Administrator
)
echo - Continuing will set it to %new_name%
pause
wmic useraccount where "SID like 'S-1-5-%%-500'" rename %new_name%

:DONE
echo ---------- Done
pause
