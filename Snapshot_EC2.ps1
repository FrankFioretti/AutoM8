## Create New Snapshots ##

$region = "us-west-2"
$instances = ((get-ec2instance -filter @( @{name='tag:Backup'; values="Auto"}; @{name='instance-state-code'; values = 0,80,16,32,64} ) -Region $region).instances).instanceid
$volumes =foreach ($instance in $instances) {
(((Get-EC2InstanceAttribute -instanceid $instance -region $region -Attribute blockdevicemapping).blockdevicemappings).ebs).volumeid
}
foreach ($volume in $volumes) {
$attachedinstance = ((get-ec2volume -VolumeId $volume -region $region).attachments).instanceid
$name = ((Get-EC2tag -filter @( @{name='resource-id';values="$attachedinstance"}) -region $region).Where({$_.Key -eq 'Name'})).value
$snapid = (New-ec2snapshot -VolumeId $volume -Description "Automatic Snapshot for $name" -region $region).SnapshotId
$tag = New-Object Amazon.EC2.Model.Tag
$tag.Key = "Name"
$tag.Value = "$name"
New-EC2Tag -Resources $snapid -Tags $tag -region $region
}
