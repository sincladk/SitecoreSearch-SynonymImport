[CmdletBinding()]
param (
    [Parameter(Mandatory=$True)]
    [string]$InputFile,
    [string]$Delimiter = ',',
    [string[]]$Header = @('Keyword','One-Way Synonyms','Two-Way Synonyms','Replacement','Last Modified','Modified By'),
    [switch]$NoHeaders
)

$ErrorActionPreference = 'Stop'

$Params = @{
    Path = $InputFile
    Delimiter = $Delimiter
}
if ($NoHeaders) {
    $Params.Add('Header', $Header)
}

$ImportedData = Import-Csv @Params

$Result = @{}
$ImportedData | % {
    $Keyword = $_.Keyword.ToLower().Trim()
    $Value = @{
        'OneWay' = "$($_.'One-Way Synonyms')".Trim().ToLower().Replace("$Delimiter ",$Delimiter).Split($Delimiter,[System.StringSplitOptions]::RemoveEmptyEntries) | Get-Unique
        'TwoWay' = "$($_.'Two-Way Synonyms')".Trim().ToLower().Replace("$Delimiter ",$Delimiter).Split($Delimiter,[System.StringSplitOptions]::RemoveEmptyEntries) | Get-Unique
        'Replacement' = $_.'Replacement'
    }
    $Result.Add($Keyword, $Value)
}

Write-Output $Result
