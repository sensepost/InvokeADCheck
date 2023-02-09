
function Get-DomainController {
    <#
    .SYNOPSIS

        This function enumerates the Domain Controllers in the current (or specified) domain.

    .DESCRIPTION

        This function enumerates the Domain Controllers in the current (or specified) domain.

    .PARAMETER Server

        Specifies an AD domain controller to bind to.

    .PARAMETER Credential

        A [Management.Automation.PSCredential] object of alternate credentials
        for connection to the remote system.

    .EXAMPLE

        Get-DomainController

        Hostname         : DC01.offsec.local
        Operating System : Windows Server 2019 Datacenter Evaluation
        Domain           : offsec.local
        Forest           : offsec.local
        Site             : Default-First-Site-Name
        FSMO Roles       : SchemaMaster; DomainNamingMaster; PDCEmulator; RIDMaster; InfrastructureMaster
        Global Catalogue : True
        Read-Only        : False

    .EXAMPLE

        $SecurePassword = ConvertTo-SecureString 'Welcome01!' -AsPlainText -Force
        $Credential = New-Object System.Management.Automation.PSCredential('OFFSEC\test', $SecurePassword)

        Get-DomainControllerVersion

    #>

   [CmdletBinding(SupportsShouldProcess=$True)]
   param (
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [string]
    $Server,

    [Parameter(Mandatory=$false)]
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
                    $DomainControllers = Get-ADDomainController -filter * @Arguments

                    foreach ($DC in $DomainControllers) {
                        $obj = New-Object System.Object
                        $obj | Add-Member -type NoteProperty -Name 'Hostname' -Value $DC.HostName
                        $obj | Add-Member -type NoteProperty -Name 'Operating System' -Value $DC.OperatingSystem
                        $obj | Add-Member -type NoteProperty -Name 'Domain' -Value $DC.Domain
                        $obj | Add-Member -type NoteProperty -Name 'Forest' -Value $DC.Forest
                        $obj | Add-Member -type NoteProperty -Name 'FSMO Roles' -Value ([string]$DC.OperationMasterRoles).replace(' ', '; ')
                        $obj | Add-Member -type NoteProperty -Name 'Global Catalogue' -Value $DC.IsGlobalCatalog
                        $obj | Add-Member -type NoteProperty -Name 'Read-Only' -Value $DC.IsReadOnly
                        $obj | Add-Member -type NoteProperty -Name 'Site' -Value $DC.Site
                        $OutputObject += $obj
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
