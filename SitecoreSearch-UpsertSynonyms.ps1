[CmdletBinding()]
param (
    [Parameter(Mandatory=$True)]
    [String]$DomainId,
    [Parameter(Mandatory=$True)]
    [String]$BearerToken,
    [Parameter(ValueFromPipeline = $True)]
    [Hashtable]$Data,
    [Switch]$Add = $False,
    [Switch]$Update = $False,
    [Switch]$Delete = $False
)

$ErrorActionPreference = 'Stop'

Set-Variable UrlPrefix -option Constant -value ([String]'https://discover.sitecorecloud.io/portal/{0}/v1/microservices/common-editor/global/resources/keywords')

$Execute = {

    # Get synonyms from Sitecore Search
    $Synonyms = Get-Synonyms

    # Generate manifest of operations
    $Manifest = Generate-Manifest($Synonyms)

    # Process manifest
    Process-Manifest($Manifest)

}

function Generate-Manifest {
    param (
        [Parameter(Mandatory=$True)]
        [Hashtable]$Synonyms
    )

    $Manifest = @()
    foreach ($Row in $Data.GetEnumerator()) {
        $Existing = $Synonyms[$row.Name]
        if ($Null -eq $Existing -and $Add) {
            $Manifest += [PSCustomObject]@{
                Action = 'ADD'
                Keyword = $Row.Name
                OneWay = $Row.Value.OneWay
                TwoWay = $Row.Value.TwoWay
                Replacement = $Row.Value.Replacement
            }
        }
        if ($Null -ne $Existing -and $Update) {
            $Version = $Existing.version
            if($Existing.status -ieq 'live') {
                $Version = $Version + 1
            }
            $Manifest += [PSCustomObject]@{
                Action = 'UPDATE'
                KeywordId = $Existing.keywordId
                Keyword = $Row.Name
                Version = $Version
                OneWay = $Row.Value.OneWay
                TwoWay = $Row.Value.TwoWay
                Replacement = $Row.Value.Replacement
            }
        }
    }

    foreach ($Row in $Synonyms.Values) {
        $Existing = $Data[$row.name]
        if ($Null -eq $Existing -and $Delete) {
            $Version = $Row.version
            if($Row.status -ieq 'live') {
                $Version = $Version + 1
            }
            $Manifest += [PSCustomObject]@{
                Action = 'DELETE'
                KeywordId = $Row.keywordId
                Keyword = $Row.name
                Version = $Version
            }
        }
    }

    Write-Verbose 'Manifest:'
    Write-Verbose ($Manifest | ConvertTo-Json)

    Write-Output $Manifest
}

function Process-Manifest {
    param (
        [Parameter(Mandatory=$True)]
        [PSCustomObject[]]$Manifest
    )

    foreach ($Row in $Manifest) {
        if ($Row.Action -eq 'ADD') {
            Add-Synonym -Keyword $Row.Keyword -OneWay $Row.OneWay -TwoWay $Row.TwoWay -Replacement $Row.Replacement
        }
        if ($Row.Action -eq 'UPDATE') {
            Update-Synonym -KeywordId $Row.KeywordId -Keyword $Row.Keyword -Version $Row.Version -OneWay $Row.OneWay -TwoWay $Row.TwoWay -Replacement $Row.Replacement
        }
        if ($Row.Action -eq 'DELETE') {
            Delete-Synonym -KeywordId $Row.KeywordId -Keyword $Row.Keyword -Version $Row.Version
        }
        Write-Output $Row
    }
}

function Get-Synonyms {
    $Request = @{
        Uri =  $UrlPrefix -f $DomainId
        Headers = @{
            'Authorization' = 'Bearer {0}' -f $BearerToken
        }
        Method = 'GET'
        ContentType = 'application/json'
    }

    $Output = @{}
    Write-Progress ("Fetching existing synonyms: {0}" -f $Request.Uri)
    Write-Verbose ($Request | ConvertTo-Json)
    $Result = Invoke-RestMethod @Request
    Write-Verbose ($Result | ConvertTo-Json)

    $Result.keywords | % {
        Write-Verbose ("Adding keyword '{0}' to synonym lookup" -f $_.name)
        $Output.Add($_.name, $_)
    }

    Write-Output $Output
}

function Add-Synonym {
    param (
        [Parameter(Mandatory=$True)]
        [string]$Keyword,
        [string[]]$OneWay,
        [string[]]$TwoWay,
        [string]$Replacement
    )

    $Body = @{
        'name' = $Keyword
    }
    if($Replacement) {
        $Body['replacement'] = $Replacement
    }
    else {
        $Body['oneWaySynonyms'] = $OneWay
        $Body['twoWaySynonyms'] = $TwoWay
    }

    $Request = @{
        Uri = $UrlPrefix -f $DomainId
        Headers = @{
            'Authorization' = 'Bearer {0}' -f $BearerToken
        }
        Method = 'POST'
        ContentType = 'application/json'
        Body = $Body | ConvertTo-Json -Compress
    }

    Write-Progress ("Adding new synonym: {0}" -f $Keyword)
    Write-Verbose ($Request | ConvertTo-Json)
    $Output = Invoke-RestMethod @Request
    Write-Verbose ($Output | ConvertTo-Json)
}

function Update-Synonym {
    param (
        [Parameter(Mandatory=$True)]
        [string]$KeywordId,
        [Parameter(Mandatory=$True)]
        [string]$Keyword,
        [Parameter(Mandatory=$True)]
        [int]$Version,
        [string[]]$OneWay,
        [string[]]$TwoWay,
        [string]$Replacement
    )

    $Body = @{
        'name' = $Keyword
        'version' = $Version
    }
    if($Replacement) {
        $Body['replacement'] = $Replacement
    }
    else {
        $Body['oneWaySynonyms'] = $OneWay
        $Body['twoWaySynonyms'] = $TwoWay
    }

    
    $Request = @{
        Uri = "$UrlPrefix/{1}" -f $DomainId, $KeywordId
        Headers = @{
            'Authorization' = 'Bearer {0}' -f $BearerToken
        }
        Method = 'PUT'
        ContentType = 'application/json'
        Body = $Body | ConvertTo-Json -Compress
    }

    Write-Progress ("Updating existing synonym: {0} ({1})" -f $Keyword, $KeywordId)
    Write-Verbose ($Request | ConvertTo-Json)
    $Output = Invoke-RestMethod @Request
    Write-Verbose ($Output | ConvertTo-Json)
}

function Delete-Synonym {
    param (
        [Parameter(Mandatory=$True)]
        [string]$KeywordId,
        [Parameter(Mandatory=$True)]
        [string]$Keyword,
        [Parameter(Mandatory=$True)]
        [int]$Version
    )

    $Body = @{
        'version' = $Version
    }

    $Request = @{
        Uri = "$UrlPrefix/{1}" -f $DomainId, $KeywordId
        Headers = @{
            'Authorization' = 'Bearer {0}' -f $BearerToken
        }
        Method = 'DELETE'
        ContentType = 'application/json'
        Body = $Body | ConvertTo-Json -Compress
    }

    Write-Progress ("Deleting existing synonym: {0} ({1})" -f $Keyword, $KeywordId)
    Write-Verbose ($Request | ConvertTo-Json)
    $Output = Invoke-RestMethod @Request
    Write-Verbose ($Output | ConvertTo-Json)
}

& $Execute
