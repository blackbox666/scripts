# Устанавливаем текущую директорию в качестве корневой
$rootDirectory = Get-Location

$query = @"
SELECT 
    *,
    CASE
        WHEN Comment LIKE '%Latency:% /% Ping:%' THEN 
            trim(
                substr(
                    Comment,
                    instr(Comment, char(10) || 'Latency:') + 9,
                    instr(substr(Comment,instr(Comment, char(10) || 'Latency:') + 9),'/') - 1
                )
            )
        ELSE NULL
    END AS LatencyTrades,
    CASE
        WHEN Comment LIKE '%Ping: % /%' THEN 
            trim(
                substr(
                    Comment,
                    instr(Comment, 'Ping:') + 5,
                    instr(substr(Comment, instr(Comment, 'Ping:') + 5), '/') - 1
                )
            )
        ELSE NULL
    END AS Ping
FROM 
    Orders
"@

# Создаем папку ExportsCSV, если она еще не существует
$exportsDirectory = Join-Path -Path $rootDirectory -ChildPath "ExportsCSV"
if (-not (Test-Path $exportsDirectory)) {
    New-Item -Path $exportsDirectory -ItemType Directory | Out-Null
}

# Получаем все файлы "Binance Futures.db" только из папок "data"
$files = Get-ChildItem -Path "$rootDirectory\*\data\Binance Futures.db" -File

foreach ($file in $files) {
    # Получаем имя родительской папки для папки "data"
    $botName = $file.Directory.Parent.Name

    # Формируем имя для CSV и путь для сохранения результатов
    $csvName = "$botName.csv"
    $outputCsvPath = Join-Path -Path $exportsDirectory -ChildPath $csvName

    # Устанавливаем рабочую директорию в папку экспорта
    Set-Location $exportsDirectory

    # Выполнение команды SQLite с помощью PowerShell
    $dbPath = "`"$($file.FullName)`""
    Invoke-Expression -Command "sqlite3.exe $dbPath `".mode csv`" `".output $csvName`" `"$query`""
}

# Возвращаемся в исходную директорию
Set-Location $rootDirectory

# Выводим уведомление о завершении
Write-Output "Export completed. Check the files in the Exports directory"
