function Write-IADChecksToCLI {
    <#
    .SYNOPSIS
        Writes the results of various Active Directory checks to the command-line interface.

    .DESCRIPTION
        The Write-IADChecksToCLI function takes the results of multiple Active Directory checks and writes them to the console in a formatted manner. It covers various aspects of AD health and security, including backup status, group memberships, account settings, and more.

    .PARAMETER Object
        A PSCustomObject containing the results of various AD checks.

    .PARAMETER Domain
        Specifies the name of the Active Directory domain being checked.

    .PARAMETER ADBackupThreshold
        Specifies the threshold date for considering AD backups as outdated. Default is 90 days ago.

    .PARAMETER PwdLastSetThreshold
        Specifies the threshold date for considering passwords as outdated. Default is 365 days ago.

    .PARAMETER LastLogonDateThreshold
        Specifies the threshold date for considering user accounts as inactive. Default is 365 days ago.

    .PARAMETER OutdatedWinVersions
        Specifies which Windows versions are considered outdated. Default is @("2000", "2003", "2008", "2012", "2016").

    .PARAMETER OutdatedFuncVersions
        Specifies which functional levels are considered outdated. Default is @("2000", "2003", "2008", "2012").

    .PARAMETER AbusableKerberosDelegationTypes
        Specifies which Kerberos delegation types are considered abusable. Default is @('Resource-Based Constrained Delegation', 'Unconstrained').

    .PARAMETER SecureKerberosEncTypes
        Specifies which Kerberos encryption types are considered secure. Default is @('8', '16', '24').

    .PARAMETER TombstoneLifetimeThreshold
        Specifies the threshold (in days) for considering the tombstone lifetime as too short. Default is 180 days.

    .EXAMPLE
        PS C:\> $CLIArgs = @{
                'Object'                          = $OutputObject
                'Domain'                          = $ADFQDN
                'ADBackupThreshold'               = $ADBackupThreshold
                'PwdLastSetThreshold'             = $PwdLastSetThreshold
                'LastLogonDateThreshold'          = $LastLogonDateThreshold
                'TombstoneLifetimeThreshold'      = $TombstoneLifetimeThreshold
                'OutdatedFuncVersions'            = $OutdatedFuncVersions
                'OutdatedWinVersions'             = $OutdatedWinVersions
                'AbusableKerberosDelegationTypes' = $AbusableKerberosDelegationTypes
                'SecureKerberosEncTypes'          = $SecureKerberosEncTypes
            }
        PS C:\> Write-IADChecksToCLI $CLIArgs

        This example runs AD health checks and then writes the results to the console with specific thresholds and criteria.

    .NOTES
        This function is part of a larger AD health checking module and relies on other functions like Update-IADOutputObjectColor and Write-IADOutput for formatting and displaying results.

    .NOTES
        This file includes code derived from the project Invoke-TrimarcADChecks available at https://github.com/Trimarc/Invoke-TrimarcADChecks, licensed under the MIT License.
        The code has been modified and adapted for use in this project.
    #>

    [CmdletBinding(SupportsShouldProcess = $True)]
    Param (
        [Parameter(Mandatory = $true)]
        [PSCustomObject]$Object,

        [Parameter(Mandatory = $true)]
        [string]$Domain,

        [Parameter(Mandatory = $true)]
        [bool]$EnableGPOChecks,

        [Parameter(Mandatory = $true)]
        [datetime]$ADBackupThreshold,

        [Parameter(Mandatory = $true)]
        [datetime]$PwdLastSetThreshold,

        [Parameter(Mandatory = $true)]
        [datetime]$LastLogonDateThreshold,

        [Parameter(Mandatory = $true)]
        [int]$TombstoneLifetimeThreshold,

        [Parameter(Mandatory = $true)]
        [array]$OutdatedFuncVersions,

        [Parameter(Mandatory = $true)]
        [array]$OutdatedWinVersions,

        [Parameter(Mandatory = $true)]
        [array]$AbusableKerberosDelegationTypes,

        [Parameter(Mandatory = $true)]
        [array]$SecureKerberosEncTypes
    )

    Begin {
        $FunctionName = $MyInvocation.MyCommand.Name
        Write-Debug "$($FunctionName) - Begin."
        Try {
            If ($script:ThisModuleLoaded -eq $true) {
                Get-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState
            }
            If ($PSCmdlet.ShouldProcess("$($FunctionName) - Begin WhatIf")) {

                $Domain = $Domain.ToString().ToUpper()

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
                    $ColeredObject = [Management.Automation.PSSerializer]::DeSerialize(
                        [Management.Automation.PSSerializer]::Serialize($Object)
                    )

                    If (($Checks -contains "All") -or
                        ($Checks -contains "ADBackupStatus")) {
                        Write-Host "[+] Active Directory Backup ($Domain):"
                        $tmp = @()
                        $ColeredObject.IADADBackupStatus | ForEach-Object {
                            If ($_.LastBackupDate -lt $ADBackupThreshold) {
                                $tmp += $_ | Update-IADOutputObjectColor -PropertyToUpdate 'LastBackupDate'
                            }
                            Else {
                                $tmp += $_
                            }
                        }

                        $tmp | Write-IADOutput
                    }
                    If (($Checks -contains "All") -or
                        ($Checks -contains "BuiltInGroupMembership")) {
                        Write-Host "[+] Default Active Directory Security Groups ($Domain):"
                        $ColeredObject.IADBuiltInGroupMembership | Select-Object Group, @{N = 'MembershipCount'; E = { $_.MembersCount } }, Notes |
                        Sort-Object -Property 'MembershipCount' -Descending | Write-IADOutput
                    }
                    If (($Checks -contains "All") -or
                        ($Checks -contains "DefaultAdministrator")) {
                        Write-Host "[+] Default Administrator Account ($Domain):"

                        If ($ColeredObject.IADDefaultAdministrator.Enabled -ne $true) {
                            [void]($ColeredObject.IADDefaultAdministrator | Update-IADOutputObjectColor -PropertyToUpdate Enabled)
                        }

                        If ($ColeredObject.IADDefaultAdministrator.MarkedAsSensitive -ne $true) {
                            [void]($ColeredObject.IADDefaultAdministrator | Update-IADOutputObjectColor -PropertyToUpdate MarkedAsSensitive)
                        }

                        If ($ColeredObject.IADDefaultAdministrator.LastLogonDate -gt $LastLogonDateThreshold) {
                            [void]($ColeredObject.IADDefaultAdministrator | Update-IADOutputObjectColor -PropertyToUpdate LastLogonDate)
                        }

                        If ($ColeredObject.IADDefaultAdministrator.PasswordLastSet -lt $PwdLastSetThreshold) {
                            [void]($ColeredObject.IADDefaultAdministrator | Update-IADOutputObjectColor -PropertyToUpdate PasswordLastSet)
                        }

                        If ($ColeredObject.IADDefaultAdministrator.ServicePrincipalName.Count -gt 0) {
                            [void]($ColeredObject.IADDefaultAdministrator | Update-IADOutputObjectColor -PropertyToUpdate ServicePrincipalName)
                        }
                        $ColeredObject.IADDefaultAdministrator | Select-Object name, Enabled, LastLogonDate, MarkedAsSensitive, created, PasswordLastSet, ServicePrincipalName | Write-IADOutput
                    }

                    If (($Checks -contains "All") -or
                        ($Checks -contains "DefaultDomainPasswordPolicy")) {
                        Write-Host "[+] Default Domain Password Policy ($Domain):"

                        If ($ColeredObject.IADDefaultDomainPasswordPolicy.ComplexityEnabled -ne $true) {
                            [void]($ColeredObject.IADDefaultDomainPasswordPolicy | Update-IADOutputObjectColor -PropertyToUpdate ComplexityEnabled)
                        }

                        If ($ColeredObject.IADDefaultDomainPasswordPolicy.ReversibleEncryptionEnabled -eq $true) {
                            [void]($ColeredObject.IADDefaultDomainPasswordPolicy | Update-IADOutputObjectColor -PropertyToUpdate ReversibleEncryptionEnabled)
                        }

                        If (($ColeredObject.IADDefaultDomainPasswordPolicy.MaxPasswordAge.TotalDays -lt 180) -or ($ColeredObject.IADDefaultDomainPasswordPolicy.MaxPasswordAge.TotalDays -gt 365)) {
                            [void]($ColeredObject.IADDefaultDomainPasswordPolicy | Update-IADOutputObjectColor -PropertyToUpdate MaxPasswordAge)
                        }

                        If ($ColeredObject.IADDefaultDomainPasswordPolicy.MinPasswordAge.TotalDays -le 1) {
                            [void]($ColeredObject.IADDefaultDomainPasswordPolicy | Update-IADOutputObjectColor -PropertyToUpdate MinPasswordAge)
                        }

                        If ($ColeredObject.IADDefaultDomainPasswordPolicy.MinPasswordLength -lt 12) {
                            [void]($ColeredObject.IADDefaultDomainPasswordPolicy | Update-IADOutputObjectColor -PropertyToUpdate MinPasswordLength)
                        }

                        If ($ColeredObject.IADDefaultDomainPasswordPolicy.PasswordHistoryCount -lt 24) {
                            [void]($ColeredObject.IADDefaultDomainPasswordPolicy | Update-IADOutputObjectColor -PropertyToUpdate PasswordHistoryCount)
                        }

                        If ($ColeredObject.IADDefaultDomainPasswordPolicy.LockoutDuration.TotalMinutes -lt 10) {
                            [void]($ColeredObject.IADDefaultDomainPasswordPolicy | Update-IADOutputObjectColor -PropertyToUpdate LockoutDuration)
                        }

                        If ($ColeredObject.IADDefaultDomainPasswordPolicy.LockoutObservationWindow.TotalMinutes -lt 10) {
                            [void]($ColeredObject.IADDefaultDomainPasswordPolicy | Update-IADOutputObjectColor -PropertyToUpdate LockoutObservationWindow)
                        }

                        If ($ColeredObject.IADDefaultDomainPasswordPolicy.LockoutThreshold -gt 5) {
                            [void]($ColeredObject.IADDefaultDomainPasswordPolicy | Update-IADOutputObjectColor -PropertyToUpdate LockoutThreshold)
                        }

                        $ColeredObject.IADDefaultDomainPasswordPolicy | Write-IADOutput
                    }
                    If (($Checks -contains "All") -or
                        ($Checks -contains "DomainController")) {
                        Write-Host "[+] Domain Controller(s) ($Domain):"
                        $OutdatedWinVersions | ForEach-Object {
                            If ($ColeredObject.IADDomainController.OperatingSystem.toLower().Contains($_.ToLower())) {
                                [void]($ColeredObject.IADDomainController | Update-IADOutputObjectColor -PropertyToUpdate OperatingSystem)
                            }
                        }
                        $ColeredObject.IADDomainController | Write-IADOutput
                    }
                    If (($Checks -contains "All") -or
                        ($Checks -contains "DomainTrust")) {
                        Write-Host "[+] Active Directory Domain Trusts ($Domain):"
                        If ($ColeredObject.IADDomainTrust) {
                            [void]($ColeredObject.IADDomainTrust | Update-IADOutputObjectColor -PropertyToUpdate Dcs)
                            $ColeredObject.IADDomainTrust | Write-IADOutput
                        }
                        Else {
                            Write-Host "    [!] No Active Directory Domain Trusts found." -ForegroundColor Green
                            Write-Host
                            Write-Host
                        }
                    }
                    If (($Checks -contains "All") -or
                        ($Checks -contains "FunctionalLevel")) {
                        Write-Host "[+] Forest and Domain Functional level ($Domain):"
                        $OutdatedFuncVersions | ForEach-Object {
                            If ($ColeredObject.IADFunctionalLevel.ForestFunctionalLevel.toLower().Contains($_.toLower())) {
                                [void]($ColeredObject.IADFunctionalLevel | Update-IADOutputObjectColor -PropertyToUpdate ForestFunctionalLevel)
                            }

                            If ($Object.IADFunctionalLevel.DomainFunctionalLevel.toLower().Contains($_.toLower())) {
                                [void]($ColeredObject.IADFunctionalLevel | Update-IADOutputObjectColor -PropertyToUpdate DomainFunctionalLevel)
                            }
                        }
                        $ColeredObject.IADFunctionalLevel | Write-IADOutput
                    }
                    if ($EnableGPOChecks) {
                        if (($Checks -contains "All") -or ($Checks -contains "GPO")) {
                            Write-Host "[+] Group Policy Objects ($Domain):"
                            if ($ColeredObject.IADGPO) {
                                $ColeredObject.IADGPO | Write-IADOutput
                            } else {
                                Write-Host "    [!] No Group Policy Objects found." -ForegroundColor Red
                                Write-Host
                                Write-Host
                            }
                        }
                        if (($Checks -contains "All") -or ($Checks -contains "GPOPermission")) {
                            Write-Host "[+] Non-default Group Policy Object permissions ($Domain):"
                            if ($ColeredObject.IADGPOPermission) {
                                $ColeredObject.IADGPOPermission | Write-IADOutput
                            } else {
                                Write-Host "    [!] No custom Group Policy Object permissions found." -ForegroundColor Green
                                Write-Host
                                Write-Host
                            }
                        }
                    }
                    If (($Checks -contains "All") -or
                        ($Checks -contains "GPPPassword")) {
                        Write-Host "[+] Group Policy Password ($Domain):"
                        If ($ColeredObject.IADGPPPassword) {
                            [void]($ColeredObject.IADGPPPassword | Update-IADOutputObjectColor -PropertyToUpdate Value)
                            $ColeredObject.IADGPPPassword | Write-IADOutput
                        }
                        Else {
                            Write-Host "    [!] No Group Policy passwords found." -ForegroundColor Green
                            Write-Host
                            Write-Host
                        }
                    }
                    If (($Checks -contains "All") -or
                        ($Checks -contains "GuestAccount")) {
                        Write-Host "[+] Guest Account ($Domain):"
                        If ($ColeredObject.IADGuestAccount.Enabled) {
                            [void]($ColeredObject.IADGuestAccount | Update-IADOutputObjectColor -PropertyToUpdate Enabled)
                        }
                        If ($ColeredObject.IADGuestAccount.PasswordLastSet) {
                            [void]($ColeredObject.IADGuestAccount | Update-IADOutputObjectColor -PropertyToUpdate PasswordLastSet)
                        }
                        $ColeredObject.IADGuestAccount | Write-IADOutput
                    }
                    If (($Checks -contains "All") -or
                        ($Checks -contains "KerberosDelegation")) {
                        Write-Host "[+] Kerberos Delegation ($Domain):"
                        If ($ColeredObject.IADKerberosDelegation) {
                            $ColeredObject.IADKerberosDelegation | ForEach-Object {
                                If ($AbusableKerberosDelegationTypes.Contains($_.DelegationType)) {
                                    [void]($ColeredObject.IADKerberosDelegation | Update-IADOutputObjectColor -PropertyToUpdate KerberosDelegationServices)
                                    [void]($ColeredObject.IADKerberosDelegation | Update-IADOutputObjectColor -PropertyToUpdate DelegationType)
                                }
                                $ColeredObject.IADKerberosDelegation | Write-IADOutput
                            }
                        }
                        Else {
                            Write-Host "    [!] No Kerberos delegations found." -ForegroundColor Green
                            Write-Host
                            Write-Host
                        }
                    }
                    If (($Checks -contains "All") -or
                        ($Checks -contains "KerberosEncryptionType")) {
                        Write-Host "[+] Kerberos Encryption Types ($Domain):"
                        $tmp = @()
                        $ColeredObject.IADKerberosEncryptionType | Where-Object { $_.'raw-msDS-SupportedEncryptionTypes' -cnotin $SecureKerberosEncTypes } | ForEach-Object {
                            $tmp += $_ | Update-IADOutputObjectColor -PropertyToUpdate 'msDS-SupportedEncryptionTypes'
                        }
                        $ColeredObject.IADKerberosEncryptionType | Where-Object { $_.'raw-msDS-SupportedEncryptionTypes' -cin $SecureKerberosEncTypes } | ForEach-Object {
                            $tmp += $_
                        }
                        Write-Host "Unique Kerberos Encryption Types active in $Domain for User Objects:"
                        $tmp | Where-Object { $_.ObjectClass -eq 'user' } | Select-Object -Unique 'msDS-SupportedEncryptionTypes' | Write-IADOutput

                        Write-Host "Unique Kerberos Encryption Types active in $Domain for Computer Objects"
                        $tmp | Where-Object { $_.ObjectClass -eq 'computer' } | Select-Object -Unique 'msDS-SupportedEncryptionTypes' | Write-IADOutput
                    }
                    If (($Checks -contains "All") -or
                        ($Checks -contains "KerberosServiceAccount")) {
                        Write-Host "[+] KRBTGT Account ($Domain):"
                        If ($ColeredObject.IADKerberosServiceAccount.PasswordLastSet -lt $PwdLastSetThreshold) {
                            [void]($ColeredObject.IADKerberosServiceAccount | Update-IADOutputObjectColor -PropertyToUpdate PasswordLastSet)
                        }
                        $ColeredObject.IADKerberosServiceAccount | Write-IADOutput
                    }
                    If (($Checks -contains "All") -or
                        ($Checks -contains "MachineQuota")) {
                        Write-Host "[+] ms-DS-Machine-Account-Quota ($Domain):"
                        If ($ColeredObject.IADMSDSMachineQuota.'ms-DS-MachineAccountQuota' -ne 0) {
                            [void]($ColeredObject.IADMSDSMachineQuota | Update-IADOutputObjectColor -PropertyToUpdate 'ms-DS-MachineAccountQuota')
                        }
                        $ColeredObject.IADMSDSMachineQuota | Write-IADOutput
                    }
                    If (($Checks -contains "All") -or
                        ($Checks -contains "ProtectedUsersGroup")) {
                        Write-Host "[+] Protected Users Security Group ($Domain):"
                        If ($ColeredObject.IADProtectedUsersGroup) {
                            $ColeredObject.IADProtectedUsersGroup | Write-IADOutput
                        }
                        Else {
                            Write-Host "    [x] No members found in the Protected Users security group." -ForegroundColor Red
                            Write-Host
                            Write-Host
                        }
                    }

                    If (($Checks -contains "All") -or
                        ($Checks -contains "RootACL")) {
                        Write-Host "[+] Interesting Active Directory domain permissions ($Domain):"
                        if ($ColeredObject.IADRootACL) {
                            $ColeredObject.IADRootACL | Write-IADOutput
                        } else {
                            Write-Host "    [x] No interesting domain permissions found." -ForegroundColor Green
                            Write-Host
                        }
                    }

                    If (($Checks -contains "All") -or
                        ($Checks -contains "TombStone")) {
                        Write-Host "[+] Tombstone Lifetime ($Domain):"
                        If ($ColeredObject.IADTombstoneLifetime.TombstoneLifetime -lt $TombstoneLifetimeThreshold) {
                            [void]($ColeredObject.IADTombstoneLifetime | Update-IADOutputObjectColor -PropertyToUpdate TombstoneLifetime)
                        }
                        $ColeredObject.IADTombstoneLifetime | Write-IADOutput
                    }
                    If (($Checks -contains "All") -or
                        ($Checks -contains "UserAccountHealth")) {
                        Write-Host "[+] User Account Health ($Domain):"

                        $totalAccounts = $($Object.IADUserAccountHealth.AllUsers | Measure-Object).Count
                        $enabledAccounts = $($Object.IADUserAccountHealth.Enabled | Measure-Object).Count
                        $disabledAccounts = $($Object.IADUserAccountHealth.Disabled | Measure-Object).Count

                        Write-Host "   [-] Total Accounts: $totalAccounts"
                        Write-Host "   [-] Enabled Accounts: $enabledAccounts"
                        Write-Host "   [-] Disabled Accounts: $disabledAccounts"

                        $inactiveCount = $($Object.IADUserAccountHealth.Inactive | Measure-Object).Count
                        Write-IADAccountHealth -Label "Accounts Identified as Inactive" -Count $inactiveCount

                        $markedAsSensitiveCount = $($Object.IADUserAccountHealth.MarkedAsSensitive | Measure-Object).Count
                        Write-IADAccountHealth -Label "Accounts Marked as Sensitive" -Count $markedAsSensitiveCount -warningThreshold 0 -ForceRedOnZeroThreshold

                        $passwordNotRequiredCount = $($Object.IADUserAccountHealth.PasswordNotRequired | Measure-Object).Count
                        Write-IADAccountHealth -Label "Accounts with Password Not Required" -Count $passwordNotRequiredCount

                        $passwordNeverExpiresCount = $($Object.IADUserAccountHealth.PasswordNeverExpires | Measure-Object).Count
                        Write-IADAccountHealth -Label "Accounts with Password Never Expires" -Count $passwordNeverExpiresCount

                        $reversibleEncryptionCount = $($Object.IADUserAccountHealth.ReversibleEncryption | Measure-Object).Count
                        Write-IADAccountHealth -Label "Accounts with Reversible Encryption" -Count $reversibleEncryptionCount

                        $kerberosRequirePreAuthCount = $($Object.IADUserAccountHealth.KerberosRequirePreAuth | Measure-Object).Count
                        Write-IADAccountHealth -Label "Accounts which do not require Kerberos Pre-auth" -Count $kerberosRequirePreAuthCount

                        $kerberosDESCount = $($Object.IADUserAccountHealth.KerberosDES | Measure-Object).Count
                        Write-IADAccountHealth -Label "Accounts with Kerberos DES" -Count $kerberosDESCount

                        $sidHistoryCount = $($Object.IADUserAccountHealth.SIDHistory | Measure-Object).Count
                        Write-IADAccountHealth -Label "Accounts with SID History" -Count $sidHistoryCount
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
