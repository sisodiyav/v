﻿$mbx = Read-Host "please enter the email address of the mailbox being migrated" 
 
$i=0
 
Do {
    $stats = Get-MoveRequestStatistics $mbx
    $data = $($stats.BytesTransferred.ToString().Split("(")[0].trim())
    $datapm = $($stats.BytesTransferredPerMinute.ToString().Split("(")[0].trim())
 
    Write-Progress -Activity "Move Request: $mbx" -Status $("Completed: $($stats.PercentComplete)%" + " | Status: $($stats.StatusDetail.value)" + " | Data xfered: " + $data + " | Data xfered/min: " + $datapm)  -PercentComplete $($stats.PercentComplete)
    Start-Sleep 10
    $i++
    
    If ($i -eq 360) {
        write-output "Operation timed out due to long running MoveRequest. Please Check MoveRequest Report"
        break
    }
 
    If ($($stats.StatusDetail.value) -eq "AutoSuspended") {
        write-output $("Delta for " + $mbx + " has completed and AutoSuspended")
        break
    }
}
until ($($stats.PercentComplete) -eq 100)
 
