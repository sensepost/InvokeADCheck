function Get-IADDefaultDomainPasswordPolicy {
    <#
    .SYNOPSIS
        Enumerates the default domain password policy in the current or specified domain.

    .DESCRIPTION
        The Get-IADDefaultPasswordPolicy function enumerates the default domain password policy in the current or specified domain.

    .PARAMETER Server
        Specifies the Active Directory Domain Controller to connect to. If not provided, the function will use the default Domain Controller for the current domain.

    .PARAMETER Credential
        Specifies a PSCredential object containing alternate credentials for connecting to the remote system. If not provided, the current user's credentials will be used.

    .EXAMPLE
        PS C:\> Get-IADDefaultPasswordPolicy

        Retrieves the default domain password policy for the current user's domain using the current user's credentials.

    .EXAMPLE
        PS C:\> $SecurePassword = ConvertTo-SecureString 'P@ssw0rd' -AsPlainText -Force
        PS C:\> $Credential = New-Object System.Management.Automation.PSCredential('AD\User', $SecurePassword)
        PS C:\> Get-IADDefaultPasswordPolicy  -Credential $Credential

        Retrieves the default domain  password policy for the user's domain using the provided alternate credentials.
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
                    $DefaultDomainPasswordPolicy = Get-ADDefaultDomainPasswordPolicy @Arguments

                    $OutputObject += New-Object PSObject -Property @{
                        'ComplexityEnabled'             = $DefaultDomainPasswordPolicy.ComplexityEnabled
                        'LockoutDuration'               = $DefaultDomainPasswordPolicy.LockoutDuration
                        'LockoutObservationWindow'      = $DefaultDomainPasswordPolicy.LockoutObservationWindow
                        'LockoutThreshold'              = $DefaultDomainPasswordPolicy.LockoutThreshold
                        'MaxPasswordAge'                = $DefaultDomainPasswordPolicy.MaxPasswordAge.Days
                        'MinPasswordAge'                = $DefaultDomainPasswordPolicy.MinPasswordAge.Days
                        'MinPasswordLength'             = $DefaultDomainPasswordPolicy.MinPasswordLength
                        'PasswordHistoryCount'          = $DefaultDomainPasswordPolicy.PasswordHistoryCount
                        'ReversibleEncryptionEnabled'   = $DefaultDomainPasswordPolicy.ReversibleEncryptionEnabled
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
