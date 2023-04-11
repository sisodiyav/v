$mbx = Read-Host "please enter the email address of the mailbox being migrated"

do{
      $stats = Get-MoverequestStatistics $mbx

send-mailmessage -From x@xyz.com -To x@xyz.com -Subject "$($user) $($stats.PercentComplete) % ExO move status" -SmtpServer 'smtp.xyz.com'

  start-sleep -Seconds 200

}until ($($stats.PercentComplete) -eq 100)

