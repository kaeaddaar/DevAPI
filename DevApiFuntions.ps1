    
#Install-Module AzureAutomationAuthoringToolkit -Scope AllUsers    
#Fancy line of code used by azure automation ISE add-on
#$RunAsConnection = Get-AutomationConnection -Name AzureRunAsConnection;try {$Login=Add-AzureRmAccount -ServicePrincipal -TenantId $RunAsConnection.TenantId -ApplicationId $RunAsConnection.ApplicationId -CertificateThumbprint $RunAsConnection.CertificateThumbprint -ErrorAction Stop}catch{Sleep 10;$Login=Add-AzureRmAccount -ServicePrincipal -TenantId $RunAsConnection.TenantId -ApplicationId $RunAsConnection.ApplicationId -CertificateThumbprint $RunAsConnection.CertificateThumbprint};Select-AzureRmSubscription -SubscriptionId $RunAsConnection.SubscriptionID
# ----- starting -----
Import-Module .\Create-Vm.psm1
Get-Command -Module Create-Vm

# ----- load Other variables ----- start
$HKeys = New-Object System.Collections.ArrayList
$Sleep = 2
$PublicIp = New-Object Microsoft.Azure.Commands.Network.Models.PSPublicIpAddress
# ----- load Other variables ----- end


# ----- Load Variables ----- start
<#
.Synopsis
   Get a hash table from a JSON settings file
.DESCRIPTION
   Get a hash table from a JSON settings file. If you pass in the $Hash parameter it will add that hash to the settings hash making a combined has.
.EXAMPLE
$Hash = @{"var1"="val1"; "var2"="Val2"}
$H1 = get-HashFromJson -Hash $Hash -SettingsPath .\Settings_Environment.json
$H1 = get-HashFromJson -Hash $H1 -SettingsPath .\Settings.json
$H1

# Results:
Name                           Value                                                                                                                                                                                                     
----                           -----                                                                                                                                                                                                     
DataDisk.DiskSizeInGb          20                                                                                                                                                                                                        
var2                           Val2                                                                                                                                                                                                      
OsDisk.Uri                                                                                                                                                                                                                               
Image.Skus                     2016-Datacenter                                                                                                                                                                                           
TestNum                        3                                                                                                                                                                                                         
Image.PublisherName            MicrosoftWindowsServer                                                                                                                                                                                    
Image.Version                  latest                                                                                                                                                                                                    
RootName                       DevApi                                                                                                                                                                                                    
ResourceGroup.RootName         System5API                                                                                                                                                                                                
var1                           val1                                                                                                                                                                                                      
Image.Offer                    WindowsServer                                                                                                                                                                                             
Storage.SkuName                Premium_LRS                                                                                                                                                                                               
DataDisk.Caching               None                                                                                                                                                                                                      
SubscriptionName1              VSE MPN                                                                                                                                                                                                   
DataDisk.Lun                   0                                                                                                                                                                                                         
VmSize                         Standard_F2s                                                                                                                                                                                              
SubscriptionName2              Windward Software - Platform Credit                                                                                                                                                                       
Location                       westus2                                                                                                                                                                                                   
Subnet.AddressPrefix           10.0.0.0/24                                                                                                                                                                                               
SubscriptionName               VSE MPN                                                                                                                                                                                                   

# Notice that Var1, and var2 from $Hash are loaded, as well as the SubscriptioName variables from .\Settings_Environment.json

#>


function get-HashFromJson ([hashtable]$Hash, [string]$SettingsPath = ".\Settings.json")
{
    $H = New-Object -TypeName hashtable
    if ($Hash -ne $null) { $Hash.Keys | % {$H.Add($_, $Hash.Item($_))} }

    $JSON = ConvertFrom-Json -InputObject (Get-Content -Path $SettingsPath -Raw)
    $JSON.psobject.Properties | % {$H.add($_.name, $_.Value)}

    if ($H -eq $null) # if we haven't loaded the hash table from a JSON settings file then use these defaults
    {
        $H.TestNum = "1"
        $H."ResourceGroup.RootName" = "System5Api"
        $H."RootName" = "DevApi"
        $H."Location" = "westus2"

        $H."VmSize" = "Standard_F2s"
        $H."Image.PublisherName" = "MicrosoftWindowsServer"
        $H."Image.Offer" = "WindowsServer"
        $H."Image.Skus" = "2016-Datacenter"
        $H."Image.Version" = "latest"
        $H."Subnet.AddressPrefix" = "10.0.0.0/24"
        $H."Storage.SkuName" = "Standard_LRS" #Premium_LRS
        $H."OsDisk.Uri" = "" # Set in code as it pulls info from $StorageAccount
        $H."DataDisk.DiskSizeInGb" = "20"
        $H."DataDisk.Lun" = "0"
        $H."DataDisk.Caching" = "None"
        $H."SubscriptionName" = "Windward Software - Platform Credit"
    }
    $H # return the hashtable
} # get-HashFromJson
# ----- Load Variables ----- end
    
# ----- declare variables from settings hash -----
$TestNum = $H.TestNum
$ResourceGroup_RootName = $H."ResourceGroup.RootName"
$RootName = $H."RootName"
$Location = $H."Location"

$VmSize = $H."VmSize"
$Image_PublisherName = $H.'Image.PublisherName'
$Image_Offer = $H.'Image.Offer'
$Image_Skus = $H.'Image.Skus'
$Image_Version = $H.'Image.Version'
$Subnet_AddressPrefix = $H.'Subnet.AddressPrefix'
$Storage_SkuName = $H.'Storage.SkuName'
$OsDisk_Uri = $H.'OsDisk.Uri'
$DataDisk_DiskSizeInGb = $H."DataDisk.DiskSizeInGb"
$DataDisk_Lun = $H."DataDisk.Lun"
$DataDisk_Caching = $H."DataDisk.Caching"
$SubscriptionName = $H."SubscriptionName"

# ----- load calculated variables ----- start
$ResourceGroup_Name = $ResourceGroup_RootName + $TestNum
$TrafficManagerEndpoint_Name = $RootName + $TestNum + "TmEndpoint"
$TrafficManager_Name = $RootName + $TestNum + "TrafficManager"
$TrafficManager_Name = $TrafficManager_Name.Replace("_","")

$VmName = $RootName + $TestNum
$ASetName = $RootName + $TestNum + "ASet"
$Subnet_Name = $RootName + $TestNum + "Subnet"
$VNetName = $RootName + $TestNum + "VNet"

$PublicIp_Name = $RootName + $TestNum + "PublicIp"
$PublicIp_Name = $PublicIp_Name.ToLower()
$Nic_Name = $RootName + $TestNum + "Nic"
$BlobPath = "vhds/" + $RootName + $TestNum + "OsDisk1.vhd"
$Storage_Name = $RootName + $TestNum + "StorageAcct"
$Storage_Name = $Storage_Name.ToLower()
$OsDisk_Name = $RootName + $TestNum + "OsDisk"
$VhdUri_Name = $RootName + $TestNum + "DataDisk1"
$VhdUri_Name = $VhdUri_Name.ToLower()
$VhdUri_BlobPath = "vhds/" + $RootName + $TestNum + "DataDisk1.vhd"
$Storage_Name_Data1 = $RootName + $TestNum + "datastorage"
$Storage_Name_Data1 = $Storage_Name.tolower() # Required to have in lower case
# ----- load calculated variables ----- end
    

# ----- Get Stuff Done (GSD) -----
if((Read-Host "Enter Y to Login") -eq "Y"){ Login-AzureRmAccount -SubscriptionName $SubscriptionName }

$RG =  Get-AzureRmResourceGroup | where {$_.ResourceGroupName -eq $ResourceGroup_Name} # Returns $null if it doesn't find the resource group
if ($RG -eq $null) { $RG = New-AzureRmResourceGroup -Name $ResourceGroup_Name -Location $Location } # if resource group doesn't exist make a new one

$ASet = Get-AzureRmAvailabilitySet -ResourceGroupName $ResourceGroup_Name | where {$_.Name -eq $ASetName} # Returns $null if availability set not found
if ($ASet -eq $null) {$ASet = New-AzureRmAvailabilitySet -ResourceGroupName $ResourceGroup_Name -Name $ASetName -Location $Location} # if availability doesn't exist make a new one

[Microsoft.Azure.Commands.Compute.Models.PSVirtualMachine]$VM = New-Object Microsoft.Azure.Commands.Compute.Models.PSVirtualMachine

if ($true) {write-host "Create-Vm"}
$VMR = create-vm -Verbose -Subnet $Subnet -VNet $VNet -PublicIp ([ref]$PublicIP) -Nic $Nic -Subnet_Name $Subnet_Name -VNet_Name $VNetName -Subnet_AddressPrefix $Subnet_AddressPrefix `
    -ResourceGroup_Name $ResourceGroup_Name -Location $Location -VmName $VmName -VmSize $VmSize -Nic_Name $Nic_Name -AutomationAccount_Name $AutomationAccount_Name `
    -OsDisk_Uri $OsDisk_Uri -OsDisk_Name $OsDisk_Name -VM $VM
#Catch {write-host "Create-Vm failed, breaking" +  $error[0].Exception + $error[0].FullyQualifiedErrorId; break}
    
# ----- Add a traffix manager (post vm creation) ----- start
# Traffic Manager
$VM = get-azurermvm -ResourceGroupName $ResourceGroup_Name -Name $VmName # Need the VM
$TrafficManagerProfile = Get-AzureRmTrafficManagerProfile | where {$_.Name -eq $TrafficManager_Name}
if($TrafficManagerProfile -eq $null){ $TrafficManagerProfile = New-AzureRmTrafficManagerProfile -Name $TrafficManager_Name -ResourceGroupName $ResourceGroup_Name `
    -ProfileStatus Enabled -RelativeDnsName $TrafficManager_Name -Ttl 30 -TrafficRoutingMethod Performance -MonitorProtocol HTTP -MonitorPath "/" -MonitorPort 80}
if ($TrafficManager_Name -ne $null)
{
    $PublicIp = Get-AzureRmPublicIpAddress -Name $PublicIp_Name -ResourceGroupName $ResourceGroup_Name
    New-AzureRmTrafficManagerEndpoint -Name $TrafficManagerEndpoint_Name -ProfileName $TrafficManager_Name -ResourceGroupName $ResourceGroup_Name `
        -Type AzureEndpoints -TargetResourceId $PublicIP.Id -EndpointStatus Enabled

    # Verify it exists
    Get-AzureRmTrafficManagerEndpoint -Name $TrafficManager_Name -ResourceGroupName $ResourceGroup_Name -Type AzureEndpoints -ProfileName $TrafficManager_Name # will error if it doesn't exist
}
# Attach the data disks
# ----- Add a traffix manager ----- end

# ----- Add data storage ----- start
$DataStorage = Get-AzureRmStorageAccount -ResourceGroupName $ResourceGroup_Name -Name $Storage_Name
if ($dataStorage -eq $null) { $DataStorage = New-AzureRmStorageAccount -ResourceGroupName $ResourceGroup_Name -SkuName "Premium_LRS" -Name $Storage_Name `
    -Location $Location -Kind Storage }

$VhdUri = $DataStorage.PrimaryEndpoints.Blob.ToString() + $VhdUri_BlobPath

Add-AzureRmVMDataDisk -VM $VM -Name $VhdUri_Name -VhdUri $VhdUri -CreateOption Empty -DiskSizeInGB $DataDisk_DiskSizeInGb -Lun $DataDisk_Lun -Caching $DataDisk_Caching
# the above worked, but I had lun and cashing parameters set, where previous attempts didn't have those set.
    
Update-AzureRmVM -VM $VM -ResourceGroupName $ResourceGroup_Name
# ----- Add data storage ----- end

