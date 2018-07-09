## Create New Snapshots ##

$region = us-west-2
$instances = ((get-ec2instance -filter @( @{name='tag:Backup';values="Auto"}) -Region $region).instances).instanceid
$volumes =foreach ($instance in $instances) {
(((Get-EC2InstanceAttribute -instanceid $instance -region $region -Attribute blockdevicemapping).blockdevicemappings).ebs).volumeid
}
foreach ($volume in $volumes) {
$attachedinstance = ((get-ec2volume -VolumeId $volume -region $region).attachments).instanceid
New-ec2snapshot -VolumeId $volume -Description "Automatic Snapshot for $AttachedInstance" -region $region
}