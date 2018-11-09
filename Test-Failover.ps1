<#
Author:George Liu
Descriptioin: this script is used to do the failover the on primise VM to Azure from HypverV 
Date:2018/10/15
1 Check the VM status :ASR Status ,DNS Status
2 


#>


function Update-DNS 
{
param(
[Parameter(Mandatory=$true,position=0)]
$computername,
[Parameter(Mandatory=$false,position=1)]
$IPAddress
)
#update the DNS for the host by blue cat DNS


}


function Check-ASR
{

param(
[Parameter(Mandatory=$true,position=0)]
$computername,
[Parameter(Mandatory=$true,position=1)]
[ValidateSet(
            "eu-prod-01",
            "us-prod-01",
            "us-nonprod-01",
            "az-sandbox-01",
            "eu-nonprod-01",
            "ap-nonprod-01",
            "ap-prod-01",
            "Pay-In-Advance"
             )]
$Subscription="ap-prod-01",
[Parameter(Mandatory=$true,position=2)]
[ValidateSet(
            "AZAP-VAULT-ASR-01",
            "ASRCN"
             )]
$ASRRecoveryServicesVaultsName="AZAP-VAULT-ASR-01",


[Parameter(Mandatory=$false)]
[switch] $ChinaAzure
)

#Set-AzureRmContext -Subscription ap-prod-01
try
{
    if($ChinaAzure)
    {Login-AzureRmAccount -SubscriptionName  $Subscription -Environment "AzureChinaCloud"  >$null}
    else
    {Login-AzureRmAccount -SubscriptionName  $Subscription  >$null}

    #null exception 
    $ASRVault=Get-AzureRmRecoveryServicesVault -Name $ASRRecoveryServicesVaultsName
    if ($ASRVault -ne $null)
    {
        $VaultFileLocation=Get-AzureRmRecoveryServicesVaultSettingsFile -SiteRecovery -Vault $ASRVault
        Import-AzureRmRecoveryServicesAsrVaultSettingsFile -Path $VaultFileLocation.FilePath  >$null
        $Fabrics = Get-AzureRmRecoveryServicesAsrFabric
            foreach ($Fabric in $Fabrics)
            {
            $Containers = Get-AzureRmRecoveryServicesAsrProtectionContainer -Fabric $Fabric
                foreach ($Container in $Containers)
                {
                $items = Get-AzureRmRecoveryServicesAsrReplicationProtectedItem -ProtectionContainer $Container
                if ($items -is [array])
                {$itemcount=1}
                else
                {$itemcount=$items.count}
                $count=0
                    foreach ($item in $items)
                    {   
                    $count++          
                        if ($item.RecoveryAzureVMName -eq $computername)
                        {
                        $ASRStatus=$item.ReplicationHealth.ToString()
                        Write-Host $computername":"$ASRStatus
                        return $item
                        break
                        }
                        if ($count -eq $itemcount)
                        {
                        return $null
                        break
                        }

                    }
                }
            }
      }
      else
      {Write-Host -ForegroundColor red "unable to find the ASRRecoveryServicesVault"}
}
Catch
{
    $ErrorMessage = $_.Exception.Message
    $FailedItem = $_.Exception.ItemName
    Write-Host -ForegroundColor red $ErrorMessage+$FailedItem
}

}


function Test-FailoverOnSchedule
{
[CmdletBinding()]
param(
[Parameter(Mandatory=$true,position=0)]
$computername,
[Parameter(Mandatory=$true,position=1)]
[ValidateSet(
            "eu-prod-01",
            "us-prod-01",
            "us-nonprod-01",
            "az-sandbox-01",
            "eu-nonprod-01",
            "ap-nonprod-01",
            "ap-prod-01",
            "Pay-In-Advance"
             )]
$Subscription="ap-prod-01",
[Parameter(Mandatory=$true,position=2)]
[ValidateSet(
            "AZAP-VAULT-ASR-01",
            "ASRCN"
             )]
$ASRRecoveryServicesVaultsName="AZAP-VAULT-ASR-01",


[Parameter(Mandatory=$false)]
[switch] $ChinaAzure
)

DynamicParam
{
$attributes = new-object System.Management.Automation.ParameterAttribute
$attributes.ParameterSetName = "__AllParameterSets"
$attributes.Mandatory = $true
$attributeCollection =new-object -Type System.Collections.ObjectModel.Collection[System.Attribute]
$_Values=(Get-AzureRmVirtualNetwork).name
if ($_Values -eq $null)
{
$_Values=("ASRNet","NKE-CDT-SNG-VNET-01","n7-vnet-01")
}   
$attributeCollection.Add($attributes)      
$ValidateSet=new-object System.Management.Automation.ValidateSetAttribute($_Values)
$attributeCollection.Add($ValidateSet)  
$dynParam1=new-object -Type System.Management.Automation.RuntimeDefinedParameter("Vnet", [string], $attributeCollection)
$paramDictionary=new-object -Type System.Management.Automation.RuntimeDefinedParameterDictionary
$paramDictionary.Add("Vnet", $dynParam1)
return $paramDictionary 
}



begin
{
    if($ChinaAzure)
    {Login-AzureRmAccount -SubscriptionName  $Subscription -Environment "AzureChinaCloud"  >$null}
    else
    {Login-AzureRmAccount -SubscriptionName  $Subscription  >$null}

}
process
{
    try
    {
    $TFOVnet=Get-AzureRmVirtualNetwork| where {$_.name -eq $_Values}

    $ASRVault=Get-AzureRmRecoveryServicesVault -Name $ASRRecoveryServicesVaultsName
    if ($ASRVault -ne $null)
    {
        $VaultFileLocation=Get-AzureRmRecoveryServicesVaultSettingsFile -SiteRecovery -Vault $ASRVault
        Import-AzureRmRecoveryServicesAsrVaultSettingsFile -Path $VaultFileLocation.FilePath >$null
        $Fabrics = Get-AzureRmRecoveryServicesAsrFabric
            foreach ($Fabric in $Fabrics)
            {
            $ASRFabric=$Fabric
            $Containers = Get-AzureRmRecoveryServicesAsrProtectionContainer -Fabric $Fabric 
                foreach ($Container in $Containers)
                {
                $items = Get-AzureRmRecoveryServicesAsrReplicationProtectedItem -ProtectionContainer $Container
                if ($items -is [array])
                {$itemcount=1}
                else
                {$itemcount=$items.count}
                $count=0
                    foreach ($item in $items)
                    {   
                    $count++          
                        if ($item.RecoveryAzureVMName -eq $computername)
                        {
                        $ASRStatus=$item.ReplicationHealth.ToString()
                        Write-Host $computername":"$ASRStatus
                        $ReplicationProtectedItem=$item

                        break
                        }
                        if ($count -eq $itemcount)
                        {
                        $ReplicationProtectedItem=$null
                        throw "unable to find the replication item for server $computername"
                        }

                    }
                }
            }  
      }
      else
      {throw  "unable to find the ASRRecoveryServicesVault $ASRRecoveryServicesVaultsNam"}
      $Vnet=($PSBoundParameters.Vnet)
      #$TFOVnet=Get-ASRNetwork -FriendlyName $Vnet -Fabric $ASRFabric -Verbose
      $TFOVnet =Get-AzureRmVirtualNetwork |where {$_.name -eq $Vnet}
      $TFONetwork= $TFOVnet.Id
      $TFOJob = Start-ASRTestFailoverJob -ReplicationProtectedItem $ReplicationProtectedItem -AzureVMNetworkId $TFONetwork -Direction PrimaryToRecovery
      #Start the failover job
      #$Job_Failover = Start-ASRUnplannedFailoverJob -ReplicationProtectedItem $ReplicationProtectedItem -Direction PrimaryToRecovery -RecoveryPoint $RecoveryPoints[-1]
      $Job_StartTime=get-date
      do {
          $Job_ProcessTime=get-date 
          $Job_Failover = Get-ASRJob -Job $TFOJob;
          $RunningTime=($Job_ProcessTime-$Job_StartTime).TotalSeconds
          Write-Host "job (start at $Job_StartTime) has been running for $RunningTime seconds"
          sleep 30
          ;
      } while (($Job_Failover.State -eq "InProgress") -or ($JobFailover.State -eq "NotStarted"))
      $JobObject=Get-ASRJob -Job $TFOJob
      if ($JobObject.State -eq 'Succeeded')
      {
      $FinishTime=($JobObject.EndTime-$JobObject.StartTime).TotalSeconds
      Write-Host -ForegroundColor green "ASR job (start at $JobObject.StartTime) took for $FinishTime seconds to finish"
      }
      else 
      {
      Write-Host -ForegroundColor red "job failed due to $JobObject.StateDescription"
      #rollback
      }  
    }
    Catch
    {
        $ErrorMessage = $_.Exception.Message
        $FailedItem = $_.Exception.ItemName
        Write-Host -ForegroundColor red $ErrorMessage+$FailedItem
    }
}

end 
{

}


} 