
Param(
    [Parameter(ParameterSetName='One')]
    [Switch]$Days,
    [Parameter(ParameterSetName='One',Mandatory=$true)]
    [ValidateRange(1,10)]
    [int]$DayRange,
    [Parameter(ParameterSetName='Two')]
    [Switch]$Hours,
    [Parameter(ParameterSetName='Two',Mandatory=$true)]
    [ValidateRange(1,24)]
    [int]$HourRange,
    [Parameter(ParameterSetName='Three')]
    [Switch]$Minutes,
    [Parameter(ParameterSetName='Three',Mandatory=$true)]
    [ValidateRange(1,60)]
    [Int]$MinuteRange,
    [Parameter(ParameterSetName='Four')]
    [DateTime]$StartTime,
    [Parameter(ParameterSetName='Four',Mandatory=$true)]
    [DateTime]$EndTime,
    [Parameter(ParameterSetName='Five')]
    [String]$Sender,
    [Parameter(ParameterSetName='Five',Mandatory=$true)]
    [String]$Recipient,
    [Parameter(ParameterSetName='Six')]
    [String]$MessageId,
    [Switch]$ShowOnlyPositives
)


##############################################

# Get SPAM

if ($Days.IsPresent) {

    $spam = Get-MessageTrace -Status FilteredAsSpam -StartDate $(Get-Date).AddDays(-$($DayRange)) -EndDate $(Get-Date) -pagesize 5000
}

if ($Hours.IsPresent) {

    $spam = Get-MessageTrace -Status FilteredAsSpam -StartDate $(Get-Date).AddHours(-$($HourRange)) -EndDate $(Get-Date) -pagesize 5000
}

if ($Minutes.IsPresent) {

    $spam = Get-MessageTrace -Status FilteredAsSpam -StartDate $(Get-Date).AddMinutes(-$($MinuteRange)) -EndDate $(Get-Date) -pagesize 5000
}

if ($StartTime) {

    $spam = Get-MessageTrace -Status FilteredAsSpam -StartDate $($startTime.ToUniversalTime()) -EndDate $($endTime.ToUniversalTime()) -pagesize 5000
}

if ($Sender) {

    $spam = Get-MessageTrace -SenderAddress $Sender -RecipientAddress $Recipient -Status FilteredAsSpam -StartDate $(Get-Date).AddDays(-10) -EndDate $(Get-Date) -pagesize 5000
}

if ($MessageID) {

    $spam = Get-MessageTrace -MessageId $MessageId -Status FilteredAsSpam -StartDate $(Get-Date).AddDays(-10) -EndDate $(Get-Date) -pagesize 5000
}



################################################

# Process all the found SPAM

if ($spam) {

    $count = $spam.count

    # Powershell COUNT method can't produce a value for 0 or 1

    if (!$count) {[int]$count = 1}

    # Check Block Sender Lists

    $obj = [PSCustomObject]@{

        Received          = ''
        SenderAddress     = ''
        RecipientAddress  = ''
        Subject           = ''
        Reason            = ''
        MessageID         = ''
    }

    # arrays

    $spams = @()

    # Start Processing the found Spams Folder

        
    for ($i=0; $i -lt $count; $i++) {

        $rule = "NO JunkEmailConfiguration or InboxRule Found"

        # write Progress

        Write-Progress -Activity "Searching SPAM Found" -Status "$i out of $count Complete:" -PercentComplete $($i/$count * 100)

        # Check Junk Mail Configuration

        $catch = (Get-MailboxJunkEmailConfiguration $spam[$i].recipientaddress).BlockedSendersAndDomains | ? {$_ -match $spam[$i].senderaddress}

        if ($catch) {

            $rule = "MailboxJunkEmailConfiguration"
        }
        else {

            # Check Inbox Rules

            $rules = Get-InboxRule -Mailbox $spam[$i].recipientaddress -warningaction "SilentlyContinue"

            ForEach ($r in $rules) {

                if ($r.FromAddressContainsWords -match $spam[$i].senderaddress -and $r.MoveToFolder -match "Junk Email") {

                    # Do nothing
                }
                else {

                    $rule = "InboxRule:FromAddressContainsWords"
                }
                
                if ($r.From -match $spam[$i].senderaddress -and $r.MoveToFolder -match "Junk Email") {

                    # Do nothing
                }
                else {

                    $rule = "InboxRule:From"
                }
            }
        }

        # Convert Received time from UTC to Eastern

        $EOS = (Get-TimeZone "Eastern Standard Time").BaseUtcOffset.totalhours

        $local = $spam[$i].Received.AddHours($EOS)
        $NewDate = $local.ToShortDateString() + " " + $local.TolongTimeString()

        # Build new output array

        $new = $obj.psobject.copy()

        $new.Received = $NewDate
        $new.MessageID = $spam[$i].messageid
        $new.SenderAddress = $spam[$i].senderaddress
        $new.RecipientAddress = $spam[$i].recipientaddress
        $new.Subject = $spam[$i].subject
        $new.Reason = $rule

        $spams += $new

        $hits = $spams | ? {$_.Reason -eq "NO JunkEmailConfiguration or InboxRule Found"}
    }
}



################################################

# Output

# Show Only Positives?

if ($ShowOnlyPositives.IsPresent) {

    $real = $hits
}

# Write Information

# Set File and Path parameters

If ($spams) {

    $filename = $(Get-Date -Format dd-MM-yyyy_HHmm) + "_SpamReport.csv"
    $path = "$env:temp\$filename"
}

# if spam but no real issues
# else if there are spams and real issues were caught
# else nothing was detected at all

if ($spams -and !$real) {

    $spams | Export-Csv -NoTypeInformation -Path $path
    Invoke-Item -Path $path

    $spams

    # Send-MailMessage
}
elseif ($spams -and $real) {

    $real | Export-Csv -NoTypeInformation -Path $path
    Invoke-Item -Path $path

    $real

    # Send-MailMessage
}
else {

    # Send-MailMessage
}

# Write-Host all good

if (!$hits) {

    Write-Host "No Legitamate SPAM was detected!" -for Green
}