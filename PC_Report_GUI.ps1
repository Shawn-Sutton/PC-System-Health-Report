Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# Form Setup
$form = New-Object System.Windows.Forms.Form
$form.Text = "PC Health Reporter - Advanced Scan"
$form.Size = New-Object System.Drawing.Size(700, 680)
$form.StartPosition = "CenterScreen"

$global:diskData = @()
$global:appsData = @()
$global:ramData  = @()

# Output Box
$outputBox = New-Object System.Windows.Forms.RichTextBox
$outputBox.Location = New-Object System.Drawing.Point(20, 180)
$outputBox.Size = New-Object System.Drawing.Size(640, 380)
$outputBox.ReadOnly = $true
$outputBox.ScrollBars = "Vertical"
$form.Controls.Add($outputBox)

# Status Bar
$statusBar = New-Object System.Windows.Forms.Label
$statusBar.Location = New-Object System.Drawing.Point(0, 620)
$statusBar.Size = New-Object System.Drawing.Size(700, 20)
$statusBar.BorderStyle = "Fixed3D"
$statusBar.TextAlign = "MiddleLeft"
$statusBar.Text = "Ready"
$form.Controls.Add($statusBar)

# Progress Bar
$progress = New-Object System.Windows.Forms.ProgressBar
$progress.Location = New-Object System.Drawing.Point(20, 560)
$progress.Size = New-Object System.Drawing.Size(640, 20)
$progress.Style = 'Continuous'
$form.Controls.Add($progress)

# Buttons
$runButton  = New-Object System.Windows.Forms.Button
$saveButton = New-Object System.Windows.Forms.Button
$csvButton  = New-Object System.Windows.Forms.Button
$exitButton = New-Object System.Windows.Forms.Button

$runButton.Text   = "Run Scan"
$saveButton.Text  = "Save Report"
$csvButton.Text   = "Export CSVs"
$exitButton.Text  = "Exit"

$buttons = @($runButton, $saveButton, $csvButton, $exitButton)
$positions = @(20,180,340,500)

for ($i = 0; $i -lt $buttons.Count; $i++) {
    $btn = $buttons[$i]
    $btn.Location = New-Object System.Drawing.Point($positions[$i], 20)
    $btn.Size = New-Object System.Drawing.Size(150, 30)
    $form.Controls.Add($btn)
}

$exitButton.Add_Click({ $form.Close() })

# ComboBox for Profile
$profileDrop = New-Object System.Windows.Forms.ComboBox
$profileDrop.Items.AddRange(@("Quick Scan","Advanced Scan","Minimal"))
$profileDrop.SelectedIndex = 1
$profileDrop.Location = New-Object System.Drawing.Point(20, 60)
$profileDrop.Size = New-Object System.Drawing.Size(200, 30)
$form.Controls.Add($profileDrop)

# Scan Options
$optionsGroup = New-Object System.Windows.Forms.GroupBox
$optionsGroup.Text = "Scan Modules"
$optionsGroup.Location = New-Object System.Drawing.Point(240, 60)
$optionsGroup.Size = New-Object System.Drawing.Size(420, 100)
$form.Controls.Add($optionsGroup)

$chkSys = New-Object System.Windows.Forms.CheckBox
$chkDisk = New-Object System.Windows.Forms.CheckBox
$chkApps = New-Object System.Windows.Forms.CheckBox
$chkNet  = New-Object System.Windows.Forms.CheckBox
$chkSvc  = New-Object System.Windows.Forms.CheckBox

$chkSys.Text = "System Info";  $chkDisk.Text = "Disk"; $chkApps.Text = "Apps"
$chkNet.Text = "Network";      $chkSvc.Text = "Services"

$checks = @($chkSys, $chkDisk, $chkApps, $chkNet, $chkSvc)
$locs   = @(10, 120, 230, 10, 120)

for ($i = 0; $i -lt $checks.Length; $i++) {
    $chk = $checks[$i]
    $chk.Checked = $true
    $chk.Location = New-Object System.Drawing.Point($locs[$i], (30 + 30 * [math]::Floor($i / 3)))
    $optionsGroup.Controls.Add($chk)
}

# Run Scan Logic
$runButton.Add_Click({
    $outputBox.Clear()
    $statusBar.Text = "Running scan..."
    $progress.Value = 20

    $date = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $outputBox.AppendText("PC Health Report - $date`r`n")
    $outputBox.AppendText("====================================`r`n")

    $os = Get-CimInstance Win32_OperatingSystem
    $cpu = Get-CimInstance Win32_Processor
    $ramTotal = [math]::Round($os.TotalVisibleMemorySize / 1024 / 1024, 2)
    $ramUsed = [math]::Round(($os.TotalVisibleMemorySize - $os.FreePhysicalMemory) / 1024 / 1024, 2)
    $global:ramData = [PSCustomObject]@{
        TotalGB = $ramTotal; UsedGB = $ramUsed; FreeGB = [math]::Round($ramTotal - $ramUsed, 2)
    }

    $disk = Get-CimInstance Win32_LogicalDisk -Filter "DriveType=3"
    $global:diskData = $disk

    $apps = Get-ItemProperty HKLM:\Software\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\* |
        Select-Object DisplayName, DisplayVersion, EstimatedSize |
        Sort-Object EstimatedSize -Descending | Select-Object -First 10
    $global:appsData = $apps

    $progress.Value = 40

    if ($chkSys.Checked) {
        $cpuLoad = (Get-Counter '\Processor(_Total)\% Processor Time').CounterSamples[0].CookedValue
        $uptime = [math]::Round((New-TimeSpan -Start $os.LastBootUpTime).TotalHours, 2)
        $battery = Get-CimInstance Win32_Battery -ErrorAction SilentlyContinue
        $av = Get-CimInstance -Namespace "root\SecurityCenter2" -ClassName AntiVirusProduct -ErrorAction SilentlyContinue

        $outputBox.AppendText("OS: $($os.Caption) ($($os.OSArchitecture))`r`n")
        $outputBox.AppendText("CPU: $($cpu.Name)`r`n")
        $outputBox.AppendText("CPU Load: $([math]::Round($cpuLoad, 2))%`r`n")
        $outputBox.AppendText("RAM: $ramUsed GB used / $ramTotal GB total`r`n")
        $outputBox.AppendText("Uptime: $uptime hours`r`n")
        if ($battery) { $outputBox.AppendText("Battery: $($battery.EstimatedChargeRemaining)%`r`n") }
        if ($av) { $outputBox.AppendText("Antivirus: $($av.displayName)`r`n") } else { $outputBox.AppendText("Antivirus: Not detected`r`n") }
        $outputBox.AppendText("`r`n")
    }

    if ($chkDisk.Checked) {
        $outputBox.AppendText("Disk Usage:`r`n")
        foreach ($d in $disk) {
            $size = [math]::Round($d.Size / 1GB, 2)
            $free = [math]::Round($d.FreeSpace / 1GB, 2)
            $used = $size - $free
            $pct  = [math]::Round(($used / $size) * 100, 1)
            $outputBox.AppendText("$($d.DeviceID): $pct% used ($used GB of $size GB)`r`n")
        }
        $outputBox.AppendText("`r`n")
    }

    if ($chkApps.Checked) {
        $outputBox.AppendText("Top Installed Programs:`r`n")
        foreach ($app in $apps) {
            $outputBox.AppendText("$($app.DisplayName) - $($app.DisplayVersion)`r`n")
        }
        $outputBox.AppendText("`r`n")
    }

    if ($chkNet.Checked) {
        $outputBox.AppendText("Network Adapters:`r`n")
        $net = Get-CimInstance Win32_NetworkAdapter | Where-Object { $_.NetEnabled -eq $true }
        foreach ($n in $net) {
            $outputBox.AppendText("Adapter: $($n.Name)`r`nMAC: $($n.MACAddress)`r`n`r`n")
        }
    }

    if ($chkSvc.Checked) {
        $outputBox.AppendText("Active Services:`r`n")
        $svc = Get-Service | Where-Object { $_.Status -eq 'Running' } | Select-Object -First 10
        foreach ($s in $svc) {
            $outputBox.AppendText("Service: $($s.DisplayName)`r`nStatus: $($s.Status)`r`n`r`n")
        }
    }

    $progress.Value = 100
    $statusBar.Text = "Scan complete"
    $outputBox.AppendText("Scan complete.`r`n")
})

# Save Report Logic
$saveButton.Add_Click({
    $saveDialog = New-Object System.Windows.Forms.SaveFileDialog
    $saveDialog.Filter = "Text Files (*.txt)|*.txt"
    $saveDialog.InitialDirectory = [Environment]::GetFolderPath("Desktop")
    $saveDialog.FileName = "PC_Health_Report.txt"
    if ($saveDialog.ShowDialog() -eq "OK") {
        $outputBox.Text | Out-File -FilePath $saveDialog.FileName -Encoding UTF8
        $statusBar.Text = "Report saved to $($saveDialog.FileName)"
    }
})

# Export CSV Logic
$csvButton.Add_Click({
    $folder = [System.Environment]::GetFolderPath("Desktop")
    try {
        $global:diskData | Export-Csv "$folder\DiskInfo.csv" -NoTypeInformation
        $global:appsData | Export-Csv "$folder\TopApps.csv" -NoTypeInformation
        $global:ramData  | Export-Csv "$folder\MemoryInfo.csv" -NoTypeInformation
        $statusBar.Text = "CSVs exported to Desktop"
    } catch {
        $statusBar.Text = "CSV export failed: $_"
    }
})

# Launch Form
[void]$form.ShowDialog()

