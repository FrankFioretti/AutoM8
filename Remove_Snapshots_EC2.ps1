## Delete Old Snapshots ##

$region = "us-west-2"
$instances = ((get-ec2instance -filter @( @{name='tag:Backup'; values="Auto"}; @{name='instance-state-code'; values = 0,80,16,32,64} ) -Region $region).instances).instanceid
$volumes =foreach ($instance in $instances) {
(((Get-EC2InstanceAttribute -instanceid $instance -region $region -Attribute blockdevicemapping).blockdevicemappings).ebs).volumeid
}

foreach ($volume in $volumes) {
    $snapshots = Get-EC2Snapshot -filter  @( @{name='volume-id';values="$volume"}) -region $region
        foreach ($snapshot in $snapshots) {
        $snapID = ($snapshot).SnapshotID
        $SnapTime = ($snapshot).Starttime
        $currentdate = (get-date)
        $snapage = (New-timespan -Start $currentdate -End $snaptime).days
        IF($snapage -ge "30") {
        Remove-Ec2Snapshot -SnapshotId $snapid -region $region -force
        } Else {
        }
        }
    }