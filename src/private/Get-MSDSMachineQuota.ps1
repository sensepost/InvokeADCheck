
function Get-MSDSMachineQuota {
    <#
    .SYNOPSIS

        This function enumerates the MS-DS-Machine-Account-Quota attribute for the current (or specified) domain.

    .DESCRIPTION

        This function enumerates the MS-DS-Machine-Account-Quota attribute for the current (or specified) domain.

    .PARAMETER Server

        Specifies an AD domain controller to bind to.

    .PARAMETER Credential

        A [Management.Automation.PSCredential] object of alternate credentials
        for connection to the remote system.

    .EXAMPLE

        Get-MSDSMachineQuota

        DistinguishedName  ms-DS-MachineAccountQuota
        -----------------  -------------------------
        DC=offsec,DC=local                        10

    .EXAMPLE

        $SecurePassword = ConvertTo-SecureString 'Welcome01!' -AsPlainText -Force
        $Credential = New-Object System.Management.Automation.PSCredential('OFFSEC\test', $SecurePassword)

        Get-MSDSMachineQuota

    #>

   [CmdletBinding(SupportsShouldProcess=$True)]
   param (
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [string]
    $Server,

    [Parameter(Mandatory=$false)]
    [Management.Automation.PSCredential]
    [Management.Automation.CredentialAttribute()]
    $Credential = [Management.Automation.PSCredential]::Empty
    )

    Begin {
        $FunctionName = $MyInvocation.MyCommand.Name
        Write-Debug "$($FunctionName) - Begin."
        Try {
            If ($script:ThisModuleLoaded -eq $true) {
                Get-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState
            }
            If ($PSCmdlet.ShouldProcess("$($FunctionName) - Begin WhatIf")) {
                $Arguments = @{}

                if ($PSBoundParameters['Server']) { $Arguments['Server'] = $Server }
                if ($PSBoundParameters['Credential']) { $Arguments['Credential'] = $Credential }
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
                    $MAQ = Get-ADObject -Identity ((Get-ADDomain @Arguments).distinguishedname) `
                        -Properties 'DistinguishedName', 'ms-DS-MachineAccountQuota'

                    $OutputObject = [PSCustomObject]@{
                        'DistinguishedName' = $MAQ.'DistinguishedName'
                        'ms-DS-MachineAccountQuota' = $MAQ."ms-ds-machineaccountquota"
                    }
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
                    Return $OutputObject
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
