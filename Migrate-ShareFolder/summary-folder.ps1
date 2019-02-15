
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
    if ($files -eq $null){
        return $path
        
        }
    else{
        $lastfilename=$files[-1]
        return $lastfilename
        }
    }

}




  
function summary-folder{
param (
[Parameter(Mandatory=$true,position=0)]     
$Path
)
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

$s=get-childitem -Path $path

if($global:lastfilename -eq $null -and $global:filesinRoot -eq 1)
{
$global:lastfilename=$s[-1]}
else{}




if ($s -ne $null)
{
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
        $totalbyGB=$global:filesummary/1GB
        write "last file is $ss.name,total capacity is $totalbyGB GB,sharepath is $global:rootpath"
        }
        elseif ($global:filesinRoot -eq 0 -and $ss.Name -eq $global:lastfilenameForOnlyFolderinRootfloder.name -and $ss.PSParentPath -eq $global:lastfilenameForOnlyFolderinRootfloder.PSParentPath)
        {
        $totalbyGB=$global:filesummary/1GB
        write "last file is $ss.name,total capacity is $totalbyGB GB,sharepath is $global:rootpath"
        }
        else
        {<#write "unabe to summary $ss the size of sharepath is $global:rootpath"#> }
        }
    }


}
else
{
    if ($path -eq $global:lastfilenameForOnlyFolderinRootfloder)
    {
    $totalbyGB=$global:filesummary/1024/1024/1024
    write "no last file ,total capacity is $totalbyGB GB,sharepath is $global:rootpath"  
    }
    else
    {<#write "unabe to summary $ss the size of sharepath is $global:rootpath"#> }

}

}


$global:lastfilenameForOnlyFolderinRootfloder=find-lastrecursionfile -path $args[0]
summary-folder $args[0] 2>$null