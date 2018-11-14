﻿<#find who login the server in last week from Security Log or RDP session LOG -done 11.08 function Get-LastlogonUser

#find which connection that server connect to --user netstat
1 use netstat -anbo to get the process/network information
2 use tasklist or get-process to get all the process
3 get the processs name (which showed Can not obtain ownership information) by match the PID 
4 show all the incoming /outcomming connection


#find which application was installed on that server  --
#find task schedule 
#last reboot time and operaot 
#find ticket in Snow and get the appowner
#find recond in bulecat 
#installed patch list
#find dns name relate to the server maybe it is the website, applictio name
#if you were the app owenr /uer ,what will you do on server 
1 check application log
2 configure/deploy services
3 troubleshot issue
4 login application

#>




function Get-LastlogonUser
{
  <#
  .SYNOPSIS
  Get the user logon activity from windows secrity log in a timeframe
  .DESCRIPTION
  Get enent id 4624 which indicate a user login.
    Logon Type 2 – Interactive
    This is what occurs to you first when you think of logons, that is, a logon at the console of a computer. You’ll see type 2 logons when a user attempts to log on at the local keyboard and screen whether with a domain account or a local account from the computer’s local SAM. To tell the difference between an attempt to logon with a local or domain account look for the domain or computer name preceding the user name in the event’s description. Don’t forget that logon’s through an KVM over IP component or a server’s proprietary “lights-out” remote KVM feature are still interactive logons from the standpoint of Windows and will be logged as such. 

    Logon Type 3 – Network
    Windows logs logon type 3 in most cases when you access a computer from elsewhere on the network. One of the most common sources of logon events with logon type 3 is connections to shared folders or printers. But other over-the-network logons are classed as logon type 3 as well such as most logons to IIS. (The exception is basic authentication which is explained in Logon Type 8 below.)

    Logon Type 4 – Batch
    When Windows executes a scheduled task, the Scheduled Task service first creates a new logon session for the task so that it can run under the authority of the user account specified when the task was created. When this logon attempt occurs, Windows logs it as logon type 4. Other job scheduling systems, depending on their design, may also generate logon events with logon type 4 when starting jobs. Logon type 4 events are usually just innocent scheduled tasks startups but a malicious user could try to subvert security by trying to guess the password of an account through scheduled tasks. Such attempts would generate a logon failure event where logon type is 4. But logon failures associated with scheduled tasks can also result from an administrator entering the wrong password for the account at the time of task creation or from the password of an account being changed without modifying the scheduled task to use the new password.

    Logon Type 5 – Service
    Similar to Scheduled Tasks, each service is configured to run as a specified user account. When a service starts, Windows first creates a logon session for the specified user account which results in a Logon/Logoff event with logon type 5. Failed logon events with logon type 5 usually indicate the password of an account has been changed without updating the service but there’s always the possibility of malicious users at work too. However this is less likely because creating a new service or editing an existing service by default requires membership in Administrators or Server Operators and such a user, if malicious, will likely already have enough authority to perpetrate his desired goal.

    Logon Type 7 – Unlock
    Hopefully the workstations on your network automatically start a password protected screen saver when a user leaves their computer so that unattended workstations are protected from malicious use. When a user returns to their workstation and unlocks the console, Windows treats this as a logon and logs the appropriate Logon/Logoff event but in this case the logon type will be 7 – identifying the event as a workstation unlock attempt. Failed logons with logon type 7 indicate either a user entering the wrong password or a malicious user trying to unlock the computer by guessing the password.

    Logon Type 8 – NetworkCleartext
    This logon type indicates a network logon like logon type 3 but where the password was sent over the network in the clear text. Windows server doesn’t allow connection to shared file or printers with clear text authentication. The only situation I’m aware of are logons from within an ASP script using the ADVAPI or when a user logs on to IIS using IIS’s basic authentication mode. In both cases the logon process in the event’s description will list advapi. Basic authentication is only dangerous if it isn’t wrapped inside an SSL session (i.e. https). As far as logons generated by an ASP, script remember that embedding passwords in source code is a bad practice for maintenance purposes as well as the risk that someone malicious will view the source code and thereby gain the password.

    Logon Type 9 – NewCredentials
    If you use the RunAs command to start a program under a different user account and specify the /netonly switch, Windows records a logon/logoff event with logon type 9. When you start a program with RunAs using /netonly, the program executes on your local computer as the user you are currently logged on as but for any connections to other computers on the network, Windows connects you to those computers using the account specified on the RunAs command. Without /netonly Windows runs the program on the local computer and on the network as the specified user and records the logon event with logon type 2.

    Logon Type 10 – RemoteInteractive
    When you access a computer through Terminal Services, Remote Desktop or Remote Assistance windows logs the logon attempt with logon type 10 which makes it easy to distinguish true console logons from a remote desktop session. Note however that prior to XP, Windows 2000 doesn’t use logon type 10 and terminal services logons are reported as logon type 2.

    Logon Type 11 – CachedInteractive
    Windows supports a feature called Cached Logons which facilitate mobile users. When you are not connected to the your organization’s network and attempt to logon to your laptop with a domain account there’s no domain controller available to the laptop with which to verify your identity. To solve this problem, Windows caches a hash of the credentials of the last 10 interactive domain logons. Later when no domain controller is available, Windows uses these hashes to verify your identity when you attempt to logon with a domain account.
  .EXAMPLE
  Give an example of how to use it
  .EXAMPLE
  Give another example of how to use it
  .PARAMETER computername
  The computer name to query. Just one.
  .PARAMETER logname
  The name of a file to write failed computer names to. Defaults to errors.txt.
  #>
  [CmdletBinding()]
param 
    (
    [Parameter(Mandatory=$true,position=0)]
    $Computername,
    [Parameter(Mandatory=$true,position=1)]
        [ValidateSet(
            "last 2 days",
            "last 7 days",
            "last 15 days",
            "last 30 days")
        ]
    $Timeframe,
    [Parameter(Mandatory=$false,position=2,ParameterSetName='Sec')]
            [ValidateSet(
            "2",
            "3",
            "4",
            "5",
            "5",    
            "7",  
            "8",   
            "9",   
            "10",   
            "11"   
               )
        ]
    $logontype,
    [Parameter(Mandatory=$True,position=3,ParameterSetName='Sec')]
    [switch] $SecurityLOG,
    [Parameter(Mandatory=$True,position=3,ParameterSetName='RDP')]
    [switch] $RDPLog
            )
    
begin
{
$now=Get-Date
$hour=$now.Hour
$min=$now.minute
$sec=$now.Second
$msec=$now.Millisecond
$diffday=$Timeframe.split(" ")[1]

$Starttime=$now.AddDays(-1*$diffday).AddHours(-1*$hour).AddMinutes(-1*$min).AddSeconds(-1*$sec).AddMilliseconds(-1*$msec)

}
process
{
#perf slow ,try to use invoke
#Get-EventLog -ComputerName $Computername -After $Starttime -LogName $Logname
#
 
$entries=@()
if ($SecurityLOG)
{
$Logname="Security"
$msgs=Get-WinEvent -ComputerName $Computername -FilterHashtable @{Logname=$Logname; ID=@(4624);StartTime=$Starttime}| select-object TimeCreated,ID,Message
 
    foreach($msg in $msgs)
    {
    $log=$msg.message.Split("`n")
        foreach($l in $log)
        {
        if ($l -match "Logon Type:"){$loginType=$l.split(":")[1].trim()}
        elseif ($l -match "Account Name:"){$accountName=$l.split(":")[1].trim()}
        elseif ($l -match "Source Network Address:"){$souceNetworkAddress=,$l.split(":")[1].trim()}
        elseif ($l -match "Logon Process:"){$logonProcess=$l.split(":")[1].trim()}     
        
        $Object = New-Object PSObject -Property @{            
        LogonType              = $loginType                 
        AccountName            = $accountName  
        SourceNetworkAddress   = $souceNetworkAddress  
        LogonProcess           = $logonProcess
        TimeGenerated          =$msg.TimeCreated
        }
        $entries+=$Object
        }

        
    }

}
elseif ($RDPLog)
{
$Logname="Microsoft-Windows-TerminalServices-LocalSessionManager/Operational"
$msgs=Get-WinEvent -ComputerName $Computername -FilterHashtable @{Logname=$Logname; ID=@(21);StartTime=$Starttime}| select-object TimeCreated,ID,Message

    foreach($msg in $msgs)
    {
    $log=$msg.message.Split("`n")
        foreach($l in $log)
        {
        if ($l -match "User:"){$user=$l.split(":")[1].trim()}
        elseif ($l -match "Session ID:"){$sessionid=$l.split(":")[0].trim(),$l.split(":")[1].trim()}
        elseif ($l -match "Source Network Address:"){$souceNetworkAddress=$l.split(":")[0].trim(),$l.split(":")[1].trim()}
        $Object = New-Object PSObject -Property @{            
        User                 = $user                 
        SessionID            = $sessionid  
        SourceNetworkAddress = $souceNetworkAddress 
        TimeGenerated        =$msg.TimeCreated
                        
        }
        $entries+=$Object
        }
    }
}
}
end
{
return $entries
}
}


function Get-NetworkConnection
{

    $netstat=netstat -anbo


    $rules=@()
    
    $talbehead="  Proto  Local Address          Foreign Address        State           PID"
    if ($netstat -contains $talbehead)
    {
    $startline=$netstat.IndexOf($talbehead)
    for ($rulestart=$startline+1;$rulestart -le 20;$rulestart++)
    {
    $rulegroup=""
    
        for($ruleend=$rulestart+1;$ruleend -le 20;$ruleend++)
        {
        if (($netstat[$ruleend] -match "TCP|UPD") -and ($netstat[$ruleend-1]) -match "\[*\]")
        {
            $i=$rulestart
            $j=$ruleend 
            for ($i;$i -lt $j;$i++)
            {
            if ($i -ne $j-1)
            {
        
            $rulegroup+=$netstat[$i]
            $rulegroup+="`n"
            }
            else
            {
           
            $rulegroup+=$netstat[$i]
            }
            }
            #write "rulegroup is $rulegroup"
            $rules+=$rulegroup
            $rulestart=$ruleend-1
        break
        }
    
        }
    
    }
    
    }
    else 
    {
    "throw expectioin"
    }
    


}