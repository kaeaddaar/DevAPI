
# ----- functions -----
function Make-Nic ($Subnet, $VNet, $Nic, $Subnet_Name, $Subnet_AddressPrefix, $VNet_Name, $ResourceGroup_Name, $Location, $Nic_Name, [Switch]$Verbose, [Microsoft.Azure.Commands.Compute.Models.PSVirtualMachine]$VM)
{
    if ($true) {write-host "Create-Subnet"}
    $Subnet = Create-Subnet -Subnet_Name $Subnet_Name -Subnet_AddressPrefix $Subnet_AddressPrefix -Verbose
    #Catch {write-host "Create-Subnet failed, breaking" +  $error[0].Exception + $error[0].FullyQualifiedErrorId; break}

    Start-Sleep 2
        
    if ($true) {write-host "Create-VNet"}
    $VNet = Create-VNet -ResourceGroup_Name $ResourceGroup_Name -Location $Location -Subnet_AddressPrefix $Subnet_AddressPrefix -Subnet $Subnet `
        -VNet_Name $VNet_Name -Verbose
    #Catch {write-host "Create-VNet failed, breaking" +  $error[0].Exception + $error[0].FullyQualifiedErrorId; break}

    if ($true) {write-host "Create-PublicIp"}
    $PublicIp = Create-PublicIp -ResourceGroup_Name $ResourceGroup_Name -Location $Location -Verbose
    #Catch {write-host "Create-PublicIp failed, breaking" +  $error[0].Exception + $error[0].FullyQualifiedErrorId; break}

    Start-Sleep 2

    if ($true) {write-host "Create-Nic"}
    $Nic = Create-Nic -ResourceGroup_Name $ResourceGroup_Name -Location $Location -PublicIp $PublicIp -Nic_Name $Nic_Name -VNet $VNet -Nic $Nic -Verbose
    #Catch {write-host "Create-Nic failed, breaking"; break}

    [Microsoft.Azure.Commands.Compute.Models.PSVirtualMachine]$VM = Add-AzureRmVMNetworkInterface -VM $VM -id $Nic.Id
    $VM
        
} # Make-Nic


function Create-Subnet ($Subnet_Name, $Subnet_AddressPrefix, [Switch]$Verbose)
{
    # $Subnet is used in Create-VNet
    # Create a subnet
<#
    $H."Subnet.Name" = $H.VmName + "Subnet"
    $H."Subnet.AddressPrefix" = "10.0.0.0/24"
#>
    $Subnet = New-AzureRmVirtualNetworkSubnetConfig -Name $Subnet_Name -AddressPrefix $Subnet_AddressPrefix
    $Subnet
} # Create-Subnet


function Create-VNet ($ResourceGroup_Name, $Location, $Subnet_AddressPrefix, $VNet_Name, $Subnet, [Switch]$Verbose)
{
    # $VNet is used in 
    # Create a VNet
<#
    $H."VNet.Name" = $H.VmName + "VNet" 
#>
    $VNet = New-AzureRmVirtualNetwork -Name $VNet_Name -ResourceGroupName $ResourceGroup_Name -Location $Location -AddressPrefix $Subnet_AddressPrefix -Subnet $Subnet
    $VNet
    Start-Sleep 2
} # Create-VNet


function Create-PublicIp ($ResourceGroup_Name, $Location, [Switch]$Verbose)
{
    # $PublicIp used in Create-Nic
    # Create a Public IP
<#
    $H."PublicIp.Name" = $H.VmName + "PublicIp"
    $H.'PublicIp.Name' = $h.'PublicIp.Name'.ToLower()
#>
    $PublicIp = New-AzureRmPublicIpAddress -Name $PublicIp_Name -ResourceGroupName $ResourceGroup_Name -Location $Location -AllocationMethod Dynamic -DomainNameLabel $PublicIp_Name
    $PublicIp
} # Create-PublicIp

Function Create-Nic ($ResourceGroup_Name, $Location, $PublicIp, $Nic_Name, $VNet, $Nic, [Switch]$Verbose)
{
    # $NIC is used in Add-AzureRmVMNetworkInterface below
    # Create a NIC
<#
    $H."Nic.Name" = $H.VmName + "Nic"
#>
    $Nic = New-AzureRmNetworkInterface -Name $Nic_Name -ResourceGroupName $ResourceGroup_Name -Location $Location -SubnetId $VNet.Subnets[0].Id -PublicIpAddressId $PublicIP.Value.Id 
    $Nic
} # Create-Nic


function Create-OsDisk ($Storage_Name, $Storage_SkuName, $StorageAccount, [Microsoft.Azure.Commands.Compute.Models.PSVirtualMachine]$VM, $OsDisk_Uri, $OsDisk_Name, [Switch]$Verbose)
{
<#
    $H."BlobPath" = "vhds/" + $H.'VmName' + "OsDisk1.vhd"
#>
    if ($true) {write-host "Create-StorageAccount"}
    $StorageAccount = Create-StorageAccount -Storage_Name $Storage_Name -Storage_SkuName $Storage_SkuName -StorageAccount $StorageAccount -Verbose
    #Catch {write-host "Create-StorageAccount failed, breaking" +  $error[0].Exception + $error[0].FullyQualifiedErrorId; break}

    $OsDisk_Uri = $StorageAccount.PrimaryEndpoints.Blob.ToString() + $BlobPath
<#
    $H."OsDisk.Name" = $H.VmName + "OsDisk"
#>
    [Microsoft.Azure.Commands.Compute.Models.PSVirtualMachine]$VM = Set-AzureRmVMOSDisk -VM $VM -Name $OsDisk_Name -VhdUri $OsDisk_Uri -CreateOption FromImage
    $VM
} # Create-OsDisk


function Create-StorageAccount ($Storage_Name, $Storage_SkuName, $StorageAccount, [Switch]$Verbose)
{
    # Create a storage account
<#
    $H."Storage.Name" = $H.VmName + "StorageAcct"
    $H.'Storage.Name' = $H.'Storage.Name'.ToLower()
    $H."Storage.SkuName" = "Premium_LRS" #Standard_LRS
#>
    #Get-AzureRmStorageAccountNameAvailability $StorageName
    $goodName = Get-AzureRmStorageAccountNameAvailability $Storage_Name
    write-host "$goodName.NameAvailable = """ + $goodName.NameAvailable
    Start-Sleep 5
    if ($goodName.NameAvailable)
    {
        $StorageAccount = New-AzureRmStorageAccount -ResourceGroupName $ResourceGroup_Name -Name $Storage_Name -Kind Storage -Location $Location -SkuName $Storage_SkuName
    }
    else
    {
        $StorageAccount = Get-AzureRmStorageAccount -ResourceGroupName $ResourceGroup_Name -Name $Storage_Name
    }
    $StorageAccount
} #Create-StorageAccount


function create-vm ([switch]$Verbose, $Subnet, $VNet, $Nic, $StorageAccount, $VNet_Name, $Subnet_Name, $Subnet_AddressPrefix, `
    $ResourceGroup_Name, $Location, $VmName, $VmSize, $Nic_Name, $OsDisk_Uri, $OsDisk_Name, $AutomationAccount_Name, [Microsoft.Azure.Commands.Compute.Models.PSVirtualMachine]$VM )
{
    #Global Inputs: $VM
    $VM = New-AzureRmVMConfig -VMName $VmName -VMSize $VmSize -AvailabilitySetId $ASet.Id
    #$Cred = Get-Credential -Message "Enter credentials" -UserName "cmackay"
    #$Cred = Get-AzureRmAutomationCredential -Name "credCliff" -ResourceGroupName "cmAuto" -AutomationAccountName "cmAutomation"
    $Cred = Get-AutomationPSCredential -Name "credCliff"
    [Microsoft.Azure.Commands.Compute.Models.PSVirtualMachine]$VM = Set-AzureRmVMOperatingSystem -VM $VM -Windows -ComputerName $VmName -Credential $Cred -EnableAutoUpdate -TimeZone "Pacific Standard Time"

<#
    $H."Image.PublisherName" = "MicrosoftWindowsServer"
    $H."Image.Offer" = "WindowsServer"
    $H."Image.Skus" = "2016-Datacenter"
    $H."Image.Version" = "latest"
#>
    [Microsoft.Azure.Commands.Compute.Models.PSVirtualMachine]$VM = Set-AzureRmVMSourceImage -VM $VM -PublisherName $Image_PublisherName -Offer $Image_Offer -Skus $Image_Skus -Version $Image_Version

    if ($true) {Write-Host "Make-Nic"}
    [Microsoft.Azure.Commands.Compute.Models.PSVirtualMachine]$VM = Make-Nic -Subnet $Subnet -VNet $VNet -Nic $Nic -Subnet_Name $Subnet_Name -Subnet_AddressPrefix $Subnet_AddressPrefix `
        -ResourceGroup_Name $ResourceGroup_Name -Location $Location -VNet_Name $VNet_Name -Nic_Name $Nic_Name -Verbose -VM $VM
#    Catch {write-host "Make-Nic failed, breaking" +  $error[0].Exception + $error[0].FullyQualifiedErrorId; break}

    if ($true) {write-host "Create-OsDisk"}
    $VM = Create-OsDisk -Storage_Name $Storage_Name -Storage_SkuName $Storage_SkuName -StorageAccount $StorageAccount -VM $VM -OsDisk_Uri $OsDisk_Uri `
        -OsDisk_Name $OsDisk_Name -Verbose
    #Catch {write-host "Create-OsDisk failed, breaking" +  $error[0].Exception + $error[0].FullyQualifiedErrorId; break}

    write-host "Press C to Cancel before creating a VM"
    if ((read-host) -eq "C") {break}
    New-AzureRmVM -VM $VM -ResourceGroupName $ResourceGroup_Name -Location $Location
    $VM
} # Create-VM


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


# ----- Add data storage ----- start
<#
.Synopsis
   Add data storage after VM has been created
.DESCRIPTION
   This code works after VM is already created
.EXAMPLE
   Example of how to use this cmdlet
.EXAMPLE
   Another example of how to use this cmdlet
.INPUTS
   $VM is the Virtual Machine data disk is being added to
   $ResourceGroup_Name is the resource group the VM and Data disks are in
   $Location is the geo location the disk will be created in. Ex: westus2
   $VhsUri_BlobPath is the blobpath. Put together using this structure: "vhds/" + $RootName + $TestNum + "OsDisk1.vhd"
   $DataDisk_DiskSizeInGb is the size in GB that the Data disk will be
   $DataDisk_Caching is the caching setting. Ex: None
   $Kind_Def is the Kind setting on the disk. Ex: "Storage"
   $CreationOption_Def is the creation option of the disk. Ex: "Empty"
   $SkuName_Def is the SkuName of the storage.Ex: "Premium_LRS"
.OUTPUTS
   Returns the VM
#>
function Add-DataDisk_PostVmCreation ($VM, $ResourceGroup_Name, $Storage_Name, $Location, $VhdUri_BlobPath, $DataDisk_DiskSizeInGb, $DataDisk_Caching, `
    $StorageAccount_Kind, $DataDisk_CreationOption, $StorageAccount_SkuName)
{
    $DataStorage = Get-AzureRmStorageAccount -ResourceGroupName $ResourceGroup_Name -Name $Storage_Name
    if ($dataStorage -eq $null) { $DataStorage = New-AzureRmStorageAccount -ResourceGroupName $ResourceGroup_Name -SkuName $StorageAccount_SkuName -Name $Storage_Name `
        -Location $Location -Kind $StorageAccount_Kind }

    $VhdUri = $DataStorage.PrimaryEndpoints.Blob.ToString() + $VhdUri_BlobPath

    Add-AzureRmVMDataDisk -VM $VM -Name $VhdUri_Name -VhdUri $VhdUri -CreateOption $DataDisk_CreationOption -DiskSizeInGB $DataDisk_DiskSizeInGb -Lun $DataDisk_Lun -Caching $DataDisk_Caching
    # the above worked, but I had lun and cashing parameters set, where previous attempts didn't have those set.
    
    Update-AzureRmVM -VM $VM -ResourceGroupName $ResourceGroup_Name
    $VM
}
# ----- Add data storage ----- end


# ----- Add a VM using basic setup used for Dev API VM -----
<#
.Synopsis
   Add a VM using basic setup
.DESCRIPTION
   Add a VM using basic setup
.EXAMPLE
cd $PSScriptRoot # set the current directory to the directory of this script
Import-Module .\Create-Vm.psm1 # Import the functions from the Create-Vm module
get-command -Module Create-Vm # Display the functions available in the Create-Vm module
$H = get-HashFromJson -SettingsPath .\Settings_Environment.json # Get environment variables
$H = get-HashFromJson -Hash $H -SettingsPath .\Settings.json # Get the Settings for this VM
Add-VmBasic -H $H

.INPUTS
   $H a settings hash
.OUTPUTS
   Output from this cmdlet (if any)
.Notes
   The setup file designed to be used here is for a minimal list of settings. I would like to enhace the functionality to provide the ability to override a calulated value with
   Your own value. This commend refers to the variables in Add-VmBasic in the section called ----- Load Calculated Variables -----
#>
function Add-VmBasic ($H) # $H is the settings hash
{
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
    
    $VM = get-azurermvm -ResourceGroupName $ResourceGroup_Name -Name $VmName # Need the VM
<#
    # ----- Add a traffic manager (post vm creation) ----- start
    # Traffic Manager
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
#>

    # Attach the data disks
    # ----- Add a traffix manager ----- end

    # ----- Add data storage ----- start
    Add-DataDisk_PostVmCreation -VM $VM -ResourceGroup_Name $ResourceGroup_Name -Storage_Name $Storage_Name_Data1 -Location $Location -VhdUri_BlobPath $VhdUri_BlobPath `
        -DataDisk_DiskSizeInGb $DataDisk_DiskSizeInGb -DataDisk_Caching $DataDisk_Caching -StorageAccount_Kind $StorageAccount_Kind -DataDisk_CreationOption `
        $DataDisk_CreationOption -StorageAccount_SkuName $StorageAccount_SkuName
} # Add-VmBasic