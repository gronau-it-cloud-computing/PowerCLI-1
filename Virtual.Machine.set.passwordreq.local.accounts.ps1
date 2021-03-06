# Description: Log in to Windows Virtual Machines and for each user set the PASSWORDREQ Windows User Flag
# Add in the PowerCLI CMDLET
Add-PSSnapin VMware.VimAutomation.Core -ErrorAction SilentlyContinue -WarningAction SilentlyContinue
# Connect to the vCenter using passthru
Connect-VIServer 10.49.11.178 -ErrorAction SilentlyContinue -WarningAction SilentlyContinue

$GuestLocal = $Host.UI.PromptForCredential("Please Enter DA Creds", "Domain Creds","AMED\joseph.kordish.da","")
$DCs = (Get-Content "C:\Users\joseph.kordish.da\Desktop\DomainControllers.txt")
$vms = (Get-VM -Location "SATX" |  Where-Object {$_.PowerState -eq "PoweredOn" -and $_.Guest.OSFullName -match "Microsoft*"})

foreach ($vm in $vms)
{
    if($DCs -notcontains $vm){
        try{
            $computer = [ADSI]"WinNT://$vm,computer"
            foreach ($user in ($computer.psbase.children | where {$_.psbase.schemaClassName -match "user"}) )
            {
                $script  = "net user " + $user.Name +" /PASSWORDREQ:YES"
                write-host $vm $user.Name
                Invoke-VMScript -VM $vm -GuestCredential $GuestLocal -ScriptType bat -ScriptText $script -RunAsync
            }
        }
            catch{
                $Error[0].Exception.Message.split(":")[1].replace("`"","").trim()
            }
        }
    }
