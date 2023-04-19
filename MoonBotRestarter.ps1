# Generate a numbered list of processes with the name MoonBot and their paths to executables
$moonBots = Get-Process -Name "MoonBot" -ErrorAction SilentlyContinue
if ($moonBots) {
    Write-Host "MoonBot processes:"
    $i = 1
    foreach ($process in $moonBots) {
        Write-Host "$i) $($process.Name) - $($process.Path)"
        $i++
    }
}
else {
    Write-Host "No MoonBot processes found."
}

# Select a process or multiple processes via the numbers from the list generated in previous step
$selectedProcesses = Read-Host "Enter the number(s) of the process(es) you want to kill and restart, separated by commas (e.g. 1, 2, 3):"
$selectedProcesses = $selectedProcesses -split "," | ForEach-Object { $_.Trim() }

# Forcefully kill the selected process or processes and restart them with a delay of 60 seconds between restarts
if ($selectedProcesses) {
    foreach ($processNumber in $selectedProcesses) {
        $process = $moonBots[$processNumber - 1]
        if ($null -ne $process) {
            $processPath = $process.Path
            Write-Host "Killing process $($process.Name) with path: $($process.Path)"
            $process.Kill()
            Write-Host "Restarting process $($process.Name) with path: $processPath"      
            Start-Process $processPath
            Write-Host "Waiting 60 seconds before restarting another MoonBot instance."      
            Start-Sleep -Seconds 60
        }
        else {
            Write-Host "No process found with number: $processNumber."
        }
    }
}
else {
    Write-Host "No processes selected to kill and restart."
}