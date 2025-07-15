Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# Create Form
$form = New-Object System.Windows.Forms.Form
$form.Text = "PC Health Reporter"
$form.Size = New-Object System.Drawing.Size(700, 600)
$form.StartPosition = "CenterScreen"

# Create Output Box
$outputBox = New-Object System.Windows.Forms.RichTextBox
$outputBox.Location = New-Object System.Drawing.Point(20, 60)
$outputBox.Size = New-Object System.Drawing.Size(640, 440)
$outputBox.ReadOnly = $true
$form.Controls.Add($outputBox)

# Create Run Button
$runButton = New-Object System.Windows.Forms.Button
$runButton.Text = "Run Health Scan"
$runButton.Location = New-Object System.Drawing.Point(20, 20)
$runButton.Size = New-Object System.Drawing.Size(150, 30)
$form.Controls.Add($runButton)

# Create Save Button
$saveButton = New-Object System.Windows.Forms.Button
$saveButton.Text = "Save Report"
$saveButton.Location = New-Object System.Drawing.Point(180, 20)
$saveButton.Size = New-Object System.Drawing.Size(150, 30)
$form.Controls.Add($saveButton)

# Create Exit Button
$exitButton = New-Object System.Windows.Forms.Button
$exitButton.Text = "Exit"
$exitButton.Location = New-Object System.Drawing.Point(340, 20)
$exitButton.Size = New-Object System.Drawing.Size(150, 30)
$exitButton.Add_Click({ $form.Close() })
$form.Controls.Add($exitButton)

# Health Scan Logic
$runButton.Add_Click({
    $outputBox.Clear()
    $date = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $outputBox.AppendText("PC Health Report - $date`r`n")
    $outputBox.AppendText("====================================`r`n")

    $os = Get-CimInstance Win32_OperatingSystem
    $cpu = Get-CimInstance Win32_Processor
    $disk = Get-CimInstance Win32_LogicalDisk -Filter "DriveType=3"
    $ramTotal = [math]::Round($os.TotalVisibleMemorySize / 1MB, 2)
    $ramUsed = [math]::Round(($os.TotalVisibleMemorySize - $os.FreePhysicalMemory) / 1MB, 2)
    $cpuLoad = (Get-Counter '\Processor(_Total)\% Processor Time').CounterSamples[0].CookedValue
    $uptime = [math]::Round((New-TimeSpan -Start $os.LastBootUpTime).TotalHours, 2)

    $battery = Get-CimInstance Win32_Battery
    $av = Get-CimInstance -Namespace "root\SecurityCenter2" -ClassName AntiVirusProduct

    $outputBox.AppendText("OS: $($os.Caption) ($($os.OSArchitecture))`r`n")
    $outputBox.AppendText("CPU: $($cpu.Name)`r`n")
    $outputBox.AppendText("CPU Load: $([math]::Round($cpuLoad, 2))%`r`n")
    $outputBox.AppendText("RAM: $ramUsed GB used / $ramTotal GB total`r`n")
    $outputBox.AppendText("Uptime: $uptime hours`r`n")

    if ($battery) {
        $outputBox.AppendText("Battery: $($battery.EstimatedChargeRemaining)% remaining`r`n")
    }

    if ($av) {
        $outputBox.AppendText("Antivirus: $($av.displayName)`r`n")
    } else {
        $outputBox.AppendText("Antivirus: Not detected`r`n")
    }

    $outputBox.AppendText("`r`nDisk Usage:`r`n")
    foreach ($d in $disk) {
        $sizeGB = [math]::Round($d.Size / 1GB, 2)
        $freeGB = [math]::Round($d.FreeSpace / 1GB, 2)
        $usedGB = $sizeGB - $freeGB
        $usedPct = [math]::Round(($usedGB / $sizeGB) * 100, 1)
        $outputBox.AppendText("$($d.DeviceID): $usedPct% used ($usedGB GB of $sizeGB GB)`r`n")
    }

    $outputBox.AppendText("`r`nTop Installed Programs:`r`n")
    $apps = Get-ItemProperty HKLM:\Software\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\* |
        Select-Object DisplayName, DisplayVersion, EstimatedSize |
        Sort-Object EstimatedSize -Descending |
        Select-Object -First 10

    foreach ($app in $apps) {
        $outputBox.AppendText("$($app.DisplayName) - $($app.DisplayVersion)`r`n")
    }

    $outputBox.AppendText("`r`nScan complete.`r`n")
})

# Save Report Logic
$saveButton.Add_Click({
    $path = "$env:USERPROFILE\Desktop\PC_Health_Report.txt"
    $outputBox.Text | Out-File $path
    [System.Windows.Forms.MessageBox]::Show("Report saved to desktop as PC_Health_Report.txt")
})

# Launch GUI
$form.ShowDialog()
