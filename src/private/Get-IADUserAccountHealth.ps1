function Get-IADUserAccountHealth {
    <#
    .SYNOPSIS
        Enumerates common user object attributes for the current or specified domain.

    .DESCRIPTION
        The Get-IADUserAccountHealth function enumerates common user object attributes for the current or specified domain.

    .PARAMETER Server
        Specifies the Active Directory Domain Controller to connect to. If not provided, the function will use the default Domain Controller for the current domain.

    .PARAMETER Credential
        Specifies a PSCredential object containing alternate credentials for connecting to the remote system. If not provided, the current user's credentials will be used.

    .PARAMETER InactiveDate
        Used to determine the cutoff point for inactive accounts. Defaults to 180 days ( $((Get-Date) - (New-TimeSpan -Days 180)) )

    .EXAMPLE
        PS C:\> Get-IADUserAccountHealth

        Enumerates user objects attribute using the current user's credentials.

    .EXAMPLE
        PS C:\> $SecurePassword = ConvertTo-SecureString 'P@ssw0rd' -AsPlainText -Force
        PS C:\> $Credential = New-Object System.Management.Automation.PSCredential('AD\User', $SecurePassword)
        PS C:\> Get-IADUserAccountHealth -Credential $Credential

        Enumerates user objects attribute using the provided alternate credentials.

    .EXAMPLE
        PS C:\> Get-IADUserAccountHealth -InactiveDate $((Get-Date) - (New-TimeSpan -Days 30))

        Enumerates user objects attribute with the inactive date parameter using the provided alternate credentials.

    .NOTES
        This file includes code derived from the project Invoke-TrimarcADChecks available at https://github.com/Trimarc/Invoke-TrimarcADChecks, licensed under the MIT License.
        The code has been modified and adapted for use in this project.
    #>

    [CmdletBinding(SupportsShouldProcess = $True)]
    Param (
        [Parameter(Mandatory = $false)]
        [ValidateNotNullOrEmpty()]
        [String]
        $Server,

        [Parameter(Mandatory = $false)]
        [Management.Automation.PSCredential]
        [Management.Automation.CredentialAttribute()]
        $Credential = [Management.Automation.PSCredential]::Empty,

        [Parameter(Mandatory = $false)]
        [DateTime]
        $InactiveDate = $((Get-Date) - (New-TimeSpan -days 180))
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
                        "Name",
                        "Enabled",
                        "SAMAccountname",
                        "DisplayName",
                        "Enabled",
                        "LastLogonDate",
                        "PasswordLastSet",
                        "PasswordNeverExpires",
                        "PasswordNotRequired",
                        "PasswordExpired",
                        "SmartcardLogonRequired",
                        "AccountExpirationDate",
                        "AdminCount",
                        "Created",
                        "Modified",
                        "LastBadPasswordAttempt",
                        "badpwdcount",
                        "CanonicalName",
                        "DistinguishedName",
                        "ServicePrincipalName",
                        "SID",
                        "SIDHistory",
                        "PrimaryGroupID",
                        "UserAccountControl",
                        "DoesNotRequirePreAuth"
                    )

                    $Arguments['Property'] = $Properties

                    $InactiveDate = (Get-Date) - (New-TimeSpan -days 180)
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
                    $DomainUsers = Get-ADUser -Filter * @Arguments | Where-Object { $_.CanonicalName -notmatch '\$$' } | Select-Object DistinguishedName, Enabled, GivenName, Name, ObjectClass, ObjectGUID, SamAccountName, @{Name = "SID"; Expression = { $_.SID.ToString() } }, Surname, UserPrincipalName, LastLogonDate, UserAccountControl, PasswordNotRequired, PasswordNeverExpires, DoesNotRequirePreAuth, SIDHistory
                    $OutputObject += [PSCustomObject]@{
                        'AllUsers'                      = $DomainUsers
                        'Enabled'                       = $DomainUsers | Where-Object { $_.Enabled -eq $True }
                        'Disabled'                      = $DomainUsers | Where-Object { $_.Enabled -eq $False }
                        'Inactive'                      = $DomainUsers | Where-Object { ($_.LastLogonDate -le $InactiveDate) -and ($_.PasswordLastSet -le $InactiveDate) }
                        'ReversibleEncryption'          = $DomainUsers | Where-Object { $_.UserAccountControl -band 0x0080 }
                        'PasswordNotRequired'           = $DomainUsers | Where-Object { $_.PasswordNotRequired -eq $True }
                        'PasswordNeverExpires'          = $DomainUsers | Where-Object { $_.PasswordNeverExpires -eq $True }
                        'KerberosDES'                   = $DomainUsers | Where-Object { $_.UserAccountControl -band 0x200000 }
                        'KerberosDoesNotRequirePreAuth' = $DomainUsers | Where-Object { $_.DoesNotRequirePreAuth -eq $True }
                        'SIDHistory'                    = $DomainUsers | Where-Object { $_.SIDHistory -like "*" }
                        'MarkedAsSensitive'             = $DomainUsers | Where-Object { $_.UserAccountControl -band 0x100000 }
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
