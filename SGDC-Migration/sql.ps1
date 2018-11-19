get-psdrive
get-help invoke-sqlcmd -detailed
Invoke-Sqlcmd  -Username sa -Password acsopsL2 "CREATE TABLE perf3(host varchar(100),type varchar(100), value float,time datetime)“
#host varchar,type varchar, value varchar,time date
$time=Get-Date
Invoke-Sqlcmd  -Username sa -Password acsopsL2 "insert into perf3 values ('host','cpu',10,'2018-09-07 00:25:01')"
Invoke-Sqlcmd  -Username sa -Password acsopsL2 "insert into perf3 values ('host2','cpu',20,'2018-09-07 01:25:01')"
Invoke-Sqlcmd  -Username sa -Password acsopsL2 "insert into perf3 values ('host','disk',12,'2018-09-07 01:00:00')"
Invoke-Sqlcmd  -Username sa -Password acsopsL2 "SELECT TABLE_NAME FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_TYPE='BASE TABLE'“
Invoke-Sqlcmd  -Username sa -Password acsopsL2 "SELECT name FROM master.dbo.sysdatabases"
Invoke-Sqlcmd  -Username sa -Password acsopsL2 "select * from sysobjects where xtype='u' and status>=0”
Invoke-Sqlcmd  -Username sa -Password acsopsL2 "SELECT TABLE_NAME FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_TYPE = 'BASE TABLE' AND TABLE_CATALOG='master'“
Invoke-Sqlcmd  -Username sa -Password acsopsL2 "select top 10 * FROM sgdc.dbo.perf order by time desc“

Invoke-Sqlcmd  -Username sa -Password acsopsL2 "SELECT * INTO sgdc.dbo.perf FROM master.dbo.perf3"

Invoke-Sqlcmd  -Username sa -Password acsopsL2 "CREATE TABLE sgdc.dbo.MigrationOwner (host varchar(100),MigrationOwner varchar(100))"


$c=Get-Content "C:\script\SGDC-Migration\MigrationOwner.csv"
foreach ($line in $c)
{

$array=$line.split(",")
$hostname=$array[0]
$owner=$array[1]

Invoke-Sqlcmd  -Username sa -Password acsopsL2 "insert into sgdc.dbo.MigrationOwner values ('$hostname','$owner')"
}

Invoke-Sqlcmd  -Username sa -Password acsopsL2 "select top 10 * FROM sgdc.dbo.MigrationOwner“