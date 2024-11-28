function Import-IADGPOModule {
    <#
    .SYNOPSIS
        Imports the GPO Management Module RSAT and installs the module if necessary.

    .DESCRIPTION
        The Import-IADADModule function checks if the GPO Management Module RSAT are available on the machine.
        If not, it prompts the user to install them. Then, it imports the GPO Management module.

    .EXAMPLE
        PS C:\> Import-IADADModule

        This command will check for the GPO Management module, prompt for installation if needed, and then import it.

    .NOTES
        Requires elevation to install RSAT if they are not already present.

    .LINK
        https://learn.microsoft.com/en-us/powershell/module/grouppolicy/
    #>

    [CmdletBinding(SupportsShouldProcess = $True)]
    Param (

    )

    Begin {
        $FunctionName = $MyInvocation.MyCommand.Name
        Write-Debug "$($FunctionName) - Begin."
        Try {
            If ($script:ThisModuleLoaded -eq $true) {
                Get-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState
            }
            If ($PSCmdlet.ShouldProcess("$($FunctionName) - Begin WhatIf")) {

            }
        }
        Catch {
            $PSCmdlet.ThrowTerminatingError($PSItem)
        }
    }
    Process {
        Write-Debug "$($FunctionName) - Process."
        Try {
            If ($PSCmdlet.ShouldProcess("$($FunctionName) - Process WhatIf")) {
                Try {

                    If (-not (Get-Module -Listavailable -Name "GroupPolicy")) {

                        Write-IADColor -Text "`n[!] It appears that the Group Policy Management Remote Server Administration Tools are missing from this machine." -Color Red
                        Write-IADColor -Text "[!] Would you like to proceed with the installation of the Group Policy Management Remote Server Administration Tools? (Y/N) " -Color Red -NoNewline
                        $Confirmed = Read-Host

                        if ($Confirmed.ToLower() -notin @('yes', 'y')) {
                            exit
                        }

                        Start-Process Powershell.exe -Wait -Verb runas -ArgumentList 'Add-WindowsCapability -Name "Rsat.GroupPolicy.Management.Tools~~~~0.0.1.0" -Online'
                    }

                    Import-Module -Name "GroupPolicy"
                }

                Catch {
                    Write-Error -Message "$($FunctionName) - $($PSItem)" -ErrorAction Stop
                }
            }
        }
        Catch {
            $PSCmdlet.ThrowTerminatingError($PSItem)
        }
    }
    End {
        Try {
            If ($PSCmdlet.ShouldProcess("$($FunctionName) - End WhatIf")) {
                Try {

                }
                Catch {
                    Write-Error -Message "$($FunctionName) - $($PSItem)" -ErrorAction Stop
                }
            }
        }
        Catch {
            $PSCmdlet.ThrowTerminatingError($PSItem)
        }
        Write-Debug "$($FunctionName) - End."
    }
}
