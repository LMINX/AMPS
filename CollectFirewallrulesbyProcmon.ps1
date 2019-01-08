$Servers=("r4wappp024","r4wappp025","r4wappp054","r4wappp026","r4wappp027","r4wappp028","r4wappp096","R4WAPPP135","r4wsqlp-bi")
$Servers=("r4wappp135")
$secpasswd = ConvertTo-SecureString "airobot%TGB^YHN&UJM8" -AsPlainText -Force
$mycreds = New-Object System.Management.Automation.PSCredential ("nike\sa.gliu10", $secpasswd)
$jobs=@()
foreach ($s in $servers)
{
if($s -eq "r4wsqlp001")
{$Dest="\\$s\c$\"}
else
{$Dest="\\$s\c$\"}

#copy-item -Path C:\users\sa.gliu10\Desktop\PMtools  -Destination  $Dest -Recurse
$job=Start-Job -ScriptBlock {copy-item -Path C:\users\sa.gliu10\Desktop\PMtools  -Destination  $args[0] -Recurse } -Credential $mycreds -ArgumentList $Dest 
$jobs+=($job)


$flag=0
while ($flag -lt $Servers.count)
{
foreach ($job in $jobs)
    {

    $j=get-job $job.id
    if ($j.State -in ("Failed","completed"))
        {
        $flag+=1
        }
    }
}
$PSexecPath="c:\PMtools\pstools\PsExec.exe"
$PMPath="C:\PMtools\ProcessMonitor\procmon.exe"
$filename=get-date -Format "yyyy-MM-dd-HHmm"
$duration=3600
$fullfilename=$filename+"L"+$duration
Write-Host -ForegroundColor Green "server is $s"
if ($s -eq "r4wappp027")
{$BackupPath="C:\$fullfilename.IML"
Write-Host -ForegroundColor green "this is 027 backuppath: $Backuppath"}
else
{$BackupPath="D:\$fullfilename.IML"}
$PMstartParameter="/accepteula /quiet /minimized /backingfile $BackupPath /loadconfig C:\PMtools\ProcmonConfiguration.pmc"
$PMstopParameter="/accepteula /terminate"
$StartCommand="$PSexecPath -s -d $PMPath $PMstartParameter"
$StopCommand="$PSexecPath -s -d $PMPath $PMstopParameter"

Invoke-Command -ScriptBlock {cmd /c $args[0];Start-Sleep -Seconds $args[2] ;cmd /c $args[1]}  -ComputerName $Servers -ArgumentList $StartCommand,$StopCommand,$duration -AsJob -Credential $mycreds 

#Invoke-Command -ScriptBlock {cmd /c $args[1]}  -ComputerName $Servers -ArgumentList $StartCommand,$StopCommand -AsJob -Credential $mycreds 
}