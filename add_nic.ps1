<# 
Author: Rongwei Jiang
Note: This powershell is to add NIC to VM. All required parameter will be read through typing.
Note: Need to specify target NIC's group name and VM's group name.
Next plan: For bulk change.

Parameter
	$VM = Name of virtual machine
	$NICName = Name of target NIC
	$NICRG = New NIC's group
	$VMRG = Virtual machine's group
	$VirtualMachine = Virtual machine's properties
#>

###Connect to Azure###
Import-Module azurerm
Login-AzureRmAccount -Subscription 'ap-prod-01'

###Input VM's name, target NIC name, Resource group name###
Write-Host "Please enter VM's name:" -ForegroundColor Green
$VM = Read-Host
Write-Host "VM name is: $VM" -ForegroundColor Green

Write-Host "Please enter target NIC's Resource Group's name:" -ForegroundColor Green
$NICRG = Read-Host
Write-Host "Target NIC Resource Group name is: $NICRG" -ForegroundColor Green

Write-Host "Please enter VM's Resource Group's name:" -ForegroundColor Green
$VMRG = Read-Host
Write-Host "VM Resource Group name is: $VMRG" -ForegroundColor Green

Write-Host "Please enter target NIC name:" -ForegroundColor Green
$NICName = Read-Host
Write-Host "NIC name is: $NICname" -ForegroundColor Green

Write-Host "Please enter existing NIC name:" -ForegroundColor Green
$Oldnic = Read-Host
Write-Host "NIC name is: $Oldnic" -ForegroundColor Green

###Check VM and target NIC###
Get-AzureRmNetworkInterface -ResourceGroupName $NICRG -Name $NICName |select Name,ID
Get-AzureRmVM -ResourceGroupName $VMRG -Name $VM |select Name,NIC

###Dellocate VM###
Stop-AzureRmVM -Name $VM -ResourceGroupName $VMRG -Confirm:$false -force
Write-Host "$VM is deallocated !" -ForegroundColor yellow

###Get target NIC###
$ID = Get-AzureRmNetworkInterface -ResourceGroupName $NICRG -Name $NICName
$ID.id

###Add target NIC and remove old NIC###
$VirtualMachine = Get-AzureRmVM -ResourceGroupName $VMRG -Name $VM
Add-AzureRmVMNetworkInterface -VM $VirtualMachine -Id $ID.id | Update-AzureRmVM
$VirtualMachine = Get-AzureRmVM -ResourceGroupName $VMRG -Name $VM
$VirtualMachine.NetworkProfile.NetworkInterfaces.Item(0).primary = $false
$VirtualMachine.NetworkProfile.NetworkInterfaces.Item(1).primary = $true
Update-AzureRmVM -ResourceGroupName $VMRG -VM $VirtualMachine
$VirtualMachine = Get-AzureRmVM -ResourceGroupName $VMRG -Name $VM
$VirtualMachine.NetworkProfile.NetworkInterfaces

$nicId = (Get-AzureRmNetworkInterface -ResourceGroupName $VMRG -Name $Oldnic).Id 
Remove-AzureRmVMNetworkInterface -VM $VirtualMachine -NetworkInterfaceIDs $nicId | Update-AzureRmVm -ResourceGroupName $vmrg

###Start VM###
Start-AzureRmVM -Name $VM -ResourceGroupName $VMRG
