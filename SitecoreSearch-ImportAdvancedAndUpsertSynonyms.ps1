[CmdletBinding()]
param (
    [Parameter(Mandatory=$True)]
    [String]$DomainId,
    [Parameter(Mandatory=$True)]
    [String]$BearerToken,
    [Parameter(Mandatory=$True)]
    [string]$InputFile,
    [Switch]$Add = $False,
    [Switch]$Update = $False,
    [Switch]$Delete = $False
)

$ErrorActionPreference = 'Stop';

$data = & "$PSScriptRoot\SitecoreSearch-InputCSV-Advanced.ps1" -InputFile $InputFile;

if (-not $data) {
    throw [Exception]::new("Couldn't get data from $InputFile");
}

& "$PSScriptRoot\SitecoreSearch-UpsertSynonyms.ps1" -Data $data -Add $Add -Update $Update -Delete $Delete -DomainId $DomainId -BearerToken $BearerToken;
