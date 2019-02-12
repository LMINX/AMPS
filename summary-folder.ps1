$Global:filesummary=$null
$global:rootpath=$null
$global:filesinRoot=$null
$global:lastfilename=$null
#$global:lastfilenameForOnlyFolderinRootfloder=$null



function find-lastrecursionfile
{
param (
[Parameter(Mandatory=$true,position=0)]
$path
)
$s=Get-ChildItem -Path $path -Directory
    if($s -ne $null)
    {
    find-lastrecursionfile -path $s[-1].PSPath
    }
    else{
    $files=Get-ChildItem -Path $path -File
    $lastfilename=$files[-1]
    return $lastfilename
    }

}
  
function summary-folder{
param (
[Parameter(Mandatory=$true,position=0)]     
$Path
)
$s=get-childitem -Path $path

if($global:rootpath -eq $null)
{$global:rootpath=$path}
else{}

if($global:filesinRoot -eq $null)
{if ((get-childitem -Path $global:rootpath -File) -ne $null)
    {$global:filesinRoot=1}
 else{$global:filesinRoot=0}
}
else{}

if ($global:filesummary -eq $null)
{$global:filesummary=0}
else{}

if($global:lastfilename -eq $null -and $global:filesinRoot -eq 1)
{
$global:lastfilename=$s[-1]}
else{}


foreach ($ss in $s)
{

if ($ss.pstypenames[0] -eq "System.IO.DirectoryInfo")
{
summary-folder -Path $ss.PSPath
}
else{
$global:filesummary+=$ss.length
if ($global:filesinRoot -eq 1 -and $ss.Name -eq $global:lastfilename -and $ss.PSParentPath -eq "Microsoft.PowerShell.Core\FileSystem::$global:rootpath")
{
$totalbyGB=$global:filesummary/1024/1024/1024
write "last file is $ss.name and total is $totalbyGB" 
}
if ($global:filesinRoot -eq 0 -and $ss.Name -eq $global:lastfilenameForOnlyFolderinRootfloder.name -and $ss.PSParentPath -eq $global:lastfilenameForOnlyFolderinRootfloder.PSParentPath)
{
$totalbyGB=$global:filesummary/1024/1024/1024
write "last file is $ss.name and total is $totalbyGB" }
}


    }
}
$global:lastfilenameForOnlyFolderinRootfloder=find-lastrecursionfile -path $args[0]
summary-folder $args[0]