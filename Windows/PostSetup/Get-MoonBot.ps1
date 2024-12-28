# UI Functions
function Show-Header {
    $width = 60
    $title = "Download MoonBot"
    $line = "=" * $width
    
    Write-Host $line -ForegroundColor Cyan
    Write-Host $title.PadLeft([math]::Floor(($width + $title.Length) / 2)).PadRight($width) -ForegroundColor Cyan
    Write-Host $line -ForegroundColor Cyan
}

function Show-Menu {
    Write-Host "`nOptions:`n" -ForegroundColor Cyan
    Write-Host " [1] Release version"
    Write-Host " [2] Testing version"
    Write-Host " [3] Exit"
    return Read-Host "`nSelect option (1-3)"
}

# Main Execution
Show-Header

$MbLinkBase = "https://api.moon-bot.com/files/"
$MbFolderBase = Join-Path $env:SystemDrive "MoonBot"

do {
    $selection = Show-Menu
    
    switch ($selection) {
        "1" {
            $MbVersion = "MoonBot"
            $MbFolder = Join-Path $MbFolderBase "$MbVersion-release"
        }
        "2" {
            $MbVersion = "MoonBot-" + (Read-Host "Enter the version name (e.g. S11)").ToUpper()
            $MbFolder = Join-Path $MbFolderBase $MbVersion
        }
        "3" { return }
        default {
            Write-Host "-- Invalid option" -ForegroundColor Red
            continue
        }
    }

    $MbPackage = Join-Path $PSScriptRoot "$MbVersion.zip"

    if (Test-Path $MbFolder -PathType Container) {
        Remove-Item -Path $MbFolder\* -Recurse -Force | Out-Null
    }

    try {
        Write-Host "-- Downloading $MbVersion.zip..." -ForegroundColor Cyan
        (New-Object System.Net.WebClient).DownloadFile($MbLinkBase + $MbVersion + ".zip", $MbPackage)
        Write-Host "-- Extracting $MbVersion.zip..." -ForegroundColor Cyan

        [System.Reflection.Assembly]::LoadWithPartialName('System.IO.Compression.FileSystem') | Out-Null
        [System.IO.Compression.ZipFile]::ExtractToDirectory($MbPackage, $MbFolder)
        Remove-Item -Path $MbPackage

        if (-not (Test-Path (Join-Path "$env:Public\Desktop" "MoonBot.lnk") -PathType Leaf)) {
            $WshShell = New-Object -ComObject WScript.Shell
            $Shortcut = $WshShell.CreateShortcut((Join-Path "$env:Public\Desktop" "MoonBot.lnk"))
            $Shortcut.TargetPath = $MbFolderBase
            $Shortcut.Save()
        }

        Write-Host "-- Extracted to $MbFolder" -ForegroundColor Green
        break
    }
    catch {
        if ($_.Exception.Message -like "*(404) Not Found*") {
            Write-Host "-- $MbVersion.zip does not exist" -ForegroundColor Red
        }
        else {
            Write-Host "-- Error: $($_.Exception.Message)" -ForegroundColor Red
        }
    }
} until ($selection -eq '3')
