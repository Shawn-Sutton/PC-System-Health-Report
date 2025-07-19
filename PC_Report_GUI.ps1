Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# Create Form
$form = New-Object System.Windows.Forms.Form
$form.Text = "PC Health Reporter"
$form.Size = New-Object System.Drawing.Size(700, 640)
$form.StartPosition = "CenterScreen"

# Global variable for disk data (used in CSV export)
$global:diskData = @()

# Output Box
$outputBox = New-Object System.Windows.Forms.RichTextBox
$outputBox.Location = New-Object System.Drawing.Point(20, 140)
$outputBox.Size = New-Object System.Drawing.Size(640, 440)
$outputBox.ReadOnly = $true
$outputBox.ScrollBars = "Vertical"
$form.Controls.Add($outputBox)

# Buttons
$runButton = New-Object System.Windows.Forms.Button
$runButton.Text = "Run Health Scan"
$runButton.Location = New-Object System.Drawing.Point(20, 20)
$runButton.Size = New-Object System.Drawing.Size(150, 30)
$form.Controls.Add($runButton)

$saveButton = New-Object System.Windows.Forms.Button
$saveButton.Text = "Save Report"
$saveButton.Location = New-Object System.Drawing.Point(180, 20)
$saveButton.Size = New-Object System.Drawing.Size(150, 30)
$form.Controls.Add($saveButton)

$csvButton = New-Object System.Windows.Forms.Button
$csvButton.Text = "Export CSV"
$csvButton.Location = New-Object System.Drawing.Point(340, 20)
$csvButton.Size = New-Object System.Drawing.Size(150, 30)
$form.Controls.Add($csvButton)

$exitButton = New-Object System.Windows.Forms.Button
$exitButton.Text = "Exit"
$exitButton.Location = New-Object System.Drawing.Point(500, 20)
$exitButton.Size = New-Object System.Drawing.Size(150, 30)
$exitButton.Add_Click({ $form.Close() })
$form.Controls.Add($exitButton)

# Scan Options GroupBox
$optionsGroup = New-Object System.Windows.Forms.GroupBox
$optionsGroup.Text = "Scan Options"
$optionsGroup.Location = New-Object System.Drawing.Point(20, 60)
$optionsGroup.Size = New-Object System.Drawing.Size(640, 70)
$form.Controls.Add($optionsGroup)

# Option Checkboxes
$chkSys = New-Object System.Windows.Forms.CheckBox
$chkSys.Text = "System Info"
$chkSys.Checked = $true
$chkSys.Location = New-Object System.Drawing.Point(10, 30)
$optionsGroup.Controls.Add($chkSys)

$chkDisk = New-Object System.Windows.Forms.CheckBox
$chkDisk.Text = "Disk Usage"
$chkDisk.Checked = $true
$chkDisk.Location = New-Object System.Drawing.Point(120, 30)
$optionsGroup.Controls.Add($chkDisk)

$chkApps = New-Object System.Windows.Forms.CheckBox
$chkApps.Text = "Installed Apps"
$chkApps.Checked = $true
$chkApps.Location = New-Object System.Drawing.Point(230, 30)
$optionsGroup.Controls.Add($chkApps)

# Health Scan Logic
$runButton.Add_Click({
    $outputBox.Clear()
    $date = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $outputBox.AppendText("PC Health Report - $date`r`n")
    $outputBox.AppendText("====================================`r`n")

    $os = Get-CimInstance Win32_OperatingSystem
    $cpu = Get-CimInstance Win32_Processor
    $disk = Get-CimInstance Win32_LogicalDisk -Filter "DriveType=3"
    $global:diskData = $disk
    $ramTotal = [math]::Round($os.TotalVisibleMemorySize / 1MB, 2)
    $ramUsed = [math]::Round(($os.TotalVisibleMemorySize - $os.FreePhysicalMemory) / 1MB, 2)
    $cpuLoad = (Get-Counter '\Processor(_Total)\% Processor Time').CounterSamples[0].CookedValue
    $uptime = [math]::Round((New-TimeSpan -Start $os.LastBootUpTime).TotalHours, 2)

    $battery = Get-CimInstance Win32_Battery
    $av = Get-CimInstance -Namespace "root\SecurityCenter2" -ClassName AntiVirusProduct

    if ($chkSys.Checked) {
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

        $outputBox.AppendText("`r`n")
    }

    if ($chkDisk.Checked) {
        $outputBox.AppendText("Disk Usage:`r`n")
        foreach ($d in $disk) {
            $sizeGB = [math]::Round($d.Size / 1GB, 2)
            $freeGB = [math]::Round($d.FreeSpace / 1GB, 2)
            $usedGB = $sizeGB - $freeGB
            $usedPct = [math]::Round(($usedGB / $sizeGB) * 100, 1)
            $outputBox.AppendText("$($d.DeviceID): $usedPct% used ($usedGB GB of $sizeGB GB)`r`n")
        }
        $outputBox.AppendText("`r`n")
    }

    if ($chkApps.Checked) {
        $outputBox.AppendText("Top Installed Programs:`r`n")
        $apps = Get-ItemProperty HKLM:\Software\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\* |
            Select-Object DisplayName, DisplayVersion, EstimatedSize |
            Sort-Object EstimatedSize -Descending |
            Select-Object -First 10

        foreach ($app in $apps) {
            $outputBox.AppendText("$($app.DisplayName) - $($app.DisplayVersion)`r`n")
        }
        $outputBox.AppendText("`r`n")
    }

    $outputBox.AppendText("Scan complete.`r`n")
})

# Save Report Logic
$saveButton.Add_Click({
    $path = "$env:USERPROFILE\Desktop\PC_Health_Report.txt"
    $outputBox.Text | Out-File $path
    [System.Windows.Forms.MessageBox]::Show("Report saved to desktop as PC_Health_Report.txt")
})

# Export CSV Logic
$csvButton.Add_Click({
    if ($global:diskData.Count -eq 0) {
        [System.Windows.Forms.MessageBox]::Show("Please run the health scan first.")
        return
    }

    $csvPath = "$env:USERPROFILE\Desktop\Disk_Report.csv"
    $global:diskData | Select-Object DeviceID, 
        @{Name="UsedGB";Expression={[math]::Round(($_.Size - $_.FreeSpace)/1GB,2)}},
        @{Name="TotalGB";Expression={[math]::Round($_.Size / 1GB,2)}} |
        Export-Csv -Path $csvPath -NoTypeInformation

    [System.Windows.Forms.MessageBox]::Show("Disk report exported to Desktop as Disk_Report.csv.")
})

# Launch GUI
$form.ShowDialog()

