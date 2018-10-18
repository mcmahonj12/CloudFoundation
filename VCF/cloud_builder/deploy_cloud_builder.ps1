<#
Title: Deploy VMware Cloud Builder vApp
Author: Jim McMahon II
Purpose: This script consumes the data in a JSON file to properly deploy a VMware Cloud Builder VM onto a desired destination vCenter Server or ESXi host.
To use the script, update the config.json file to contain the desired vApp properties. The script will read in the content and use it to deploy the 
vApp.

Ensure to update the variables below for the desired deployment. These properties could also be turned into variables and the script made into a module for 
large scale deployments
#>

$dstVC = "192.168.1.14"
$userVC = "administrator@vsphere.local"
$userPwd = "VMware1!"
$dstDs = "vsanDatastore"
$ovaPath = "D:\Software\VCF\3.0\vcf-cloudbuild-3.0.0.0-10044179_OVF10.ova"
$ovaPropsPath = "E:\Users\Jim\Documents\Git\Projects\CloudFoundation\VCF\cloud_builder\config.json"


Write-Host "This script attempts to deploy a Cloud Builder VM. There are no error traps so use at your own risk" -ForegroundColor Red

function Menu {
    param(
        $obj
    )

    do {
        $menu = @{}
        Clear-Host
        Write-Host "**** Select a Cloud Builder instance to deploy ****" -ForegroundColor Magenta
        for ($i = 1; $i -le $obj.instances.count; $i++) {
            Write-Host "$i. $($obj.instances[$i-1].id)" -ForegroundColor Green
            $menu.Add($i, ($obj.instances[$i - 1].id))
        }

        Write-Host "***************************************************" -ForegroundColor Magenta
        Write-Host "Note: Currently no error checking here. An invalid " -ForegroundColor Red
        Write-Host "selection will throw errors." -ForegroundColor Red
        Write-Host "***************************************************" -ForegroundColor Magenta

        [int]$ans = Read-Host 'Choose an available instance or type "0" to quit'
        if ($ans -eq 0) {
            Write-Host "Exiting..."
            Exit
        }
        elseif ($ans -gt $obj.instances.count) {
            Write-Host "Invalid selection. Please try again."
            Start-Sleep(2)
        }
    
    } until ($ans -lt $obj.instances.count)

    $selection = $menu.Item($ans) ; Write-Host "The script will deploy Cloud Builder for $selection." -ForegroundColor Blue

    Return $ans
}

function Get-ConfigSettings {
    param (
        $ovaProps
    )
    $try = 3
    while (!(Test-Path $ovaProps) -and $try -gt "0") {
        if ($try -gt "0") {
            Write-Host "The pattern file in path $ovaProps does not exist."
            $ovaProps = Read-Host -Prompt "Please enter the full path to the Cloud Builder pattern file. $try attempts left"
            $try--
        }
        else {
            Write-Host "Unable to locate the Cloud Builder pattern file. The script will now exit."
            Exit
        }
    }

    $content = Get-Content -Path $ovaProps | ConvertFrom-Json

    return $content
}

function Confirm-Path($p) {
    $try = 3
    while (!(Test-Path $p) -and $try -gt "0") {
        if ($try -gt "0") {
            Write-Host "The file in path $p does not exist."
            $p = Read-Host -Prompt "Please enter the full path to the Cloud Builder OVA. $try attempts left"
            $try--
        }
        else {
            Write-Host "Unable to locate the Cloud Builder OVA. The script will now exist."
            Exit
        }
    }
}

function Set-OvaProperties {
    param (
        $settings,
        $ovaProps
    )
    #Guestinfo Settings
    $ovaProps.Common.guestinfo.ROOT_PASSWORD.Value = $settings.sudoPwd
    $ovaProps.Common.guestinfo.ADMIN_USERNAME.Value = $settings.adminUser
    $ovaProps.Common.guestinfo.ADMIN_PASSWORD.Value = $settings.adminPwd
    $ovaProps.Common.guestinfo.ip0.Value = $settings.ipAddress
    $ovaProps.Common.guestinfo.netmask0.Value = $settings.netmask
    $ovaProps.Common.guestinfo.gateway.Value = $settings.gateway
    $ovaProps.Common.guestinfo.hostname.Value = $settings.vmname
    $ovaProps.Common.guestinfo.DNS.Value = $settings.dnsIp
    $ovaProps.Common.guestinfo.ntp.Value = $settings.ntpIp

    #IP Protocol Settings
    $ovaProps.IpAssignment.IpProtocol.Value = $settings.ipProtocol

    #Network Mapping Settings
    $ovaProps.NetworkMapping.Network_1.Value = $settings.portGroup

    return $ovaProps
}

#Try connecting to the specified vCenter Server and break nicely from the script on error.
Write-Host "Connecting to destination vCenter Server $dstVC" -ForegroundColor Green
Try {
    Write-Host "Trying to connect to vCenter Server $dstVC"
    Connect-VIServer -server $dstVC -user $userVC -Password $userPwd -ErrorAction Stop | Out-Null
}
Catch {
    Write-Host "Unable to connect to $dstVC"
    Write-Host $_.Exception.Message
    Break
}

#Confirm the OVA and pattern settings are available in the specified locations.
Confirm-Path $ovaPath
$obj = Get-ConfigSettings $ovaPropsPath
$s = Menu ($obj)
$s--

Write-Host "Using Cloud Builder OVA located at $ovaPath" -ForegroundColor Magenta
Write-Host "Getting OVA properties" -ForegroundColor Magenta

#Set the OVA configuration object to be passed during deployment.
$ovaConf = Set-OvaProperties ($obj.instances[$s]) (Get-OvfConfiguration -Ovf $ovaPath)

#Choose a vApp to deploy the OVA to.
Write-Host "Destination vApp Choices" Green
Get-VApp
$vApp = Get-VApp -Name (Read-Host -Prompt 'Enter the vApp to place Cloud Builder VM')

#Choose a cluster to deploy the OVA.
Write-Host "Destination cluster options" -ForegroundColor Magenta
Get-Cluster | Select Name
$VMhost = Get-Cluster (Read-Host -Prompt 'Enter the cluster name where the vApp is located') | Get-VMhost | Sort MemoryGB | Select -first 1
$datastore = Get-Datastore $dstDs

#Deploy the Cloud Builder OVA using the desired settings above.
Write-Host "Importing the Cloud Builder vApp and setting its properties" -ForegroundColor Magenta
Import-VApp -source $ovaPath -OvfConfiguration $ovaConf -Name $ovaConf.Common.GuestInfo.hostname -VMHost $VMhost -Location $vApp -Datastore $datastore -Confirm:$false

#Power on the vApp once it has been deployed.
Write-Host "Starting the Cloud Builder vApp" -ForegroundColor Green
Start-VM | Get-VM $ovaConf.Common.GuestInfo.hostname

#Cleanup the PowerShell sessions.
Write-Host "Disconnecting from vCenter Server" -ForegroundColor Green
Disconnect-VIServer -Confirm:$false 