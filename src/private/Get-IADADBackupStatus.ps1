Function Get-IADADBackupStatus {
    <#
    .SYNOPSIS
        Retrieves the Active Directory backup status for the current or specified domain.

    .DESCRIPTION
        The Get-IADADBackupStatus function enumerates the Active Directory backup status for each partition in the current or specified domain. It provides information about the last backup date for each partition.

    .PARAMETER Server
        Specifies the Active Directory Domain Controller to connect to. If not provided, the function will use the default Domain Controller for the current domain.

    .PARAMETER Credential
        Specifies a PSCredential object containing alternate credentials for connecting to the remote system. If not provided, the current user's credentials will be used.

    .EXAMPLE
        PS C:\> Get-IADADBackupStatus

        Retrieves the last backup date for AD partitions of the current domain using the current user's credentials.

    .EXAMPLE
        PS C:\> $SecurePassword = ConvertTo-SecureString 'Welcome01!' -AsPlainText -Force
        PS C:\> $Credential = New-Object System.Management.Automation.PSCredential('AD\User', $SecurePassword)
        PS C:\> Get-IADADBackupStatus -Credential $Credential -Server dc01.ad.domain.tld

        Retrieves the last backup date from the specified domain controller 'dc01.ad.domain.tld' using the provided alternate credentials.

    .LINK
        https://learn.microsoft.com/en-us/windows/win32/ad/backing-up-an-active-directory-server

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

                    $Domain = (Get-ADDomainController @Arguments).Domain

                    If ($Arguments['Credential']) {
                        $CredentialUser = ($Credential.UserName.ToString())
                        $CredentialPassword = ($Credential.GetNetworkCredential().Password.ToString())

                        $Context = New-Object System.DirectoryServices.ActiveDirectory.DirectoryContext("Domain", $Domain, $CredentialUser, $CredentialPassword)
                    }
                    Else {
                        $Context = New-Object System.DirectoryServices.ActiveDirectory.DirectoryContext("Domain", $Domain)
                    }

                    $DomainController = [System.DirectoryServices.ActiveDirectory.DomainController]::findOne($Context)

                    ForEach ($Partition in $DomainController.Partitions) {
                        $DomainControllerMetadata = $DomainController.GetReplicationMetadata($partition)
                        $DsaSignature = $DomainControllerMetadata.Item("dsaSignature")
                        $BackupDate = $dsaSignature.LastOriginatingChangeTime.DateTime

                        $OutputObject += New-Object PSObject -Property @{
                            "Partition"      = $Partition
                            "LastBackupDate" = $BackupDate
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
