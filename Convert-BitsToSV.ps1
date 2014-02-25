<#
.SYNOPSIS
Convert-BitsXfersToSV.ps1 takes the output from Get-HostData.ps1's Bits Transfer 
collection and parses the FileList data into delimited format suitable for stack 
ranking via get-stakrank.ps1.

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
    $RemoteName = $Localname = $IsTransferComplete = $BytesTotal = $BytesTransferrred = $False
    $data = Import-Clixml $File
    $data | % { $_.FileList } | ConvertTo-Csv -NoTypeInformation -Delimiter $Delimiter
}

. .\mal-seine-common.ps1

Convert-Main -FileNamePattern $FileNamePattern -Delimiter $Delimiter -tofile $tofile
