function Get-IADFunctionalLevel {
    <#
    .SYNOPSIS
        Enumerates the Forest and Domain Functional Levels.

    .DESCRIPTION
        The Get-IADFunctionalLevel function enumerates the Forest and Domain Functional Levels.

    .PARAMETER Server
        Specifies the Active Directory Domain Controller to connect to. If not provided, the function will use the default Domain Controller for the current domain.

    .PARAMETER Credential
        Specifies a PSCredential object containing alternate credentials for connecting to the remote system. If not provided, the current user's credentials will be used.

    .EXAMPLE
        PS C:\> Get-IADFunctionalLevel

        Retrieves information about the Domain and Forest functional levels using the current user's credentials.

    .EXAMPLE
        PS C:\> $SecurePassword = ConvertTo-SecureString 'P@ssw0rd' -AsPlainText -Force
        PS C:\> $Credential = New-Object System.Management.Automation.PSCredential('AD\User', $SecurePassword)
        PS C:\> Get-IADFunctionalLevel -Credential $Credential

        Retrieves information about the Domain and Forest functional levels using the provided alternate credentials.

    .LINK
        https://learn.microsoft.com/en-us/windows-server/identity/ad-ds/active-directory-functional-levels

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
                    $OutputObject+= New-Object PSObject -Property @{
                        'ForestFunctionalLevel' = $((Get-ADForest @Arguments).ForestMode).ToString()
                        'DomainFunctionalLevel' = $((Get-ADDomain @Arguments).DomainMode).ToString()
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
