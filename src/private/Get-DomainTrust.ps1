function Get-DomainTrust {
    <#
    .SYNOPSIS
        This function enumerates the Domain Trusts for the current (or specified) domain.
    .DESCRIPTION
        This function enumerates the Domain Trusts for the current (or specified) domain.
    .PARAMETER Server
        Specifies an AD domain controller to bind to.
    .PARAMETER Credential
        A [Management.Automation.PSCredential] object of alternate credentials for connection to the remote system.
    .EXAMPLE
        PS C:\> Get-DomainTrust

        Name              DCs                       Direction IntraForest SIDFilteringForestAware SIDFilteringQuarantined SelectiveAuthentication ForestTransitive DisallowTransivity
        ----              ---                       --------- ----------- ----------------------- ----------------------- ----------------------- ---------------- ------------------
        tech.offsec.local DC2.tech.offsec.local BiDirectional        True                   False                   False                   False            False              False
        defsec.local      DC3.defsec.local      BiDirectional       False                   False                   False                   False             True              False
    .EXAMPLE
        PS C:\> $SecurePassword = ConvertTo-SecureString 'Welcome01!' -AsPlainText -Force
        PS C:\> $Credential = New-Object System.Management.Automation.PSCredential('OFFSEC\test', $SecurePassword)
        PS C:\> Get-DomainTrust
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
                    $DomainTrusts = Get-ADTrust -Filter * @Arguments |
                    Select-Object Name, Direction, IntraForest, SIDFilteringForestAware, SIDFilteringQuarantined, `
                        SelectiveAuthentication, ForestTransitive, DisallowTransivity

                    foreach ($Trust in $DomainTrusts) {
                        $TrustedDCs = Get-ADDomainController -Filter * -Server $Trust.Name

                        $TrustsObj = New-Object -TypeName PSObject
                        $TrustsObj | Add-Member -MemberType NoteProperty -Name 'Name' -Value $Trust.Name
                        $TrustsObj | Add-Member -MemberType NoteProperty -Name 'DCs' -Value $TrustedDCs.HostName
                        $TrustsObj | Add-Member -MemberType NoteProperty -Name 'Direction' -Value $Trust.Direction
                        $TrustsObj | Add-Member -MemberType NoteProperty -Name 'IntraForest' -Value $Trust.IntraForest
                        $TrustsObj | Add-Member -MemberType NoteProperty -Name 'SIDFilteringForestAware' -Value $Trust.SIDFilteringForestAware
                        $TrustsObj | Add-Member -MemberType NoteProperty -Name 'SIDFilteringQuarantined' -Value $Trust.SIDFilteringQuarantined
                        $TrustsObj | Add-Member -MemberType NoteProperty -Name 'SelectiveAuthentication' -Value $Trust.SelectiveAuthentication
                        $TrustsObj | Add-Member -MemberType NoteProperty -Name 'ForestTransitive' -Value $Trust.ForestTransitive
                        $TrustsObj | Add-Member -MemberType NoteProperty -Name 'DisallowTransivity' -Value $Trust.DisallowTransivity
                        $OutputObject += $TrustsObj
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
