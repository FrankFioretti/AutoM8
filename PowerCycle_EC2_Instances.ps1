$region = "us-west-2"
$runninginstances = ((get-ec2instance -filter @( @{name='tag:PowerCycle'; values="Auto"}; @{name='instance-state-code'; values = 16} ) -Region $region).instances).instanceid
foreach ($runninginstance in $runninginstances) {
Stop-EC2Instance -InstanceId $runninginstance -Region $region
}

$stoppedinstances = ((get-ec2instance -filter @( @{name='tag:PowerCycle'; values="Auto"}; @{name='instance-state-code'; values = 80} ) -Region $region).instances).instanceid
foreach ($stoppedinstance in $stoppedinstances) {
Start-EC2Instance -InstanceId $stoppedinstance -Region $region
}