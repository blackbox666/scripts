# UI Functions
function Show-Header {
    $width = 60
    $title = "Configure Fixed DPI Scaling"
    $description = "Default: Adaptive"
    $line = "=" * $width
    
    Write-Host $line -ForegroundColor Cyan
    Write-Host $title.PadLeft([math]::Floor(($width + $title.Length) / 2)).PadRight($width) -ForegroundColor Cyan
    Write-Host $description.PadLeft([math]::Floor(($width + $description.Length) / 2)).PadRight($width) -ForegroundColor Cyan
    Write-Host $line -ForegroundColor Cyan
}

function Show-Menu {
    Write-Host "`nDPI Scaling Options:`n" -ForegroundColor Cyan
    Write-Host " [1] Set to 100% (96 DPI)"
    Write-Host " [2] Set to 125% (120 DPI)"
    Write-Host " [3] Set to 150% (144 DPI)"
    Write-Host " [4] Set to 175% (168 DPI)"
    Write-Host " [5] Set to 200% (192 DPI)"
    Write-Host " [6] Restore Adaptive DPI"
    Write-Host " [7] Exit"
    return Read-Host "`nSelect option (1-7)"
}

# Helper Functions
function Get-CurrentDpi {
    try {
        $dpiValue = Get-ItemProperty -Path "HKCU:\Control Panel\Desktop" -Name "LogPixels" -ErrorAction Stop
        return $dpiValue.LogPixels
    }
    catch {
        return $null
    }
}

# Core Functions
function Enable-FixedDpi {
    param ([int]$newDpi)
    
    Write-Host "Press Enter to set Fixed DPI to '$newDpi'..." -NoNewline
    Read-Host
    
    Set-ItemProperty -Path "HKCU:\Control Panel\Desktop" -Name "LogPixels" -Value $newDpi -Type DWord
    Set-ItemProperty -Path "HKCU:\Control Panel\Desktop" -Name "Win8DpiScaling" -Value 1 -Type DWord
    Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server\WinStations" -Name "IgnoreClientDesktopScaleFactor" -Value 1 -Type DWord
    
    Write-Host "-- Fixed DPI enabled and set to '$newDpi'" -ForegroundColor Green
    Write-Host "-- Logoff required to apply changes" -ForegroundColor DarkYellow
}

function Disable-FixedDpi {
    Write-Host "Press Enter to disable fixed DPI scaling..." -NoNewline
    Read-Host

    Remove-ItemProperty -Path "HKCU:\Control Panel\Desktop" -Name "LogPixels" -ErrorAction SilentlyContinue
    Remove-ItemProperty -Path "HKCU:\Control Panel\Desktop" -Name "Win8DpiScaling" -ErrorAction SilentlyContinue
    Remove-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server\WinStations" -Name "IgnoreClientDesktopScaleFactor" -ErrorAction SilentlyContinue

    Write-Host "-- Fixed DPI disabled" -ForegroundColor Green
    Write-Host "-- System will now use client's DPI settings" -ForegroundColor Green
    Write-Host "-- Logoff required to apply changes" -ForegroundColor DarkYellow
}

# Main Execution
Show-Header

do {
    Write-Host "`n-- Current DPI Scaling: $(
        $currentDpi = Get-CurrentDpi
        if ($null -ne $currentDpi) { 
            "$currentDpi DPI (Fixed)" 
        } else { 
            "Dynamic" 
        }
    )" -ForegroundColor Green
    
    switch (Show-Menu) {
        '1' { Enable-FixedDpi -newDpi 96 }
        '2' { Enable-FixedDpi -newDpi 120 }
        '3' { Enable-FixedDpi -newDpi 144 }
        '4' { Enable-FixedDpi -newDpi 168 }
        '5' { Enable-FixedDpi -newDpi 192 }
        '6' { Disable-FixedDpi }
        '7' { return }
        default { Write-Host "-- Invalid option" -ForegroundColor Red }
    }
} until ($false)