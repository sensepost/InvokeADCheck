function Get-IADGPO {
    <#
    .SYNOPSIS
        Enumerates the Group Policy Objects in the current or specified domain.

    .DESCRIPTION
        The Get-IADGPO function enumerates the Group Policy Objects in the current or specified domain.

    .PARAMETER Server
        Specifies the Active Directory Domain Controller to connect to. If not provided, the function will use the default Domain Controller for the current domain.

    .EXAMPLE
        PS C:\> Get-IADGPO

        Retrieves information about the Group Policy Objects for the current user's domain using the current user's credentials.
    #>

    [CmdletBinding(SupportsShouldProcess = $True)]
    Param (
        [Parameter(Mandatory = $false)]
        [ValidateNotNullOrEmpty()]
        [string]
        $Server
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
                    $GPOObjects = Get-GPO -all @Arguments

                    ForEach ($GPO in $GPOObjects) {
                        $OutputObject += New-Object PSObject -Property @{
                            'DisplayName'  = $GPO.DisplayName
                            'DomainName'   = $GPO.DomainName
                            'Owner'        = $GPO.Owner
                            'Id'           = $GPO.Id
                            'Description'  = $GPO.Description
                            'CreationTime' = $GPO.CreationTime
                        }
                    }

                    $OutputObject = $OutputObject | Select-Object Id, DisplayName, Owner, Description, DomainName, CreationTime
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
