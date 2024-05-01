# Welcome to the Synonym Importer for Sitecore Search!

Need to import a bunch of synonyms into the Sitecore Search CEC? Let's take care of that!

## Why do you need this?
The Sitecore Search CEC doesn't support bulk importing of synonyms. Typing them by hand is *super boring*.

Perhaps you want to maintain a master list in source control and automate the synonym deployment.

![image](https://github.com/nevnet/SitecoreSearch-SynonymImport/assets/8563228/6430886c-2790-4a40-97bd-e41eacd72350 "There is no import button")
> Look! There is no 'import' button in the Sitecore Search CEC. Maybe it is a phase 2 feature?

You CAN export synonyms in the Sitecore Search CEC. This script supports using the same exported CSV file format so you can easily download, modify, then re-import your synonyms.

## What you need to get started

- Basic knowledge of PowerShell. Some snippets are provided here for you to cut 'n' paste.
- A CSV file in one of the supported file formats. You can also manually craft a Hashtable and pass it to the script.
- An API authorization token from a logged in Sitecore Search CEC user session.
- The Domain ID of the Sitecore Search account you want to import your synonyms into.

## Show me how!

Log in to the Sitecore Search CEC using your credentials and grab your **Domain ID** and your **authorization token**.

Your Domain ID is available from the account selector in the top nav or the URL.

![image](https://github.com/nevnet/SitecoreSearch-SynonymImport/assets/8563228/fbe88aac-a218-49b7-bf73-0bf9f495fcd3)

Your authorization token is a little bit harder to find and it is NOT the same API token that you use the call the search or ingestion API. The CEC content is served from the host name *cec.sitecorecloud.io*, but it calls some APIs with the host name *discover.sitecorecloud.io*. Use your dev tools to find an API request to *discover.sitecorecloud.io* while browsing the CEC and grab your authorization token from the Authorization header. You don't need the 'bearer' prefix, the script will add that for you.

![image](https://github.com/nevnet/SitecoreSearch-SynonymImport/assets/8563228/18555efa-fc39-4309-b4aa-140ffdbd98ab)
> You don't need the 'bearer' prefix, just the token string.

> **Note:** Your token is only valid for a limited period of time. If you get authorization errors while running the script then you need to log in to the Sitecore Search CEC and get another token.

Next, get your synonyms into a format the import script understands. There are two utility scripts included to do this for you: **SitecoreSearch-InputCSV-Advanced.ps1** and **SitecoreSearch-InputCSV-Basic.ps1**. These scripts will take a CSV file and output a variable in the appropriate format.

If you're not sure which script to run, take a look at the example CSV files (**synonyms-advanced.csv** and **synonyms-basic.csv**). Make sure your CSV file matches one of them.

> **Note:** The *SitecoreSearch-InputCSV-Advanced.ps1* script supports the same file format that the Sitecore Search CEC uses to export synonyms. This format allows creating all types of synonyms in a single file (One-way, Two-way and Replacement synonyms). The *SitecoreSearch-InputCSV-Basic.ps1* script supports a single type of synonym and is more likely what you'll get if you export your synonyms from a different system.

These snippets assume you're running in a PowerShell console and all files are in the current working directory:

```powershell
# For the advanced CSV file format, specify the path to the CSV file
$data = ./SitecoreSearch-InputCSV-Advanced.ps1 -InputFile 'synonyms-advanced.csv'

# For the basic CSV file format, optionally specify the type of synonyms the file contains. 'OneWay' is the default if not specified.
$data = ./SitecoreSearch-InputCSV-Basic.ps1 -InputFile 'synonyms-basic.csv' -Type [OneWay|TwoWay|Replacement]
```

When your CSV file has been parsed correctly the $data variable contains a Hashtable that you can inspect:

![image](https://github.com/nevnet/SitecoreSearch-SynonymImport/assets/8563228/a2e00ed9-b591-4f8d-988b-a2fd5ec4e1e2)

Execute the import script by passing your $data variable, Domain ID, authorization token and a few control flags:

```powershell
# Pipe your $data variable to the import script
$data | ./SitecoreSearch-UpsertSynonyms.ps1 -Add -Update -Delete -DomainId '[Your domain ID]' -BearerToken '[Your token]'

#... or just pass it as a regular parameter
./SitecoreSearch-UpsertSynonyms.ps1 -Data $data -Add -Update -Delete -DomainId '[Your domain ID]' -BearerToken '[Your token]'
````

## Control flags
|||
|--|--|
|**-Add**|Synonyms that EXIST in your CSV file and DO NOT EXIST in Sitecore Search will be added.|
|**-Update**|Synonyms that EXIST in your CSV file and EXIST in Sitecore Search will be updated.|
|**-Delete**|Synonyms that DO NOT EXIST in your CSV file and EXIST in Sitecore Search will be deleted.|

> **Note:** If you plan on using your CSV file as the master list of synonyms you will always want to choose -Add, -Update and -Delete.

Combine the control flags to meet your requirements. If you don't provide any of the control flags, the script will not import any synonyms.

## Final thoughts

- For more detailed output, you can add the -Verbose parameter to the script.
- This script is not doing anything you couldn't do yourself via the Sitecore Search CEC. It simply coordinates all the required API calls to fetch, update and delete the synonyms in your account.
- The script does not perform the final 'Publish' operation. All synonyms that were touched during the import (including deleted ones) will be in a draft state. You must click 'Publish' in the CEC for the changes to be applied and a reindex may be required before the changes take effect.
- The utility scripts will do their best to remove duplicates, special characters and trim white-space.
- There are some additional input parameters not documented here. For example, if your delimiter is a character other than a comma, you can change that with **-Delimiter**. If your CSV file has no header row, then consider using **-NoHeaders**.
- To manually craft your own input variable, the syntax is pretty simple. You need a hastable of hashtables similar to the following:
```powershell
@{
  'keyword1' = @{
    'OneWay' = @('synonym1','synonym2')
    'TwoWay' = @('synonym3','synonym4')
  }
  'kewyord2' = @{
    'Replacement' = 'synonym5'
  }
}
```
- If a keyword has all 3 types defined, then only 'Replacement' will be honored. OneWay and TwoWay synonyms are string arrays, while Replacement synonyms are just a single string.