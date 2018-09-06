Param
(
    [parameter(Mandatory=$true)]
    [String]$SubnetAZ,
	[String]$User,
    [String]$ServerName,
	[String]$Backup,
    [String]$Practice,
    [String]$OSVersion,
    [String]$InstanceType,
    [String]$DriveSize
)

import-module AWSPowerShell

$p1 = new-object Amazon.CloudFormation.Model.Parameter
$p1.ParameterKey = "SubnetAZ"
$p1.ParameterValue = "$SubnetAZ"

$p2 = new-object Amazon.CloudFormation.Model.Parameter    
$p2.ParameterKey = "User"
$p2.ParameterValue = "$User"

$p3 = new-object Amazon.CloudFormation.Model.Parameter    
$p3.ParameterKey = "ServerName"
$p3.ParameterValue = "$ServerName"

$p4 = new-object Amazon.CloudFormation.Model.Parameter    
$p4.ParameterKey = "Practice"
$p4.ParameterValue = "$Practice"

$p5 = new-object Amazon.CloudFormation.Model.Parameter    
$p5.ParameterKey = "OSVersion"
$p5.ParameterValue = "$OSVersion"

$p6 = new-object Amazon.CloudFormation.Model.Parameter    
$p6.ParameterKey = "InstanceType"
$p6.ParameterValue = "$InstanceType"

$p7 = new-object Amazon.CloudFormation.Model.Parameter    
$p7.ParameterKey = "DriveSize"
$p7.ParameterValue = "$DriveSize"

$stack = New-CFNStack -Stackname $ServerName `
-TemplateURL "https://s3.us-east-2.amazonaws.com/BUCKET/TEMPLATE.json" `
-Parameters @( $p1, $p2, $p3, $p4, $p5, $p6, $p7 ) `
-Region us-east-2