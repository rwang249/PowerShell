###Used to generate report of users inside certain AD groups###

import-module activedirectory

$output = ""
$groups = @("vpn_blah1","vpn_blah2")

foreach($group in $groups){
$g = $group.ToUpper()

get-adgroupmember $group | get-aduser -Properties Name, DisplayName, Description, ObjectClass, SamAccountName | select @{Label="Group Name"; Expression={"$g"}}, `
@{Label="cn"; Expression={$_.Name}}, `
@{Label="Display Name"; Expression={$_.displayname}}, `
@{Label="Description"; Expression={$_.Description}}, `
@{Label="class"; Expression={$_.ObjectClass}}, `
@{Label="Pre-W2K Name"; Expression={$_.samaccountname}} |  Export-CSV $output -notypeinformation
}