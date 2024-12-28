# Display header
function Show-Header {
    Write-Host "-------------------------------------------------" -ForegroundColor Cyan
    Write-Host "- This script allows you to rename the Administrator account." -ForegroundColor Cyan
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

function Get-CurrentAdminUsername {
    return (Get-WmiObject -Class Win32_UserAccount -Filter "SID like 'S-1-5-%-500'").Name
}

function Get-NewUsername {
    param (
        [string]$current_name
    )

    $new_name = Read-Host "Enter the new username (Press Enter to keep '$current_name')"
    if (-not $new_name) { $new_name = $current_name }
    return $new_name
}

function Rename-AdministratorAccount {
    param (
        [string]$new_name
    )

    $adminAccount = Get-WmiObject -Class Win32_UserAccount -Filter "SID like 'S-1-5-%-500'"
    $adminAccount.Rename($new_name) | Out-Null
}

function Test-RenamingOperation {
    param (
        [string]$new_name
    )

    $current_name = Get-CurrentAdminUsername

    if ($current_name -ne $new_name) {
        Write-Host "ERROR: Failed to rename the Administrator account." -ForegroundColor Red
        Read-Host "Press Enter to exit..."
        exit
    }
    else {
        Write-Host "-- Account has been renamed to '$new_name'" -ForegroundColor Green
    }
}

# Main script execution
Show-Header
Test-AdminRights
$current_name = Get-CurrentAdminUsername
Write-Host "Current Administrator account name: '$current_name'" -ForegroundColor Yellow

$new_name = Get-NewUsername -current_name $current_name
if ($new_name -eq $current_name) {
    Write-Host "-- No change in account name. Exiting script." -ForegroundColor Cyan
    Read-Host "Press Enter to exit..."
    exit
}

Rename-AdministratorAccount -new_name $new_name
Test-RenamingOperation -new_name $new_name

Write-Host "-- Done --" -ForegroundColor Green
Read-Host "Press Enter to exit..."
