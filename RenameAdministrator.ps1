# Display header
Write-Host "-------------------------------------------------"
Write-Host "- $($MyInvocation.MyCommand.Name)"
Write-Host "- "
Write-Host "- This script allows you to rename the Administrator account."
Write-Host "- "
Write-Host "-------------------------------------------------"

# Check for admin rights
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

if (-not $isAdmin) {
    Write-Host "ERROR: You lack the necessary permissions to rename the Administrator account. Please right-click and run as administrator." -ForegroundColor Red
    Read-Host "Press Enter to exit..."
    exit
} else {
    Write-Host "[Admin rights confirmed]"
}

# Get the new name
$new_name = Read-Host "Enter the new username (Press Enter for default 'Administrator')"
if (-not $new_name) { $new_name = "Administrator" }

Write-Host "- The Administrator account will be renamed to '$new_name'"
Read-Host "Press Enter to continue..."

# Rename the Administrator account
Get-WmiObject -Class Win32_UserAccount -Filter "SID like 'S-1-5-%-500'" | ForEach-Object {
    $_.Rename($new_name)
}

# Check the renaming operation
$current_name = (Get-WmiObject -Class Win32_UserAccount -Filter "SID like 'S-1-5-%-500'").Name

if ($current_name -ne $new_name) {
    Write-Host "ERROR: Failed to rename the Administrator account." -ForegroundColor Red
    Read-Host "Press Enter to exit..."
    exit
}

# Done
Write-Host "---------- Done"
Read-Host "Press Enter to exit..."
