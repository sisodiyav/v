$AutoService = Get-WmiObject -Class win32_service -Filter "StartMode = 'Auto'"
$AutoService | Export-Csv -NoTypeInformation -Path "d:\temp\AutoServices.csv"

 

# Run on server after patched

 

$DisabledService = Get-WmiObject -Class win32_service -Filter "StartMode = 'Auto'"

 

# compare

 

$AutoService = Import-Csv -Path "d:\temp\AutoServices.csv"

 

$services = (Compare-Object $AutoService.name $DisabledService.name).inputobject