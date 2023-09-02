# Download MoonBot

$MbLinkBase = 'https://api.moon-bot.com/files/'
$MbFolderBase = Join-Path $env:SystemDrive "MoonBot"
$PublicDesktop = [Environment]::GetFolderPath('CommonDesktopDirectory')
$MbShortcutPath = Join-Path $PublicDesktop "MoonBot.lnk"

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

            if (-not (Test-path $MbShortcutPath -PathType Leaf)) {
                $MbShortcut = (New-Object -ComObject WScript.Shell).CreateShortcut($MbShortcutPath)
                $MbShortcut.TargetPath = $MbFolderBase
                $MbShortcut.Save()
            }

            Write-Host "Extracted to $MbFolder" -ForegroundColor Cyan
            Write-Host 'Press any key to exit...' -ForegroundColor Cyan
            $null = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown')
            break # Exit the loop
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
    }
    else {
        Write-Host 'Invalid input, please try again...' -ForegroundColor Red
    }
}
