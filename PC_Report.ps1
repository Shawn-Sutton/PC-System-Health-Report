# PC_Report.ps1
# Author: Shawn Sutton
# Description: Gathers system health info and outputs it to a report on the desktop.

$reportPath = "$env:USERPROFILE\Desktop\PC_Health_Report.txt"
$logPath = ".\toolkit.log"
$date = Get-Date -Format "yyyy-MM-dd HH:mm:ss"

function Write-Log {
    param ([string]$Message)
    Add-Content -Path $logPath -Value "$date : $Message"
}

# Collect System Info
$os = Get-CimInstance Win32_OperatingSystem
$cpu = Get-CimInstance Win32_Processor
$disk = Get-CimInstance Win32_LogicalDisk -Filter "DriveType=3"
$ramTotal = [math]::Round(($os.TotalVisibleMemorySize / 1MB), 2)
$ramUsed = [math]::Round(($os.TotalVisibleMemorySize - $os.FreePhysicalMemory) / 1MB, 2)
$cpuLoad = (Get-Counter '\Processor(_Total)\% Processor Time').CounterSamples[0].CookedValue
$uptime = [math]::Round((New-TimeSpan -Start $os.LastBootUpTime).TotalHours, 2)

$battery = Get-CimInstance Win32_Battery
$av = Get-CimInstance -Namespace "root\SecurityCenter2" -ClassName AntiVirusProduct

# Start Report
"PC Health Report - $date" | Out-File $reportPath
"====================================" | Out-File $reportPath -Append
"OS: $($os.Caption) ($($os.OSArchitecture))" | Out-File $reportPath -Append
"CPU: $($cpu.Name)" | Out-File $reportPath -Append
"CPU Load: $([math]::Round($cpuLoad, 2))%" | Out-File $reportPath -Append
"RAM: $ramUsed GB used / $ramTotal GB total" | Out-File $reportPath -Append
"Uptime: $uptime hours" | Out-File $reportPath -Append

if ($battery) {
    "Battery: $($battery.EstimatedChargeRemaining)% remaining" | Out-File $reportPath -Append
}

if ($av) {
    "Antivirus: $($av.displayName)" | Out-File $reportPath -Append
} else {
    "Antivirus: Not detected" | Out-File $reportPath -Append
}

"" | Out-File $reportPath -Append
"Disk Usage:" | Out-File $reportPath -Append

foreach ($d in $disk) {
    $sizeGB = [math]::Round($d.Size / 1GB, 2)
    $freeGB = [math]::Round($d.FreeSpace / 1GB, 2)
    $usedGB = $sizeGB - $freeGB
    $usedPct = [math]::Round(($usedGB / $sizeGB) * 100, 1)
    "$($d.DeviceID): $usedPct% used ($usedGB GB of $sizeGB GB)" | Out-File $reportPath -Append
}

"" | Out-File $reportPath -Append
"Top Installed Programs (by size):" | Out-File $reportPath -Append
$apps = Get-ItemProperty HKLM:\Software\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\* |
    Select-Object DisplayName, DisplayVersion, EstimatedSize |
    Sort-Object EstimatedSize -Descending |
    Select-Object -First 10

foreach ($app in $apps) {
    "$($app.DisplayName) - $($app.DisplayVersion)" | Out-File $reportPath -Append
}

"" | Out-File $reportPath -Append
"Report saved to: $reportPath" | Out-File $reportPath -Append
Write-Log "PC Health Report generated successfully"

