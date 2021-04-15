#used to add gce servers which sit in single zones to snapshot schedules. Not necessary if VM was built using Terraform
$servers = @( "")
$servers2 = @( "" )
$servers3 = @( "" )
$region = "#region"
$project = ""
gcloud config set project $project

foreach ($server in $servers){

gcloud compute disks add-resource-policies $server --resource-policies "tier-2" --zone "$region-a"
gcloud compute disks add-resource-policies $server-data-disk --resource-policies "tier-2" --zone "$region-a"
}

foreach ($server in $servers2){

gcloud compute disks add-resource-policies $server --resource-policies "tier-2" --zone "$region-b"
gcloud compute disks add-resource-policies $server-data-disk --resource-policies "tier-2" --zone "$region-b"
}

foreach ($server in $servers3){

gcloud compute disks add-resource-policies $server --resource-policies "tier-2" --zone "$region-c"
gcloud compute disks add-resource-policies $server-data-disk --resource-policies "tier-2" --zone "$region-c"
}