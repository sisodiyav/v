#
#converts folder ID into a format usable by ediscovery
#

Function Process-Stats {

    param (

        $stats,
        $val
    )

    foreach ($mbxa in $stats) {

        $this = (Compare-Object $paths.FolderPath $mbxa.FolderPath -IncludeEqual | ? {$_.SideIndicator -eq "=="}).inputobject

        if ($this) {

            Add-Member -InputObject $mbxa -MemberType NoteProperty -Name "Location" -Value "$val"
            $mbxa
        }
    }
}

# Instructions

Write-host "Make sure you mave stored a CSV in a proper location that stores the FolderPaths requested in the ticket with the column name FolderPath. You will be asked for this to continue. The script will fail without it." -ForegroundColor Yellow
Write-Host "`nNOTE: The new .CSV export will be saved in the exact same location with today's date and the alias of the user (minus any periods)" -ForegroundColor Yellow
Write-Host "NOTE: Please do not put any quotes arount the file path, even if the file path has spaces. By default the Read-Host does this by default and doing so will break the command!" -ForegroundColor Yellow
Write-Host "NOTE: Make sure to select 'KQL Editor when copying the FolderId Field from the CSV into Content Search" -ForegroundColor Yellow
Write-Host "`nPress any key to continue...`n"

# Press any Key to Continue command

$null = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown')

# Collecting User input

$mbx = Read-Host "Enter email address"
$FolderPaths = Read-Host "Enter the location of the CSV for the FolderPaths. Please remember. No Quotes!"

# Processing Mailbox Folder Stats

Write-Host "Collecting all Primary Mailbox Folder Statistics..." -ForegroundColor Yellow
$mbxStatistics = Get-MailboxFolderStatistics -Identity $mbx 

Write-Host "Collecting all Archive Mailbox Folder Statistics..." -ForegroundColor Yellow
$mbxStatistics2 = Get-MailboxFolderStatistics -Identity $mbx -Archive 

# Import pre-defined list of FolderPaths

$paths = Import-Csv -Path $FolderPaths

# Comparing Input CSV to Mailbox Folder Stats

Write-Host "Processing Data..." -ForegroundColor Yellow

$found = @()
$found += Process-Stats -stats $mbxStatistics -val "Mailbox"
$found += Process-Stats -stats $mbxStatistics2 -val "Archive"

# Convert Comparison output FolderIDs to ASCII FolderIDs

$folderQueries2 = @()

foreach ($stat in $found) {

    $encoding = [System.Text.Encoding]::GetEncoding("us-ascii")
    $nibbler = $encoding.GetBytes("0123456789ABCDEF");
    $indexIdBytes = New-Object byte[] 48;
    $folderIdBytes = [Convert]::FromBase64String($stat.FolderId)
    $indexIdIdx = 0
    $folderIdBytes | select -Skip 23 -First 24 | %{$indexIdBytes[$indexIdIdx++] = $nibbler[$_ -shr 4]; $indexIdBytes[$indexIdIdx++] = $nibbler[$_ -band 0xF]}
    $folderIdConverted = $($encoding.GetString($indexIdBytes))

    # This is where we add each object to the array

    $folderDetails = New-Object PSObject

    Add-Member -InputObject $folderDetails -MemberType NoteProperty -Name FolderPath -Value $stat.FolderPath
    Add-Member -InputObject $folderDetails -MemberType NoteProperty -Name Location -Value $stat.Location
    Add-Member -InputObject $folderDetails -MemberType NoteProperty -Name ItemsinFolder -Value $stat.ItemsInFolder
    Add-Member -InputObject $folderDetails -MemberType NoteProperty -Name FolderIdOld -Value $stat.folderid
    Add-Member -InputObject $folderDetails -MemberType NoteProperty -Name FolderIdNew -Value $folderIdConverted
    
    $folderQueries2 += $folderDetails
}

$folderqueries = $folderQueries2 | select folderpath, location, itemsinfolder, folderidold, @{name="Folderidnew";Expression={$('folderid="' + $_.FolderIdNew + '"')}}

# Create new name for file

$date = Get-Date -Format "yyyy-mm-dd_HH-mm-ss"
$name = $($date + "_" + $mbx.split("@")[0].Replace(".","") + ".csv")

# Get former file path

$NewPath = $FolderPaths.replace("\","\`n")
$NewPath = $NewPath.split("`n")
$del = $NewPath | select -Last 1
$NewPath = $NewPath | ? {$_ -notmatch $del}
[string]$NewPath = $NewPath -join ''
$NewPath = $($NewPath + $name)

# Export to former path

$folderqueries | export-csv -path $NewPath -NoTypeInformation

# Show in console

$folderqueries

<#
    $encoding = [System.Text.Encoding]::GetEncoding("us-ascii")
    $nibbler = $encoding.GetBytes("0123456789ABCDEF");
    $indexIdBytes = New-Object byte[] 48;
    $folderIdBytes = [Convert]::FromBase64String($FolderId)
    $indexIdIdx = 0
    $folderIdBytes | select -Skip 23 -First 24 | %{$indexIdBytes[$indexIdIdx++] = $nibbler[$_ -shr 4]; $indexIdBytes[$indexIdIdx++] = $nibbler[$_ -band 0xF]}
    $folderIdConverted = $($encoding.GetString($indexIdBytes))
#>