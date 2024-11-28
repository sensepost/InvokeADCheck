function Get-IADProtectedUsersGroup {
    <#
    .SYNOPSIS
        Enumerates the Protected Users group for the current or specified domain.

    .DESCRIPTION
        The Get-IADProtectedUsersGroup function enumerates the Protected Users group for the current or specified domain.

    .PARAMETER Recursive
        Gathers members of the Protected Users group recursively.

    .PARAMETER Server
        Specifies the Active Directory Domain Controller to connect to. If not provided, the function will use the default Domain Controller for the current domain.

    .PARAMETER Credential
        Specifies a PSCredential object containing alternate credentials for connecting to the remote system. If not provided, the current user's credentials will be used.

    .EXAMPLE
        PS C:\> Get-IADProtectedUsersGroup

        Retrieves the members of built-in Active Directory Protected Users group using the current user's credentials.

    .EXAMPLE
        PS C:\> $SecurePassword = ConvertTo-SecureString 'P@ssw0rd' -AsPlainText -Force
        PS C:\> $Credential = New-Object System.Management.Automation.PSCredential('AD\User', $SecurePassword)
        PS C:\> Get-IADProtectedUsersGroup -Credential $Credential

        Retrieves the members of built-in Active Directory Protected Users group using the provided alternate credentials.

    .LINK
        https://learn.microsoft.com/en-us/windows-server/security/credentials-protection-and-management/protected-users-security-group
    #>

    [CmdletBinding(SupportsShouldProcess = $True)]
    Param (
        [Parameter(Mandatory = $false)]
        [switch]
        $Recursive,

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

                    If ($PSBoundParameters['Recursive']) {
                        $Arguments['Recursive'] = $true
                    }
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
                    $ProtectedUsersGroup = Get-ADObject -filter "ObjectSID -eq `"$((get-addomain @Arguments).DomainSID.Value)-525`"" @Arguments

                    $ProtectedUsersGroupUsers = @(Get-ADObject -LDAPFilter "(&(memberOf:1.2.840.113556.1.4.1941:=$($ProtectedUsersGroup.DistinguishedName)))" -Properties * @Arguments)

                    ForEach ($GroupMember in $ProtectedUsersGroupUsers) {
                        $OutputObject+= New-Object PSObject -Property @{
                            'Name'              = $GroupMember.Name
                            'DistinguishedName' = $GroupMember.DistinguishedName
                            'SamAccountName'    = $GroupMember.SamAccountName
                            'objectClass'       = $GroupMember.ObjectClass
                            'SID'               = ($($GroupMember.objectSid.value).split('-')[-1])
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
