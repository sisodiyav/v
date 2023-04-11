
# a simple function 

Function Get-xMailbox {

    Param (
        [string]$mbx,
        [string]$something
    )

    Get-Mailbox $mbx
    Get-EXOMailboxStatistics $mbx
}

# example of combining commands into one output

Function Get-AmitsMailbox2 {

    Param (
        [array]$mbxes
    )

    #creating empty array

    $arr = @()

    foreach ($m in $mbxes) {

        # Get multiple variables from various commands

        $mb = Get-Mailbox $m
        $mbs = Get-MailboxStatistics $m

        # create new PS Object

        $obj = New-Object PSObject

        # fill out the object

        $obj | Add-Member -Name "DisplayName" -Value $mb.displayname -MemberType NoteProperty
        $obj | Add-Member -Name "Email" -Value $mb.primarysmtpaddress -MemberType NoteProperty
        $obj | Add-Member -Name "TotalItemSize" -Value $mbs.totalitemsize.value -MemberType NoteProperty

        # add object to the array

        $arr += $obj
    }

    $arr
}


$mbx1 = Read-Host "Please give me the first email"
$mbx2 = Read-Host "Please give me the second email"

Get-xMailbox -mbx $mbx1
Get-xMailbox -mbx $mbx2

Get-xMailbox2 -mbxes $mbx1, $mbx2