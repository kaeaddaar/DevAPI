# Author: Clifford MacKay

# Quick sample for finding state of RM VMs
function global:get-VmStatus
{
    Get-AzureRmResourceGroup | Get-AzureRmVM -Status
}


# ----- Logon -----

function global:Logon
{
    write-host "Enter Y if you would like to enter your credentials, or hit ENTER to continue"
    $LogonAgain = Read-Host

    if($LogonAgain -eq "Y")
    {
        # enter your logon info
        Login-AzureRmAccount -SubscriptionName "Visual Studio Enterprise – MPN"
    }
}

# ----- get-cmEnum -----

#>>>>>>>>>>>> WARNING: NOT READY FOR USE <<<<<<<<<<<<
function golbal:get-cmEnum
{
    Param (
    [Collection] $Arr
    )
    
    $Enum = -1

    #Enumerate the resource group
    for ($i = 0; $i -le $Arr.Count - 1; $i++)
    {
       $Item = $Enum[$i]
    }
}
# ----- get-cmEnumResourceGroup -----

function global:get-cmEnumResourceGroup # Returns the ResourceGroup selected
{
    #Get-AzureRmNetworkInterface -ResourceGroupName cmRDSH2 | Format-List -Property Name,ResourceGroupName,Location
    #Write-Host "Start: get-cmEnumResourceGroup"
    $colRG = Get-AzureRmResourceGroup
    Write-Host $colRG  | Select-Object -Property ResourceGroupName, Location
    $EnumRG = -1

    # Enumerate the resource Group
    for($i=0; $i -le $colRG.Count - 1; $i++)
    {
        $RG = $colRG[$i]
        write-host $i, $RG.ResourceGroupName
    }

    write-host ""
    write-host "Enter the number of the resource group you would like to select. (Hit ENTER key to get ResourceGroup 0)"
    $RGNum = Read-Host
    $RGName = $colRG[$RGNum].ResourceGroupName
    

    #Write-Host 01 $colRG[$RGNum].ResourceGroupName
    foreach ($RG in $colRG)
    {
        if ($RG.ResourceGroupName -eq $RGName)
        {
            [Microsoft.Azure.Commands.ResourceManager.Cmdlets.SdkModels.PSResourceGroup]$ReturnResult = $RG
            #Write-Host 02 $RG.ResourceGroupName
        }
    }
    $ReturnResult
    if ($ReturnResult -eq $null) 
    {
        Write-Host "Resource Group Not Found, breaking"
        break
    }
    else 
    {
        if ($ReturnResult.Count -gt 1)
        {
            Write-Host 'More than 1 resource group was returned. Count = '$ReturnResult.Count'. Breaking'
            break
        }
        else
        {
            Write-Host 'Resource Group Found: "'$ReturnResult.ResourceGroupName'"'
        }
    }
    #Write-Host "End: get-cmEnumResourceGroup"
}


# ----- New-cmStorageAccount

function global:New-cmStorageAccount ([Parameter(Mandatory=$true)] [String]$RGName, [string]$StorageName = "cmpsstorageacct", $Kind = "Storage", $SkuName = "Standard_LRS", $RGLoc = "westus2")
{
    # Create a storage account
    NB $StorageName
    $goodName = Get-AzureRmStorageAccountNameAvailability $StorageName
    #write-host 'goodName.NameAvailable = "' $goodName.NameAvailable
    Start-Sleep 5
    if ($goodName.NameAvailable)
    {
        $RGStorageAccount = New-AzureRmStorageAccount -ResourceGroupName $RGName -Name $StorageName -Kind Storage -Location $RGLoc -SkuName "Standard_LRS"
    }
    else
    {
        Write-Host "The name $StorageName is not available, proceeding to get it from $RGName. We will break on error. It may be that the storage account is use in another ResourceGroup."
        $RGStorageAccount = Get-AzureRmStorageAccount -ResourceGroupName $RGName -Name $StorageName
        NB $RGStorageAccount
    }
    $RGStorageAccount
}


# ----- New-cmVNet -----
# This function just does the vnet and subnet pieces in one shot

Function global:New-cmVNet
{
    Param
    (   
        [Parameter(Mandatory=$true)] [String]$RGName, 
        [Parameter(Mandatory=$true)] [String]$VNetName, 
        [Parameter(Mandatory=$true)] [String]$SubnetName, 
        [String]$VNetAddressPrefix = "10.0.2.0/16", 
        [String]$SubnetAddressPrefix = "10.0.2.0/24",
        [String]$RGLoc = "westus2"
    )
    

    # Create a subnet
    $RGSubnet = New-AzureRmVirtualNetworkSubnetConfig -Name $SubnetName -AddressPrefix $SubnetAddressPrefix

    # Create a VNet
    $RGVnet = New-AzureRmVirtualNetwork -Name $VNetName -ResourceGroupName $RGName -Location $RGLoc -AddressPrefix $VNetAddressPrefix -Subnet $RGSubnet
    $RGVnet
}


# ----- get-cmValidOption ----- Utility

Function global:get-cmValidOption ($Arr, $PropName, $Default)
{    
    # Purpose: take and arrany, enumerate it, and allow the user to choose an element
    if ($Arr -eq $null) { Break }
    for($i=0; $i -le $Arr.Count - 1; $i++) { write-host $i, $Arr[$i] }
    Write-Host 'Please select a valid option from the list (hit Enter to pick option 0)'
    $Choice = Read-Host
    if ($Arr -eq $null) { Break }

    if ($ReturnResult.Count -gt 1)
    {
        Write-Host 'More than 1 resource group was returned. Count = '$ReturnResult.Count'. Returning the default'
        $Default
    }
    else
    {
        $Arr[$Choice]
    }
}

# ----- Get public ip -----

function global:New-cmPublicIP
{
    Param
    (   

        [Parameter(Mandatory=$true)] [String]$RGName, 
        [Parameter(Mandatory=$true)] $RGVnet, 
        [String]$RGLoc = "uswest2", 
        [String]$RGPublicIPName = "cmPSPublicIP",
        [String]$RGNicName = "cmPSNIC"
    )

# Create a Public IP
$RGPublicIP = New-AzureRmPublicIpAddress -Name $RGPublicIPName -ResourceGroupName $RGName -Location $RGLoc -AllocationMethod Dynamic

#write-host " $RGVnet.Subnets[0].Id = """ + $RGVnet.Subnets[0].Id

# Create a NIC
$RgNIC = New-AzureRmNetworkInterface -Name "cmPSNIC" -ResourceGroupName $RGName -Location $RGLoc -SubnetId $RGVnet.Subnets[0].Id -PublicIpAddressId $RGPublicIP.Id

}


# ----- CNull ----- Purpose: If null initialize to a value (need to test)
Function global:CNull($Anything, $ValueIfNull) { if ($Anything -eq $null) { $Anything = $ValueIfNull } else { $false } }

# ----- NB ----- Purpose: Break on null
Function global:NB ($Anything, $Message = "Breaking") { if ($Anything -eq $null) 
{ Write-Host $Message
break } }


# ----- Create a Load Balancer -----

function global:New-cmLoadBalancer
{
    Param
    (   

        [Parameter(Mandatory=$true)] [String]$RGName, 
        [Parameter(Mandatory=$true)] $RGVnet,
        $InputX = @{
            "FrontEndIpName" = "cmPsFrontEndIp"
            "FrontEndPrivateIp" = "10.0.0.5"
            "BackEndIpName" = "cmPsBackEndIp"
            "InboundNatRuleName1" = "cmPsInboundNatRdp1"
            "Inbound1FrontPort" = 3441
            "InboundNatRuleName2" = "cmPsInboundNatRdp2"
            "Inbound2FrontPort" = 3442
            "BackEndPort" = 3389
            "InboundProtocol" = "Tcp"
            "HealthProbeName" = "cmPsHealthProbe"
            "HealthProbeRequestPath" = "./"
            "HealthProbeProtocol" = "http"
            "HealthProbePort" = 80
            "HealthProbeIntervalInSeconds" = 15
            "HealthProbeProbeCount" = 2
            "LoadBalancerName" = "cmPsLoadBalancer"
            "LoadBalanceRuleName" = "cmPsLoadBalanceRule"
            "LoadBalanceProtocol" = "Tcp"
            "LoadBalanceFrontEndPort" = 80
            "LoadBalanceBackEndPort" = 80
            "BackEndNic1Name" = "cmpsbackendnic1"
            "BackEndPrivateIp1" = "10.0.0.6"
            "BackEndNic2Name" = "cmpsbackendnic2"
            "BackEndPrivateIp2" = "10.0.0.7"
            }
    )
    

    # ----- Create a Load Balancer ----- begin
    # https://docs.microsoft.com/en-us/azure/load-balancer/load-balancer-get-started-internet-arm-ps
    $ErrorActionPreference = "stop"
        $FrontEndIpName = $InputX.Item("FrontEndIpName") #"cmPsFrontEndIp" 
        $FrontEndPrivateIp = $InputX.Item("FrontEndPrivateIp") #"10.0.0.5"
        Write-Output '$RGFrontEndIp = New-AzureRmLoadBalancerFrontendIpConfig ...'
        $RGFrontEndIp = New-AzureRmLoadBalancerFrontendIpConfig -Name $FrontEndIpName -PrivateIpAddress $FrontEndPrivateIp -SubnetId $RGVnet.subnets[0].Id

        $BackEndIpName = $InputX.Item("BackEndIpName") #"cmPsBackEndIp"
        Write-Output '$RGBackEndAddressPool = New-AzureRmLoadBalancerBackendAddressPoolConfig ...'
        $RGBackEndAddressPool = New-AzureRmLoadBalancerBackendAddressPoolConfig -Name $BackEndIpName
        
        $InboundNatRuleName1 = $InputX.Item("InboundNatRuleName1") #"cmPsInboundNatRdp1"
        $Inbound1FrontPort = $InputX.Item("Inbound1FrontPort") #3441 
        $InboundNatRuleName2 = $InputX.Item("InboundNatRuleName2") #"cmPsInboundNatRdp2"
        $Inbound2FrontPort = $InputX.Item("Inbound2FrontPort") #3442
        $BackEndPort = $InputX.Item("BackEndPort") #3389
        $InboundProtocol = $InputX.Item("InboundProtocol") #"Tcp"
        Write-Host '$RGInboundNatRule1 = New-AzureRmLoadBalancerInboundNatRuleConfig ...'
        $RGInboundNatRule1 = New-AzureRmLoadBalancerInboundNatRuleConfig -Name $InboundNatRuleName1 -FrontendIpConfiguration $RGFrontEndIp -Protocol $InboundProtocol -FrontendPort $Inbound1FrontPort -BackendPort $BackEndPort
        WRite-host '$RGInboundNatRule2 = New-AzureRmLoadBalancerInboundNatRuleConfig ...'
        $RGInboundNatRule2 = New-AzureRmLoadBalancerInboundNatRuleConfig -Name $InboundNatRuleName2 -FrontendIpConfiguration $RGFrontEndIp -Protocol $InboundProtocol -FrontendPort $Inbound2FrontPort -BackendPort $BackEndPort

        $HealthProbeName = $InputX.Item("HealthProbeName") #"cmPsHealthProbe"
        $HealthProbeRequestPath = $InputX.Item("HealthProbeRequestPath") #"./"
        $HealthProbeProtocol = $InputX.Item("HealthProbeProtocol") #"http"
        $HealthProbePort = $InputX.Item("HealthProbePort") #80
        $HealthProbeIntervalInSeconds = $InputX.Item("HealthProbeIntervalInSeconds") #15
        $HealthProbeProbeCount = $InputX.Item("HealthProbeProbeCount") #2
        $LoadBalanceRuleName = $InputX.Item("LoadBalanceRuleName") #"cmPsLoadBalanceRule"
        $LoadBalanceProtocol = $InputX.Item("LoadBalanceProtocol") #"Tcp"
        $LoadBalanceFrontEndPort = $InputX.Item("LoadBalanceFrontEndPort") #80
        $LoadBalanceBackEndPort = $InputX.Item("LoadBalanceBackEndPort") #80
        write-host '$RGHealthProbe = New-AzureRmLoadBalancerProbeConfig'
        $RGHealthProbe = New-AzureRmLoadBalancerProbeConfig -Name $HealthProbeName -RequestPath $HealthProbeRequestPath -Protocol $HealthProbeProtocol -Port $HealthProbePort -IntervalInSeconds $HealthProbeIntervalInSeconds -ProbeCount $HealthProbeProbeCount
        Write-Host '$RGLoadBalanceRule = New-AzureRmLoadBalancerRuleConfig'
        $RGLoadBalanceRule = New-AzureRmLoadBalancerRuleConfig -Name $LoadBalanceRuleName -FrontendIpConfiguration $RGFrontEndIp -BackendAddressPool $RGBackEndAddressPool -Probe $RGHealthProbe -Protocol $LoadBalanceProtocol -FrontendPort $LoadBalanceFrontEndPort -BackendPort $LoadBalanceBackEndPort

        $LoadBalancerName = $InputX.Item("LoadBalancerName") #"cmPsLoadBalancer"
        write-host '$RGLoadBalancer = New-AzureRmLoadBalancer ...'
        $RGLoadBalancer = New-AzureRmLoadBalancer -ResourceGroupName $RGName -Name $LoadBalancerName -Location $locName -FrontendIpConfiguration $RGFrontEndIp -InboundNatRule $RGInboundNatRule1 -BackendAddressPool $RGBackEndAddressPool -Probe $RGHealthProbe

        $VnetBackEndSubnetName = $InputX.Item("VnetBackEndSubnetName") #$SubnetName
        Write-Host '$RGBackEndSubnet = Get-AzureRmVirtualNetworkSubnetConfig ...'
        $RGBackEndSubnet = Get-AzureRmVirtualNetworkSubnetConfig -Name $VnetBackEndSubnetName -VirtualNetwork $RGVnet
        $BackEndNic1Name = $InputX.Item("BackEndNic1Name") #"cmpsbackendnic1"
        $BackEndPrivateIp1 = $InputX.Item("BackEndPrivateIp1") #"10.0.0.6"
        Write-Host '$RGBackEndNic1 = New-AzureRmNetworkInterface ...'
        $RGBackEndNic1 = New-AzureRmNetworkInterface -ResourceGroupName $RGName -Name $BackEndNic1Name -Location $locName -PrivateIpAddress $BackEndPrivateIp1 -Subnet $RGBackEndSubnet -LoadBalancerBackendAddressPool $RGLoadBalancer.BackendAddressPools[0] -LoadBalancerInboundNatRule $RGLoadBalancer.InboundNatRules[0]
        $BackEndNic2Name = $InputX.Item("BackEndNic2Name") #"cmpsbackendnic2"
        $BackEndPrivateIp2 = $InputX.Item("BackEndPrivateIp2") #"10.0.0.7"
        Write-Host '$RGBackEndNic1 = New-AzureRmNetworkInterface ...'
        $RGBackEndNic1 = New-AzureRmNetworkInterface -ResourceGroupName $RGName -Name $BackEndNic2Name -Location $locName -PrivateIpAddress $BackEndPrivateIp2 -Subnet $RGBackEndSubnet -LoadBalancerBackendAddressPool $RGLoadBalancer.BackendAddressPools[0] -LoadBalancerInboundNatRule $RGLoadBalancer.InboundNatRules[1]

    $RGLoadBalancer
}

# SIG # Begin signature block
# MIIEMwYJKoZIhvcNAQcCoIIEJDCCBCACAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQU83mNX3swHYTBUCxbVgaMItnN
# H2ygggI9MIICOTCCAaagAwIBAgIQXqngHMtFJZBLvtKB5kMYmzAJBgUrDgMCHQUA
# MCwxKjAoBgNVBAMTIVBvd2VyU2hlbGwgTG9jYWwgQ2VydGlmaWNhdGUgUm9vdDAe
# Fw0xNzAyMDkxNzU3NDBaFw0zOTEyMzEyMzU5NTlaMBoxGDAWBgNVBAMTD1Bvd2Vy
# U2hlbGwgVXNlcjCBnzANBgkqhkiG9w0BAQEFAAOBjQAwgYkCgYEAxJMXSX2yDza4
# YoV7fYGLG+XE5KuXS17haubcZNNb85RbiguXlg8mOViEUalyEcEPdY5xfR1b62K7
# Jt3J82RlEfwnVtmin5EXW3hYOYRP87U/pkKiq1MHULcmKO2kReTQmMtJB7Lw7HMB
# g7bsaQzkOqzbgL38cMaowb/Kjo+VR+MCAwEAAaN2MHQwEwYDVR0lBAwwCgYIKwYB
# BQUHAwMwXQYDVR0BBFYwVIAQO7kzIfSp327hSz/mt29jcKEuMCwxKjAoBgNVBAMT
# IVBvd2VyU2hlbGwgTG9jYWwgQ2VydGlmaWNhdGUgUm9vdIIQrgjaQlc+9IhF3X9o
# nylYgTAJBgUrDgMCHQUAA4GBAAy7KZBYUA9VbxygZSoCQVZnjgDjcu5tmHnWxqhD
# OS2ZuMoMH38IO1D9fgqc2dvSANyVtvZ9KLPZcBvbos1yprogGvAIHZ5S2LEHvE1f
# cB8ygMkqEmCddMeT7nJx0rU5wUaG8FMB44nA676kC33HIabLVc1CQq7oU0JbR5BO
# j8IcMYIBYDCCAVwCAQEwQDAsMSowKAYDVQQDEyFQb3dlclNoZWxsIExvY2FsIENl
# cnRpZmljYXRlIFJvb3QCEF6p4BzLRSWQS77SgeZDGJswCQYFKw4DAhoFAKB4MBgG
# CisGAQQBgjcCAQwxCjAIoAKAAKECgAAwGQYJKoZIhvcNAQkDMQwGCisGAQQBgjcC
# AQQwHAYKKwYBBAGCNwIBCzEOMAwGCisGAQQBgjcCARUwIwYJKoZIhvcNAQkEMRYE
# FP/Xd/Jy3/1SgVawkb/BjQBSXTfJMA0GCSqGSIb3DQEBAQUABIGAAYH1XLSk498O
# +J6QhJ4IDggJ6iKl+4dEKC4nKWhHEMUTQEzVcoW+zRDllCJ2H94W/KMV/CtUHh3e
# uNQDc4Vt0xz9FYJAPO4uvuIAvBubKShU6WOLBqV5mvG1sAmthkB7CxQh5BSe4sbe
# b90kVx0drJ8h7omIcfEtdnIQRX+ir+o=
# SIG # End signature block
