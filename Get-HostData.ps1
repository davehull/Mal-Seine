<#
.SYNOPSIS
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
  9. Service triggers
 10. Bits Transfers
 
All output is copied to a zip archive for offline analysis.

I have run this script or slight variations of it over 10s of 1000s of hosts at a time and performed analysis beginning
with stack ranking the data (see https://github.com/davehull/Get-StakRank#get-stakrank) and reviewing outliers. There 
are commercial products that will gather much of this data, and in more robust ways, bypassing the WinAPI and scraping
memory for process and networking artifacts, but those tools can take hours to run depending on the amount of RAM in 
the box. This script takes a couple minutes per host.

Average size of collected data is around 1.5 - 2 MiB with compression. Uncompressed data averages around 10 - 12MiB per
host, but YMMV depending on what your hosts are doing.
#>

$sharename = "\\CONFIGURE\THIS"
# make a \bin\ dir in the share for latest version of Sysinternals autorunsc.exe and handle.exe 
# available from http://technet.microsoft.com/en-us/sysinternals


if ($sharename -match "CONFIGURE") {
    write-host "`n[*] ERROR: You must edit the script and configure a share for the data to be written to, and for autorunsc.exe to be run from.`n"
    exit
}

#put autorunsc.exe, handle.exe in the following path
$sharebin = $sharename + "\bin\"

$temp = $env:temp
$this_computer = $($env:COMPUTERNAME)
$zipfile = $temp + "\" + $this_computer + "_bh.zip"

# get autoruns
$arunsout = $temp + "\" + $this_computer + "_aruns.csv"
& "$sharebin\autorunsc.exe" /accepteula -a -c -v -f '*' | set-content -encoding ascii $arunsout


# get dnscache
$dnsout = $temp + "\" + $this_computer + "_dnscache.txt"
& ipconfig /displaydns | select-string 'Record Name' | foreach-object { $_.ToString().Split(' ')[-1] } | `
  select -unique | sort | set-content -encoding ascii $dnsout


# get process data
$procout = $temp + "\" + $this_computer + "_prox.xml"
get-process | export-clixml $procout

# tasklist gives username
$tlist = $temp + "\" + $this_computer + "_tlist.csv"
& tasklist /v /fo csv | set-content -encoding ascii $tlist


# get arp cache
$arpout = $temp + "\" + $this_computer + "_arp.txt"
& arp -a | set-content -encoding ascii $arpout


# get netstat
$netstatout = $temp + "\" + $this_computer + "_netstat.txt"
& netstat -n -a -o -b | set-content -encoding ascii $netstatout


# get handle
$handleout = $temp + "\" + $this_computer + "_handle.txt"
& "$sharebin\handle.exe" /accepteula -a | set-content -encoding ascii $handleout


# get image file execution options
$imgxoptout = $temp + "\" + $this_computer + "_imgexecopt.txt"
& reg query "HKLM\software\microsoft\windows nt\currentversion\image file execution options" /s | set-content -encoding ascii $imgxoptout
  

# get bits transfers
$bitsxferout = $temp + "\" + $this_computer + "_bitsxfer.xml"
Get-BitsTransfer -AllUsers | Export-Clixml $bitsxferout
  

# get service triggers
$svctrigout = $temp + "\" + $this_computer + "_svctriggers.txt"
$($(foreach ($svc in (& c:\windows\system32\sc query)) { 
  if ($svc -match "SERVICE_NAME:\s(.*)") {
    & c:\windows\system32\sc qtriggerinfo $($matches[1])
  }
})|?{$_.length -gt 1 -and $_ -notmatch "\[SC\] QueryServiceConfig2 SUCCESS|has not registered for any" }) | set-content -encoding Ascii $svctrigout


# check for locked files
function Test-FileLock {
    param([parameter(Mandatory=$true)]
        [string]$Path
    )

    $oFile = New-Object System.IO.FileInfo $Path

    if ((Test-Path -Path $Path) -eq $false)
    {
        $false 
        return
    }

    try {
        $oStream = $oFile.Open([System.IO.FileMode]::Open, [System.IO.FileAccess]::ReadWrite, [System.IO.FileShare]::None)
        if ($oStream) {
            $oStream.Close()
        }
        $false
    }
    catch {
        $true
    }
}


# consolidate all
function add-zip
{
    param([string]$zipfilename)

    if (-not (test-path($zipfilename))) {
        set-content $zipfilename ("PK" + [char]5 + [char]6 + ("$([char]0)" * 18))
        (dir $zipfilename).IsReadOnly = $false
    }

    $shellApplication = new-object -com shell.application
    $zipPackage = $shellApplication.NameSpace($zipfilename)

    foreach($file in $input) {
        $zipPackage.CopyHere($file.FullName)
        Start-Sleep -milliseconds 500
    }
}

# wait for locked zipfile
function ziplock
{
    param([string]$zipfilename)
    $tries = 0
    while ($tries -lt 100) {
        if (Test-FileLock($zipfile)) {
            Start-Sleep -seconds 1
            $tries++
            continue
        } else {
            break
        }
    }
}


ls $dnsout     | add-zip $zipfile
ziplock $zipfile

ls $procout    | add-zip $zipfile
ziplock $zipfile

ls $tlist      | add-zip $zipfile
ziplock $zipfile

ls $arpout     | add-zip $zipfile
ziplock $zipfile

ls $netstatout | add-zip $zipfile
ziplock $zipfile

ls $arunsout   | add-zip $zipfile
ziplock $zipfile

ls $handleout  | add-zip $zipfile
ziplock $zipfile

ls $imgxoptout | add-zip $zipfile
ziplock $zipfile

ls $svctrigout | add-zip $zipfile
ziplock $zipfile

ls $bitsxferout | add-zip $zipfile
ziplock $zipfile

copy $zipfile $sharename
rm $dnsout
rm $procout
rm $tlist
rm $arpout
rm $netstatout
rm $arunsout
rm $handleout
rm $imgxoptout
rm $svctrigout
rm $bitsxferout
ziplock $zipfile
rm $zipfile
