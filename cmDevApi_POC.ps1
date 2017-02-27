    #Login-AzureRmAccount -SubscriptionName "VSE MPN"
    Login-AzureRmAccount -SubscriptionName "Windward Software - Platform Credit"
    
    $H = New-Object -TypeName hashtable
    $H."TestNum" = ""
    $H.RGName = "System5API" + $H.TestNum

    $H.VmName = "DevApi" + $H.TestNum
    $H.Location = "westus2"
    $H.VmSize = "Standard_F2s"

    $Sleep = 2

    $RgList = Get-AzureRmResourceGroup 
    $RgExists = ($null -ne ($RgList | where {$_.ResourceGroupName -eq $H.RGName}))

    if ($RgExists) {Get-AzureRmResourceGroup -Name $H.RGName}
    else {New-AzureRmResourceGroup -Name $H.RGName -Location $H.Location}

    $H.ASetName = "DevApiASet"
    $ASetList = Get-AzureRmAvailabilitySet -ResourceGroupName $H.RGName
    $ASetExists = ($null -ne ($ASetList | where {$_.Name -eq $H.ASetName}))

    if ($ASetExists) {$ASet = Get-AzureRmAvailabilitySet -ResourceGroupName $H.RGName -Name $H.ASetName}
    else {$ASet = New-AzureRmAvailabilitySet -ResourceGroupName $h.RGName -Name $H.ASetName -Location $H.Location}

    $VM = New-AzureRmVMConfig -VMName $H.VmName -VMSize $H.VmSize -AvailabilitySetId $ASet.Id
    $Cred = Get-Credential -Message "Enter credentials"
    Set-AzureRmVMOperatingSystem -VM $VM -Windows -ComputerName $H.VmName -Credential $Cred -EnableAutoUpdate -TimeZone "Pacific Standard Time"

    $H."Image.PublisherName" = "MicrosoftWindowsServer"
    $H."Image.Offer" = "WindowsServer"
    $H."Image.Skus" = "2016-Datacenter"
    $H."Image.Version" = "latest"
    Set-AzureRmVMSourceImage -VM $VM -PublisherName $H.'Image.PublisherName' -Offer $H.'Image.Offer' -Skus $H.'Image.Skus' -Version $H.'Image.Version'

        # Create a subnet
        $H."Subnet.Name" = $H.VmName + "Subnet"
        $H."Subnet.AddressPrefix" = "10.0.0.0/24"

        $Subnet = New-AzureRmVirtualNetworkSubnetConfig -Name $H.'Subnet.Name' -AddressPrefix $H.'Subnet.AddressPrefix'
        Start-Sleep $sleep

        # Create a VNet
        $H."VNet.Name" = $H.VmName + "VNet"
        $Vnet = New-AzureRmVirtualNetwork -Name $H.'VNet.Name' -ResourceGroupName $H.RGName -Location $H.Location -AddressPrefix $H.'Subnet.AddressPrefix' -Subnet $Subnet
        Start-Sleep $sleep

        # Create a Public IP
        $H."PublicIp.Name" = $H.VmName + "PublicIp"
        $H.'PublicIp.Name' = $h.'PublicIp.Name'.ToLower()
        $PublicIP = New-AzureRmPublicIpAddress -Name $H.'PublicIp.Name' -ResourceGroupName $H.RGName -Location $H.Location -AllocationMethod Dynamic -DomainNameLabel $H.'PublicIp.Name'
        Start-Sleep $sleep

        # Create a NIC
        $H."Nic.Name" = $H.VmName + "Nic"
        $NIC = New-AzureRmNetworkInterface -Name $H.'Nic.Name' -ResourceGroupName $H.RGName -Location $H.Location -SubnetId $VNet.Subnets[0].Id -PublicIpAddressId $PublicIP.Id

    Add-AzureRmVMNetworkInterface -VM $VM -id $Nic.Id 

    $H."BlobPath" = "vhds/" + $H.'VmName' + "OsDisk1.vhd"

        # Create a storage account
        $H."Storage.Name" = $H.VmName + "StorageAcct"
        $H.'Storage.Name' = $H.'Storage.Name'.ToLower()
        $H."Storage.SkuName" = "Premium_LRS" #Standard_LRS
        #Get-AzureRmStorageAccountNameAvailability $StorageName
        $goodName = Get-AzureRmStorageAccountNameAvailability $H.'Storage.Name'
        write-host "$goodName.NameAvailable = """ + $goodName.NameAvailable
        Start-Sleep 5
        if ($goodName.NameAvailable)
        {
        $StorageAccount = New-AzureRmStorageAccount -ResourceGroupName $H.RGName -Name $H.'Storage.Name' -Kind Storage -Location $H.Location -SkuName $H.'Storage.SkuName'
        }
        else
        {
        $StorageAccount = Get-AzureRmStorageAccount -ResourceGroupName $H.RGName -Name $H.'Storage.Name'
        }

    $H."OsDistUri" = $StorageAccount.PrimaryEndpoints.Blob.ToString() + $H.BlobPath
    $H."OsDisk.Name" = $H.VmName + "OsDisk"
    $VM = Set-AzureRmVMOSDisk -VM $Vm -Name $H.'OsDisk.Name' -VhdUri $H.OsDistUri -CreateOption FromImage

    New-AzureRmVM -VM $VM -ResourceGroupName $H.RGName -Location $H.Location

# Traffic Manager
    $H."TrafficManager.Name" = $H.RGName + "TrafficManager"
    $H.'TrafficManager.Name' = $H.'TrafficManager.Name'.Replace("_","")
    New-AzureRmTrafficManagerProfile -Name $H.'TrafficManager.Name' -ResourceGroupName $H.RGName -ProfileStatus Enabled -RelativeDnsName $H.'TrafficManager.Name' -Ttl 30 -TrafficRoutingMethod Performance -MonitorProtocol HTTP -MonitorPath "/" -MonitorPort 80
    $H."TrafficManagerEndpoint.Name" = $H.VmName + "TmEndpoint"
    $H."TrafficManagerEndpoint.Id" = "/subscriptions/7261fdd2-889c-491b-8657-1ff32e1cac4b/resourceGroups/DevAPI_Test/providers/Microsoft.Network/networkInterfaces/DevAPINic"

    New-AzureRmTrafficManagerEndpoint -Name $H.'TrafficManagerEndpoint.Name' -ProfileName $H.'TrafficManager.Name' -ResourceGroupName $H.RGName -Type AzureEndpoints -TargetResourceId $PublicIP.Id -EndpointStatus Enabled

# Attach the data disks

    $H."VhdUri.BlobPath" = "vhds/" + $H.'VmName' + "DataDisk1.vhd"
    $H."Storage.Name" = $H.VmName + "testdatastorage"
    $H."Storage.Name" = $H.'Storage.Name'.tolower() # Required to have in lower case
    
    #$DataStorage = Get-AzureRmStorageAccount -ResourceGroupName $H.'RgName' -Name $H.'Storage.Name'
    $H."VhdUri.Name" = $H.VmName + "DataDisk1"
    $H.'VhdUri.Name' = $H.'VhdUri.Name'.ToLower()
    #$H.'VhdUri.Name' = "cmtestabc"
    #$DataStorage = New-AzureRmStorageAccount -ResourceGroupName $H.'RGName' -SkuName "Premium_LRS" -Name $H."Storage.Name" -Location $H.Location -Kind "BlobStorage" -AccessTier "Hot"
    $DataStorage = New-AzureRmStorageAccount -ResourceGroupName $H.'RGName' -SkuName "Premium_LRS" -Name $H."Storage.Name" -Location $H.Location -Kind Storage

    $H."VhdUri" = $DataStorage.PrimaryEndpoints.Blob.ToString() + $H.'VhdUri.BlobPath'
    Add-AzureRmVMDataDisk -VM $VM -Name $H.'VhdUri.Name' -VhdUri $H.VhdUri -CreateOption Empty -DiskSizeInGB 20 -Lun 0 -Caching None
    #Update-AzureRmVM -VM $VM -ResourceGroupName $H.RGName
    # the above worked, but I had lun and cashing parameters set, where previous attempts didn't have those set.
