# UI Functions
function Show-Header {
    $width = 60
    $title = "Manage Built-in Administrator"
    $line = "=" * $width
    
    Write-Host $line -ForegroundColor Cyan
    Write-Host $title.PadLeft([math]::Floor(($width + $title.Length) / 2)).PadRight($width) -ForegroundColor Cyan
    Write-Host $line -ForegroundColor Cyan
}

function Show-Menu {
    Write-Host "`nOptions:`n" -ForegroundColor Cyan
    Write-Host " [1] Rename Account"
    Write-Host " [2] Change Password"
    Write-Host " [3] Exit"
    return Read-Host "`nSelect option (1-3)"
}

# Helper Functions
function Get-CurrentAdminUsername {
    return (Get-WmiObject -Class Win32_UserAccount -Filter "SID like 'S-1-5-%-500'").Name
}

function ConvertFrom-SecureString {
    param([SecureString]$secureString)
    
    $bstr = [IntPtr]::Zero
    try {
        $bstr = [Runtime.InteropServices.Marshal]::SecureStringToBSTR($secureString)
        return [Runtime.InteropServices.Marshal]::PtrToStringAuto($bstr)
    }
    finally {
        if ($bstr -ne [IntPtr]::Zero) {
            [Runtime.InteropServices.Marshal]::ZeroFreeBSTR($bstr)
        }
    }
}

# Core Functions
function Set-AdministratorAccount {
    $newName = Read-Host "Enter new account name"
    
    if ([string]::IsNullOrWhiteSpace($newName)) {
        Write-Host "-- No name provided." -ForegroundColor Yellow
        return $false
    }

    $currentName = Get-CurrentAdminUsername
    if ($newName -eq $currentName) {
        Write-Host "-- No changes made." -ForegroundColor Yellow
        return $false
    }

    Write-Host "Press Enter to rename account to '$newName'..." -NoNewline
    Read-Host
    
    try {
        Rename-LocalUser -Name $currentName -NewName $newName -ErrorAction Stop | Out-Null
        Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon" -Name "DefaultUserName" -Value $newName -ErrorAction Stop
        Write-Host "-- Account renamed to '$newName'" -ForegroundColor Green
        Write-Host "-- Logoff required to apply changes." -ForegroundColor DarkYellow
        return $true
    }
    catch {
        Write-Host "-- Error: $($_.Exception.Message)" -ForegroundColor Red -NoNewline
        Write-Host "-- Cannot change account name." -ForegroundColor Red
        return $false
    }
}

function Set-AdministratorPassword {
    $newPassword = Read-Host "Enter new password" -AsSecureString
    $confirmPassword = Read-Host "Confirm new password" -AsSecureString
    
    $newPasswordPlain = ConvertFrom-SecureString -secureString $newPassword
    $confirmPasswordPlain = ConvertFrom-SecureString -secureString $confirmPassword
    
    if ([string]::IsNullOrWhiteSpace($newPasswordPlain) -or [string]::IsNullOrWhiteSpace($confirmPasswordPlain)) {
        Write-Host "-- Passwords cannot be empty." -ForegroundColor Red
        return $false
    }
    
    if ($newPasswordPlain -ne $confirmPasswordPlain) {
        Write-Host "-- Passwords do not match." -ForegroundColor Red
        return $false
    }

    Write-Host "Press Enter to set the new password..." -NoNewline
    Read-Host
    
    try {
        Set-LocalUser -Name (Get-CurrentAdminUsername) -Password $newPassword -ErrorAction Stop | Out-Null
        Start-Process -FilePath Autologon.exe -ArgumentList "/accepteula", (Get-CurrentAdminUsername), $env:COMPUTERNAME, $newPasswordPlain -Wait -NoNewWindow
        Write-Host "-- Password changed successfully." -ForegroundColor Green
        Write-Host "-- Logoff required to apply changes." -ForegroundColor DarkYellow
        return $true
    }
    catch {
        Write-Host "-- Error: $($_.Exception.Message)" -ForegroundColor Red -NoNewline
        Write-Host "-- Cannot change password." -ForegroundColor Red
        return $false
    }
}

# Main Execution
Show-Header

do {
    Write-Host "`n-- Current Built-in Admin Username: $(Get-CurrentAdminUsername)" -ForegroundColor Green
    
    switch (Show-Menu) {
        '1' { [void](Set-AdministratorAccount) }
        '2' { [void](Set-AdministratorPassword) }
        '3' { return }
        default { Write-Host "-- Invalid option." -ForegroundColor Red }
    }
} until ($false)