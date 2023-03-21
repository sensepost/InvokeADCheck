function Get-KerberosDelegation {
    <#
    .SYNOPSIS
        This function enumerates xxx in the current (or specified) domain.
    .DESCRIPTION
        This function enumerates xxx in the current (or specified) domain.
    .PARAMETER Server
        Specifies an AD domain controller to bind to.
    .PARAMETER Credential
        A [Management.Automation.PSCredential] object of alternate credentials for connection to the remote system.
    .EXAMPLE
        PS C:\> Get-KerberosDelegation

    .EXAMPLE
        PS C:\> $SecurePassword = ConvertTo-SecureString 'Welcome01!' -AsPlainText -Force
        PS C:\> $Credential = New-Object System.Management.Automation.PSCredential('OFFSEC\test', $SecurePassword)

        Get-KerberosDelegation
    #>

    [CmdletBinding(SupportsShouldProcess = $True)]
    Param (
        [Parameter(Mandatory = $false)]
        [ValidateNotNullOrEmpty()]
        [string]
        $Server,

        [Parameter(Mandatory = $false)]
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

                $Properties = @(
                    'Name',
                    'ObjectClass',
                    'PrimaryGroupID',
                    'UserAccountControl',
                    'ServicePrincipalName',
                    'msDS-AllowedToDelegateTo',
                    'msDS-AllowedToActOnBehalfOfOtherIdentity'
                )

                $Arguments['Property'] = $Properties

                $OutputObject = @()
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
                    $KRBDelegationObjects = Get-ADObject -filter { ((UserAccountControl -BAND 0x0080000) -OR (UserAccountControl -BAND 0x1000000) -OR
                        (msDS-AllowedToDelegateTo -like '*') -OR (msDS-AllowedToActOnBehalfOfOtherIdentity -like '*'))
                        -AND (PrimaryGroupID -ne '516') -AND (PrimaryGroupID -ne '521') } @Arguments

                    foreach ($Object in $KRBDelegationObjects) {
                        if ($Object.UserAccountControl -BAND 0x0080000) {
                            $KRBDelegationServices = 'All Services'
                            $KRBType = 'Unconstrained'
                        }
                        else {
                            $KRBDelegationServices = 'Specific Services'
                            $KRBType = 'Constrained'
                        }

                        if ($Object.UserAccountControl -BAND 0x1000000) {
                            $KRBDelegationAllowedProtocols = 'Any (Protocol Transition)'
                            $KRBType = 'Constrained with Protocol Transition'
                        }
                        else {
                            $KRBDelegationAllowedProtocols = 'Kerberos'
                        }

                        if ($Object.'msDS-AllowedToActOnBehalfOfOtherIdentity') {
                            $KRBType = 'Resource-Based Constrained Delegation'
                        }

                        $obj = New-Object System.Object
                        $obj | Add-Member -MemberType NoteProperty -Name DistinguishedName -Value $Object.DistinguishedName -Force
                        $obj | Add-Member -MemberType NoteProperty -Name Name -Value $Object.Name -Force
                        $obj | Add-Member -MemberType NoteProperty -Name ServicePrincipalName -Value $Object.ServicePrincipalName -Force
                        $obj | Add-Member -MemberType NoteProperty -Name KerberosDelegationServices -Value $KRBDelegationServices -Force
                        $obj | Add-Member -MemberType NoteProperty -Name DelegationType -Value $KRBType -Force
                        $obj | Add-Member -MemberType NoteProperty -Name KerberosDelegationAllowedProtocols -Value $KRBDelegationAllowedProtocols -Force
                        $OutputObject += $obj
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
