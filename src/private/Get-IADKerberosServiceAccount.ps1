function Get-IADKerberosServiceAccount {
    <#
    .SYNOPSIS
        Enumerates the KRBTGT account for the current or specified domain.

    .DESCRIPTION
        The Get-IADKerberosServiceAccount function enumerates the KRBTGT account for the current (or specified) domain and returns all relevant account information.

    .PARAMETER Server
        Specifies the Active Directory Domain Controller to connect to. If not provided, the function will use the default Domain Controller for the current domain.

    .PARAMETER Credential
        Specifies a PSCredential object containing alternate credentials for connecting to the remote system. If not provided, the current user's credentials will be used.

    .EXAMPLE
        PS C:\> Get-IADKerberosServiceAccount

        Retrieves information about the KRBTGT account using the current user's credentials.

    .EXAMPLE
        PS C:\> $SecurePassword = ConvertTo-SecureString 'P@ssw0rd' -AsPlainText -Force
        PS C:\> $Credential = New-Object System.Management.Automation.PSCredential('AD\User', $SecurePassword)
        PS C:\> Get-IADKerberosServiceAccount -Credential $Credential

        Retrieves information about the KRBTGT account using the provided alternate credentials.

    .LINK
        https://learn.microsoft.com/en-us/windows-server/identity/ad-ds/manage/understand-default-user-accounts

    .LINK
        https://techcommunity.microsoft.com/t5/core-infrastructure-and-security/faqs-from-the-field-on-krbtgt-reset/ba-p/2367838

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
                    $KRBTGT = Get-ADUser 'krbtgt' -Properties 'msds-keyversionnumber', 'Created', 'PasswordLastSet' @Arguments

                    $OutputObject+= New-Object PSObject -Property @{
                        'Name'                  = $KRBTGT.Name
                        'DistinguishedName'     = $KRBTGT.DistinguishedName
                        'Created'               = $KRBTGT.Created
                        'PasswordLastSet'       = $KRBTGT.PasswordLastSet
                        'msds-keyversionnumber' = $KRBTGT.'msds-keyversionnumber'
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
