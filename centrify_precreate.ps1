
$hostname = $null
$container = "#Unix server OU"
$zone = "#general centrify OU"
$zoneAdmin = "#zone admin group"

do 
{
$hostname = read-host -prompt "Please enter server name(not FQDN)"

    if($hostname -ne $null)
    {
        [string]$answer=read-host -prompt "Is this hostname correct?($hostname)  y/n"
        if ($answer -eq "n")
        {
            $answer = $null
        } 
        else
        {
        echo $hostname
        }
    }
}
until($answer -eq "y")

$dnsname = $hostname + ".blah.com"

Import-Module "Centrify.DirectControl.PowerShell"
New-CdmManagedComputer -name $hostname -Zone $zone -DnsName $dnsname -Container $container`
-Delegate $zoneAdmin -AdjoinAndMachineOverride -LicenseType Server

Read-Host "Press any key to exit..."
exit