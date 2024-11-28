function Get-IADDomainTrust {
    <#
    .SYNOPSIS
        Enumerates the Domain Trusts for the current or specified domain.

    .DESCRIPTION
        The Get-IADDomainTrust function enumerates the Domain Trusts for the current or specified domain. It provides infromation about the configured Active Directory trust.

    .PARAMETER Server
        Specifies the Active Directory Domain Controller to connect to. If not provided, the function will use the default Domain Controller for the current domain.

    .PARAMETER Credential
        Specifies a PSCredential object containing alternate credentials for connecting to the remote system. If not provided, the current user's credentials will be used.

    .EXAMPLE
        PS C:\> Get-IADDomainTrust

        Retrieves information about domain trusts for the current user's domain using the current user's credentials.

    .EXAMPLE
        PS C:\> $SecurePassword = ConvertTo-SecureString 'P@ssw0rd' -AsPlainText -Force
        PS C:\> $Credential = New-Object System.Management.Automation.PSCredential('AD\User', $SecurePassword)
        PS C:\> Get-IADDomainTrust -Credential $Credential

        Retrieves information about domain trusts for the user's domain using the provided alternate credentials.

    .LINK
        https://learn.microsoft.com/en-us/entra/identity/domain-services/concepts-forest-trust

    .LINK
        https://carlwebster.com/finding-domain-trusts-active-directory-forest-using-microsoft-powershell/
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
                    $DomainTrusts = Get-ADObject -Filter { ObjectClass -eq "trustedDomain" } -Properties * @Arguments

                    ForEach ($Trust in $DomainTrusts) {
                        Try {
                            $TrustedDCs = (Get-ADDomainController -Filter * -Server $Trust.Name -ErrorAction SilentlyContinue).HostName
                        }
                        Catch {
                            $TrustedDCs = "Unable to contact Domain"
                        }

                        Switch ($Trust.TrustType) {
                            1 {
                                $TrustType = "Downlevel (Windows NT domain external)"
                            }
                            2 {
                                $TrustType = "Uplevel (Active Directory domain - parent-child, root domain, shortcut, external, or forest)"
                            }
                            3 {
                                $TrustType = "MIT (non-Windows) Kerberos version 5 realm"
                            }
                            4 {
                                $TrustType = "DCE (Theoretical trust type - DCE refers to Open Group's Distributed Computing Environment specification)"
                            }
                            Default {
                                $TrustType = $TrustTypeNumber
                            }
                        }

                        Switch ($Trust.TrustAttributes) {
                            1 {
                                $TrustAttributes = "Non-Transitive"
                            }
                            2 {
                                $TrustAttributes = "Uplevel clients only (Windows 2000 or newer"
                            }
                            4 {
                                $TrustAttributes = "Quarantined Domain (External)"
                            }
                            8 {
                                $TrustAttributes = "Forest Trust"
                            }
                            16 {
                                $TrustAttributes = "Cross-Organizational Trust (Selective Authentication)"
                            }
                            32 {
                                $TrustAttributes = "Intra-Forest Trust (trust within the forest)"
                            }
                            64 {
                                $TrustAttributes = "Inter-Forest Trust (trust with another forest)"
                            }
                            Default {
                                $TrustAttributes = $TrustAttributesNumber
                            }
                        }

                        Switch ($Trust.TrustDirection) {
                            0 {
                                $TrustDirection = "Disabled (The trust relationship exists but has been disabled)"
                            }
                            1 {
                                $TrustDirection = "Inbound (TrustING domain)"
                            }
                            2 {
                                $TrustDirection = "Outbound (TrustED domain)"
                            }
                            3 {
                                $TrustDirection = "Bidirectional (two-way trust)"
                            }
                            Default {
                                $TrustDirection = $TrustDirectionNumber
                            }
                        }

                        $OutputObject += New-Object PSObject -Property @{
                            'Name'                 = $Trust.Name
                            'DCs'                  = $TrustedDCs
                            'Direction'            = $Trust.TrustDirection
                            'DirectionTranslated'  = $TrustDirection
                            'Attributes'           = $Trust.TrustAttributes
                            'AttributesTranslated' = $TrustAttributes
                            'TrustType'            = $Trust.TrustType
                            'TrustTypeTranslated'  = $TrustType
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
