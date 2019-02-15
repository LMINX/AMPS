<#
Date:2019/02/12
Version:0.1
Authon:George Liu
Descripton:use this script to migrate the share folder from the old server to new server
Detail: 
1.get all the share folder from the source server and classify them by share typeï¼?public share folder,user home share(shared name with $),ohter and summary their size or 
the number of subfolders, last access time.

2. foreach share folder
create the same share in the new server with the same permission according to the old server. 
trigger the initial robocopy for sync folder by size disorder
3.log the process of the copy procdure
4. stop the old share and trigger the final copy
#>
$global:remotepssessioncount=0
function summary-servershare{
    [CmdletBinding()]
    param (
          [Parameter(Mandatory=$true,position=0)]
          $Computername,
          [Parameter(Mandatory=$true,position=1)]
          #[System.Management.ManagementObject#root\cimv2\Win32_Share]
          $Win32_shareObject
          #[Parameter(Mandatory=$true,position=1)]
          #$Sharenameï¼?
          #[Parameter(Mandatory=$false,position=2)]
          #$SharePath  
    )

    if ($Win32_shareObject.type -eq 0){
        #this is share folder ,summary the size
        #Start-Job -ScriptBlock {param($path) summary-folder -path $path} -InitializationScript $func -ArgumentList ($path)
        #invoke-command -computername $computername -ScriptBlock ${Function:summary-folder}  -ArgumentList $Win32_shareObject.path
        #invoke-command -computername $computername -ScriptBlock {C:\temp\summary-folder.ps1 $args[0]}  -ArgumentList $Win32_shareObject.path
        if($global:remotepssessioncount%100 -eq 0 -and $global:remotepssessioncount -ne 0)
        {
        "remotepssessioncount is $global:remotepssessioncount"
        Start-Sleep 60
        }
        $job=invoke-command -computername $computername -ScriptBlock {C:\temp\summary-folder.ps1 $args[0]}  -ArgumentList $Win32_shareObject.path -asjob 
        $global:remotepssessioncount++


        $global:alljobs+=$job
        #$alljobids+=$job.id
        
    }
    elseif ($Win32_shareObject.type -eq 1) {
        write-host "sharePrinter:$Win32_shareObject.Name"
    }
    elseif($Win32_shareObject.type -notin (2,3)){
        write-host "localPrinter:$Win32_shareObject.Name"
    
    }

    }



function get-sharefolder {
      <#
  .SYNOPSIS
  Get the all share folder infomation from 1 server
  .DESCRIPTION
  Get all the share folder from the source server and classify them by share typeï¼?public share folder,user home share(shared name with $),ohter and summary their size or 
  the number of subfolders, last access time.
  gwmi -class win32_share to query all the share (including default share ,such as c$ ,admin$,share folder which type is 0, share priter which type is 1)
  .EXAMPLE
  get-sharefolder -computer shareserver

  .PARAMETER computername
  The computer name to query. Just one.

  #>
    [CmdletBinding()]
    param (
          [Parameter(Mandatory=$true,position=0)]
          $Computername
    )
    try {
        $servershare=get-WmiObject -class Win32_Share -computer $Computername -ErrorAction Stop
        #get each share folder summary in parallel
        $servershare
    }
    catch {
        $errorcode=$_.Exception.Message+'`n'+$error[-1].InvocationInfo.positionmessage
        "unable to get server share from $computername with errocode"+'`n'+$errorcode
    }
    finally {
        
    }
}

$starttime=Get-Date

$as=get-sharefolder -Computername seoul-svr-01

$global:alljobs=@()
    $results=@()

foreach ($s in $as){
summary-servershare -Computername seoul-svr-01 -Win32_shareObject $s
}


$jobnotcompleted=$true
    while ($jobnotcompleted){
        foreach( $job in $global:alljobs){
            $job=get-job -id $job.id
            if ($job.state -eq 'Running')
            {
            $job.id
            $job.Command
            Start-Sleep -Seconds 5
                break
            }
            
            $jobnotcompleted=$false
        }
    }


foreach ($j in $global:alljobs)
{

$results+=receive-job -Job $j -keep
}
$endtime=Get-Date
"total runtime is $(($endtime-$starttime).totalseconds) seconds"
$results.Count
#$results
#$global:alljobs|receive-job 

    
