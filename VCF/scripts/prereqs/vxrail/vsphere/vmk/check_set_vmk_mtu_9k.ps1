# Script checks vmkernels deployed by VxRail Manager to ensure Jumbo Frames has been configured for vSAN and vMotion as VxRail sets all components to MTU 1500.
# If not, Jumbo Frames is configured on vSAN/vMotion vmkernels.

Write-Host "Getting all vMotion and vSAN enabled vmkernels not currently set with an MTU of 9K." -ForegroundColor Green
$vmk = Get-VDSwitch | Where-Object {$_.name -like "VMware HCIA *"} | Get-VMHost | Get-VMHostNetworkAdapter | Where-Object {(($_.VMotionEnabled -eq "True") -or ($_.VsanTrafficEnabled -eq "True")) -and ($_.mtu -ne "9000")}

if ($vmk) {
    Write-Host "Found the following vMotion/vSAN vmkernels not set for Jumbo Frames." -ForegroundColor Red
    $vmk

    Write-Host "Setting all vMotion and vSAN enabled vmkernels not currently set with an MTU of 9K." -ForegroundColor Green
    $vmk | Foreach-Object {Set-VMHostNetworkAdapter -VirtualNic $_ -Mtu 9000 -Confirm:$false}

    Write-Host "Re-checking all vMotion and vSAN enabled vmkernels have been set with an MTU of 9K." -ForegroundColor Magenta
    $vmk = Get-VDSwitch | Where-Object {$_.name -like "VMware HCIA *"} | Get-VMHost | Get-VMHostNetworkAdapter | Where-Object {(($_.VMotionEnabled -eq "True") -or ($_.VsanTrafficEnabled -eq "True")) -and ($_.mtu -ne "9000")} | Select-Object VMHost, Name, Mtu, IP | Sort-Object VMHost
}
else {
    Write-Host "No vMotion/vSAN enabled vmkernels not set with an MTU of 9K." -ForegroundColor Green
}