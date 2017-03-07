# Add-VmBasic function used to create DevApi environment

# ----- prep stuff -----
#Install-Module AzureAutomationAuthoringToolkit -Scope AllUsers    
#Fancy line of code used by azure automation ISE add-on
#$RunAsConnection = Get-AutomationConnection -Name AzureRunAsConnection;try {$Login=Add-AzureRmAccount -ServicePrincipal -TenantId $RunAsConnection.TenantId -ApplicationId $RunAsConnection.ApplicationId -CertificateThumbprint $RunAsConnection.CertificateThumbprint -ErrorAction Stop}catch{Sleep 10;$Login=Add-AzureRmAccount -ServicePrincipal -TenantId $RunAsConnection.TenantId -ApplicationId $RunAsConnection.ApplicationId -CertificateThumbprint $RunAsConnection.CertificateThumbprint};Select-AzureRmSubscription -SubscriptionId $RunAsConnection.SubscriptionID

# ----- starting -----
cd $PSScriptRoot # set the current directory to the directory of this script
#Remove-Module .\Create-vm.psm1
Import-Module .\Create-Vm.psm1
get-command -Module Create-Vm

# ----- Load Variables -----
$H = get-HashFromJson -SettingsPath .\Settings_Environment.json
$H = get-HashFromJson -Hash $H -SettingsPath .\Settings.json

Add-VmBasic -H $H
