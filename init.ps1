# 03/06/2014
# 
#
$dhcp=Get-WmiObject -Class Win32_NetworkAdapterConfiguration -Filter IPEnabled=TRUE -ComputerName . | select DHCPServer
$ip=$dhcp.DHCPServer

if ( ! ($ip -as [ipaddress]) )
{
	write-host "*** ERROR *** unable to get DHCP IP address ..."
	exit 1
}
$src='windows_install_batch.bat'
$dst="$env:systemroot\windows_install_batch.bat"
wpeutil disablefirewall
#& 'tftp.exe' '-t5' '-r3' $ip  'get' $src  $dst
write-host "Downloading script : $src from TFTP: $ip ..."
$args=("-i", "-t5" , "-r3" , $ip , "get" , $src , $dst)
Start-Process tftp.exe -ArgumentList $args -wait  -WindowStyle Hidden
wpeutil enablefirewall
if ( (test-path $dst) )
{ cmd /k $dst}
else
{
	write-host "*** ERROR *** unable to get file $src from tftp $ip"
	exit 1
}
