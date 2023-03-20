function Get-UserAccountHealth {
    <#
    .SYNOPSIS
        This function enumerates Enabled, Disabled, Inactive, ReversibleEncryption, PasswordNotRequired, PasswordNeverExpires, KerberosDES, KerberosRequirePreAuth,
        SIDHistory AD properties for the current or specified domain.
    .DESCRIPTION
        This function enumerates Enabled, Disabled, Inactive, ReversibleEncryption, PasswordNotRequired, PasswordNeverExpires, KerberosDES, KerberosRequirePreAuth,
        SIDHistory AD properties for the current or specified domain.
    .PARAMETER Server
        Specifies an AD domain controller to bind to.
    .PARAMETER Credential
        A [Management.Automation.PSCredential] object of alternate credentials for connection to the remote system.
    .EXAMPLE
        PS C:\> Get-UserAccountHealth

        Enabled                : {CN=Administrator,CN=Users,DC=offsec,DC=local, CN=TECH$,CN=Users,DC=offsec,DC=local, CN=DEFSEC$,CN=Users,DC=offsec,DC=local, CN=test1,CN=Users,DC=offsec,DC=local...}
        Disabled               : {CN=Guest,CN=Users,DC=offsec,DC=local, CN=krbtgt,CN=Users,DC=offsec,DC=local}
        Inactive               : {CN=Guest,CN=Users,DC=offsec,DC=local}
        ReversibleEncryption   : {CN=Attacker_1,CN=Users,DC=offsec,DC=local}
        PasswordNotRequired    : {CN=Guest,CN=Users,DC=offsec,DC=local, CN=TECH$,CN=Users,DC=offsec,DC=local, CN=DEFSEC$,CN=Users,DC=offsec,DC=local}
        PasswordNeverExpires   : {CN=Administrator,CN=Users,DC=offsec,DC=local, CN=Guest,CN=Users,DC=offsec,DC=local, CN=Attacker_1,CN=Users,DC=offsec,DC=local}
        KerberosDES            : {CN=Attacker_1,CN=Users,DC=offsec,DC=local}
        KerberosRequirePreAuth : {CN=Attacker_1,CN=Users,DC=offsec,DC=local}
        SIDHistory             : {}
    .EXAMPLE
        PS C:\> $SecurePassword = ConvertTo-SecureString 'Welcome01!' -AsPlainText -Force
        PS C:\> $Credential = New-Object System.Management.Automation.PSCredential('OFFSEC\test', $SecurePassword)
        PS C:\> Get-UserAccountHealth
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
                    "SIDHistory",
                    "PrimaryGroupID",
                    "UserAccountControl",
                    "DoesNotRequirePreAuth"
                )

                $Arguments['Property'] = $Properties
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
                    $InactiveDate = (Get-Date) - (New-TimeSpan -days 180)

                    $DomainUsers = @(Get-ADUser -Filter * @Arguments)

                    $OutputObject = [PSCustomObject]@{
                        "Enabled"                = @($DomainUsers.Where{ $_.Enabled -eq $True })
                        'Disabled'               = @($DomainUsers.Where{ $_.Enabled -ne $True })
                        'Inactive'               = @($DomainUsers.Where{ ($_.LastLogonDate -le $InactiveDate) -and ($_.PasswordLastSet -le $InactiveDate) })
                        'ReversibleEncryption'   = @($DomainUsers.Where{ $_.UserAccountControl -band 0x0080 })
                        'PasswordNotRequired'    = @($DomainUsers.Where{ $_.PasswordNotRequired -eq $True })
                        'PasswordNeverExpires'   = @($DomainUsers.Where{ $_.PasswordNeverExpires -eq $True })
                        'KerberosDES'            = @($DomainUsers.Where{ $_.UserAccountControl -band 0x200000 })
                        'KerberosRequirePreAuth' = @($DomainUsers.Where{ $_.DoesNotRequirePreAuth -eq $True })
                        'SIDHistory'             = @($DomainUsers.Where{ $_.SIDHistory -like "*" })
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
