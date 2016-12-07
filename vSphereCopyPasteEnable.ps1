###############################################################################
##vSphereCopyPasteEnable.ps1
##
##Description:      sets/creates advanced settings on VMs based on CSV input
##Created by:       Tobias Rasbach
##Creation Date:    Dec, 07, 2016
###############################################################################
#VARIABLES

$VMs = 'dekheft52vm*' #enter string that matches the VM name * use possible
$vcenter = "vcenter01.vmsae01.local" #script will connect to this vcenter server
$title = "Enable Copy & Paste for VMRC"
$message = "Do you want to perform the Action for these VMs?`n"

$yes = New-Object System.Management.Automation.Host.ChoiceDescription "&Yes", `
    "Perform the action for all VMs."

$no = New-Object System.Management.Automation.Host.ChoiceDescription "&No", `
    "Retain all settings."

$options = [System.Management.Automation.Host.ChoiceDescription[]]($yes, $no)
$arrValues = @()

#FUNCTIONS

function ConnectToVcenter {
    param(
        $vcenter
    )
    #Load snap-in and connect to vCenter
    #$VmSnapin = Get-PSSnapin -Name VMware.VimAutomation.Core *>$null
    
    if (!(get-PSSnapin -Name VMware.VimAutomation.Core -ErrorAction SilentlyContinue)) {
        Add-PSSnapin VMware.VimAutomation.Core
        if(get-PSSnapin -Name VMware.VimAutomation.Core -ErrorAction SilentlyContinue){"Snapin VMware.VimAutomation.Core added."}
    }
    if ($global:DefaultVIServers.Count -ne 1) {
        Connect-VIServer $vCenter
        Write-Host "Connected to vCenter: $vCenter"
    }
}


#SCRIPT MAIN
ConnectToVcenter -vcenter $vcenter

$arrVMs = Get-VM -name $VMs|sort 
$str = $arrVMs|Out-string
$result = $host.ui.PromptForChoice($title, $message + $str, $options, 0)

switch ($result)
    {
        0 {
            foreach ($vm in $arrVMs){
                $objTemp= [pscustomobject]@{VM=$vm.name; 'isolation.tools.copy.disable'=($vm|Get-AdvancedSetting -name 'isolation.tools.copy.disable').value; 'isolation.tools.paste.disable'=($vm|Get-AdvancedSetting -name 'isolation.tools.paste.disable').value}
    
                if(!($vm|Get-AdvancedSetting -name 'isolation.tools.copy.disable')){
                    if ($vm | New-AdvancedSetting -Name 'isolation.tools.copy.disable' -Value 'false' -Type 'VM' -Confirm:$false){
                        $objTemp.'isolation.tools.copy.disable' += "false (new)"
                    }
                }

                if(!($vm|Get-AdvancedSetting -name 'isolation.tools.paste.disable')){
                    if($vm | New-AdvancedSetting -Name 'isolation.tools.paste.disable' -Value 'false' -Type 'VM' -Confirm:$false){
                        $objTemp.'isolation.tools.paste.disable' += "false (new)"
                    }
                }
    
                $objTemp
                $arrValues += $objTemp
            }
        }
        1 {return(0)}
    }
