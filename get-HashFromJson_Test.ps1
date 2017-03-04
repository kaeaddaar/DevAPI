#if ((Read-Host "Enter Y to import .\Create-vm.psm1") -eq "Y") { Import-Module .\Create-Vm.psm1 }
Import-Module .\Create-Vm.psm1

Write-Output ("Path of this script is " + ($PSScriptRoot))
cd $PSScriptRoot
# Test: you should see the va1, var2, plus the Settings from both files displayed
$Hash = @{"var1"="val1"; "var2"="Val2"}
$H1 = get-HashFromJson -Hash $Hash -SettingsPath ".\Test\get-HashFromJson\Settings_Environment.json"
$H1 = get-HashFromJson -Hash $H1 -SettingsPath ".\Test\get-HashFromJson\Settings.json"
$H1

#Write-Output -InputObject " ----- Writing Test File .\get-HashFromJson_test.txt -----"
#$H1 | ConvertTo-Json | Out-File -FilePath .\get-HashFromJson_test.txt
#Remove the old test file
#remove-item -Path ".\Test\get-HashFromJson\get-HashFromJson_ExpectedResults.txt"

Write-Output -InputObject " ----- Begin compare of settings to the expected results -----"
$H2 = Get-Content -Path ".\Test\get-HashFromJson\get-HashFromJson_ExpectedResults.txt" | ConvertFrom-Json
$H1 = $H1 | ConvertTo-Json | ConvertFrom-Json
$H2.psobject.Properties | % {if ($_.Value -ne $H1.psobject.Properties.Item($_.Name).Value) { Write-Output ("fail on " + $_.Name + " of expected value " + $_.Value + " not equal to " + $H1.psobject.Properties.Item($_.Name).Value) } }

Write-Output "If no fail messages, then test was a success"

