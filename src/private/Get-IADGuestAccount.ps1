function Get-IADGuestAccount {
    <#
    .SYNOPSIS
        Enumerates the Guest account for the current or specified domain.
    .DESCRIPTION
        The Get-IADGuestAccount function enumerates the Guest account for the current or specified domain and returns all relevant account information.

    .PARAMETER Server
        Specifies the Active Directory Domain Controller to connect to. If not provided, the function will use the default Domain Controller for the current domain.

    .PARAMETER Credential
        Specifies a PSCredential object containing alternate credentials for connecting to the remote system. If not provided, the current user's credentials will be used.

    .EXAMPLE
        PS C:\> Get-IADGuestAccount

        Retrieves information about the Guest account using the current user's credentials.

    .EXAMPLE
        PS C:\> $SecurePassword = ConvertTo-SecureString 'P@ssw0rd' -AsPlainText -Force
        PS C:\> $Credential = New-Object System.Management.Automation.PSCredential('AD\User', $SecurePassword)
        PS C:\> Get-IADGuestAccount -Credential $Credential

        Retrieves information about the Guest account using the provided alternate credentials.

    .LINK
        https://learn.microsoft.com/en-us/windows-server/identity/ad-ds/manage/understand-default-user-accounts
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
                    $GuestAccount = Get-ADUser -Properties 'Created', 'Enabled', 'PasswordLastSet' -filter "ObjectSID -eq `"$((Get-ADDomain @Arguments).DomainSID.Value)-501`"" @Arguments
                    If ([string]::IsNullOrEmpty($GuestAccount.PasswordLastSet)) {
                        $PasswordLastSet = 'Never'
                    }
                    Else {
                        $PasswordLastSet = $GuestAccount.PasswordLastSet
                    }
                    $OutputObject+= New-Object PSObject -Property @{
                        'Name'              = $GuestAccount.Name
                        'DistinguishedName' = $GuestAccount.DistinguishedName
                        'Enabled'           = $GuestAccount.Enabled
                        'Created'           = $GuestAccount.Created
                        'PasswordLastSet'   = $PasswordLastSet
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
