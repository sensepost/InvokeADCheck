<#
TODO: Check whether the default encryption method has changed for newer Windows Server versions (RC4_HMAC_MD5).
#>

function Get-KerberosEncryptionType {
    <#
    .SYNOPSIS
        This function enumerates Kerberos Encryption in the current or specified domain.
    .DESCRIPTION
        This function enumerates Kerberos Encryption in the current or specified domain.
    .PARAMETER Server
        Specifies an AD domain controller to bind to.
    .PARAMETER Credential
        A [Management.Automation.PSCredential] object of alternate credentials for connection to the remote system.
    .EXAMPLE
        PS C:\> Get-KerberosEncryptionType
    .EXAMPLE
        PS C:\> $SecurePassword = ConvertTo-SecureString 'Welcome01!' -AsPlainText -Force
        PS C:\> $Credential = New-Object System.Management.Automation.PSCredential('OFFSEC\test', $SecurePassword)
        PS C:\> Get-KerberosEncryptionType

        Name          msDS-SupportedEncryptionTypes          ObjectClass
        ----          -----------------------------          -----------
        Administrator Not defined - defaults to RC4_HMAC_MD5 user
        DC1           RC4, AES 128, AES 256                  computer
        krbtgt        Not defined - defaults to RC4_HMAC_MD5 user
        CLIENT01      RC4, AES 128, AES 256                  computer
        test1         Not defined - defaults to RC4_HMAC_MD5 user
        Attacker_1    Not defined - defaults to RC4_HMAC_MD5 user
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

                $SupportedEncryptionTypes = @{
                    0x0  = "Not defined - defaults to RC4_HMAC_MD5"
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
                    $ADObjects = Get-ADObject -LDAPFilter "(&(|(objectclass=user)(objectClass=Computer)))" -Properties *

                    foreach ($ADObj in $ADObjects) {
                        if ($SupportedEncryptionTypes.Keys -contains $ADObj.'msDS-SupportedEncryptionTypes') {
                            $obj = New-Object System.Object
                            $obj | Add-Member -type NoteProperty -Name 'Name' -Value $ADObj.Name
                            $obj | Add-Member -type NoteProperty -Name 'msDS-SupportedEncryptionTypes' -Value $SupportedEncryptionTypes[$ADObj.'msDS-SupportedEncryptionTypes']
                            $obj | Add-Member -type NoteProperty -Name 'ObjectClass' -Value $ADObj.ObjectClass
                            $OutputObject += $obj
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
