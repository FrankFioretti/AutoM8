 #Map Parameters to Variables

 Param
(
    [parameter(Mandatory=$true)]
    [String]$newemail,
	[String]$region,
    [String]$accountname,
	[String]$newinternalvpcrange,
    [String]$newdmzvpcrange,
    [String]$newinternalsubneta,
    [String]$newinternalsubnetb,
    [String]$newdmzsubneta,
    [String]$newdmzsubnetb
)


 #Manually Gather Initial Variables

 #$newemail = "NewAccount@Domain.com"
 #$region = "us-east-2"
 #$accountname = "NewAccount"
 #$newinternalvpcrange = "10.155.155.0/25"
 #$newdmzvpcrange = "10.155.155.128/25"
 #$newinternalsubneta = "10.155.155.0/26"
 #$newinternalsubnetb = "10.155.155.64/26"
 #$newdmzsubneta = "10.155.155.128/26"
 #$newdmzsubnetb = "10.155.155.192/26"
 $arnprefix = "arn:aws:iam::"
 $arnsuffix = ":role/OrganizationAccountAccessRole"
 $dhcpoptions = @( @{Key="domain-name";Values=@("domain.com")}, @{Key="domain-name-servers";Values=@("10.X.X.1","10.X.X.2")})
 $aza = $region+"a"
 $azb = $region+"b"

 #Import PS Modules
 
 Import-Module AWSPowerShell

 #Create the new account

 $newaccount = New-ORGAccount -AccountName $accountname -Email $newemail -Region $region
 $creationid = $newaccount.Id

 sleep 30

 $newaccountid = (Get-ORGAccountCreationStatus -createaccountrequestid $creationid -region $region).AccountId

 IF([string]::IsNullOrEmpty($newaccountid)) {            
    Exit            
} else {                        
}

 #Get credentials for new account
 
 $newaccountdefaultrolearn = "$arnprefix$newaccountid$arnsuffix"
 $newaccountassumerole = Use-STSRole -RoleSessionName "Admin_$accountname" -RoleArn "$newaccountdefaultrolearn"
 $newaccountcreds = $newaccountassumerole.Credentials
 $newaccesskey = ($newaccountassumerole.Credentials).AccessKeyId

 IF([string]::IsNullOrEmpty($newaccesskey)) {            
   Exit            
 } else {                        
 }

 #################################
 #Create resources in new account#
 #################################

 #Create IAM Roles and Policies

 $newadminrole = New-IAMRole -AssumeRolePolicyDocument (Get-Content -raw C:\vro\New_Admin_Role_Policy.json) -RoleName "Admin_$accountname" -Region $region -Credential $newaccountcreds
 $newhcrole = New-IAMRole -AssumeRolePolicyDocument (Get-Content -raw C:\vro\New_DevOps_Role_Policy.json) -RoleName "DevOps_$accountname" -Region $region -Credential $newaccountcreds
 $hcdevopspolicy = New-IAMPolicy -PolicyName DevOps_Policy -PolicyDocument (Get-Content -Raw C:\vro\Supplemental_Policy.json) -Region $region -Credential $newaccountcreds
 $vpcdenypolicy = New-IAMPolicy -PolicyName VPC_Deny_Policy -PolicyDocument (Get-Content -Raw C:\vro\Deny_Policy.json) -Region $region -Credential $newaccountcreds
 
 #Attach Policies to Roles
 
 Register-IAMRolePolicy -RoleName "Admin_$accountname" -PolicyArn arn:aws:iam::aws:policy/AdministratorAccess -Region $region -Credential $newaccountcreds
 Register-IAMRolePolicy -RoleName "DevOps_$accountname" -PolicyArn $hcdevopspolicy.Arn -Region $region -Credential $newaccountcreds
 Register-IAMRolePolicy -RoleName "DevOps_$accountname" -PolicyArn $vpcdenypolicy.Arn -Region $region -Credential $newaccountcreds
 Register-IAMRolePolicy -RoleName "DevOps_$accountname" -PolicyArn arn:aws:iam::aws:policy/AmazonRDSFullAccess -Region $region -Credential $newaccountcreds
 Register-IAMRolePolicy -RoleName "DevOps_$accountname" -PolicyArn arn:aws:iam::aws:policy/AmazonEC2FullAccess -Region $region -Credential $newaccountcreds
 Register-IAMRolePolicy -RoleName "DevOps_$accountname" -PolicyArn arn:aws:iam::aws:policy/SecretsManagerReadWrite -Region $region -Credential $newaccountcreds
 Register-IAMRolePolicy -RoleName "DevOps_$accountname" -PolicyArn arn:aws:iam::aws:policy/AWSLambdaFullAccess -Region $region -Credential $newaccountcreds
 Register-IAMRolePolicy -RoleName "DevOps_$accountname" -PolicyArn arn:aws:iam::aws:policy/AmazonSESFullAccess -Region $region -Credential $newaccountcreds
 Register-IAMRolePolicy -RoleName "DevOps_$accountname" -PolicyArn arn:aws:iam::aws:policy/AmazonAPIGatewayAdministrator -Region $region -Credential $newaccountcreds
 Register-IAMRolePolicy -RoleName "DevOps_$accountname" -PolicyArn arn:aws:iam::aws:policy/IAMReadOnlyAccess -Region $region -Credential $newaccountcreds
 Register-IAMRolePolicy -RoleName "DevOps_$accountname" -PolicyArn arn:aws:iam::aws:policy/AWSXrayFullAccess -Region $region -Credential $newaccountcreds

 #Create New VPCs

 $newinternalvpc = New-EC2VPC -CidrBlock $newinternalvpcrange -Region $region -Credential $newaccountcreds
 $newdmzvpc = New-EC2VPC -CidrBlock $newdmzvpcrange -Region $region -Credential $newaccountcreds
 
 #Tag New VPCs

 $newdmzvpctag = New-Object Amazon.EC2.Model.Tag
 $tag.Key = "Name"
 $tag.Value = "DMZ"
 New-EC2Tag -Resources $newdmzvpc.VpcId -Tags $newdmzvpctag -region $region -Credential $newaccountcreds

 $newinternalvpctag = New-Object Amazon.EC2.Model.Tag
 $tag.Key = "Name"
 $tag.Value = "Internal"
 New-EC2Tag -Resources $newinternalvpc.VpcId -Tags $newinternalvpctag -region $region -Credential $newaccountcreds

 #Create DHCP Options and associate with new VPCs

 $newdhcpoptions = New-EC2DhcpOption -DhcpConfiguration $dhcpoptions -Force -Region $region -Credential $newaccountcreds
 Register-EC2DhcpOption -DhcpOptionsId $newdhcpoptions.DhcpOptionsId -VpcId $newinternalvpc.VpcId -force -Region $region -Credential $newaccountcreds
 Register-EC2DhcpOption -DhcpOptionsId $newdhcpoptions.DhcpOptionsId -VpcId $newdmzvpc.VpcId -force -Region $region -Credential $newaccountcreds

 #Create New Subnets

 $newinternalsubnetida = New-EC2Subnet -VpcId $newinternalvpc.VpcId -CidrBlock $newinternalsubneta -AvailabilityZone $aza -Region $region -Credential $newaccountcreds
 $newinternalsubnetidb = New-EC2Subnet -VpcId $newinternalvpc.VpcId -CidrBlock $newinternalsubnetb -AvailabilityZone $azb -Region $region -Credential $newaccountcreds
 $newdmzsubnetida = New-EC2Subnet -VpcId $newdmzvpc.VpcId -CidrBlock $newdmzsubneta -AvailabilityZone $aza -Region $region -Credential $newaccountcreds
 $newdmzsubnetidb = New-EC2Subnet -VpcId $newdmzvpc.VpcId -CidrBlock $newdmzsubnetb -AvailabilityZone $azb -Region $region -Credential $newaccountcreds

 #Tag New Subnets

 $newinternalsubnetatag = New-Object Amazon.EC2.Model.Tag
 $newinternalsubnetatag.Key = "Name"
 $newinternalsubnetatag.Value = "Internal_A"
 New-EC2Tag -Resources $newinternalsubnetida.SubnetId -Tags $newinternalsubnetatag -region $region -Credential $newaccountcreds

 $newinternalsubnetbtag = New-Object Amazon.EC2.Model.Tag
 $newinternalsubnetbtag.Key = "Name"
 $newinternalsubnetbtag.Value = "Internal_B"
 New-EC2Tag -Resources $newinternalsubnetidb.SubnetId -Tags $newinternalsubnetbtag -region $region -Credential $newaccountcreds

 $newdmzsubnetatag = New-Object Amazon.EC2.Model.Tag
 $newdmzsubnetatag.Key = "Name"
 $newdmzsubnetatag.Value = "DMZ_A"
 New-EC2Tag -Resources $newdmzsubnetida.SubnetId -Tags $newdmzsubnetatag -region $region -Credential $newaccountcreds

 $newdmzsubnetbtag = New-Object Amazon.EC2.Model.Tag
 $newdmzsubnetbtag.Key = "Name"
 $newdmzsubnetbtag.Value = "DMZ_B"
 New-EC2Tag -Resources $newdmzsubnetidb.SubnetId -Tags $newdmzsubnetbtag -region $region -Credential $newaccountcreds

 #Create Security Groups

 $newinternalsecuritygroup = New-EC2SecurityGroup -GroupName Inbound -Description "Allows all traffic from On-Prem" -VpcId $newinternalvpc.VpcId -Region $region -Credential $newaccountcreds
 $newdmzsecuritygroup = New-EC2SecurityGroup -GroupName Inbound -Description "Allows all traffic from On-Prem" -VpcId $newdmzvpc.VpcId -Region $region -Credential $newaccountcreds

 #Add rules to security groups

 $internalruletcp = @{ IpProtocol="tcp"; FromPort="0"; ToPort="65535"; IpRanges="10.0.0.0/8" }
 $internalruleudp = @{ IpProtocol="udp"; FromPort="0"; ToPort="65535"; IpRanges="10.0.0.0/8" }
 $internalruleicmp = @{ IpProtocol="icmp"; FromPort="-1"; ToPort="-1"; IpRanges="10.0.0.0/8" }

 Grant-EC2SecurityGroupIngress -GroupId $newinternalsecuritygroup -IpPermission @( $internalruletcp, $internalruleudp, $internalruleicmp ) -Region $region -Credential $newaccountcreds
 Grant-EC2SecurityGroupIngress -GroupId $newdmzsecuritygroup -IpPermission @( $internalruletcp, $internalruleudp, $internalruleicmp ) -Region $region -Credential $newaccountcreds

 #Create VPC Peering Connection

 $newvpcpeeringconnection = New-EC2VpcPeeringConnection -VpcId $newinternalvpc.VpcId -PeerVpcId $newdmzvpc.VpcId -Force -Region $region -Credential $newaccountcreds
 Approve-EC2VpcPeeringConnection -VpcPeeringConnectionId $newvpcpeeringconnection.VpcPeeringConnectionId -Force -Region $region -Credential $newaccountcreds

 #Send Confirmation E-Mail

 $newaccountidemail = $newaccountid
 $newinternalvpcidemail = $newinternalvpc.VpcId
 $newdmzvpcemail = $newdmzvpc.VpcId
 $newaccountrootemailaddress = $newemail
 $outdata = "New Account Name = $accountname <br /> New Account Root E-Mail = $newaccountrootemailaddress <br /> New Account ID = $newaccountidemail <br /> Admin Role Name = Admin_$accountname <br /> DevOps Role Name = DevOps_$accountname <br /> Region = $region <br /> New Internal VPC ID = $newinternalvpcidemail <br /> New DMZ VPC ID = $newdmzvpcemail"
 Send-MailMessage -SmtpServer mail.domain.com  -To AWS-Org-Admins@domain.com -From "no-reply@domain.com" -Subject "AWS Account Creation - $accountname" -Bodyashtml $outdata