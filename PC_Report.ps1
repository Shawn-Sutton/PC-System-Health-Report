# PC_Report.ps1
# Author: Shawn Sutton
# Description: Gathers system health info and outputs it to a report on the desktop.

$reportPath = "$env:USERPROFILE\Desktop\PC_Health_Report.txt"
$date = Get-Date -Format "yyyy-MM-dd HH:mm:ss"

# System Info
$os = Get-CimInstance Win32_OperatingSystem
$cpu = Get-CimInstance Win32_Processor
$disk = Get-CimInstance Win32_LogicalDisk -Filter "DriveType=3"
$ram = [math]::Round(($os.TotalVisibleMemorySize / 1MB), 2)

# Create Report
"PC Health Report - $date" | Out-File $reportPath
"====================================" | Out-File $reportPath -Append
"OS: $($os.Caption) ($($os.OSArchitecture))" | Out-File $reportPath -Append
"CPU: $($cpu.Name)" | Out-File $reportPath -Append
"Total RAM: $ram GB" | Out-File $reportPath -Append
"Uptime: $([math]::Round((New-TimeSpan -Start $os.LastBootUpTime).TotalHours, 2)) hours" | Out-File $reportPath -Append
"" | Out-File $reportPath -Append

# Disk Info
"Disk Usage:" | Out-File $reportPath -Append
foreach ($d in $disk) {
    $sizeGB = [math]::Round($d.Size / 1GB, 2)
    $freeGB = [math]::Round($d.FreeSpace / 1GB, 2)
    $usedGB = $sizeGB - $freeGB
    "$($d.DeviceID): Used $usedGB GB / $sizeGB GB (Free: $freeGB GB)" | Out-File $reportPath -Append
}

# Installed Programs (Top 10 by size)
"" | Out-File $reportPath -Append
"Installed Programs (Top 10 by size):" | Out-File $reportPath -Append
$apps = Get-ItemProperty HKLM:\Software\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\* |
    Select-Object DisplayName, DisplayVersion, EstimatedSize |
    Sort-Object EstimatedSize -Descending |
    Select-Object -First 10

foreach ($app in $apps) {
    "$($app.DisplayName) - $($app.DisplayVersion)" | Out-File $reportPath -Append
}

"" | Out-File $reportPath -Append
"Report saved to: $reportPath"
