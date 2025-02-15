﻿<#
.SYNOPSIS
    Export-HVPools.ps1
.VERSION
    .8b
.DESCRIPTION
    Exports all the pools on a Horizon Connection Server and saves this into separate JSON files and Entitlements into a TXT File
.NOTES
    Author(s): Kevin Byrne (Based on work by Ivo Beerens)
    Requirements:  
    Make sure the VMware.HV.Helper module is installed, see: https://github.com/vmware/PowerCLI-Example-Scripts
    Copy the VMware.Hv.Helper to the module location.
#>

#Login variables
$horizonServer = Read-Host -Prompt 'Enter the Horizon Connection Server Name'
$username = Read-Host -Prompt 'Enter the Username (without the domain name)'
$password = Read-Host -Prompt 'Enter the Password' -AsSecureString
$domain = Read-Host -Prompt 'Enter the Horizon AD Domain'

#DEBUG login variables
#$horizonServer = "SERVER"
#$username = "USER"
#$domain = "DOMAIN"

#File location variable
$fileloc = "C:\FULLPATH"
$logfilePath = "C:\FULLPATH\FILE.txt"

Start-Transcript -Path "$logfilePath" -Append

#Connect to the Horizon Environment
Write-Output "", "Connect to the Connection Server" 
Connect-HVServer -Server $horizonServer -Domain $domain -user $username -Password $password

#Export each pools configuration into individual JSON files, and the Entitlements into individual TXT files
Write-Output "", "Connection Server pool export!", ""
$Pools = (Get-HVPool).base.name
Write-Output "Exporting these pools to Json:"
Write-Output $Pools, ""


ForEach ($Pool in $Pools) {
    
    #Exporting the Pool into a JSON file
    Write-Output "=====================================================", ""
    Write-Output "Export pool: $Pool"
    $JSONfile = ($fileloc + $Pool + ".json")
    Get-hvpool -PoolName $Pool | Get-HVPoolSpec -FilePath $JSONFile | Out-Null
    Write-Output "", "These are the Machine Names:"
    $Machinenames = (Get-HVMachine -PoolName $Pool).base.name
    Write-Output $Machinenames
    
    #Updating the JSON file with the VMs instead of Null
    $MachineJSON = (Get-Content $JSONfile | ConvertFrom-Json)
    $MachineList = [System.Collections.Generic.List[object]]::new()
    $MachineNames.ForEach({
        $MachineList.Add([pscustomobject]@{Machine=$_})
        })
    $MachineJSON.ManualDesktopSpec.Machines = $MachineList
    $MachineJSON | ConvertTo-Json -Depth 10 | Out-File $JSONFile
    
    #Exporting the Entitlements into a TXT file for each Pool
    Write-Output "", "These are the Entitlements:"
    $PoolEntitlements = (Get-HVEntitlement -ResourceName $Pool).base.DisplayName
    $EntitlementsFile = ($fileloc + $Pool + ".txt")
    Write-Output $PoolEntitlements | Tee-Object -FilePath $EntitlementsFile
    Write-Output "", "Settings and Entitlements for $Pool are Exported!", ""
    }

Write-Output "", "*************** Export Complete! ***************", ""
Disconnect-HVServer -Server $horizonServer -Confirm:$false
Stop-Transcript | Out-Null
