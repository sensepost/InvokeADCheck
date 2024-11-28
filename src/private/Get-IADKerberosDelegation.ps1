function Get-IADKerberosDelegation {
    <#
    .SYNOPSIS
        Enumerates any Kerberos delegation on the current or specified domain.

    .DESCRIPTION
        The Get-IADKerberosDelegation function enumerates any Kerberos delegation on the current (or specified) domain.

    .PARAMETER Server
        Specifies the Active Directory Domain Controller to connect to. If not provided, the function will use the default Domain Controller for the current domain.

    .PARAMETER Credential
        Specifies a PSCredential object containing alternate credentials for connecting to the remote system. If not provided, the current user's credentials will be used.

    .EXAMPLE
        PS C:\> Get-IADKerberosDelegation

        Retrieves information about Kerberos delegation for the current user's domain using the current user's credentials.

    .EXAMPLE
        PS C:\> $SecurePassword = ConvertTo-SecureString 'P@ssw0rd' -AsPlainText -Force
        PS C:\> $Credential = New-Object System.Management.Automation.PSCredential('AD\User', $SecurePassword)
        PS C:\> Get-IADKerberosDelegation -Credential $Credential

        Retrieves information about Kerberos delegation using the provided alternate credentials.

    .LINK
        https://learn.microsoft.com/en-us/defender-for-identity/security-assessment-unconstrained-kerberos

    .NOTES
        This file includes code derived from the project Invoke-TrimarcADChecks available at https://github.com/Trimarc/Invoke-TrimarcADChecks, licensed under the MIT License.
        The code has been modified and adapted for use in this project.
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
                $OutputObject = @()
                Try {
                    $Arguments = @{}

                    If ($PSBoundParameters['Server']) {
                        $Arguments['Server'] = $Server
                    }
                    If ($PSBoundParameters['Credential']) {
                        $Arguments['Credential'] = $Credential
                    }

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
    Process {
        Write-Debug "$($FunctionName) - Process."
        Try {
            If ($PSCmdlet.ShouldProcess("$($FunctionName) - Process WhatIf")) {
                Try {
                    $KRBDelegationObjects = Get-ADObject -filter { ((UserAccountControl -BAND 0x0080000) -OR (UserAccountControl -BAND 0x1000000) -OR
                        (msDS-AllowedToDelegateTo -like '*') -OR (msDS-AllowedToActOnBehalfOfOtherIdentity -like '*'))
                        -AND (PrimaryGroupID -ne '516') -AND (PrimaryGroupID -ne '521') } @Arguments

                    ForEach ($KRBObject in $KRBDelegationObjects) {
                        If ($KRBObject.UserAccountControl -BAND 0x0080000) {
                            $KRBDelegationServices = 'All Services'
                            $KRBType = 'Unconstrained'
                        }
                        Else {
                            $KRBDelegationServices = 'Specific Services'
                            $KRBType = 'Constrained'
                        }

                        If ($KRBObject.UserAccountControl -BAND 0x1000000) {
                            $KRBDelegationAllowedProtocols = 'Any (Protocol Transition)'
                            $KRBType = 'Constrained with Protocol Transition'
                        }
                        Else {
                            $KRBDelegationAllowedProtocols = 'Kerberos'
                        }

                        If ($KRBObject.'msDS-AllowedToActOnBehalfOfOtherIdentity') {
                            $KRBType = 'Resource-Based Constrained Delegation'
                        }

                        $OutputObject+= New-Object PSObject -Property @{
                            'DistinguishedName'                  = $KRBObject.DistinguishedName
                            'Name'                               = $KRBObject.Name
                            'ServicePrincipalName'               = $KRBObject.ServicePrincipalName
                            'KerberosDelegationServices'         = $KRBDelegationServices
                            'DelegationType'                     = $KRBType
                            'KerberosDelegationAllowedProtocols' = $KRBDelegationAllowedProtocols
                        }
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
