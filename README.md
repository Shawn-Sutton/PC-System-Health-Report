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
PC Health Report - 2025-06-25 14:12:00
====================================
OS: Windows 10 Pro (64-bit)
CPU: Intel(R) Core(TM) i5-8250U CPU @ 1.60GHz
Total RAM: 7.89 GB
Uptime: 4.25 hours

Disk Usage:
C:: Used 95.32 GB / 256.00 GB (Free: 160.68 GB)

Installed Programs (Top 10 by size):
Google Chrome - 125.0.6422.112
Microsoft Office - 2021
...

