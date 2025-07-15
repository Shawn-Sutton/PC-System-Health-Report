# PC System Health & Info Report (PowerShell)

This PowerShell script collects essential PC health data including OS, CPU, RAM, disk usage, uptime, and installed apps. It creates a report saved to the user’s desktop.

## 🔧 Features
- OS and architecture info
- CPU and total RAM
- System uptime
- Disk usage per drive
- Top 10 installed programs by size

## 📦 How to Use
1. Download or clone the repo.
2. Right-click `PC_Report.ps1` → "Run with PowerShell"
3. The report will appear on your desktop as `PC_Health_Report.txt`

## 🖼️ Sample Output
```
PC Health Report - 2025-07-15 11:51:12
====================================
OS: Microsoft Windows 10 Pro (64-bit)
CPU: Intel(R) Core(TM) i5-6500 CPU @ 3.20GHz
CPU Load: 5.71%
RAM: 8.62 GB used / 15.89 GB total
Uptime: 131.76 hours
Antivirus: Windows Defender

Disk Usage:
C:: 21.7% used (101.08 GB of 464.92 GB)
D:: 95.6% used (890.21 GB of 931.5 GB)
R:: 58.9% used (0.43 GB of 0.73 GB)

Top Installed Programs (by size):
UE Prerequisites (x64) - 1.0.22.0  
Microsoft Visual C++ 2015–2022 Redistributable (x64) - 14.42.34438  
Microsoft Visual C++ 2015–2022 Redistributable (x86) - 14.42.34438  
Microsoft Visual C++ 2022 X86 Additional Runtime - 14.42.34438  
Microsoft Visual C++ 2022 X86 Minimum Runtime - 14.42.34438  
—  
— 1.3.195.61  
Microsoft Edge - 138.0.3351.83  
Microsoft Edge WebView2 Runtime - 138.0.3351.83  
—  

...

