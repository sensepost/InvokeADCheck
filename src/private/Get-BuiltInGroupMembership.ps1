function Get-BuiltInGroupMembership {
    <#
    .SYNOPSIS
        This function enumerates the Domain Controllers in the current (or specified) domain.
    .DESCRIPTION
        This function enumerates the Domain Controllers in the current (or specified) domain.
    .PARAMETER Recursive
        Recursively gather members of the Protected Users group.
    .PARAMETER Server
        Specifies an AD domain controller to bind to.
    .PARAMETER Credential
        A [Management.Automation.PSCredential] object of alternate credentials for connection to the remote system.
    .EXAMPLE
        PS C:\> Get-BuiltInGroupMembership
    .EXAMPLE
        PS C:\> $SecurePassword = ConvertTo-SecureString 'Welcome01!' -AsPlainText -Force
        PS C:\> $Credential = New-Object System.Management.Automation.PSCredential('OFFSEC\test', $SecurePassword)
        PS C:\> Get-BuiltInGroupMembership
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

                $BuiltInADGroupSIDs = @{
                    'Administrators'              = '544'
                    'Domain Admins'               = '512'
                    'Enterprise Admins'           = '519'
                    'Schema Admins'               = '518'
                    'Account Operators'           = '548'
                    'Server Operators'            = '549'
                    'Group Policy Creator Owners' = '520'
                    'DNSAdmins'                   = '1101'
                    'Enterprise Key Admins'       = '527'
                    # 'Exchange Domain Servers' =
                    # 'Exchange Enterprise Servers' =
                    # 'Exchange Admins' =
                    # 'Organization Management' =
                    # 'Exchange Windows Permissions' =
                }

                $ADGroups = @()
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

                    foreach ($SID in $BuiltInADGroupSIDs.Values) {
                        $DN = Get-ADGroup -Filter * -Properties Name, SID |
                        Where-Object -Property SID -like "*S-1-5*-$($SID)"
                        $ADGroups += $DN
                    }

                    foreach ($ADGroup in $ADGroups) {
                        $Members = Get-ADGroupMember $ADGroup @Arguments

                        $Obj = [PSCustomObject]@{
                            'GroupName' = $ADGroup.Name
                            'Members'   = $Members.DistinguishedName
                        }

                        $OutputObject += $Obj
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
