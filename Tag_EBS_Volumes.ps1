$region = "us-west-2"
$instances = ((get-ec2instance -filter @( @{name='tag:Backup'; values="Auto"}; @{name='instance-state-code'; values = 0,80,16,32,64} ) -Region $region).instances).instanceid
$volumes =foreach ($instance in $instances) {
(((Get-EC2InstanceAttribute -instanceid $instance -region $region -Attribute blockdevicemapping).blockdevicemappings).ebs).volumeid
}
foreach ($volume in $volumes) {
$tag = New-Object Amazon.EC2.Model.Tag
$tag.Key = "Backup"
$tag.Value = "Auto"
New-EC2Tag -Resources $volume -Tags $tag -region $region
}