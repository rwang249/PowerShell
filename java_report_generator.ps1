#general script to mass rename files for consistency

###Create Empty Hash###
$hash=@{}

###Location of Log files###
$serverlog=""

###Location of Output###
$output = ""

###Rename Files for consistency###
$misnamedfiles=get-childitem $serverlog | where { $_.Name -notmatch '^.*.blah.com_java_version.txt'}
$filename = $misnamedfiles | select -expand name
foreach($file in $filename)
{
    try{
    $servername = $file.IndexOf("_")
    $svrname = $file.substring(0, $servername)
    $oldname = "$svrname"+"_java_version.txt"
    $newname = "$svrname"+".blah.com_java_version.txt"

    $misnamedfiles | rename-item -newname {$_.Name -replace $oldname,$newname}
    }
    catch{
    }
}

###Generate report for server's Java version###
$logfiles = get-childitem $serverlog

foreach ($logfile in $logfiles)
{

        $filename = $logfile.name
        $servername = $filename.IndexOf("_")
        $svrname = $filename.substring(0, $servername)

        ###Gather unparsed info for memory###
        [string]$java_version=get-content "$serverlog\$filename"

        $hash | sort-object name | select-object @{Label="ServerName"; Expression={$svrname}}, `
        @{Label="Java Version"; Expression={$java_version}} `
        | export-csv $output -NoTypeInformation -append
}
