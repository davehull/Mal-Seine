Mal-Seine
=========

If you're looking at this, you should check out Kansa (https://github.com/davehull/Kansa).

A reference script for collecting data from hosts in an organization when seining for evil.
What does the script collect:
  1. Prefetch
  2. Processes using Powershell Get-Process (includes modules, threads, etc.)
  3. Processes using tasklist (includes owner)
  4. Open handles using Sysinternals Handle.exe
  5. DNS cache
  6. ARP cache
  7. Netstat with process name and PID
  8. Autoruns using Sysinternals Autorunsc.exe
  9. Bits Transfers
  10. Service Triggers
  11. Service failures
  12. WMI Event Consumers
  13. Powershell profiles

All output is copied to a zip archive for offline analysis.

I have run this script or slight variations of it over 10s of 1000s of hosts at time and performed analysis beginning with stack ranking the data (see https://github.com/davehull/Get-StakRank#get-stakrank) and reviewing outliers. There are commercial products that will gather much of this data, and in more robust ways, bypassing the WinAPI and scraping memory for process and networking artifacts, but those tools can take hours to run depending on the amount of RAM in the box. This script takes a couple minutes per host.

Average size of collected data is around 1.5 - 2 MiB with compression. Uncompressed data averages around 10 - 12MiB per
host, but YMMV depending on what your hosts are doing.

Some of the collected data doesn't immediately lend itself to easy analysis. You can use the conversion scripts to convert those data sets to delimited values that can be stack ranked, loaded into Excel, a database or other analysis tools. These include:
  1. Convert-NetstatToSV.ps1
  2. Convert-HandleToSV.ps1
  3. Convert-SvcTrigToSV.ps1
  4. Convert-SvcFailToSV.ps1
  5. Convert-BitsToSV.ps1
