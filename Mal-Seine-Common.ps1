<#
.SYNOPSIS
Common functions used by more than one of the Mal-Seine scripts.
#>

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

function Convert-Main {
<#
.SYNOPSIS
Main function that drives multiple conversion scripts.
#>
Param(
    [Parameter(Mandatory=$True,Position=0)]
        [string]$FileNamePattern,
    [Parameter(Mandatory=$True,Position=1)]
        [char]$Delimiter,
    [Parameter(Mandatory=$True,Position=2)]
        [boolean]$tofile=$False
)

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
}
