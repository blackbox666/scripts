# Set TLS 1.2 for this PowerShell session
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

# Create PowerShell profile if it doesn't exist 
if (!(Test-Path $PROFILE)) { New-Item -ItemType File -Force -Path $PROFILE | Out-Null } ; . $PROFILE

# Install Chocolatey
if (Get-Command choco -ErrorAction SilentlyContinue) {
    Write-Host "Chocolatey is already installed." -ForegroundColor Green
}
else {
    try {
        Write-Host "Installing Chocolatey..." -ForegroundColor Cyan
        Set-ExecutionPolicy Bypass -Scope Process -Force
        Invoke-Expression ((New-Object System.Net.WebClient).DownloadString("https://community.chocolatey.org/install.ps1")) | Out-Null
        choco feature enable -n=allowGlobalConfirmation | Out-Null
        choco feature enable -n=useRememberedArgumentsForUpgrades | Out-Null
        choco feature disable -n=showDownloadProgress | Out-Null
    }
    catch {
        Write-Error "Error installing Chocolatey: $_"
    }
}

# Function to install software using Chocolatey
function Install-ChocoPackage {
    param (
        [string]$packageName
    )
    try {
        Write-Host "Installing $packageName..." -ForegroundColor Cyan
        choco install $packageName -y -r | Out-Null
    }
    catch {
        Write-Error "Error installing ${packageName}: $_"
    }
}

# Install 7-Zip using Chocolatey
Install-ChocoPackage "7zip"

# Associate common file formats with 7-Zip
$archiveFormats = @(
    @{ extension = ".7z"; typeName = "7-Zip.7z"; iconIndex = 0 },
    @{ extension = ".zip"; typeName = "7-Zip.zip"; iconIndex = 1 },
    @{ extension = ".rar"; typeName = "7-Zip.rar"; iconIndex = 3 },
    @{ extension = ".tar"; typeName = "7-Zip.tar"; iconIndex = 13 }
)

foreach ($format in $archiveFormats) {
    Invoke-Expression "REG ADD ""HKCR\$($format.extension)"" /ve /d ""$($format.typeName)"" /f" | Out-Null
    Invoke-Expression "REG ADD ""HKCR\$($format.typeName)"" /ve /d ""$($format.extension) Archive"" /f" | Out-Null
    Invoke-Expression "REG ADD ""HKCR\$($format.typeName)\DefaultIcon"" /ve /d ""C:\Program Files\7-Zip\7z.dll,$($format.iconIndex)"" /f" | Out-Null
    Invoke-Expression "REG ADD ""HKCR\$($format.typeName)\shell\open\command"" /ve /d ""C:\Program Files\7-Zip\7zFM.exe %1"" /f" | Out-Null
}

# Set the 7-Zip language to English
New-ItemProperty -Path "HKCU:\SOFTWARE\7-Zip" -Name "Lang" -Value "-" -PropertyType String -Force | Out-Null

# Install Mem Reduct using Chocolatey
Install-ChocoPackage "memreduct"; Stop-Process -Name "memreduct" -ErrorAction SilentlyContinue -Force

# Apply optimized Mem Reduct settings
$memReductConfig = "C:\Program Files\Mem Reduct\memreduct.ini"

$memReductSettings = @"
[memreduct]
AutoreductEnable=true
AutoreductIntervalEnable=false
HotkeyCleanEnable=false
IsStartMinimized=true
IsShowReductConfirmation=false
CheckUpdatesPeriod=0
Language=English
IsNotificationsSound=false
"@

Set-Content -Path $memReductConfig -Value $memReductSettings

# Add Mem Reduct to startup and launch it
New-ItemProperty -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run" -Name "Mem Reduct" -Value """C:\Program Files\Mem Reduct\memreduct.exe"" -minimized" -PropertyType String -Force | Out-Null
Start-Process "C:\Program Files\Mem Reduct\memreduct.exe" -ArgumentList "-minimized"

# Install additional software using Chocolatey
Install-ChocoPackage "notepad3"

# Install IPBan
try {
    Write-Host "Installing IPBan..." -ForegroundColor Cyan
    $ScriptPath = ((New-Object System.Net.WebClient).DownloadString("https://raw.githubusercontent.com/DigitalRuby/IPBan/master/IPBanCore/Windows/Scripts/install_latest.ps1"))
    Invoke-Command -ScriptBlock ([scriptblock]::Create($ScriptPath)) -Args "silent", $true
}
catch {
    Write-Error "Error installing IPBan: $_"
}

# Prompt to restart the computer after installation
switch (Read-Host "Restart computer now? [y/n]") {
    "y" { Restart-Computer -Force -Confirm:$false }
    "n" { Write-Host "Restart cancelled..." -ForegroundColor Yellow }
    default { Write-Warning "Invalid input..." }
}