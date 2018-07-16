$region = "us-west-2"
$instances = ((get-ec2instance -filter @( @{name='tag:Startup'; values="Auto"}; @{name='instance-state-code'; values = 0,80,16,32,64} ) -Region $region).instances).instanceid
foreach ($instance in $instances) {
Start-EC2Instance -InstanceId $instance -Region $region
}