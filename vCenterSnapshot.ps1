#take VMware snapshots
$vcserver = ""
$snapshotServerCSV = "###.csv"
import-module VMware.PowerCLI

connect-viserver -server $vcserver


#uncomment to take snapshot
#import-csv $snapshotServerCSV | %{get-vm $_.name} | new-snapshot -name BeforePatching -memory -Description "Snapshot taken before patching"

#uncomment to remove snapshot
import-csv $snapshotServerCSV| %{get-vm $_.name} | get-snapshot | where {$_.name -like "BeforePatching"} | remove-snapshot -Confirm:$false -RunAsync