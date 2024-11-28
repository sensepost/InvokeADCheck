function Get-IADBuiltInGroupMembership {
    <#
    .SYNOPSIS
        Enumerates the members of built-in Active Directory groups for the current or specified domain.

    .DESCRIPTION
        The Get-IADBuiltInGroupMembership function enumerates the members of built-in Active Directory groups for the current (or specified) domain. It provides information about the number of users in comparison to the default number of users.

    .PARAMETER Server
        Specifies the Active Directory Domain Controller to connect to. If not provided, the function will use the default Domain Controller for the current domain.

    .PARAMETER Credential
        Specifies a PSCredential object containing alternate credentials for connecting to the remote system. If not provided, the current user's credentials will be used.

    .EXAMPLE
        PS C:\> Get-IADBuiltInGroupMembership

        Retrieves the members of built-in Active Directory groups using the current user's credentials.

    .EXAMPLE
        PS C:\> $SecurePassword = ConvertTo-SecureString 'P@ssw0rd' -AsPlainText -Force
        PS C:\> $Credential = New-Object System.Management.Automation.PSCredential('AD\User', $SecurePassword)
        PS C:\> Get-IADBuiltInGroupMembership -Credential $Credential

        Retrieves the members of built-in Active Directory groups using the provided alternate credentials.

    .LINK
        https://learn.microsoft.com/en-us/windows-server/identity/ad-ds/plan/security-best-practices/implementing-least-privilege-administrative-models

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

                    $ADGroups = @()
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
                    $Notes = @{
                        '544'  = 'By default this group has 3 Member(s)'
                        '512'  = 'By default this group has 1 Member(s)'
                        '519'  = 'By default this group has 1 Member(s)'
                        '518'  = 'By default this group has 1 Member(s)'
                        '548'  = 'By default this group has 0 Member(s)'
                        '549'  = 'By default this group has 0 Member(s)'
                        '520'  = 'By default this group has 1 Member(s)'
                        '1101' = 'By default this group has 0 Member(s)'
                        '527'  = 'By default this group has 0 Member(s)'
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
                    ForEach ($SID in $BuiltInADGroupSIDs.Values) {
                        $DN = Get-ADGroup -Filter * @Arguments -Properties Name, SID |
                        Where-Object -Property SID -like "*S-1-5*-$($SID)"
                        $ADGroups += $DN
                    }

                    ForEach ($ADGroup in $ADGroups) {
                        $Members = @(Get-ADObject -LDAPFilter "(&(memberOf:1.2.840.113556.1.4.1941:=$($ADGroup.DistinguishedName)))" @Arguments -Properties DistinguishedName, Name, sAMAccountName, Description)

                        $OutputObject += New-Object PSObject -Property @{
                            "Group"        = $ADGroup.Name
                            "Members"      = $Members
                            "MembersCount" = $(($Members | Measure-Object).Count)
                            "Notes"        = $Notes["$((($ADGroup.SID.Value.ToString()).Split('-'))[-1])"]
                        }
                    }

                    $OutputObject = $OutputObject | Select-Object Group, MembersCount, Notes, Members | Sort-Object MembersCount -Descending
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
