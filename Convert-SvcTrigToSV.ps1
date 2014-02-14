<#
.SYNOPSIS
Convert-SvcTrigsToSV.ps1 takes the output from Get-HostData.ps1's Service Trigger 
collection and parses it into delimited format suitable for stack ranking via 
get-stakrank.ps1.

.PARAMETER FileNamePattern
Specifies the naming pattern common to the handle file output to be converted.
.PARAMETER Delimiter
Specifies the delimiter character to use for output. Tab is default.
.PARAMETER ToFile
Specifies that output be written to a file matching the FileNamePattern (same path),
but with .tsv or .csv extension depending on delimtier (.tsv is default).
.PARAMETER NameProviders
Looks up LogProviders names and where matches are found, replaces GUIDs with "friendly"
names.
#>

[CmdletBinding()]
Param(
    [Parameter(Mandatory=$True,Position=0)]
        [string]$FileNamePattern,
    [Parameter(Mandatory=$False,Position=1)]
        [string]$Delimiter="`t",
    [Parameter(Mandatory=$False,Position=2)]
        [switch]$tofile=$False,
    [Parameter(Mandatory=$False,Position=3)]
        [switch]$NameProviders=$False
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

function Get-LogProviderHash {
    Write-Verbose "Entering $($MyInvocation.MyCommand)"
    $LogProviders = @{}
    foreach ($provider in (& $env:windir\system32\logman.exe query providers)) {
        if ($provider -match "\{") {
            $LogName, $LogGuid = ($provider -split "{") -replace "}"
            $LogName = $LogName.Trim()
            $LogGuid = $LogGuid.Trim()
            if ($LogProviders.ContainsKey($LogGuid)) {} else {
                Write-Verbose "Adding ${LogGuid}:${LogName} to `$LogProviders hash."
                $LogProviders.Add($LogGuid, $LogName)
            }
        }
    }
    $LogProviders
    Write-Verbose "Exiting $($MyInvocation.MyCommand)"
}

function Convert {
Param(
    [Parameter(Mandatory=$True,Position=0)]
        [String]$File,
    [Parameter(Mandatory=$True,Position=1)]
        [char]$Delimiter,
    [Parameter(Mandatory=$False,Position=2)]
        [hashtable]$LogProviders
)
    Write-Verbose "Entering $($MyInvocation.MyCommand)"
    Write-Verbose "Processing $File."
    $ServiceName = $Action = $Condition = $Value = $False
    $CondPattern = '(?<Desc>[-_ A-Za-z0-9]+)\s:\s(?<Guid>[-0-9a-fA-F]+)\s(?<Trailer>[-\[A-Za-z0-9 ]+\]*)'
    $data = gc $File
    ("ServiceName","Action","Condition","Value") -join $Delimiter
    foreach($line in $data) {
        $line = $line.Trim()
        if ($line -match "SERVICE_NAME:\s(?<SvcName>[-_A-Za-z0-9]+)") {
            if ($ServiceName -and $Action -and $Condition) {
                if ($Value) {
                    ($ServiceName,$Action,$Condition,$Value) -join $Delimiter
                } else {
                    ($ServiceName,$Action,$Condition,$null) -join $Delimiter
                }
            }
            $ServiceName = $matches['SvcName']
            $Action = $Condition = $Value = $False
        } elseif ($line -match "(START SERVICE|STOP SERVICE)") {
            if ($ServiceName -and $Action -and $Condition) {
                if ($Value) {
                    ($ServiceName,$Action,$Condition,$Value) -join $Delimiter
                } else {
                    ($ServiceName,$Action,$Condition,$null) -join $Delimiter
                }
            }
            $Action = ($matches[1])
            $Condition = $Value = $False
        } elseif ($line -match "DATA\s+") {
            $Value = $line -replace "\s+", " "
        } else {
            $Condition = $line -replace "\s+", " "
            if ($LogProviders) {
                $ProviderName = $False
                if ($Condition -match $CondPattern) {
                    $Guid = $($matches['Guid']).ToUpper()
                    $ProviderName = $LogProviders.$Guid
                    if ($ProviderName) {
                        $Condition = ($matches['Desc'] + ": " + $LogProviders.$Guid + " " + $matches['Trailer'])
                    }
                }
            }
            $Value = $False
        }
    }
    if ($Value) {
        ($ServiceName,$Action,$Condition,$Value) -join $Delimiter
    } else {
        ($ServiceName,$Action,$Condition,$null) -join $Delimiter
    }
}

if ($NameProviders) {
    $LogProviders = Get-LogProviderHash
<#    $LogProviders
    exit#>
}

$Files = Get-Files -FileNamePattern $FileNamePattern

foreach ($File in $Files) {
    if ($LogProviders) {
        $data = Convert $File $Delimiter $LogProviders
    } else {
        $data = Convert $File $Delimiter
    }
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
