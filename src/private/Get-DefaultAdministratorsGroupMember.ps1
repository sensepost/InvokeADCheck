function Get-DefaultAdministratorsGroupMember {
    <#
    .SYNOPSIS
        This function enumerates the members of the built-in Administrators group for the current (or specified) domain.
    .DESCRIPTION
        This function enumerates the members of the built-in Administrators group for the current (or specified) domain.
    .PARAMETER Server
        Specifies an AD domain controller to bind to.
    .PARAMETER Credential
        A [Management.Automation.PSCredential] object of alternate credentials for connection to the remote system.
    .EXAMPLE
        PS C:\> Get-DefaultAdministratorsGroupMember

        Name          DistinguishedName                            LastLogonDate        PasswordLastSet      ServicePrincipalName
        ----          -----------------                            -------------        ---------------      --------------------
        CLIENT01$     CN=CLIENT01,CN=Computers,DC=offsec,DC=local  2/23/2023 10:31:43 AM 2/23/2023 10:31:42 AM {}
        Administrator CN=Administrator,CN=Users,DC=offsec,DC=local 2/21/2023 4:30:42 PM 2/21/2023 2:39:36 PM {}
        user1         CN=User1,CN=Users,DC=defsec,DC=local         2/22/2023 9:22:05 PM 2/22/2023 3:23:59 PM {}
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
                    $AdministratorsGroup = Get-ADGroup -Filter * @Arguments -Properties Name, SID |
                    Where-Object -Property SID -like "*S-1-5*-544"

                    $Members = Get-ADGroupMember $AdministratorsGroup @Arguments -Recursive

                    foreach ($Member in $Members) {
                        $Arguments['Identity'] = $Member

                        if ($Member.ObjectClass -eq 'user') {
                            $Member = Get-ADUser @Arguments -Properties LastLogonDate, PasswordLastSet, ServicePrincipalName
                        }

                        if ($Member.ObjectClass -eq 'computer') {
                            $Member = Get-ADComputer @Arguments -Properties LastLogonDate, PasswordLastSet
                        }

                        if ($Member.ObjectClass -eq 'msDS-GroupManagedServiceAccount') {
                            $Member = Get-ADServiceAccount @Arguments -Properties LastLogonDate, PasswordLastSet
                        }

                        $MembersObj = New-Object -TypeName PSObject
                        $MembersObj | Add-Member -MemberType NoteProperty -Name 'Name' -Value $Member.SamAccountName
                        $MembersObj | Add-Member -MemberType NoteProperty -Name 'DistinguishedName' -Value $Member.distinguishedName
                        $MembersObj | Add-Member -MemberType NoteProperty -Name 'LastLogonDate' -Value $Member.LastLogonDate
                        $MembersObj | Add-Member -MemberType NoteProperty -Name 'PasswordLastSet' -Value $Member.PasswordLastSet
                        $MembersObj | Add-Member -MemberType NoteProperty -Name 'ServicePrincipalName' -Value $Member.ServicePrincipalName
                        $OutputObject += $MembersObj
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
