<#
.SYNOPSIS
Convert-HandleToSV.ps1 takes the output from Sysinternals handle.exe -a and parses
it into delimited format suitable for stack ranking via get-stakrank.ps1.

.NOTE
Handle Ids are discarded and remaining lines are deduped.

.PARAMETER FileNamePattern
Specifies the naming pattern common to the handle file output to be converted.
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
    ("Process","PId","Owner","Type","Perms","Name") -join $Delimiter
    foreach($line in $data) {
        if ($line -notmatch "^-{30,}|Handle v|Copyright \(C\) 1997|Sysinternals \- www\.") {
            $line = $line.Trim()
            if ($line -match " pid: ") {
                $HandleId = $Type = $Perms = $Name = $null
                $pattern = "(?<ProcessName>^[-a-zA-Z0-9_.]+) pid: (?<PId>\d+) (?<Owner>.+$)"
                if ($line -match $pattern) {
                    $ProcessName,$ProcId,$Owner = ($matches['ProcessName'],$matches['PId'],$matches['Owner'])
                }
            } else {
                $pattern = "(?<HandleId>^[a-f0-9]+): (?<Type>\w+)"
                if ($line -match $pattern) {
                    $HandleId,$Type = ($matches['HandleId'],$matches['Type'])
                    $Perms = $Name = $null
                    switch ($Type) {
                        "File" {
                            $pattern = "(?<HandleId>^[a-f0-9]+):\s+(?<Type>\w+)\s+(?<Perms>\([-RWD]+\))\s+(?<Name>.*)"
                            if ($line -match $pattern) {
                                $Perms,$Name = ($matches['Perms'],$matches['Name'])
                            }
                        }
                        default {
                            $pattern = "(?<HandleId>^[a-f0-9]+):\s+(?<Type>\w+)\s+(?<Name>.*)"
                            if ($line -match $pattern) {
                                $Name = ($matches['Name'])
                            }
                        }
                    }
                    if ($Name -ne $null) {
                        # ($ProcessName,$ProcId,$Owner,$HandleId,$Type,$Perms,$Name) -join $Delimiter
                        ($ProcessName,$ProcId,$Owner,$Type,$Perms,$Name) -join $Delimiter
                    }
                }
            }
        }
    }
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
        $data | Select -Unique | Set-Content -Encoding Ascii $outpath
    } else {
        $data | Select -Unique
    }
}
