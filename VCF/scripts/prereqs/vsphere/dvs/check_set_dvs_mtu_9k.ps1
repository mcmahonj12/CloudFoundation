# Script checks Distributed Switches deployed by VxRail Manager to ensure the Jumbo Frames has been configured.
# If not, Jumbo Frames is configured on the Distributed Switch.

Get-VDSwitch | Where-Object {($_.name -like "VMware HCIA *") -and ($_.mtu -ne "9000")} | Set-VDSwitch -Mtu 9000