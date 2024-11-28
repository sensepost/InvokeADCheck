function Get-IADTombstoneLifetime {
    <#
    .SYNOPSIS
        Enumerates the Tombstone Lifetime attribute for the current or specified domain.

    .DESCRIPTION
        The Get-IADTombstoneLifetime function enumerates the Tombstone Lifetime attribute for the current or specified domain.

    .PARAMETER Server
        Specifies the Active Directory Domain Controller to connect to. If not provided, the function will use the default Domain Controller for the current domain.

    .PARAMETER Credential
        Specifies a PSCredential object containing alternate credentials for connecting to the remote system. If not provided, the current user's credentials will be used.

    .EXAMPLE
        PS C:\> Get-IADTombstoneLifetime

        Retrieves the value of the Tombstone Lifetime attribute using the current user's credentials.

    .EXAMPLE
        PS C:\> $SecurePassword = ConvertTo-SecureString 'P@ssw0rd' -AsPlainText -Force
        PS C:\> $Credential = New-Object System.Management.Automation.PSCredential('AD\User', $SecurePassword)
        PS C:\> Get-IADTombstoneLifetime -Credential $Credential

        Retrieves the value of the Tombstone Lifetime attribute using the provided alternate credentials.

    .LINK
        https://learn.microsoft.com/en-us/previous-versions/technet-magazine/cc137800(v=msdn.10)?redirectedfrom=MSDN

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
                    $ADConfigurationNamingContext = (Get-ADRootDSE @Arguments).configurationNamingContext
                    $TombstoneLifetime = Get-ADObject -Identity "CN=Directory Service,CN=Windows NT,CN=Services,$($ADConfigurationNamingContext)" -Partition "$ADConfigurationNamingContext" -Properties TombstoneLifetime @Arguments

                    $OutputObject+= New-Object PSObject -Property @{
                        'TombstoneLifetime' = $TombstoneLifetime.tombstoneLifetime
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
