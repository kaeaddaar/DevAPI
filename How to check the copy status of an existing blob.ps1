login-azurermaccount

Import-Module C:\users\playi\Documents\GitHub\DevAPI\Functions-Common.ps1
Get-Command -Module functions-common
$S = "SubscriptionName"
get-cmValidOption -Arr (Get-AzureRmSubscription | select -ExpandProperty $S) -PropName $S -Default (Get-AzureRmSubscription | select -ExpandProperty $S)[0]

$SAName = "servicestorageprem"
$StorageKey = "6l/prezOZTOXGH1EK1b77vzt8olQjgOhpyp0LO6WCfs4wcqV+qppMZwuVJpi9ZxGrvo8rlbhkd5Q9bTN4dI12Q=="
$Context = New-AzureStorageContext -StorageAccountName $SAName -StorageAccountKey $StorageKey


$CloudBlob = Get-AzureStorageBlob -Container "vhds" -Blob "Sunday, March 19, 2017 3:33:50 PM, ServiceAppOsDisk1.vhd" -Context $Context
$Blob = Get-AzureStorageBlobCopyState -Context $Context -Blob "Sunday, March 19, 2017 3:33:50 PM, ServiceAppOsDisk1.vhd" -Container "vhds"

$Blob.Status -eq "Success"
2

