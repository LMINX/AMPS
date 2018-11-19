<#
get monitor data from the server from the data center.
include hardware information and perfmance date
CPU/IO/network
log them into the database

how to draw the pickure?


test IO;
 do {add-Content -value "abc" -path d:\t3.txt} while($true)  
 each instance will increse about 30 IOPS request.
#>


function Get-Vmsize {
param(
[Parameter(Mandatory=$true,position=0)]
$computername
)

}

$func=
{
function Get-PerfData{
param(
[Parameter(Mandatory=$true,position=0)]
$computername,
[Parameter(Mandatory=$false,position=1)]
$PerfCounters=("\Processor(_Total)\% Processor Time","\LogicalDisk(_Total)\Disk Transfers/sec","\LogicalDisk(_Total)\Disk Bytes/sec", "\network interface(microsoft hyper-v network adapter)\Bytes Total/sec")
)

$perf=Get-Counter -ComputerName $computername -Counter $PerfCounters
$time=$perf.timestamp
foreach ($sample in $perf.CounterSamples)
    {
        $metric=switch -Wildcard ($sample.path) 
        {
        '*\Processor(_Total)\% Processor Time'{'cpu'}
        '*\LogicalDisk(_Total)\Disk Transfers/sec'{'diskIORequest'}
        '*\LogicalDisk(_Total)\Disk Bytes/sec'{'diskIOThrought'}
        '*\network interface(microsoft hyper-v network adapter)\Bytes Total/sec'{'NetworkThrought'}
        }
        $value=$sample.CookedValue
        $dBParams=@(
         "computername='$computername'",
         "time='$time'"
         "metric='$metric'"
         "value=‘$value'"
        )
        Invoke-Sqlcmd  -Username sa -Password acsopsL2 "insert into sgdc.dbo.perf values ('$computername','$metric',$value,'$time')" -Variable $dBParams
        
    }
#Get-Counter -ComputerName r4wappp076 -Counter  "\Processor(_Total)\% Processor Time" -SampleInterval 60 -Continuous      //CPU Usage
#Get-Counter -ComputerName r4wappp076 -Counter  "\LogicalDisk(_Total)\Disk Transfers/sec" -SampleInterval 60 -Continuous //IO request per second
#Get-Counter -ComputerName r4wappp076 -Counter  "\LogicalDisk(_Total)\Disk Bytes/sec" -SampleInterval 60 -Continuous//IO throughtput per second
#Get-Counter -ComputerName r4wappp076 -Counter  "\Network Interface(total)\Bytes Total/sec" -SampleInterval 10 -Continuous //network throughput per second
}
#Get-PerfData -computername R4wappp003
}

$computernames=Get-Content "C:\script\SGDC-Migration\computers.txt"
do
{
    foreach ($computername in $computernames)
    {
    Start-Job -ScriptBlock {param($computername) Get-PerfData -computername $computername} -InitializationScript $func -ArgumentList ($computername)
    }
    Start-Sleep 300
}
while ($true)
