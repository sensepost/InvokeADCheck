
function Get-DefaultAdministrator {
    <#
    .SYNOPSIS
        This function enumerates the default Administrator account for the current (or specified) domain and returns all relevant account information.
    .DESCRIPTION
        This function enumerates the default Administrator account for the current (or specified) domain and returns all relevant account information.
    .PARAMETER Server
        Specifies an AD domain controller to bind to.
    .PARAMETER Credential
        A [Management.Automation.PSCredential] object of alternate credentials
        for connection to the remote system.
    .EXAMPLE
        PS C:\ > Get-DefaultAdministrator

        Name                 : Administrator
        Enabled              : True
        Created              : 30/01/2023 10:55:56
        PasswordLastSet      : 30/01/2023 10:49:30
        LastLogonDate        : 30/01/2023 11:02:51
        ServicePrincipalName : {MSSQLSvc/myhost-2.offsec.local:1432, MSSQLSvc/myhost.offsec.local:1433}
    .EXAMPLE
        PS C:\ > $SecurePassword = ConvertTo-SecureString 'Welcome01!' -AsPlainText -Force
        PS C:\ > $Credential = New-Object System.Management.Automation.PSCredential('OFFSEC\test', $SecurePassword)
        PS C:\ > Get-DefaultAdministrator -Credential $Credential

        Name                 : Administrator
        Enabled              : True
        Created              : 30/01/2023 10:55:56
        PasswordLastSet      : 30/01/2023 10:49:30
        LastLogonDate        : 30/01/2023 11:02:51
        ServicePrincipalName : {MSSQLSvc/myhost-2.offsec.local:1432, MSSQLSvc/myhost.offsec.local:1433}
    #>

    [CmdletBinding(SupportsShouldProcess = $True)]
    param (
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
                    $Administrator = Get-ADUser "$((get-addomain).DomainSID.Value)-500" -Properties 'Name', 'Enabled', 'Created', 'PasswordLastSet', 'LastLogonDate', 'ServicePrincipalName' @Arguments

                    $OutputObject = [PSCustomObject]@{
                        'Name'                 = $Administrator.Name
                        'Enabled'              = $Administrator.Enabled
                        'Created'              = $Administrator.Created
                        'PasswordLastSet'      = $Administrator.PasswordLastSet
                        'LastLogonDate'        = $Administrator.LastLogonDate
                        'ServicePrincipalName' = $Administrator.ServicePrincipalName
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