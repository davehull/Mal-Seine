<#
.SYNOPSIS
A placeholder for a script to turn BITS transfer data to separated values format suitable for analysis.
.NOTES
$data = Import-Clixml .\LUHAD_bitsxfer.xml
$($data | % { $_; $_.FileList|% {$_}}) | fl *
#>
