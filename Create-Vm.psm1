
# ----- functions -----
function Make-Nic ($Subnet, $VNet, [ref]$PublicIp, $Nic, $Subnet_Name, $Subnet_AddressPrefix, $VNet_Name, $ResourceGroup_Name, $Location, $Nic_Name, [Switch]$Verbose, [Microsoft.Azure.Commands.Compute.Models.PSVirtualMachine]$VM)
{
    if ($true) {write-host "Create-Subnet"}
    $Subnet = Create-Subnet -Subnet_Name $Subnet_Name -Subnet_AddressPrefix $Subnet_AddressPrefix -Verbose
    #Catch {write-host "Create-Subnet failed, breaking" +  $error[0].Exception + $error[0].FullyQualifiedErrorId; break}

    Start-Sleep $sleep
        
    if ($true) {write-host "Create-VNet"}
    $VNet = Create-VNet -ResourceGroup_Name $ResourceGroup_Name -Location $Location -Subnet_AddressPrefix $Subnet_AddressPrefix -Subnet $Subnet `
        -VNet_Name $VNet_Name -Verbose
    #Catch {write-host "Create-VNet failed, breaking" +  $error[0].Exception + $error[0].FullyQualifiedErrorId; break}

    if ($true) {write-host "Create-PublicIp"}
    $PublicIp = Create-PublicIp -ResourceGroup_Name $ResourceGroup_Name -Location $Location -Verbose -PublicIp ([ref]$PublicIp)
    #Catch {write-host "Create-PublicIp failed, breaking" +  $error[0].Exception + $error[0].FullyQualifiedErrorId; break}

    Start-Sleep $sleep

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
    Start-Sleep $sleep
} # Create-VNet


function Create-PublicIp ($ResourceGroup_Name, $Location, [Switch]$Verbose, [ref]$PublicIp)
{
    # $PublicIp used in Create-Nic
    # Create a Public IP
<#
    $H."PublicIp.Name" = $H.VmName + "PublicIp"
    $H.'PublicIp.Name' = $h.'PublicIp.Name'.ToLower()
#>
    ([ref]$PublicIp) = New-AzureRmPublicIpAddress -Name $PublicIp_Name -ResourceGroupName $ResourceGroup_Name -Location $Location -AllocationMethod Dynamic -DomainNameLabel $PublicIp_Name
    $PublicIp.Value
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


function create-vm ([switch]$Verbose, $Subnet, $VNet, [ref]$PublicIp, $Nic, $StorageAccount, $VNet_Name, $Subnet_Name, $Subnet_AddressPrefix, `
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
    [Microsoft.Azure.Commands.Compute.Models.PSVirtualMachine]$VM = Make-Nic -Subnet $Subnet -VNet $VNet -PublicIp ([ref]$PublicIp) -Nic $Nic -Subnet_Name $Subnet_Name -Subnet_AddressPrefix $Subnet_AddressPrefix `
        -ResourceGroup_Name $ResourceGroup_Name -Location $Location -VNet_Name $VNet_Name -Nic_Name $Nic_Name -Verbose -VM $VM
#    Catch {write-host "Make-Nic failed, breaking" +  $error[0].Exception + $error[0].FullyQualifiedErrorId; break}

    if ($true) {write-host "Create-OsDisk"}
    $VM = Create-OsDisk -Storage_Name $Storage_Name -Storage_SkuName $Storage_SkuName -StorageAccount $StorageAccount -VM $VM -OsDisk_Uri $OsDisk_Uri `
        -OsDisk_Name $OsDisk_Name -Verbose
    #Catch {write-host "Create-OsDisk failed, breaking" +  $error[0].Exception + $error[0].FullyQualifiedErrorId; break}

    write-host "Press C to Cancel before creating a VM"
    if (read-host -eq "C") {break}
    New-AzureRmVM -VM $VM -ResourceGroupName $ResourceGroup_Name -Location $Location
    $VM
} # Create-VM
