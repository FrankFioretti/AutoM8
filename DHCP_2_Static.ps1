$DG = ((Get-NetIPConfiguration).IPv4DefaultGateway).NextHop
$IP = ((Get-NetIPConfiguration).IPv4Address).IPAddress
$DNS = Get-DnsClientServerAddress -InterfaceAlias "Ethernet" | Select Object -ExpandProperty ServerAddresses
Set-NetIPInterface -InterfaceAlias "Ethernet" -Dhcp Disabled
New-NetIPAddress -InterfaceAlias "Ethernet" -IPAddress $IP -PrefixLength 24 -DefaultGateway $DG
Set-DnsClientServerAddress -InterfaceAlias "Ethernet" -ServerAddresses $DNS