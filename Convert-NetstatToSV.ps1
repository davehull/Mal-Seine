<#
.SYNOPSIS
Convert-NetstatToSV.ps1 takes the output from netstat.exe -n -a -o -b and parses
it into delimited format suitable for stack ranking via get-stakrank.ps1. This is
a first effort and I may play around with it some more. I see some have converted
netstat's output to an object and that's probably a better idea, it's easy to go
from an object to delimited data with Powershell.

I need to break out the IP/Host data from port for Local and Foreign addresses.
.PARAMETER FileNamePattern
Specifies the naming pattern common to the netstat files to be converted.
.PARAMETER Delimiter
Specifies the delimiter character to use for output. Tab is default.
.PARAMETER ToFile
Specifies that output be written to a file matching the FileNamePattern (same path),
but with .tsv or .csv extension depending on delimtier (.tsv is default).
#>

[CmdletBinding()]
Param(
    [Parameter(Mandatory=$True,Position=0)]
        [string]$FileNamePattern,
    [Parameter(Mandatory=$False,Position=1)]
        [string]$Delimiter="`t",
    [Parameter(Mandatory=$False,Position=2)]
        [switch]$tofile=$False
)

function Get-Files {
<#
.SYNOPSIS
Returns the list of input files matching the user supplied file name pattern.
Traverses subdirectories.
#>
Param(
    [Parameter(Mandatory=$True,Position=0)]
        [String]$FileNamePattern
)
    Write-Verbose "Entering $($MyInvocation.MyCommand)"
    Write-Verbose "Looking for files matching user supplied pattern, $FileNamePattern"
    Write-Verbose "This process traverses subdirectories so it may take some time."
    $Files = @(ls -r $FileNamePattern | % { $_.FullName })
    if ($Files) {
        Write-Verbose "File(s) matching pattern, ${FileNamePattern}:`n$($Files -join "`n")"
        $Files
    } else {
        Write-Error "No input files were found matching the user supplied pattern, `
            ${FileNamePattern}."
        Write-Verbose "Exiting $($MyInvocation.MyCommand)"
        exit
    }
    Write-Verbose "Exiting $($MyInvocation.MyCommand)"
}

function Convert {
Param(
    [Parameter(Mandatory=$True,Position=0)]
        [String]$File,
    [Parameter(Mandatory=$True,Position=1)]
        [char]$Delimiter
)
    Write-Verbose "Entering $($MyInvocation.MyCommand)"
    Write-Verbose "Processing $File."
    $data = gc $File
    "Proto`tLocal Address`tForeign Address`tState`tPId`tComponent`tExecutable"
    foreach($line in $data) {
       if ($line.length -gt 1 -and $line -notmatch "Active Connections|Proto  Local Address") {
            $line = $line.trim()
            if ($line.StartsWith("TCP") -or $line.StartsWith("UDP")) {
                $topline
                $component = $executable = $False
                $line = $line -replace '\s+', $Delimiter
                $topline = $line
            } else { 
                if ($line -match "^\[[-_a-zA-Z0-9.]+\.(exe|com|ps1)\]$" -and $component -eq $False) {
                    $component  = $line
                    $executable = $line
                    $topline += $Delimiter + ($component, $executable -join $Delimiter)
                } elseif (!$component) {
                    $component = $line
                    $topline += $Delimiter + $component
                } else {
                    $executable = $line
                    $topline += $Delimiter + $executable
                }
                if ($component -eq "Can not obtain ownership information") {
                    $executable = $component
                    $topline += $Delimiter + $executable
                }
            }
        }
    }
    $topline
}

$Files = Get-Files -FileNamePattern $FileNamePattern

foreach ($File in $Files) {
    $data = Convert $File $Delimiter
    if ($tofile) {
        $path = ls $File
        $outpath = $path.DirectoryName + "\" + $path.BaseName          
        if ($Delimiter -eq "`t") {
            $outpath += ".tsv"
        } elseif ($Delimiter -eq ",") {
            $outpath += ".csv"
        } else {
            $outpath += ".sv"
        }
        Write-Verbose "Writing output to ${outpath}."
        $data | set-content -Encoding Ascii $outpath 
    } else {
        $data
    }
}
