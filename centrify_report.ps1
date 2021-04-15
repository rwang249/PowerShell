#used to generate email report for all users in the Centrify system. Needs to be run on host system.

Import-Module "Centrify.DirectControl.PowerShell"

$definition = @’
using System;
using System.DirectoryServices;

namespace Centrify.DcPowerShell.Report
{
    public class AdHelpers
    {
        public static DirectoryEntry GetDirectoryEntry(string dn)
        {
            return GetDirectoryEntry(dn, null, null, null);
        }

        public static DirectoryEntry GetDirectoryEntry(string dn, string[] properties)
        {
            return GetDirectoryEntry(dn, null, null, properties);
        }

        public static DirectoryEntry GetDirectoryEntry(string dn, string username, string password)
        {
            return GetDirectoryEntry(dn, username, password, null);
        }

        public static DirectoryEntry GetDirectoryEntry(string dn, string username, string password, string[] properties)
        {
            string domain = dn.ToLower();

            domain = domain.StartsWith("dc=") ? "," + domain : domain;

            int index = domain.IndexOf(",dc=");
            if (index < 0)
            {
                string msg = string.Format("Invalid DN {0}", dn);
                throw new ArgumentException(msg);
            }

            domain = domain.Substring(index).Replace(",dc=", ".").Trim('.');

            string path = string.Format("LDAP://{0}/{1}", domain, dn);

            DirectoryEntry entry = new DirectoryEntry(path, username, password, AuthenticationTypes.Sealing | AuthenticationTypes.Secure);
            if (properties == null)
            {
                entry.RefreshCache();
            }
            else
            {
                entry.RefreshCache(properties);
            }

            return entry;
        }
    }
}
‘@

if (-not ([System.Management.Automation.PSTypeName]'Centrify.DcPowerShell.Report.AdHelpers').Type)
{
    Add-Type -TypeDefinition $definition -ReferencedAssemblies System.DirectoryServices.dll
}

function New-DirectoryEntry([string]$ObjectDn, [System.Management.Automation.PSCredential]$Credential, [string[]]$Properties)
{
    if ($Credential)
    {
        $username = $Credential.UserName
        $password = $Credential.GetNetworkCredential().Password
        if ($Properties)
        {
            [Centrify.DcPowerShell.Report.AdHelpers]::GetDirectoryEntry($ObjectDn, $username, $password, $Properties)
        }
        else
        {
            [Centrify.DcPowerShell.Report.AdHelpers]::GetDirectoryEntry($ObjectDn, $username, $password)
        }
    }
    else
    {
        if ($Properties)
        {
            [Centrify.DcPowerShell.Report.AdHelpers]::GetDirectoryEntry($ObjectDn, $Properties)
        }
        else
        {
            [Centrify.DcPowerShell.Report.AdHelpers]::GetDirectoryEntry($ObjectDn)
        }
    }
}

#E.g. Child.Parent.com, UserA -> Child.Parent.com\UserA
function Compose-HostNameForDisplay([string]$DomainName, [string]$SamAccountName)
{
    return "{0}@{1}" -f $SamAccountName, $DomainName
}

#e.g. child.centrify.com => dc=child,dc=centrify,dc=com
function Convert-DomainToDN([string]$DomainName)
{
    return "{0}{1}" -f "dc=", $DomainName.Replace(".", ",dc=")
}

#This function composes the value of Role Assignment Location
function Get-RoleAssignmentLocationHelper($SourceAssignment)
{
    $result = ""

    if ($SourceAssignment)  
    {
        if ($SourceAssignment.Zone)
        {            
            $result = $SourceAssignment.Zone.CanonicalName
        }
        elseif ($SourceAssignment.Computer)
        {
            $result = "{0}: {1}" -f "Computer", $SourceAssignment.Computer
        }
        elseif ($SourceAssignment.ComputerRole)
        {
            $result = "{0}: {1}" -f "Computer role", $SourceAssignment.ComputerRole
        }
    }

    return $result
}

function Get-DomainFromDistinguishedName([string]$Dn)
{
    if ($Dn)
    {
        $arr = $Dn.SubString($Dn.ToLower().IndexOf(",dc=") + 1).split(",")
        $domain = ""
        foreach ($str in $arr)
        {
            $domain = "{0}.{1}" -f $domain, $str.SubString($str.IndexOf("=") + 1).Trim()
        }

        return  $domain.SubString(1) #remove the first "." at the begin
    }
    else
    {
        return ""
    }
}

function Get-TimeZoneInfo([string]$Gmt)
{    
    [string]$trimmed = $Gmt.Trim()
    [TimeZoneInfo]$result = $null
    [string]$value = ""
    [string]$sign = ""
    [string]$hour = ""
    [string]$minute = ""
    Set-Variable GMT_M12 -Option Constant -Value "Dateline Standard Time"
    Set-Variable GMT_M11 -Option Constant -Value "UTC-11"
    Set-Variable GMT_M10 -Option Constant -Value "Hawaiian Standard Time"
    Set-Variable GMT_M9 -Option Constant -Value "Alaskan Standard Time"
    Set-Variable GMT_M8 -Option Constant -Value "Pacific Standard Time"
    Set-Variable GMT_M7 -Option Constant -Value "Mountain Standard Time"
    Set-Variable GMT_M6 -Option Constant -Value "Central Standard Time"
    Set-Variable GMT_M5 -Option Constant -Value "Eastern Standard Time"
    Set-Variable GMT_M430 -Option Constant -Value "Venezuela Standard Time"
    Set-Variable GMT_M4 -Option Constant -Value "Atlantic Standard Time"
    Set-Variable GMT_M330 -Option Constant -Value "Newfoundland Standard Time"
    Set-Variable GMT_M3 -Option Constant -Value "Greenland Standard Time"
    Set-Variable GMT_M2 -Option Constant -Value "Mid-Atlantic Standard Time"
    Set-Variable GMT_M1 -Option Constant -Value "Azores Standard Time"
    Set-Variable GMT_0 -Option Constant -Value "GMT Standard Time"
    Set-Variable GMT_P1 -Option Constant -Value "Romance Standard Time"
    Set-Variable GMT_P2 -Option Constant -Value "GTB Standard Time"
    Set-Variable GMT_P3 -Option Constant -Value "Arab Standard Time"
    Set-Variable GMT_P330 -Option Constant -Value "Iran Standard Time"
    Set-Variable GMT_P4 -Option Constant -Value "Arabian Standard Time"
    Set-Variable GMT_P430 -Option Constant -Value "Afghanistan Standard Time"
    Set-Variable GMT_P5 -Option Constant -Value "West Asia Standard Time"
    Set-Variable GMT_P530 -Option Constant -Value "India Standard Time"
    Set-Variable GMT_P545 -Option Constant -Value "Nepal Standard Time"
    Set-Variable GMT_P6 -Option Constant -Value "Central Asia Standard Time"
    Set-Variable GMT_P630 -Option Constant -Value "Myanmar Standard Time"
    Set-Variable GMT_P7 -Option Constant -Value "SE Asia Standard Time"
    Set-Variable GMT_P8 -Option Constant -Value "China Standard Time"
    Set-Variable GMT_P9 -Option Constant -Value "Tokyo Standard Time"
    Set-Variable GMT_P930 -Option Constant -Value "AUS Central Standard Time"
    Set-Variable GMT_P10 -Option Constant -Value "AUS Eastern Standard Time"
    Set-Variable GMT_P11 -Option Constant -Value "Central Pacific Standard Time"
    Set-Variable GMT_P12 -Option Constant -Value "UTC+12"
    Set-Variable GMT_P13 -Option Constant -Value "Tonga Standard Time"

    if (!$Gmt)
    {
        return $null
    }

    if ($trimmed.ToLower().IndexOf("gmt") -ne 0)
    {
        return $null
    }

    #E.g. GMT+6:30 -> +
    $sign = $trimmed.SubString(3, 1)
    #E.g. GMT+6 -> 6:30
    $value = $trimmed.SubString(4)

    if ($value.Length -eq 1)
    {
        $hour = $value.PadLeft(2, "0")
        $minute = "00"
    }
    elseif ($value.Length -eq 2)
    {
        $hour = $value
        $minute = "00"
    }
    elseif ($value.Length -eq 3) #no such combination
    {
        return $null
    }
    elseif ($value.Length -eq 4 -And $value.IndexOf(":") -eq 1) #e.g. 6:30
    {
        $hour = $value.SubString(0, 1).PadLeft(2, "0") #E.g. 06
        $minute = $value.SubString(2) #E.g. 30
    }
    elseif ($value.Length -eq 5 -And $value.IndexOf(":") -eq 2) #e.g. 06:30
    {
        $hour = $value.SubString(0, 2) #e.g. 06
        $minute = $value.SubString(3) #e.g. 30
    }

    switch ($sign + $hour + $minute)
    {
        "-1200" { $result = [TimeZoneInfo]::FindSystemTimeZoneById($GMT_M12) }
        "-1100" { $result = [TimeZoneInfo]::FindSystemTimeZoneById($GMT_M11) }
        "-1000" { $result = [TimeZoneInfo]::FindSystemTimeZoneById($GMT_M10) }
        "-0900" { $result = [TimeZoneInfo]::FindSystemTimeZoneById($GMT_M9) }
        "-0800" { $result = [TimeZoneInfo]::FindSystemTimeZoneById($GMT_M8) }
        "-0700" { $result = [TimeZoneInfo]::FindSystemTimeZoneById($GMT_M7) }
        "-0600" { $result = [TimeZoneInfo]::FindSystemTimeZoneById($GMT_M6) }
        "-0500" { $result = [TimeZoneInfo]::FindSystemTimeZoneById($GMT_M5) }
        "-0430" { $result = [TimeZoneInfo]::FindSystemTimeZoneById($GMT_M430) }
        "-0400" { $result = [TimeZoneInfo]::FindSystemTimeZoneById($GMT_M4) }
        "-0330" { $result = [TimeZoneInfo]::FindSystemTimeZoneById($GMT_M330) }
        "-0300" { $result = [TimeZoneInfo]::FindSystemTimeZoneById($GMT_M3) }
        "-0200" { $result = [TimeZoneInfo]::FindSystemTimeZoneById($GMT_M2) }
        "-0100" { $result = [TimeZoneInfo]::FindSystemTimeZoneById($GMT_M1) }
        "-0000" { $result = [TimeZoneInfo]::FindSystemTimeZoneById($GMT_0) }
        "+0000" { $result = [TimeZoneInfo]::FindSystemTimeZoneById($GMT_0) }
        "+0100" { $result = [TimeZoneInfo]::FindSystemTimeZoneById($GMT_P1) }
        "+0200" { $result = [TimeZoneInfo]::FindSystemTimeZoneById($GMT_P2) }
        "+0300" { $result = [TimeZoneInfo]::FindSystemTimeZoneById($GMT_P3) }
        "+0330" { $result = [TimeZoneInfo]::FindSystemTimeZoneById($GMT_P330) }
        "+0400" { $result = [TimeZoneInfo]::FindSystemTimeZoneById($GMT_P4) }
        "+0430" { $result = [TimeZoneInfo]::FindSystemTimeZoneById($GMT_P430) }
        "+0500" { $result = [TimeZoneInfo]::FindSystemTimeZoneById($GMT_P5) }
        "+0530" { $result = [TimeZoneInfo]::FindSystemTimeZoneById($GMT_P530) }
        "+0545" { $result = [TimeZoneInfo]::FindSystemTimeZoneById($GMT_P545) }
        "+0600" { $result = [TimeZoneInfo]::FindSystemTimeZoneById($GMT_P6) }
        "+0630" { $result = [TimeZoneInfo]::FindSystemTimeZoneById($GMT_P630) }
        "+0700" { $result = [TimeZoneInfo]::FindSystemTimeZoneById($GMT_P7) }
        "+0800" { $result = [TimeZoneInfo]::FindSystemTimeZoneById($GMT_P8) }
        "+0900" { $result = [TimeZoneInfo]::FindSystemTimeZoneById($GMT_P9) }
        "+0930" { $result = [TimeZoneInfo]::FindSystemTimeZoneById($GMT_P930) }
        "+1000" { $result = [TimeZoneInfo]::FindSystemTimeZoneById($GMT_P10) }
        "+1100" { $result = [TimeZoneInfo]::FindSystemTimeZoneById($GMT_P11) }
        "+1200" { $result = [TimeZoneInfo]::FindSystemTimeZoneById($GMT_P12) }
        "+1300" { $result = [TimeZoneInfo]::FindSystemTimeZoneById($GMT_P13) }
        default { $result = $null }
    }

    return $result
}

function Get-ZonesHelper([string[]]$DomainNames, [string[]]$ZoneNames, [string[]]$Type)
{
    if ($DomainNames -And $ZoneNames)
    {
        foreach ($domainName in $DomainNames)
        {
            foreach ($zoneName in $ZoneNames)
            {
                if ($domainName -And $zoneName)
                {
                    if ($Type)
                    {
                        Get-CdmZone -Domain $domainName -Name $zoneName -Type $Type
                    }
                    else
                    {
                        Get-CdmZone -Domain $domainName -Name $zoneName
                    }
                }
            }
        }
    }
    elseif ($DomainNames)
    {
        foreach ($domainName in $DomainNames)
        {
            if ($domainName)
            {
                if ($Type)
                {
                    Get-CdmZone -Domain $domainName -Type $Type
                }
                else
                {
                    Get-CdmZone -Domain $domainName
                }
            }
        }
    }
    elseif ($ZoneNames)
    {
        foreach ($zoneName in $ZoneNames)
        {
            if ($zoneName)
            {
                if ($Type)
                {
                    Get-CdmZone -Name $zoneName -Type $Type
                }
                else
                {
                    Get-CdmZone -Name $zoneName
                }
            }
        }
    }
    else
    {
        if ($Type)
        {
            Get-CdmZone -Type $Type
        }
        else
        {
            Get-CdmZone
        }
    }
}

function Get-ZoneHelper([string[]]$DomainNames, [string[]]$ZoneNames, [string[]]$Type)
{
    $result = @()

    if ($DomainNames -And $ZoneNames)
    {
        foreach ($domainName in $DomainNames)
        {
            foreach ($zoneName in $ZoneNames)
            {
                if ($domainName -And $zoneName)
                {
                    if ($Type)
                    {
                        $result += Get-CdmZone -SearchRoot (Convert-DomainToDN -DomainName $domainName) -Name $zoneName -Type $Type
                    }
                    else
                    {
                        $result += Get-CdmZone -SearchRoot (Convert-DomainToDN -DomainName $domainName) -Name $zoneName
                    }
                }
            }
        }
    }
    elseif ($DomainNames)
    {
        foreach ($domainName in $DomainNames)
        {
            if ($domainName)
            {
                if ($Type)
                {
                    $result += Get-CdmZone -SearchRoot (Convert-DomainToDN -DomainName $domainName) -Type $Type
                }
                else
                {
                    $result += Get-CdmZone -SearchRoot (Convert-DomainToDN -DomainName $domainName)
                }
            }
        }
    }
    elseif ($ZoneNames)
    {
        foreach ($zoneName in $ZoneNames)
        {
            if ($zoneName)
            {
                if ($Type)
                {
                    $result += Get-CdmZone -Name $zoneName -Type $Type
                }
                else
                {
                    $result += Get-CdmZone -Name $zoneName
                }
            }
        }
    }
    else
    {
        if ($Type)
        {
            $result = Get-CdmZone -Type $Type
        }
        else
        {
            $result = Get-CdmZone
        }
    }

    return $result
}

function Concat-StringArray([string[]]$Values, [string]$Delimiter = ",", [switch]$NewLine)
{
    $result = ""
    $nl = [Environment]::NewLine

    if ($Values)
    {
        foreach ($value in $Values)
        {        
            $result += $value + $Delimiter
            if ($NewLine)
            {
                $result += $nl
            }
        }
        $result = $result.Trim().Trim($Delimiter)
    }

    return $result
}

function GetEffectiveRightsByZone
{
    Param(
        [Parameter(Mandatory=$True,ValueFromPipeline=$True)]
        [Centrify.DirectControl.PowerShell.Types.CdmZone]$Zone,
        [string[]]$Users,
        [Bool]$IsUnixRights = $true,
        [Bool]$IsWinRights = $true
    )

    Process
    {
        if ($Users)
        {
            foreach ($user in $Users)
            {
                if ($IsUnixRights)
                {
                    # Get effective unix rights
                    try
                    {
                        Get-CdmEffectiveUnixRight -User $user -ComputersInZone $Zone | where { $_ }
                    }
                    catch [Exception] 
                    {
                        $errorMsg = "Failed to get effective unix rights in the zone '$Zone'. Error message: " + $_.Exception.Message
                        Write-Warning $errorMsg
                    }
                }

                if ($IsWinRights)
                {
                    # Get effective windows rights
                    try
                    {
                        Get-CdmEffectiveWindowsRight -User $user -ComputersInZone $Zone | where { $_ }
                    }
                    catch [Exception] 
                    {
                        $errorMsg = "Failed to get effective windows rights in the zone '$Zone'. Error message: " + $_.Exception.Message
                        Write-Warning $errorMsg
                    }
                }
            }
        }
        else
        {
            if ($IsUnixRights)
            {
                # Get effective unix rights
                try
                {
                    Get-CdmEffectiveUnixRight -ComputersInZone $Zone | where { $_ }
                }
                catch [Exception] 
                {
                    $errorMsg = "Failed to get effective unix rights in the zone '$Zone'. Error message: " + $_.Exception.Message
                    Write-Warning $errorMsg
                }
            }
            
            if ($IsWinRights)
            {
                # Get effective windows rights
                try
                {
                    Get-CdmEffectiveWindowsRight -ComputersInZone $Zone | where { $_ }
                }
                catch [Exception] 
                {
                    $errorMsg = "Failed to get effective windows rights in the zone '$Zone'. Error message: " + $_.Exception.Message
                    Write-Warning $errorMsg
                }
            }
        }
    }
}

function GetEffectiveRightsByComputer
{
    Param(
        [Parameter(Mandatory=$True,ValueFromPipeline=$True)]
        [string]$Computer,
        [string[]]$Users,
        [Bool]$IsUnixRights = $true,
        [Bool]$IsWinRights = $true
    )

    Process
    {
        if ($Users)
        {
            foreach ($user in $Users)
            {
                if ($user)
                {
                    if ($IsUnixRights)
                    {
                        # Get effective unix rights
                        try
                        {
                            Get-CdmEffectiveUnixRight -User $user -Computer $Computer | where { $_ }
                        }
                        catch [Exception] 
                        {
                            if ($_.Exception.Message.ToLower() -ne "please specify a unix computer.".ToLower())
                            {
                                $errorMsg = "Failed to get effective unix rights in the computer '$Computer'. Error message: " + $_.Exception.Message
                                Write-Warning $errorMsg
                            }
                        }
                    }

                    if ($IsWinRights)
                    {
                        # Get effective windows rights
                        try
                        {
                            Get-CdmEffectiveWindowsRight -User $user -Computer $Computer | where { $_ }
                        }
                        catch [Exception] 
                        {
                            if ($_.Exception.Message.ToLower() -ne "please specify a windows computer.".ToLower())
                            {
                                $errorMsg = "Failed to get effective windows rights in the computer '$Computer'. Error message: " + $_.Exception.Message
                                Write-Warning $errorMsg
                            }
                        }
                    }
                }
            }
        }
        else
        {
            if ($IsUnixRights)
            {
                # Get effective unix rights
                try
                {
                    Get-CdmEffectiveUnixRight -Computer $Computer | where { $_ }
                }
                catch [Exception] 
                {
                    if ($_.Exception.Message.ToLower() -ne "please specify a unix computer.".ToLower())
                    {
                        $errorMsg = "Failed to get effective unix rights in the computer '$Computer'. Error message: " + $_.Exception.Message
                        Write-Warning $errorMsg
                    }
                }
            }

            if ($IsWinRights)
            {
                # Get effective windows rights
                try
                {
                    Get-CdmEffectiveWindowsRight -Computer $Computer | where { $_ }
                }
                catch [Exception] 
                {
                    if ($_.Exception.Message.ToLower() -ne "please specify a windows computer.".ToLower())
                    {
                        $errorMsg = "Failed to get effective windows rights in the computer '$Computer'. Error message: " + $_.Exception.Message
                        Write-Warning $errorMsg
                    }
                }
            }
        }
    }
}

function GetEffectiveRightsByUser
{
    Param(
        [Parameter(Mandatory=$True,ValueFromPipeline=$True)]
        [string]$User,
        [Bool]$IsUnixRights = $true,
        [Bool]$IsWinRights = $true
    )

    Process
    {
        if ($IsUnixRights)
        {
            # Get effective unix rights
            try
            {
                Get-CdmEffectiveUnixRight -User $User | where { $_ }
            }
            catch [Exception] 
            {
                $errorMsg = "Failed to get effective unix rights for user '$User'. Error message: " + $_.Exception.Message
                Write-Warning $errorMsg
            }
        }

        if ($IsWinRights)
        {
            # Get effective windows rights
            try
            {
                Get-CdmEffectiveWindowsRight -User $User | where { $_ }
            }
            catch [Exception] 
            {
                $errorMsg = "Failed to get effective windows rights for user '$User'. Error message: " + $_.Exception.Message
                Write-Warning $errorMsg
            }
        }
    }
}

# Notes: Get-CdmEffectiveUnixRight and Get-CdmEffectiveWindowsRight contain 3 parameters, they are Zone,
# ComputersInZone, and Computer, however the cmdlets only accept 1 out of the 3 parameters each time
# This function returns Unix Effective Rights and Windows Effective Rights according to the filters provided (i.e. DomainNames,ZoneNames,ComputerSams,UserSams)
function Get-EffectiveRightHelper
{
    Param(
        [string[]]$DomainNames,
        [string[]]$ZoneNames,
        [string[]]$ComputerSams,
        [string[]]$UserSams,
        [Ref]$UnixRightRecords,
        [Ref]$WindowsRightRecords
    )

    $zones = @()
    $zones = Get-ZoneHelper -DomainNames $DomainNames -ZoneNames $ZoneNames -Type Hierarchical

    if ($ComputerSams -And $UserSams)
    {
        foreach ($computerSam in $ComputerSams)
        {
            if ($computerSam)
            {
                foreach ($userSam in $UserSams)
                {
                    if ($userSam)
                    {
                        if ($UnixRightRecords)
                        {
                            $unixRights = @()                        

                            try
                            {
                                $unixRights = Get-CdmEffectiveUnixRight -Computer $computerSam -User $userSam                                   
                            }
                            catch [Exception] 
                            {
                                Process-UnixRightOsMismatchException -ex $_.Exception
                            }

                            if ($unixRights)
                            {
                                foreach ($unixRight in $unixRights)
                                {
                                    if ($unixRight)
                                    {
                                        foreach ($zone in $zones)
                                        {
                                            if ($zone -And $unixRight.Computer)
                                            {
                                                if ($unixRight.Computer.Zone.DistinguishedName.ToLower() -eq $zone.DistinguishedName.ToLower())
                                                {
                                                    $UnixRightRecords.Value += $unixRight
                                                }
                                            }
                                        }
                                    }
                                }           
                            }
                        }

                        if ($WindowsRightRecords)
                        {
                            $winRights = @()

                            try
                            {
                                $winRights = Get-CdmEffectiveWindowsRight -Computer $computerSam -User $userSam
                            }
                            catch [Exception] 
                            {
                                Process-WindowsRightOsMismatchException -ex $_.Exception
                            }

                            if ($winRights)
                            {
                                foreach ($winRight in $winRights)
                                {
                                    if ($winRight)
                                    {
                                        foreach ($zone in $zones)
                                        {
                                            if ($zone -And $winRight.Computer)
                                            {
                                                if ($winRight.Computer.Zone.DistinguishedName.ToLower() -eq $zone.DistinguishedName.ToLower())
                                                {
                                                    $WindowsRightRecords.Value += $winRight
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }           
    elseif ($ComputerSams)
    {
        foreach ($computerSam in $ComputerSams)
        {
            if ($computerSam)
            {
                if ($UnixRightRecords)
                {
                    $unixRights = @()

                    try
                    {
                        $unixRights = Get-CdmEffectiveUnixRight -Computer $computerSam
                    }
                    catch [Exception]
                    {
                        Process-UnixRightOsMismatchException -ex $_.Exception
                    }

                    if ($unixRights)
                    {
                        foreach ($unixRight in $unixRights)
                        {
                            if ($unixRight)
                            {
                                foreach ($zone in $zones)
                                {
                                    if ($zone -And $unixRight.Computer)
                                    {
                                        if ($unixRight.Computer.Zone.DistinguishedName.ToLower() -eq $zone.DistinguishedName.ToLower())
                                        {
                                            $UnixRightRecords.Value += $unixRight
                                        }
                                    }
                                }
                            }
                        }
                    }
                }

                if ($WindowsRightRecords)
                {
                    $winRights = @()

                    try
                    {
                        $winRights = Get-CdmEffectiveWindowsRight -Computer $computerSam
                    }
                    catch [Exception]
                    {
                        Process-WindowsRightOsMismatchException -ex $_.Exception
                    }

                    if ($winRights)
                    {
                        foreach ($winRight in $winRights)
                        {
                            if ($winRight)
                            {
                                foreach ($zone in $zones)
                                {
                                    if ($zone -And $winRight.Computer)
                                    {
                                        if ($winRight.Computer.Zone.DistinguishedName.ToLower() -eq $zone.DistinguishedName.ToLower())
                                        {
                                            $WindowsRightRecords.Value += $winRight
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    elseif ($UserSams)
    {    
        foreach ($zone in $zones) 
        {
            if ($zone)
            {
                foreach ($userSam in $UserSams)
                {                
                    if ($userSam)
                    {
                        if ($UnixRightRecords)
                        {
                            try
                            {
                                foreach ($right in (Get-CdmEffectiveUnixRight -User $userSam -ComputersInZone $zone))
                                {
                                    if ($right)
                                    {
                                        $UnixRightRecords.Value += $right
                                    }
                                }
                            }
                            catch [Exception]
                            {
                                Process-ClassicZoneNotSupportedException -ex $_.Exception
                            }
                        }

                        if ($windowsRightRecords)
                        {
                            try
                            {
                                foreach ($right in (Get-CdmEffectiveWindowsRight -User $userSam -ComputersInZone $zone))
                                {
                                    if ($right)
                                    {
                                        $WindowsRightRecords.Value += $right
                                    }
                                }                                
                            }
                            catch [Exception]
                            {
                                Process-ClassicZoneNotSupportedException -ex $_.Exception
                            }
                        }
                    }
                }
            }
        }
    }
    else
    {
        foreach ($zone in $Zones)
        {
            if ($zone)
            {
                if ($UnixRightRecords)
                {
                    foreach ($right in (Get-CdmEffectiveUnixRight -ComputersInZone $zone))
                    {
                        if ($right)
                        {
                            $UnixRightRecords.Value += $right
                        }
                    }
                }

                if ($WindowsRightRecords)
                {
                    foreach ($right in (Get-CdmEffectiveWindowsRight -ComputersInZone $zone))
                    {
                        if ($right)
                        {
                            $WindowsRightRecords.Value += $right
                        }
                    }
                }
            }
        }
    }
}

function Process-UnixRightOsMismatchException([Exception]$ex)
{
    $expected = $false

    if ($ex -Is [ApplicationException])
    {
        if ($ex.Message.ToLower() -eq "please specify a unix computer.".ToLower())
        {
            $expected = $true
        }
    }

    if (!$expected)
    {
        throw $_
    }
}

function Process-WindowsRightOsMismatchException([Exception]$ex)
{
    $expected = $false
    
    if ($ex -Is [ApplicationException])
    {
        if ($ex.Message.ToLower() -eq "please specify a windows computer.".ToLower())
        {
            $expected = $true
        }
    }

    if (!$expected)
    {
        throw $_
    }
}

function Process-ClassicZoneNotSupportedException([Exception]$ex)
{
    $expected = $false

    if ($ex -Is [ApplicationException])
    {
        if ($ex.Message.ToLower() -eq "classic zone is not supported.".ToLower())
        {
            $expected = $true
        }
    }

    if (!$expected)
    {
        throw $_
    }
}

function Replace-TagHelper([string]$Content, [string]$Tag, [string]$DisplayText)
{
    $tagIndex = -1
    $tagLength = -1
    $result = $Content

    if ($result)
    {
        $tagLength = $Tag.Length

        while (($tagIndex = $result.ToLower().IndexOf($Tag.ToLower())) -gt -1)
        {
            $result = $result.Remove($tagIndex, $taglength)
            $result = $result.Insert($tagIndex, $DisplayText)
        }
    }

    return $result
}

function Get-HomeDirDisplayPathHelper([string]$Path, [string]$DisplayHome, [string]$DisplayUser)
{    
    $homeTag = "%{home}"
    $userTag = "%{user}"
    $result = $path

    $result = Replace-TagHelper -Content $result -Tag $homeTag -DisplayText $DisplayHome
    $result = Replace-TagHelper -Content $result -Tag $userTag -DisplayText $DisplayUser

    return $result    
}

#Check if the zone matching with the specified domain names
function Verify-ZoneDomainHelper([Centrify.DirectControl.PowerShell.Types.CdmZone]$Zone, [string[]]$DomainNames)
{
    $result = $false

    if ($DomainNames -And $Zone)
    {
        foreach ($domainName in $DomainNames)
        {
            if ($domainName)
            {  
                if ($Zone.Domain.ToLower() -eq $domainName.ToLower())
                {
                    $result = $true
                    break
                }
            }
        }
    }
    else
    {
        $result = $true
    }

    return $result
}

#Check if the zone matching with the specified zone names
function Verify-ZoneNameHelper([Centrify.DirectControl.PowerShell.Types.CdmZone]$Zone, [string[]]$ZoneNames)
{
    $result = $false

    if ($ZoneNames -And $Zone)
    {
        foreach ($zoneName in $ZoneNames)
        {
            if ($zoneName)
            {
                if ($Zone.Name.ToLower() -eq $zoneName.ToLower())
                {
                    $result = $true
                    break
                }
            }
        }
    }
    else
    {
        $result = $true
    }

    return $result
}

#e.g. for .WhenCreated of DirectoryEntry
function Get-DateTimeFromUtcCodedTimeHelper([DateTime]$UtcCodedTime)
{
    #change to original first
    $result = [TimeZoneInfo]::ConvertTimeFromUtc($UtcCodedTime, [TimeZoneInfo]::Local)

    #set with timezone
    $result = [TimeZoneInfo]::ConvertTime($result, $m_TimeZone)

    return $result 
}

#e.g. for .PwdLastSet of DirectoryEntry
function Get-DateTimeFromLargeIntegerHelper([object]$LargeInteger)
{
    $result = [TimeZoneInfo]::ConvertTime([DateTime]::FromFileTime($compDirEntry.ConvertLargeIntegerToInt64($largeInteger)), $m_TimeZone)

    return $result
}

Import-Module "ActiveDirectory"
$primaryGroup = @{}
function GetUserProfilesByZone()
{
    Param(
        [Parameter(Mandatory=$True,ValueFromPipeline=$True)]
        [Centrify.DirectControl.PowerShell.Types.CdmZone]$Zone,
        [string[]]$Users
    )

    Process
    {
        if ($Users)
        {
            foreach ($user in $Users)
            {
                try
                {
                    Get-CdmUserProfile -Zone $Zone -User $user
                }
                catch [Exception] 
                {
                    $errorMsg = "Failed to get user profiles in the zone '$Zone'. Error message: " + $_.Exception.Message
                    Write-Warning $errorMsg
                }
            }
        }
        else
        {
            try
            {
                Get-CdmUserProfile -Zone $Zone
            }
            catch [Exception] 
            {
                $errorMsg = "Failed to get user profiles in the zone '$Zone'. Error message: " + $_.Exception.Message
                Write-Warning $errorMsg
            }
        }
    }
}


function GetUserProfileByUser()
{
    Param(
        [Parameter(Mandatory=$True,ValueFromPipeline=$True)]
        [string]$User
    )

    Process
    {
        try
        {
            Get-CdmUserProfile -User $User
        }
        catch [Exception] 
        {
            $errorMsg = "Failed to get user profile for user '$User'. Error message: " + $_.Exception.Message
            Write-Warning $errorMsg
        }
    }
}

function GetUserPrimaryGroup()
{
    Param(
        [Parameter(Mandatory=$True)]
        [object]$UserProfile
    )
    $groupName = $null

    if ($UserProfile)
    {
        $key = $UserProfile.Zone.DistinguishedName.ToLower() + $UserProfile.PrimaryGroupId
        $groupName = $primaryGroup.Get_Item($key)
        if (!$groupName)
        {
            $groupName = $UserProfile.PrimaryGroupId
            if ($groupName)
            {
                $groupProfile = Get-CdmGroupProfile -Zone $UserProfile.Zone -GID $UserProfile.PrimaryGroupId
                if ($groupProfile)
                {
                    $groupName = $groupProfile.Name
                }
            }
            if (!$primaryGroup.ContainsKey($key))
            {
                $primaryGroup.Add($key, $groupName)
            }
        }
    }
    
    return $groupName
}

$ZoneDomain = "blah.com"
$zones = Get-ZonesHelper -DomainNames $ZoneDomain -ZoneNames $Zone 
$table=@()


foreach ($z in $zones)
{
    if ($z)
    {
        
        $profiles = GetUserProfilesByZone -Zone $z
        foreach ($UserProfile in $profiles){
	        if ($UserProfile){

	            $aDUser = ""
	            if ($UserProfile.User)
	            {
	                $aDUser = $UserProfile.User.ToString()
	            }
	            $groupProfileName = GetUserPrimaryGroup -UserProfile $userProfile

	            $centrifyUser = $userProfile.Name
	                try 
	                {
	                    $user=get-aduser $centrifyUser -Properties accountexpirationdate
	                        if($user.accountexpirationdate -lt (get-date) -and $user.accountexpirationdate -ne $null){
	                            $expired = $true
	                            $ADenabled = $user.enabled
	                        }
	                        else{
	                            $expired = $false
	                            $ADenabled = $user.enabled
	                        }
	                } 
	                catch [Microsoft.ActiveDirectory.Management.ADIdentityNotFoundException]
	                {
	                    $ADdeleted = $true
	                    $ADenabled = $false
	                }
	                
	            $record = new-object psobject -property @{"Zone"=$UserProfile.Zone.Name; "AD User"=$aDUser; "UNIX User Name"=$UserProfile.Name; "UID"=$UserProfile.Uid; "Shell"=$UserProfile.Shell; "Home Directory"=$UserProfile.HomeDirectory; "Is Enabled"=$UserProfile.UnixEnabled; "Primary Group"=$groupProfileName ; "Deleted off AD"=$ADdeleted ; "AD Enabled"=$ADenabled ; "AD Expired"=$expired}  
	            $table += $record
            }
    	}
	}
}

$table | export-csv -path "C:\Program Files\Centrify\PowerShell\Centrify.DirectControl.PowerShell\Reports\centrify.csv"

$recipients = @("user@blah.com")

foreach ($recipient in $recipients){
Send-MailMessage -to "$recipient" -from "Centrify Server" -Subject "Weekly Centrify Report" -Attachments "C:\Program Files\Centrify\PowerShell\Centrify.DirectControl.PowerShell\Reports\centrify.csv" -SmtpServer "mail.blah.com" -Body "Weekly Report of Users on Centrify"
}