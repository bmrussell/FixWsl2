param([switch]$Help, [switch]$Fix, [switch]$UnFix, [switch]$Whatif, [string]$VpnAdapter = "PANGP Virtual Ethernet Adapter #2")

$adapters = (Get-NetAdapter | Where-Object {$_.InterfaceDescription -Match $VpnAdapter -or $_.Name -eq "vEthernet (WSL)"})
$connected = (Get-NetIPInterface | Where-Object {$_.ConnectionState -eq "Connected" -and $_.AddressFamily -eq "IPv4"})
$JoinParams = @{
	Left = $adapters
	Right = $connected
	LeftJoinProperty = 'ifIndex'
	RightJoinProperty = 'ifIndex'
	Type = 'OnlyIfInBoth'    
	LeftProperties = 'Name', 'InterfaceDescription'
	RightProperties = 'InterfaceAlias', 'InterfaceMetric'
}
$before = Join-Object @JoinParams

if ($Help -eq $true) {
	Write-Host "WSL2 is a seperate VM with its own network adapter so connecting to a VPN breaks internet connectivity"
	Write-Host "This script changes the priority of the adapters so the WSL2 NIC gets out first`n"
	Write-Host "Parameters:"
	Write-Host "  -Fix              fix WSL2 and break other stuff"
	Write-Host "  -UnFix            set things back"
	Write-Host "  -VpnAdapter Name  match your VPN adapter. The default is for GlobalProtect"
	Write-Host "  -Whatif           get a dump of the current adapters and what would be done with the above options`n"
	Write-Host "Requires Join-Object Module, install with:"
	Write-Host "   Install-Module -Name Join-Object`n"
	
	Write-Host "`n`nCurrent Interface Metrics:"

	$before
	exit 0
}

if ($Whatif -eq $true) {    	
	Write-Host "Will change Interface Metrics as follows:"
    if ($Fix -eq $true) {
        Write-Host "    vEthernet (WSL) = 1"
        Write-Host "   "$VpnAdapter " = 6000"        
    } else {
        Write-Host "    vEthernet (WSL) = 5000"
        Write-Host "   "$VpnAdapter " = 1"
    }
	Write-Host "`nOn:"
	$before    
} else {
    if ($Fix -eq $true) {
        $adapters | Where-Object {$_.Name -eq "vEthernet (WSL)"}            | Set-NetIPInterface -InterfaceMetric 1
        $adapters | Where-Object {$_.InterfaceDescription -eq $VpnAdapter}  | Set-NetIPInterface -InterfaceMetric 6000
    } else {
        $adapters | Where-Object {$_.Name -eq "vEthernet (WSL)"}            | Set-NetIPInterface -InterfaceMetric 5000
        $adapters | Where-Object {$_.InterfaceDescription -eq $VpnAdapter}  | Set-NetIPInterface -InterfaceMetric 1
    }
    $adaptersAfter = (Get-NetAdapter | Where-Object {$_.InterfaceDescription -Match $VpnAdapter -or $_.Name -eq "vEthernet (WSL)"})
    $connectedAfter = (Get-NetIPInterface | Where-Object {$_.ConnectionState -eq "Connected" -and $_.AddressFamily -eq "IPv4"})
	$JoinParams = @{
		Left = $adaptersAfter
		Right = $connectedAfter
		LeftJoinProperty = 'ifIndex'
		RightJoinProperty = 'ifIndex'
		Type = 'OnlyIfInBoth'    
		LeftProperties = 'Name', 'InterfaceDescription'
		RightProperties = 'InterfaceAlias', 'InterfaceMetric'
	}
    Join-Object @JoinParams
}

