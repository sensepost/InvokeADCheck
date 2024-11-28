function Get-IADGPOPermission {
    <#
    .SYNOPSIS
        Enumerates the Group Policy Object permissions in the current or specified domain.

    .DESCRIPTION
        The Get-IADGPOPermission function enumerates the Group Policy Object permissions in the current or specified domain.
        Filters out any standard group which has GPO permissions by default.

    .PARAMETER Server
        Specifies the Active Directory Domain Controller to connect to. If not provided, the function will use the default Domain Controller for the current domain.

    .EXAMPLE
        PS C:\> Get-IADGPOPermission

        Retrieves information about the Group Policy Object permissions for the current user's domain using the current user's credentials.
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
                    $StandardTrustees = @('Domain Admins', 'Enterprise Admins', 'Administrator', 'SYSTEM', 'Authenticated Users', 'ENTERPRISE DOMAIN CONTROLLERS')
                    $GPOObjects = Get-GPO -all @Arguments

                    ForEach ($GPO in $GPOObjects) {
                        $GPOPermissions = Get-GPPermissions -Guid $GPO.id -All @Arguments
                        foreach ($GPOPermission in $GPOPermissions) {
                            if ($StandardTrustees -notcontains $GPOPermission.Trustee.Name) {
                                $OutputObject += New-Object PSObject -Property @{
                                    'DisplayName' = $GPO.DisplayName
                                    'Id'          = $GPO.Id
                                    'Trustee'     = $GPOPermission.Trustee.Name
                                    'TrusteeType' = $GPOPermission.Trustee.SidType
                                    'Permission'  = $GPOPermission.Permission
                                    'Inherited'   = $GPOPermission.Inherited
                                }
                            }
                        }
                    }

                    $OutputObject = $OutputObject | Select-Object Id, DisplayName, Trustee, TrusteeType, Permission, Inherited
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
