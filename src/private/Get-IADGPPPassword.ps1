function Get-IADGPPPassword {
    <#
    .SYNOPSIS
        Enumerates the SYSVOL directory for GPP passwords in the current or specified domain.

    .DESCRIPTION
        The Get-IADGPPPassword function enumerates the SYSVOL directory for GPP passwords in the current or specified domain.

    .PARAMETER Server
        Specifies the Active Directory Domain Controller to connect to. If not provided, the function will use the default Domain Controller for the current domain.

    .PARAMETER Credential
        Specifies a PSCredential object containing alternate credentials for connecting to the remote system. If not provided, the current user's credentials will be used.

    .EXAMPLE
        PS C:\> Get-IADGPPPassword

        Retrieves all AD Group Policy passwords for the user's domain using the current user's credentials.

    .EXAMPLE
        PS C:\> $SecurePassword = ConvertTo-SecureString 'P@ssw0rd' -AsPlainText -Force
        PS C:\> $Credential = New-Object System.Management.Automation.PSCredential('AD\User', $SecurePassword)
        PS C:\> Get-IADGPPPassword -Credential $Credential

        Retrieves all AD Group Policy passwords for the user's domain using the provided alternate credentials.

    .LINK
        https://learn.microsoft.com/en-us/defender-for-identity/reversible-passwords-group-policy
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
                        $Arguments['Credential']    = $Credential
                    }

                    $Domain = Get-ADDomain @Arguments

                    $DriveParams = @{
                        'Root'       = "\\$($Domain.InfrastructureMaster)\SYSVOL\"
                        'PSProvider' = 'FileSystem'
                        'Name'       = 'IADSYSVOL'
                    }

                    If ($PSBoundParameters['Credential']) {
                        $DriveParams.Credential  = $Credential
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

                    [void](New-PSDrive @DriveParams)

                    $CpasswordFiles = Get-ChildItem -Path "$($DriveParams.Name):$($Domain.DNSroot)\Policies\*.xml" -Recurse | Select-String -Pattern 'cpassword'

                    ForEach ($File in $CpasswordFiles) {
                        $OutputObject += New-Object PSObject -Property @{
                            "FilePath" = $($File.toString().split(':'))[0]
                            "Row"      = $($File.toString().split(':'))[1]
                            "Value"    = $($File.toString().split(':'))[2]
                        }
                    }

                    if ((Get-PSDrive $DriveParams.Name)) {
                        Remove-PSDrive -Name $DriveParams.Name -Force
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
