function Get-KerberosServiceAccount {
    <#
    .SYNOPSIS
        This function enumerates the KRBTGT account for the current (or specified) domain and returns all relevant account information.
    .DESCRIPTION
        This function enumerates the KRBTGT account for the current (or specified) domain and returns all relevant account information.
    .PARAMETER Server
        Specifies an AD domain controller to bind to.
    .PARAMETER Credential
        A [Management.Automation.PSCredential] object of alternate credentials for connection to the remote system.
    .EXAMPLE
        PS C:\> Get-KerberosServiceAccount

        Name                  : krbtgt
        DistinguishedName     : CN=krbtgt,CN=Users,DC=offsec,DC=local
        Created               : 30/01/2023 10:56:34
        PasswordLastSet       : 30/01/2023 10:56:34
        msds-keyversionnumber : 2

    .EXAMPLE
        PS C:\> $SecurePassword = ConvertTo-SecureString 'Welcome01!' -AsPlainText -Force
        PS C:\> $Credential = New-Object System.Management.Automation.PSCredential('OFFSEC\test', $SecurePassword)
        PS C:\> Get-KerberosServiceAccount -Credential $Credential

        Name                  : krbtgt
        DistinguishedName     : CN=krbtgt,CN=Users,DC=offsec,DC=local
        Created               : 30/01/2023 10:56:34
        PasswordLastSet       : 30/01/2023 10:56:34
        msds-keyversionnumber : 2
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

                    $OutputObject = [PSCustomObject]@{
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
