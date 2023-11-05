# Set the current directory as the root
$rootDirectory = Get-Location

# Create ExportsCSV folder if it doesn't exist
$exportsDirectory = Join-Path -Path $rootDirectory -ChildPath "ExportsCSV"
if (-not (Test-Path $exportsDirectory)) {
    New-Item -Path $exportsDirectory -ItemType Directory | Out-Null
}

# Import the module for SQLite
Import-Module PSSQLite

# Define properties to exclude for the compact report
$excludeProperties = @('Comment', 'exOrderID', 'Source', 'Channel', 'Status', 'BaseCurrency', 'SignalType', 'FName', 'deleted', 'Emulator', 'Imp', 'IsShort', 'TaskID')

# Retrieve all "Binance Futures.db" files only from "data" folders
$files = Get-ChildItem -Path "$rootDirectory\*\data\Binance Futures.db" -File

# Save current culture settings
$currentCulture = [System.Threading.Thread]::CurrentThread.CurrentCulture

# Set culture settings to use a dot as decimal separator
[System.Threading.Thread]::CurrentThread.CurrentCulture = New-Object System.Globalization.CultureInfo("en-US")

foreach ($file in $files) {
    # Get the parent folder name for the "data" folder
    $botName = $file.Directory.Parent.Name

    # Form the full CSV name and compact CSV name and path for saving the results
    $fullCsvName = "${botName}_full.csv"
    $compactCsvName = "${botName}_lite.csv"
    $fullOutputCsvPath = Join-Path -Path $exportsDirectory -ChildPath $fullCsvName
    $compactOutputCsvPath = Join-Path -Path $exportsDirectory -ChildPath $compactCsvName

    Write-Host "Exporting orders from $($file.FullName)"

    # Extract data from the database
    $data = Invoke-SqliteQuery -DataSource $file.FullName -Query "SELECT * FROM Orders"

    # Process data for both exports
    $processedData = $data | ForEach-Object {
        # Convert unixtime to readable datetime
        $dateTimeFormat = "yyyy-MM-dd HH:mm:ss"
        $_.BuyDate = [System.DateTimeOffset]::FromUnixTimeSeconds($_.BuyDate).DateTime.ToString($dateTimeFormat)
        $_.SellSetDate = [System.DateTimeOffset]::FromUnixTimeSeconds($_.SellSetDate).DateTime.ToString($dateTimeFormat)
        $_.CloseDate = [System.DateTimeOffset]::FromUnixTimeSeconds($_.CloseDate).DateTime.ToString($dateTimeFormat)
        
        # Extract latency and ping using regex
        $comment = $_.Comment
        $latencyMatch = if ($comment -match "(?<=\bLatency:\s)\d+") { $matches[0] } else { 'N/A' }
        $pingMatch = if ($comment -match "(?<=Ping:\s)\d+") { $matches[0] } else { 'N/A' }

        # Add Latency and Ping to the object
        $_ | Add-Member -NotePropertyName "Latency" -NotePropertyValue $latencyMatch -PassThru |
        Add-Member -NotePropertyName "Ping" -NotePropertyValue $pingMatch -PassThru
    }

    # Export full data to CSV
    $processedData | Export-Csv -Path $fullOutputCsvPath -NoTypeInformation

    # Export compact data to CSV with excluded properties
    $processedData | Select-Object * -ExcludeProperty $excludeProperties |
    Export-Csv -Path $compactOutputCsvPath -NoTypeInformation

    Write-Host "Finished the export for $($file.FullName)"
}

# Reset to the original directory
Set-Location $rootDirectory

# Restore original culture settings
[System.Threading.Thread]::CurrentThread.CurrentCulture = $currentCulture

# Display completion message
Write-Output "Export completed. Check the files in the ExportsCSV directory"
