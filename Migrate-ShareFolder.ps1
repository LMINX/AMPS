<#
Date:2019/02/12
Version:0.1
Authon:George Liu
Descripton:use this script to migrate the share folder from the old server to new server
Detail: 
1.get all the share folder from the source server and classify them by share type； public share folder,user home share(shared name with $),ohter and summary their size or 
the number of subfolders, last access time.

2. foreach share folder
create the same share in the new server with the same permission according to the old server. 
trigger the initial robocopy for sync folder by size disorder
3.log the process of the copy procdure
4. stop the old share and trigger the final copy
#>

function summary-servershare{
    [CmdletBinding()]
    param (
          [Parameter(Mandatory=$true,position=0)]
          $Computername,
          [Parameter(Mandatory=$true,position=1)]
          #[System.Management.ManagementObject#root\cimv2\Win32_Share]
          $Win32_shareObject
          #[Parameter(Mandatory=$true,position=1)]
          #$Sharename，
          #[Parameter(Mandatory=$false,position=2)]
          #$SharePath  
    )
    
    if ($Win32_shareObject.type -eq 0)
    {
        #this is share folder ,summary the size
        #Start-Job -ScriptBlock {param($path) summary-folder -path $path} -InitializationScript $func -ArgumentList ($path)
        "start"
        #invoke-command -computername $computername -ScriptBlock ${Function:summary-folder}  -ArgumentList $Win32_shareObject.path
        invoke-command -computername $computername -ScriptBlock {C:\temp\summary-folder.ps1 $args[0]}  -ArgumentList $Win32_shareObject.path
        "end"
    }

    }



function get-sharefolder {
      <#
  .SYNOPSIS
  Get the all share folder infomation from 1 server
  .DESCRIPTION
  Get all the share folder from the source server and classify them by share type； public share folder,user home share(shared name with $),ohter and summary their size or 
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

$as=get-sharefolder -Computername seoul-svr-01
summary-servershare -Computername seoul-svr-01 -Win32_shareObject $as[3] 


