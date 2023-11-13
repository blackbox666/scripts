# Download MoonBot

$MbLinkBase = 'https://api.moon-bot.com/files/'
$MbFolderBase = Join-Path $env:SystemDrive "Optional\MoonBot"

while ($true) {

    Write-Host 'Type ' -NoNewline
    Write-Host '1 ' -ForegroundColor Green -NoNewline
    Write-Host 'or ' -NoNewline
    Write-Host '2 ' -ForegroundColor Red -NoNewline
    Write-Host 'to download ' -NoNewline
    Write-Host 'Release (1) ' -ForegroundColor Green -NoNewline
    Write-Host 'or ' -NoNewline
    Write-Host 'Testing (2): ' -ForegroundColor Red -NoNewline

    $MbVersionChoice = Read-Host

    if ($MbVersionChoice -in 1, 2) {
        if ($MbVersionChoice -eq 1) {
            $MbVersion = 'MoonBot'
            $MbFolder = Join-Path $MbFolderBase "$MbVersion-release"
        }
        else {
            Write-Host 'Enter the version name, e.g. S11: ' -NoNewline
            $MbVersion = 'MoonBot-' + (Read-Host).ToUpper()
            $MbFolder = Join-Path $MbFolderBase $MbVersion
        }

        $MbLink = $MbLinkBase + $MbVersion + '.zip'
        $MbFilename = [System.IO.Path]::GetFileName($MbLink)
        $MbPackage = Join-Path $PSScriptRoot $MbFilename

        if (Test-Path $MbFolder -PathType Container) {
            Remove-Item -Path $MbFolder\* -Recurse -Force | Out-Null
        }

        try {
            Write-Host "Downloading $MbFilename" -ForegroundColor Cyan
            (New-Object System.Net.WebClient).DownloadFile($MbLink, $MbPackage)
            Write-Host "Extracting $MbFilename" -ForegroundColor Cyan

            [System.Reflection.Assembly]::LoadWithPartialName('System.IO.Compression.FileSystem') | Out-Null
            [System.IO.Compression.ZipFile]::ExtractToDirectory($MbPackage, $MbFolder)
            Remove-Item -Path $MbPackage

            Write-Host "Extracted to $MbFolder" -ForegroundColor Cyan
        }
        catch {
            if ($_.Exception.Message -like '*(404) Not Found*') {
                Write-Warning "$MbFilename does not exist..."
            }
            else {
                Write-Error "Error: $($_.Exception.Message)"
                break # Exit the loop
            }
        }
        Write-Host 'Press any key to continue...' -ForegroundColor Cyan
        $null = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown')
        break # Exit the loop
    }
    else {
        Write-Host 'Invalid input, please try again...' -ForegroundColor Red
    }
}

Write-Host 'Now the script is going to update running MoonBot instances' -ForegroundColor Yellow

$ProcessNames = (Get-Process -Name 'MoonBot' -ErrorAction SilentlyContinue)
            
foreach ($ProcessNamesObject in $ProcessNames) {
    
    $ProcessExePath = $ProcessNamesObject.Path
    $ParentDirectoryPath = ($ProcessNamesObject.Path | Split-Path)
    $ParentDirectoryName = ($ProcessNamesObject.Path -split '\\')[-2]

    $ConfirmHotkey = (Read-Host "Do you want to close and update $($ParentDirectoryName)? Type Y or N").ToLower()
            
    if ($ConfirmHotkey -eq 'y') {

        $ProcessNamesObject.CloseMainWindow() | Out-Null
        Start-Sleep -Seconds 3

        while (-not $ProcessNamesObject.HasExited) {
            Write-Host "$($ProcessNamesObject.MainWindowTitle) has open windows. Trying to close now..." -ForegroundColor Yellow
            $wshell = New-Object -ComObject WScript.Shell
            $wshell.AppActivate($ProcessNamesObject.Id) | Out-Null
            $wshell.SendKeys($ConfirmHotkey) | Out-Null
            Write-Host "Terminated $($ProcessNamesObject.MainWindowTitle)"
            Start-Sleep -Seconds 3
        }
        
        Write-Host "Terminated $($ParentDirectoryName)..." -ForegroundColor Green
        Write-Host "Updating $($ParentDirectoryName)..." -ForegroundColor Green
        Copy-Item -Path $MbFolder\* -Destination $ParentDirectoryPath -Recurse -Force
        Write-Host "Waiting 3 minutes to avoid possible IP bans..." -ForegroundColor Green
        Start-Sleep -Seconds 180
        Write-Host "Starting $($ParentDirectoryName)..." -ForegroundColor Green
        Start-Process -FilePath $ProcessExePath
    }
    else {
        Write-Host "Skipping $($ParentDirectoryName)" -ForegroundColor Green
    }

    Write-Host 'Press any key to continue...' -ForegroundColor Cyan
    $null = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown')
}
