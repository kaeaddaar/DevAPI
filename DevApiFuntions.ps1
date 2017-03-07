    
#Install-Module AzureAutomationAuthoringToolkit -Scope AllUsers    
#Fancy line of code used by azure automation ISE add-on
#$RunAsConnection = Get-AutomationConnection -Name AzureRunAsConnection;try {$Login=Add-AzureRmAccount -ServicePrincipal -TenantId $RunAsConnection.TenantId -ApplicationId $RunAsConnection.ApplicationId -CertificateThumbprint $RunAsConnection.CertificateThumbprint -ErrorAction Stop}catch{Sleep 10;$Login=Add-AzureRmAccount -ServicePrincipal -TenantId $RunAsConnection.TenantId -ApplicationId $RunAsConnection.ApplicationId -CertificateThumbprint $RunAsConnection.CertificateThumbprint};Select-AzureRmSubscription -SubscriptionId $RunAsConnection.SubscriptionID
# ----- starting -----
cd $PSScriptRoot # set the current directory to the directory of this script
Import-Module .\Create-Vm.psm1
Get-Command -Module Create-Vm

# ----- load Other variables -----
$Sleep = 2
#$PublicIp = New-Object Microsoft.Azure.Commands.Network.Models.PSPublicIpAddress

# ----- Load Variables -----
$H = get-HashFromJson -SettingsPath .\Settings_Environment.json
$H = get-HashFromJson -Hash $H -SettingsPath .\Settings.json


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
$StorageAccount_Kind = $H."StorageAccount.Kind"
$DataDisk_CreationOption = $H."DataDisk.CreationOption"
$StorageAccount_SkuName = $H."StorageAccount.SkuName"

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
$VMR = create-vm -Verbose -Subnet $Subnet -VNet $VNet -Nic $Nic -Subnet_Name $Subnet_Name -VNet_Name $VNetName -Subnet_AddressPrefix $Subnet_AddressPrefix `
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
    #Get-AzureRmTrafficManagerEndpoint -Name $TrafficManager_Name -ResourceGroupName $ResourceGroup_Name -Type AzureEndpoints -ProfileName $TrafficManager_Name # will error if it doesn't exist
}
# Attach the data disks
# ----- Add a traffix manager ----- end

# ----- Add data storage ----- start
#Add-DataDisk_PostVmCreation $VM, $ResourceGroup_RootName, $Storage_Name, $Location, $VhdUri_BlobPathm $DataDisk_DiskSizeInGb, $DataDisk_Caching, $StorageAccount_Kind, $DataDisk_CreationOption, $StorageAccount_SkuName
Add-DataDisk_PostVmCreation -VM $VM -ResourceGroup_Name $ResourceGroup_Name -Storage_Name $Storage_Name_Data1 -Location $Location -VhdUri_BlobPath $VhdUri_BlobPath `
    -DataDisk_DiskSizeInGb $DataDisk_DiskSizeInGb -DataDisk_Caching $DataDisk_Caching -StorageAccount_Kind $StorageAccount_Kind -DataDisk_CreationOption `
    $DataDisk_CreationOption -StorageAccount_SkuName $StorageAccount_SkuName
