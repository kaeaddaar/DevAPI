    #Install-Module AzureAutomationAuthoringToolkit -Scope AllUsers    
    #Fancy line of code used by azure automation ISE add-on
    #$RunAsConnection = Get-AutomationConnection -Name AzureRunAsConnection;try {$Login=Add-AzureRmAccount -ServicePrincipal -TenantId $RunAsConnection.TenantId -ApplicationId $RunAsConnection.ApplicationId -CertificateThumbprint $RunAsConnection.CertificateThumbprint -ErrorAction Stop}catch{Sleep 10;$Login=Add-AzureRmAccount -ServicePrincipal -TenantId $RunAsConnection.TenantId -ApplicationId $RunAsConnection.ApplicationId -CertificateThumbprint $RunAsConnection.CertificateThumbprint};Select-AzureRmSubscription -SubscriptionId $RunAsConnection.SubscriptionID
    # ----- starting -----
    if((Read-Host "Enter Y to Login") -eq "Y"){ Login-AzureRmAccount -SubscriptionName "VSE MPN" }
    #if((Read-Host "Enter Y to Login") -eq "Y"){ Login-AzureRmAccount -SubscriptionName "Windward Software - Platform Credit" }
    
    $HKeys = New-Object System.Collections.ArrayList
    $H = New-Object -TypeName hashtable

    # Top Level
    $X = foreach ($item in @("ResourceGroup.Name", "RGName", "TestNum", "RootName", "VmName", "Location", "VmSize", "ASetName")) {$HKeys.add($item)} # Global Hash Keys
    $H."TestNum" = "14"
    $H.RGName = "System5API" + $H.TestNum
    $H.'ResourceGroup.Name' = $H.RGName
    $ResourceGroup_Name = $H.'ResourceGroup.Name'
    $TestNum = $H.TestNum

    $H."RootName" = "DevApi"
    $RootName = $H.RootName
    $H.VmName = $H.'RootName' + $H.TestNum
    $H.Location = "westus2"
    $Location = $H.Location
    $VmName = $H.VmName
    
    $H.VmSize = "Standard_F2s"
    $H.ASetName = $H.'RootName' + $H.TestNum + "ASet"
    $VmSize = $H.VmSize
    $ASetName = $H.ASetName

    # Create-Vm
    $H."Image.PublisherName" = "MicrosoftWindowsServer"
    $H."Image.Offer" = "WindowsServer"
    $H."Image.Skus" = "2016-Datacenter"
    $H."Image.Version" = "latest"
    $Image_PublisherName = $H.'Image.PublisherName'
    $Image_Offer = $H.'Image.Offer'
    $Image_Skus = $H.'Image.Skus'
    $Image_Version = $H.'Image.Version'

    # Create-SubNet
    $H."Subnet.Name" = $H.'RootName' + $H.TestNum + "Subnet"
    $H."Subnet.AddressPrefix" = "10.0.0.0/24"
    $Subnet_Name = $H.'Subnet.Name'
    $Subnet_AddressPrefix = $H.'Subnet.AddressPrefix'

    # Create-VNet
    $H."VNet.Name" = $H.'RootName' + $H.TestNum + "VNet" # Depends on .VmName
    $VNetName = $H.'VNet.Name'

    # Create-PublicIp
    $H."PublicIp.Name" = $H.'RootName' + $H.TestNum + "PublicIp"
    $H.'PublicIp.Name' = $h.'PublicIp.Name'.ToLower()
    $PublicIp_Name = $H.'PublicIp.Name'

    # Create-Nic
    $H."Nic.Name" = $H.'RootName' + $H.TestNum + "Nic"
    $Nic_Name = $H.'Nic.Name'

    # Create-OsDisk
    $H."BlobPath" = "vhds/" + $H.'RootName' + $H.TestNum + "OsDisk1.vhd"
    $BlobPath = $H.BlobPath

    # Create-StorageAccount
    $H."Storage.Name" = $H.'RootName' + $H.TestNum + "StorageAcct"
    $H.'Storage.Name' = $H.'Storage.Name'.ToLower()
    $H."Storage.SkuName" = "Premium_LRS" #Standard_LRS
    $Storage_Name = $H.'Storage.Name'
    $Storage_SkuName = $H.'Storage.SkuName'
    
    # Create-OsDisk
    $H."OsDisk.Uri" = "" # Set in code as it pulls info from $StorageAccount
    $H."OsDisk.Name" = $H.'RootName' + $H.TestNum + "OsDisk" # Depends on .RootName and .TestNum
    $OsDisk_Uri = $H.'OsDisk.Uri'
    $OsDisk_Name = $H.'OsDisk.Name'

    $AutomationAccount_Name = "cmAutomation"
    $Automation_ResourceGroupName = "DevAPITest6"

    #New-Object Microsoft.Azure.Commands.Network.Models.PSSubnet
    $Sleep = 2
    
    $RG =  Get-AzureRmResourceGroup | where {$_.ResourceGroupName -eq $H.'ResourceGroup.Name'} # Returns $null if it doesn't find the resource group
    if ($RG -eq $null) { $RG = New-AzureRmResourceGroup -Name $H.'ResourceGroup.Name' -Location $H.Location } # if resource group doesn't exist make a new one

    $ASet = Get-AzureRmAvailabilitySet -ResourceGroupName $H.'ResourceGroup.Name' | where {$_.Name -eq $H.ASetName} # Returns $null if availability set not found
    if ($ASet -eq $null) {$ASet = New-AzureRmAvailabilitySet -ResourceGroupName $h.RGName -Name $H.ASetName -Location $H.Location} # if availability doesn't exist make a new one

    [Microsoft.Azure.Commands.Compute.Models.PSVirtualMachine]$VM = New-Object Microsoft.Azure.Commands.Compute.Models.PSVirtualMachine

function create-vm ([switch]$Verbose, $Subnet, $VNet, $PublicIp, $Nic, $StorageAccount, $VNet_Name, $Subnet_Name, $Subnet_AddressPrefix, $ResourceGroup_Name, $Location, $VmName, $VmSize, $Nic_Name, $OsDisk_Uri, $OsDisk_Name, $AutomationAccount_Name, [Microsoft.Azure.Commands.Compute.Models.PSVirtualMachine]$VM )
{
    #Global Inputs: $VM
    $VM = New-AzureRmVMConfig -VMName $VmName -VMSize $VmSize -AvailabilitySetId $ASet.Id
    #$Cred = Get-Credential -Message "Enter credentials" -UserName "cmackay"
    #$Cred = Get-AzureRmAutomationCredential -Name "credCliff" -ResourceGroupName "cmAuto" -AutomationAccountName "cmAutomation"
    $Cred = Get-AutomationPSCredential -Name "credCliff"
    [Microsoft.Azure.Commands.Compute.Models.PSVirtualMachine]$VM = Set-AzureRmVMOperatingSystem -VM $VM -Windows -ComputerName $VmName -Credential $Cred -EnableAutoUpdate -TimeZone "Pacific Standard Time"

    $X = foreach ($item in @("Image.PublisherName", "Image.Offer", "Image.Skus", "Image.Version")) {$HKeys.add($item)} # Global Hash Keys

<#
    $H."Image.PublisherName" = "MicrosoftWindowsServer"
    $H."Image.Offer" = "WindowsServer"
    $H."Image.Skus" = "2016-Datacenter"
    $H."Image.Version" = "latest"
#>
    [Microsoft.Azure.Commands.Compute.Models.PSVirtualMachine]$VM = Set-AzureRmVMSourceImage -VM $VM -PublisherName $Image_PublisherName -Offer $Image_Offer -Skus $Image_Skus -Version $Image_Version

    function Make-Nic ($Subnet, $VNet, $PublicIp, $Nic, $Subnet_Name, $Subnet_AddressPrefix, $VNet_Name, $ResourceGroup_Name, $Location, $Nic_Name, [Switch]$Verbose, [Microsoft.Azure.Commands.Compute.Models.PSVirtualMachine]$VM)
    {
        function Create-Subnet ($Subnet_Name, $Subnet_AddressPrefix, [Switch]$Verbose)
        {
            $X = foreach ($item in @("Subnet.Name", "Subnet", "Subnet.AddressPrefix")) {$HKeys.add($item)} # Global Hash Keys
            # $Subnet is used in Create-VNet
            # Create a subnet
        <#
            $H."Subnet.Name" = $H.VmName + "Subnet"
            $H."Subnet.AddressPrefix" = "10.0.0.0/24"
        #>
            $Subnet = New-AzureRmVirtualNetworkSubnetConfig -Name $Subnet_Name -AddressPrefix $Subnet_AddressPrefix
            $Subnet
        } # Create-Subnet
        if ($true) {write-host "Create-Subnet"}
        $Subnet = Create-Subnet -Subnet_Name $Subnet_Name -Subnet_AddressPrefix $Subnet_AddressPrefix -Verbose
        #Catch {write-host "Create-Subnet failed, breaking" +  $error[0].Exception + $error[0].FullyQualifiedErrorId; break}

        Start-Sleep $sleep
        
        function Create-VNet ($ResourceGroup_Name, $Location, $Subnet_AddressPrefix, $VNet_Name, $Subnet, [Switch]$Verbose)
        {
            # $VNet is used in 
            $X = foreach ($item in @("VNet.Name")) {$HKeys.add($item)} # Global Hash Keys
            # Create a VNet
        <#
            $H."VNet.Name" = $H.VmName + "VNet" 
        #>
            $VNet = New-AzureRmVirtualNetwork -Name $VNet_Name -ResourceGroupName $ResourceGroup_Name -Location $Location -AddressPrefix $Subnet_AddressPrefix -Subnet $Subnet
            $VNet
            Start-Sleep $sleep
        } # Create-VNet
        if ($true) {write-host "Create-VNet"}
        $VNet = Create-VNet -ResourceGroup_Name $ResourceGroup_Name -Location $Location -Subnet_AddressPrefix $Subnet_AddressPrefix -Subnet $Subnet `
            -VNet_Name $VNet_Name -Verbose
        #Catch {write-host "Create-VNet failed, breaking" +  $error[0].Exception + $error[0].FullyQualifiedErrorId; break}

        function Create-PublicIp ($ResourceGroup_Name, $Location, [Switch]$Verbose)
        {
            # $PublicIp used in Create-Nic
            $X = foreach ($item in @("PublicIp.Name")) {$HKeys.add($item)} # Global Hash Keys
            # Create a Public IP
        <#
            $H."PublicIp.Name" = $H.VmName + "PublicIp"
            $H.'PublicIp.Name' = $h.'PublicIp.Name'.ToLower()
        #>
            $PublicIP = New-AzureRmPublicIpAddress -Name $PublicIp_Name -ResourceGroupName $ResourceGroup_Name -Location $Location -AllocationMethod Dynamic -DomainNameLabel $PublicIp_Name
            $PublicIP
        } # Create-PublicIp
        if ($true) {write-host "Create-PublicIp"}
        $PublicIp = Create-PublicIp -ResourceGroup_Name $ResourceGroup_Name -Location $Location -Verbose
        #Catch {write-host "Create-PublicIp failed, breaking" +  $error[0].Exception + $error[0].FullyQualifiedErrorId; break}

        Start-Sleep $sleep

        Function Create-Nic ($ResourceGroup_Name, $Location, $PublicIp, $Nic_Name, $VNet, $Nic, [Switch]$Verbose)
        {
            # $NIC is used in Add-AzureRmVMNetworkInterface below
            $X = foreach ($item in @("Nic.Name")) {$HKeys.add($item)} # Global Hash Keys
            # Create a NIC
        <#
            $H."Nic.Name" = $H.VmName + "Nic"
        #>
            $Nic = New-AzureRmNetworkInterface -Name $Nic_Name -ResourceGroupName $ResourceGroup_Name -Location $Location -SubnetId $VNet.Subnets[0].Id -PublicIpAddressId $PublicIP.Id 
            $Nic
        } # Create-Nic
        if ($true) {write-host "Create-Nic"}
        $Nic = Create-Nic -ResourceGroup_Name $ResourceGroup_Name -Location $Location -PublicIp $PublicIp -Nic_Name $Nic_Name -VNet $VNet -Nic $Nic -Verbose
        #Catch {write-host "Create-Nic failed, breaking"; break}

        [Microsoft.Azure.Commands.Compute.Models.PSVirtualMachine]$VM = Add-AzureRmVMNetworkInterface -VM $VM -id $Nic.Id
        $VM
    } # Make-Nic
    if ($true) {Write-Host "Make-Nic"}
    [Microsoft.Azure.Commands.Compute.Models.PSVirtualMachine]$VM = Make-Nic -Subnet $Subnet -VNet $VNet -PublicIp $PublicIp -Nic $Nic -Subnet_Name $Subnet_Name -Subnet_AddressPrefix $Subnet_AddressPrefix `
        -ResourceGroup_Name $ResourceGroup_Name -Location $Location -VNet_Name $VNet_Name -Nic_Name $Nic_Name -Verbose -VM $VM
#    Catch {write-host "Make-Nic failed, breaking" +  $error[0].Exception + $error[0].FullyQualifiedErrorId; break}

    function Create-OsDisk ($Storage_Name, $Storage_SkuName, $StorageAccount, [Microsoft.Azure.Commands.Compute.Models.PSVirtualMachine]$VM, $OsDisk_Uri, $OsDisk_Name, [Switch]$Verbose)
    {
    <#
        $H."BlobPath" = "vhds/" + $H.'VmName' + "OsDisk1.vhd"
    #>
        function Create-StorageAccount ($Storage_Name, $Storage_SkuName, $StorageAccount, [Switch]$Verbose)
        {
            $X = foreach ($item in @("Storage.Name", "Storage.SkuName")) {$HKeys.add($item)} # Global Hash Keys
            # Create a storage account
        <#
            $H."Storage.Name" = $H.VmName + "StorageAcct"
            $H.'Storage.Name' = $H.'Storage.Name'.ToLower()
            $H."Storage.SkuName" = "Premium_LRS" #Standard_LRS
        #>
            #Get-AzureRmStorageAccountNameAvailability $StorageName
            $goodName = Get-AzureRmStorageAccountNameAvailability $H.'Storage.Name'
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
        if ($true) {write-host "Create-StorageAccount"}
        $StorageAccount = Create-StorageAccount -Storage_Name $Storage_Name -Storage_SkuName $Storage_SkuName -StorageAccount $StorageAccount -Verbose
        #Catch {write-host "Create-StorageAccount failed, breaking" +  $error[0].Exception + $error[0].FullyQualifiedErrorId; break}

        $X = foreach ($item in @("OsDisk.Uri", "OsDisk.Name")) {$HKeys.add($item)} # Global Hash Keys
        $OsDisk_Uri = $StorageAccount.PrimaryEndpoints.Blob.ToString() + $BlobPath
    <#
        $H."OsDisk.Name" = $H.VmName + "OsDisk"
    #>
        [Microsoft.Azure.Commands.Compute.Models.PSVirtualMachine]$VM = Set-AzureRmVMOSDisk -VM $VM -Name $OsDisk_Name -VhdUri $OsDisk_Uri -CreateOption FromImage
        $VM
    } # Create-OsDisk
    if ($true) {write-host "Create-OsDisk"}
    $VM = Create-OsDisk -Storage_Name $Storage_Name -Storage_SkuName $Storage_SkuName -StorageAccount $StorageAccount -VM $VM -OsDisk_Uri $OsDisk_Uri `
        -OsDisk_Name $OsDisk_Name -Verbose
    #Catch {write-host "Create-OsDisk failed, breaking" +  $error[0].Exception + $error[0].FullyQualifiedErrorId; break}

    write-host "Press C to Cancel before creating a VM"
    if (read-host -eq "C") {break}
    [Microsoft.Azure.Commands.Compute.Models.PSVirtualMachine]$VM = New-AzureRmVM -VM $VM -ResourceGroupName $ResourceGroup_Name -Location $Location
    $VM
} # Create-VM
if ($true) {write-host "Create-Vm"}
[Microsoft.Azure.Commands.Compute.Models.PSVirtualMachine]$VM = create-vm -Verbose -Subnet $Subnet -VNet $VNet -PublicIp $PublicIP -Nic $Nic -Subnet_Name $Subnet_Name -VNet_Name $VNetName -Subnet_AddressPrefix $Subnet_AddressPrefix `
    -ResourceGroup_Name $ResourceGroup_Name -Location $Location -VmName $VmName -VmSize $VmSize -Nic_Name $Nic_Name -AutomationAccount_Name $AutomationAccount_Name `
    -OsDisk_Uri $OsDisk_Uri -OsDisk_Name $OsDisk_Name -VM $VM
#Catch {write-host "Create-Vm failed, breaking" +  $error[0].Exception + $error[0].FullyQualifiedErrorId; break}


# Traffic Manager
    $H."TrafficManager.Name" = $H.RGName + "TrafficManager"
    $H.'TrafficManager.Name' = $H.'TrafficManager.Name'.Replace("_","")
    $TrafficManagerProfile = New-AzureRmTrafficManagerProfile -Name $H.'TrafficManager.Name' -ResourceGroupName $H.RGName -ProfileStatus Enabled -RelativeDnsName $H.'TrafficManager.Name' -Ttl 30 -TrafficRoutingMethod Performance -MonitorProtocol HTTP -MonitorPath "/" -MonitorPort 80
    $H."TrafficManagerEndpoint.Name" = $H.'RootName' + $H.TestNum + "TmEndpoint"
#    $H."TrafficManagerEndpoint.Id" = "/subscriptions/7261fdd2-889c-491b-8657-1ff32e1cac4b/resourceGroups/DevAPI_Test/providers/Microsoft.Network/networkInterfaces/DevAPINic"
    $H."TrafficManagerEndpoint.Id" = TrafficManagerProfile.Id

    New-AzureRmTrafficManagerEndpoint -Name $H.'TrafficManagerEndpoint.Name' -ProfileName $H.'TrafficManager.Name' -ResourceGroupName $H.RGName -Type AzureEndpoints -TargetResourceId $PublicIP.Id -EndpointStatus Enabled

# Attach the data disks

    $H."VhdUri.BlobPath" = "vhds/" + $H.'RootName' + $H.TestNum + "DataDisk1.vhd"
    $H."Storage.Name" = $H.'RootName' + $H.TestNum + "testdatastorage"
    $H."Storage.Name" = $H.'Storage.Name'.tolower() # Required to have in lower case
    
    #$DataStorage = Get-AzureRmStorageAccount -ResourceGroupName $H.'RgName' -Name $H.'Storage.Name'
    $H."VhdUri.Name" = $H.'RootName' + $H.TestNum + "DataDisk1"
    $H.'VhdUri.Name' = $H.'VhdUri.Name'.ToLower()
    #$H.'VhdUri.Name' = "cmtestabc"
    #$DataStorage = New-AzureRmStorageAccount -ResourceGroupName $H.'RGName' -SkuName "Premium_LRS" -Name $H."Storage.Name" -Location $H.Location -Kind "BlobStorage" -AccessTier "Hot"
    $DataStorage = New-AzureRmStorageAccount -ResourceGroupName $H.'RGName' -SkuName "Premium_LRS" -Name $H."Storage.Name" -Location $H.Location -Kind Storage

    $H."VhdUri" = $DataStorage.PrimaryEndpoints.Blob.ToString() + $H.'VhdUri.BlobPath'
    Add-AzureRmVMDataDisk -VM $VM -Name $H.'VhdUri.Name' -VhdUri $H.VhdUri -CreateOption Empty -DiskSizeInGB 20 -Lun 0 -Caching None
    #Update-AzureRmVM -VM $VM -ResourceGroupName $H.RGName
    # the above worked, but I had lun and cashing parameters set, where previous attempts didn't have those set.
