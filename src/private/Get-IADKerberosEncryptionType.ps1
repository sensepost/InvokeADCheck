function Get-IADKerberosEncryptionType {
    <#
    .SYNOPSIS
        Enumerates Kerberos encryption types for the current or specified domain.

    .DESCRIPTION
        The Get-IADKerberosEncryptionType function enumerates Kerberos encryption types for the current or specified domain.

    .PARAMETER Server
        Specifies the Active Directory Domain Controller to connect to. If not provided, the function will use the default Domain Controller for the current domain.

    .PARAMETER Credential
        Specifies a PSCredential object containing alternate credentials for connecting to the remote system. If not provided, the current user's credentials will be used.

    .EXAMPLE
        PS C:\> Get-IADKerberosEncryptionType

        Retrieves information about Kerberos encryption types for the current user's domain using the current user's credentials.

    .EXAMPLE
        PS C:\> $SecurePassword = ConvertTo-SecureString 'P@ssw0rd' -AsPlainText -Force
        PS C:\> $Credential = New-Object System.Management.Automation.PSCredential('AD\User', $SecurePassword)
        PS C:\> Get-IADKerberosEncryptionType -Credential $Credential

        Retrieves information about Kerberos kerberos encryption types using the provided alternate credentials.

    .LINK
        https://learn.microsoft.com/en-us/previous-versions/windows/it-pro/windows-10/security/threat-protection/security-policy-settings/network-security-configure-encryption-types-allowed-for-kerberos
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

                    $SupportedEncryptionTypes = @{
                        0x0  = "Not defined - Default value"
                        0x1  = "DES_CBC_CRC"
                        0x2  = "DES_CBC_MD5"
                        0x3  = "DES_CBC_CRC, DES_CBC_MD5"
                        0x4  = "RC4"
                        0x5  = "DES_CBC_CRC, RC4"
                        0x6  = "DES_CBC_MD5, RC4"
                        0x7  = "DES_CBC_CRC, DES_CBC_MD5, RC4"
                        0x8  = "AES 128"
                        0x9  = "DES_CBC_CRC, AES 128"
                        0xA  = "DES_CBC_MD5, AES 128"
                        0xB  = "DES_CBC_CRC, DES_CBC_MD5, AES 128"
                        0xC  = "RC4, AES 128"
                        0xD  = "DES_CBC_CRC, RC4, AES 128"
                        0xE  = "DES_CBC_MD5, RC4, AES 128"
                        0xF  = "DES_CBC_CBC, DES_CBC_MD5, RC4, AES 128"
                        0x10 = "AES 256"
                        0x11 = "DES_CBC_CRC, AES 256"
                        0x12 = "DES_CBC_MD5, AES 256"
                        0x13 = "DES_CBC_CRC, DES_CBC_MD5, AES 256"
                        0x14 = "RC4, AES 256"
                        0x15 = "DES_CBC_CRC, RC4, AES 256"
                        0x16 = "DES_CBC_MD5, RC4, AES 256"
                        0x17 = "DES_CBC_CRC, DES_CBC_MD5, RC4, AES 256"
                        0x18 = "AES 128, AES 256"
                        0x19 = "DES_CBC_CRC, AES 128, AES 256"
                        0x1A = "DES_CBC_MD5, AES 128, AES 256"
                        0x1B = "DES_CBC_MD5, DES_CBC_MD5, AES 128, AES 256"
                        0x1C = "RC4, AES 128, AES 256"
                        0x1D = "DES_CBC_CRC, RC4, AES 128, AES 256"
                        0x1E = "DES_CBC_MD5, RC4, AES 128, AES 256"
                        0x1F = "DES+A1:C33_CBC_MD5, DES_CBC_MD5, RC4, AES 128, AES 256"
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
                    $ADObjects = Get-ADObject -LDAPFilter "(&(|(objectclass=user)(objectClass=Computer)))" -Properties * @Arguments

                    ForEach ($ADObj in $ADObjects) {
                        If ($SupportedEncryptionTypes.Keys -contains $ADObj.'msDS-SupportedEncryptionTypes') {
                            $OutputObject+= New-Object PSObject -Property @{
                                'Name'                             = $ADObj.Name
                                'msDS-SupportedEncryptionTypes'    = $SupportedEncryptionTypes[$ADObj.'msDS-SupportedEncryptionTypes']
                                'raw-msDS-SupportedEncryptionTypes'= $ADObj.'msDS-SupportedEncryptionTypes'
                                'ObjectClass'                      = $ADObj.ObjectClass
                            }
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
