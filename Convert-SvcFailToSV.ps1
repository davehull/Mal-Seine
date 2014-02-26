<#
.SYNOPSIS
Convert-SvcFailToSV.ps1 takes the output from Get-HostData.ps1's Service Failure 
collection and parses it into delimited format suitable for stack ranking via 
get-stakrank.ps1.

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

function Convert {
Param(
    [Parameter(Mandatory=$True,Position=0)]
        [String]$File,
    [Parameter(Mandatory=$True,Position=1)]
        [char]$Delimiter
)
    Write-Verbose "Entering $($MyInvocation.MyCommand)"
    Write-Verbose "Processing $File."
    $ServiceName = $RstPeriod = $RebootMsg = $CmdLine = $FailAction1 = $FailAction2 = $FailAction3 = $False
    $data = gc $File
    ("ServiceName","ResetPeriod","RebootMessage","CommandLine", "FailureAction1", "FailureAction2", "FailureAction3") -join $Delimiter
    foreach($line in $data) {
        if ($line.StartsWith("[SC]")) {
            continue
        }
        $line = $line.Trim()
        if ($line -match "^S.*\:\s(?<SvcName>[-_A-Za-z0-9]+)") {
            if ($ServiceName) {
                ($ServiceName,$RstPeriod,$RebootMsg,$CmdLine,$FailAction1,$FailAction2,$FailAction3) -replace "False", $null -join $Delimiter
                $ServiceName = $RstPeriod = $RebootMsg = $CmdLine = $FailAction1 = $FailAction2 = $FailAction3 = $False
            }
            $ServiceName = $matches['SvcName']
        } elseif ($line -match "^RESE.*\:\s(?<RstP>[0-9]+|INFINITE)") {
            $RstPeriod = $matches['RstP']
        } elseif ($line -match "^REB.*\:\s(?<RbtMsg>.*)") {
            $RebootMsg = $matches['RbtMsg']
        } elseif ($line -match "^C.*\:\s(?<Cli>.*)") {
            $CmdLine = $matches['Cli']
        } elseif ($line -match "^F.*\:\s(?<Fail1>.*)") {
            $FailAction1 = $matches['Fail1']
            $FailAction2 = $FailAction3 = $False
        } elseif ($line -match "^(?<FailNext>REST.*)") {
            if ($FailAction2) {
                $FailAction3 = $matches['FailNext']
            } else {
                $FailAction2 = $matches['FailNext']
            }
        }
    }
    ($ServiceName,$RstPeriod,$RebootMsg,$CmdLine,$FailAction1,$FailAction2,$FailAction3) -replace "False", $null -join $Delimiter
}
. .\mal-seine-common.ps1

Convert-Main -FileNamePattern $FileNamePattern -Delimiter $Delimiter -tofile $tofile