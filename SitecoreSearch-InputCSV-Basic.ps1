[CmdletBinding()]
param (
    [Parameter(Mandatory=$True)]
    [string]$InputFile,
    [string]$Delimiter = ',',
    [int]$Columns = '99',
    [Parameter(Mandatory)]
    [ValidateSet('OneWay', 'TwoWay','Replacement')]
    [string]$Type = 'OneWay'
)

$ErrorActionPreference = 'Stop'

$Header = [String[]]@(1..$Columns | % { "col$_" })

$ImportedData = Import-Csv -Path $InputFile -Delimiter $Delimiter -Header $Header

$Result = @{}
$ImportedData | % {
    $Keyword = $_.col1.ToLower().Trim()
    $Value = @{
        'OneWay' = @()
        'TwoWay' = @()
        'Replacement' = $Null
    }
    if ($Type -ieq 'oneway') {
        $Value['OneWay'] = @($_.PSObject.Properties | Select-Object -Skip 1 | Where-Object { ![String]::IsNullOrWhiteSpace($_.Value) } | % { $_.Value.Trim().ToLower() } | Get-Unique)
    }
    if ($Type -ieq 'twoway') {
        $Value['TwoWay'] = @($_.PSObject.Properties | Select-Object -Skip 1 | Where-Object { ![String]::IsNullOrWhiteSpace($_.Value) } | % { $_.Value.Trim().ToLower() } | Get-Unique)
    }
    if (($Type -ieq 'replacement') -and (![String]::IsNullOrWhiteSpace(($_.col2)))) {
        $Value['Replacement'] = $_.col2.Trim().ToLower()
    }

    if ($Value['OneWay'].Count -eq 0 -and $Value['TwoWay'].Count -eq 0 -and $Null -eq $Value['Replacement']) {
        Write-Error ('Synonym must have at least 1 value for keyword: {0}' -f $Keyword)
    }

    $Result.Add($Keyword, $Value)
}

Write-Output $Result
