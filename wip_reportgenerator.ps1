#created consolidated report from files downloaded by downloadreports.ps1

###Create Empty Hash###
$hash=@{}

###Location of Log files###
$serverLogFiles=""

###Location of Outputted Report###
$output = ""

###Rename Files for consistency###
$misnamedfiles=get-childitem $serverlog | where { $_.Name -notmatch '^.*.blah.com_patching_log.txt'}
$filename = $misnamedfiles | select -expand name
foreach($file in $filename)
{
    try{
    $servername = $file.IndexOf("_")
    $svrname = $file.substring(0, $servername)
    $oldname = "$svrname"+"_patching_log.txt"
    $newname = "$svrname"+".blah.com_patching_log.txt"

    $misnamedfiles | rename-item -newname {$_.Name -replace $oldname,$newname}
    }
    catch{
    }
}

$logfiles = get-childitem $serverlog

###Define Regex###
$pattern1 = "\#\#\#lsblkASM\#\#\#(.*)\#\#\#lsblk -d\#\#\#"
$pattern2 = "\#\#\#lsblk -d\#\#\#(.*)\#\#\#lvs\#\#\#"
$pattern3 = "\#\#\#lvs\#\#\#(.*)\#\#\#ifcfg-eth0"

foreach ($logfile in $logfiles)
{

        $filename = $logfile.name
        $servername = $filename.IndexOf("_")
        $svrname = $filename.substring(0, $servername)

        ###Gather unparsed info for memory###
        [string]$memory=get-content "$serverLogFiles\$filename" | select-string -Pattern "Mem:"

        ###Gather unparsed info for swap###
        [string]$swap=get-content "$serverLogFiles\$filename" | select-string -Pattern "Swap:"

        ###Gather unprased info for CPU###
        [string]$lscpu=get-content "$serverLogFiles\$filename"| select-string -Pattern "^CPU\(s\):"

        ###Gather copy of file for further processing###
        $df=get-content "$serverLogFiles\$filename"

        ###Initialize Variables###
        $totalsize=$null
        $substractsize=$null
        $asmsize=$null

        ###Processing for All Space Used by ASM Disks###
        $ASMs =[regex]::match($df, $pattern1).captures.groups[0].value
        $ASM = [string]$ASMs -split "part"

        ###Processing for All Space Used by Physical Volumes###
        $lsblk=[regex]::match($df, $pattern2).captures.groups[0].value
        $pv = [string]$lsblk -split 'disk'

        ###Processing for All Space Used by Logical Volumes###
        $lvs =[regex]::match($df, $pattern3).captures.groups[0].value
        $lv = [string]$lvs -split "vg"

        ###Grab Memory Size###
        $mem = $memory.split("  ")[9]
        if(!$mem)
        {
            $mem = $memory.split(" ")[10]
        }

        if(!$mem)
        {
            $mem = $memory.split(" ")[11]
        }

        ###Grab Swap Size###
        $swapsize = $swap.split("  ")[8]

        if(!$swapsize)
        {
            $swapsize = $swap.split(" ")[9]
        }

        ###Grab Number of CPUs###
        $cpu = $lscpu.split(" ")[16]


        ###For each physical volume, add disk size to totalasmsize###
        foreach($asmdisk in $asm)
        {           
                    $asmsplit = $asmdisk -split "\s+"
                    foreach($adisk in $asmsplit){
                        if($adisk -clike '*G' -and $adisk -notlike 'RM' -and $adisk -notlike '*M')
                        {         
                            [int]$asmspace = $adisk.Trim("G")
                            [int]$totalasmsize += $asmspace
                        }

                    }
        }

        ###For each logical volume, add disk size to subtractsize###
        foreach($v in $lv)
        {
                $asize = $v.split("g")[0]
                $vo = $asize.split(" ")
                foreach ($lvline in $vo)
                {
                    if ($lvline -match '\d+' -and $lvline -notmatch '/dev/*')
                    {
                        ###Convert if disk has <###
                        if ($lvline -like "<*")
                        {
                            $lvline = $lvline -replace '<',''
                            [int]$substractsize += $lvline
                        }
                        ###Convert if disk is in terabytes###
                        elseif ($lvline -like "*t")
                        {
                            $lvline = $lvline -replace 't',''
                            $lvline = [int]$lvline * 1000
                            [int]$substractsize += $lvline
                        }
                        else
                        {
                            [int]$substractsize += $lvline
                        }
                    }
                }
        }

        ###For each physical volume, add disk size to totalsize###
        foreach($disk in $pv)
        {           
                    $split = $disk -split "\s+"
                    foreach($d in $split){
                        if($d -clike '*G')
                        { 
                            $diskspace = $d
                            
                            if($diskspace -notlike 'RM' -and $diskspace -notlike '*M')
                            {
                            [int]$space = $diskspace.Trim("G")
                            $totalsize += $space
                            }
                        }

                    }
        }

        ###Round Memory and Swap to nearest GB###
        $roundedswap = [math]::round($swapsize/1024)
        $roundedmem= [math]::round($mem/1024)

        ###Add 7 for Hidden Storage in Root Partition###
        [int]$substractsize = [int]$substractsize + 7

        ###Perform Calculations for Figuring out Total ASM Disk Space###
        [int]$totalasm = [int]$totalsize - [int]$substractsize - ([int]$roundedswap - 8)

        ###Perform Calculations for Figuring out Free Disk Space###
        [int]$freespace = [int]$totalsize - ([int]$substractsize + $totalasm)

        ###Cast $subtractsize to string for hash use###
        [string]$subtractsize=$substractsize

        ###Add Variables to hash###

        if($svrname -like '*db*')
        {
            $hash.add($svrname, [PSCustomObject]@{
            "servername" = $svrname
            "memory"= [string]$roundedmem
            "cpu"= [string]$cpu
            "swapsize" = [string]$roundedswap
            "LVtotalsize"= [string]$substractsize
            "totalsize" = [string]$totalsize
            "totalASMsize"= [string]$totalasmsize
            })
        }
        else
        {
            $hash.add($svrname, [PSCustomObject]@{
            "servername" = $svrname
            "memory"= [string]$roundedmem
            "cpu"= [string]$cpu
            "swapsize" = [string]$roundedswap
            "LVtotalsize"= [string]$substractsize
            "totalsize" = [string]$totalsize
            "totalASMsize"= "Non-DB Server"
            })
        }

        $hash | sort-object name | select-object @{Label="ServerName"; Expression={$hash.$svrname.'servername'}}, `
        @{Label="Core"; Expression={$hash.$svrname.'cpu'}}, `
        @{Label="RAM"; Expression={$hash.$svrname.'memory'}}, `
        @{Label="Swap"; Expression={$hash.$svrname.'swapsize'}}, `
        @{Label="Total Disk Size"; Expression={$hash.$svrname.'totalsize'}}, `
        @{Label="Data Size"; Expression={$hash.$svrname.'LVtotalsize'}}, `
        @{Label="ASM Size"; Expression={$hash.$svrname.'totalASMsize'}} `
        | export-csv $output -NoTypeInformation -append

        ###Reset Variables###
        $mem=$null
        $cpu=$null
        $swapsize=$null
        $totalsize=$null
        $asmsize=$null
        $substractsize=$null
        $totalasmsize=$null
}
