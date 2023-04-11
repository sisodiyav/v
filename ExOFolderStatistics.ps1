Get-MailboxFolderStatistics -Id "x@xyz.com" | select name, FolderPath,FolderSize,ItemsInFolder | Sort-Object ItemsInFolder | export-csv C:\Users\x\AppData\Local\Temp\FolderSize2.csv

#get-moverequest x@xyz.com | Get-MoveRequestStatistics -IncludeReport | fl
