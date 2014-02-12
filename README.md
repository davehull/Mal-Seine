Mal-Seine
=========

A reference script for collecting data from hosts in an organization when seining for evil.
What does the script collect:
  1. Autoruns using Sysinternals Autorunsc.exe
  2. DNS Cache
  3. Processes using Powershell Get-Process (includes modules, threads, etc.)
  4. Processes using tasklist (includes owner)
  5. ARP Cache
  6. Netstat with process name and PID
  7. Open handles using Sysinternals Handle.exe
  8. ImageFileExecution Options
  9. Bits Transfers
  10. Service triggers
  11. Service failures

All output is copied to a zip archive for offline analysis.

I have run this script or slight variations of it over 10s of 1000s of hosts at time and performed analysis beginning
with stack ranking the data (see https://github.com/davehull/Get-StakRank#get-stakrank) and reviewing outliers. There 
are commercial products that will gather much of this data, and in more robust ways, bypassing the WinAPI and scraping
memory for process and networking artifacts, but those tools can take hours to run depending on the amount of RAM in 
the box. This script takes a couple minutes per host.

Average size of collected data is around 1.5 - 2 MiB with compression. Uncompressed data averages around 10 - 12MiB per
host, but YMMV depending on what your hosts are doing.

I've added a script to this repo for converting Windows multiline netstat -n -a -o -b output to a delimited format.
Delimited data is easily stack ranked using Get-StakRank mentioned above.
