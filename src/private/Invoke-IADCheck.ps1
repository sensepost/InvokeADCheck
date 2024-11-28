function Invoke-IADCheck {
    <#
    .SYNOPSIS
        Parses Invoke-ADCheck checks and executes the private functions for the selected checks.

    .DESCRIPTION
        The Invoke-IADCheck function parses Invoke-ADCheck checks and executes the private functions for the selected checks.
        Once the chosen checks have been completed, the PSCustomObject OutputObject with results is returned to the public Invoke-ADCheck function.

    .EXAMPLE
        PS C:\> Invoke-IADCheck -Checks $Checks

        This command will parse the $Checks array and execute any selected checks and return the results.
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
        $Credential = [Management.Automation.PSCredential]::Empty,

        [Parameter(Mandatory=$True)]
        [String[]]$Checks
    )

    Begin {
        $FunctionName = $MyInvocation.MyCommand.Name
        Write-Debug "$($FunctionName) - Begin."
        Try {
            If ($script:ThisModuleLoaded -eq $true) {
                Get-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState
            }
            If ($PSCmdlet.ShouldProcess("$($FunctionName) - Begin WhatIf")) {

                If ($PSBoundParameters['Server']) {
                    $Arguments['Server'] = $Server
                }

                If ($PSBoundParameters['Credential']) {
                    $Arguments['Credential']    = $Credential
                }

                Write-Verbose "$($FunctionName) - Setup empty OutputObject with predefined structure."

                $OutputObject = [PSCustomObject] @{
                    IADADBackupStatus              = $null
                    IADBuiltInGroupMembership      = $null
                    IADDefaultAdministrator        = $null
                    IADDefaultDomainPasswordPolicy = $null
                    IADDomainController            = $null
                    IADDomainTrust                 = $null
                    IADFunctionalLevel             = $null
                    IADGPO                         = $null
                    IADGPOPermission               = $null
                    IADGPPPassword                 = $null
                    IADGuestAccount                = $null
                    IADKerberosDelegation          = $null
                    IADKerberosEncryptionType      = $null
                    IADKerberosServiceAccount      = $null
                    IADMSDSMachineQuota            = $null
                    IADProtectedUsersGroup         = $null
                    IADRootACL                     = $null
                    IADTombstoneLifetime           = $null
                    IADUserAccountHealth           = $null
                }

                Write-Verbose "$($FunctionName) - Setup functions hashtable."

                $checkFunctions = @{
                    "ADBackupStatus"              = { $OutputObject.IADADBackupStatus = Get-IADADBackupStatus @Arguments }
                    "BuiltInGroupMembership"      = { $OutputObject.IADBuiltInGroupMembership = Get-IADBuiltInGroupMembership @Arguments }
                    "DefaultAdministrator"        = { $OutputObject.IADDefaultAdministrator = Get-IADDefaultAdministrator @Arguments }
                    "DefaultDomainPasswordPolicy" = { $OutputObject.IADDefaultDomainPasswordPolicy = Get-IADDefaultDomainPasswordPolicy @Arguments }
                    "DomainController"            = { $OutputObject.IADDomainController = Get-IADDomainController @Arguments }
                    "DomainTrust"                 = { $OutputObject.IADDomainTrust = Get-IADDomainTrust @Arguments }
                    "FunctionalLevel"             = { $OutputObject.IADFunctionalLevel = Get-IADFunctionalLevel @Arguments }
                    "GPO"                         = { if ($EnableGPOChecks) { $OutputObject.IADGPO = Get-IADGPO } }
                    "GPOPermission"               = { if ($EnableGPOChecks) { $OutputObject.IADGPOPermission = Get-IADGPOPermission } }
                    "GPPPassword"                 = { $OutputObject.IADGPPPassword = Get-IADGPPPassword @Arguments }
                    "GuestAccount"                = { $OutputObject.IADGuestAccount = Get-IADGuestAccount @Arguments }
                    "KerberosDelegation"          = { $OutputObject.IADKerberosDelegation = Get-IADKerberosDelegation @Arguments }
                    "KerberosEncryptionType"      = { $OutputObject.IADKerberosEncryptionType = Get-IADKerberosEncryptionType @Arguments }
                    "KerberosServiceAccount"      = { $OutputObject.IADKerberosServiceAccount = Get-IADKerberosServiceAccount @Arguments }
                    "MachineQuota"                = { $OutputObject.IADMSDSMachineQuota = Get-IADMSDSMachineQuota @Arguments }
                    "ProtectedUsersGroup"         = { $OutputObject.IADProtectedUsersGroup = Get-IADProtectedUsersGroup @Arguments }
                    "RootACL"                     = { $OutputObject.IADRootACL = Get-IADRootACL @Arguments }
                    "TombStone"                   = { $OutputObject.IADTombstoneLifetime = Get-IADTombstoneLifetime @Arguments }
                    "UserAccountHealth"           = { $OutputObject.IADUserAccountHealth = Get-IADUserAccountHealth @Arguments }
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
                    Write-Verbose "$($FunctionName) - Loop through selected checks."

                    foreach ($Check in $CheckFunctions.Keys) {
                        if ($Checks -contains "All" -or $Checks -contains $Check) {
                            $CheckFunctions[$Check].Invoke()
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
                    return $OutputObject
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
