function Get-IADRootACL {
    <#
    .SYNOPSIS
        Enumerates the AD root ACL for the current or specified domain.

    .DESCRIPTION
        The Get-IADRootACL function enumerates the AD root ACL for the current or specified domain.

    .PARAMETER Server
        Specifies the Active Directory Domain Controller to connect to. If not provided, the function will use the default Domain Controller for the current domain.

    .PARAMETER Credential
        Specifies a PSCredential object containing alternate credentials for connecting to the remote system. If not provided, the current user's credentials will be used.

    .EXAMPLE
        PS C:\> Get-IADRootACL

        Retrieves the AD root ACL for the current user's domain using the current user's credentials.

    .EXAMPLE
        PS C:\> $SecurePassword = ConvertTo-SecureString 'P@ssw0rd' -AsPlainText -Force
        PS C:\> $Credential = New-Object System.Management.Automation.PSCredential('AD\User', $SecurePassword)
        PS C:\> Get-IADRootACL  -Credential $Credential

        Retrieves the AD root ACL for the user's domain using the provided alternate credentials.
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

                    $DomainSID = (Get-ADDomain @Arguments).DomainSID.Value

                    $NonStandardACEs = @()

                    $StandardACEs = @(
                        "$($DomainSID)-512 Allow CreateChild, Self, WriteProperty, ExtendedRight, GenericRead, WriteDacl, WriteOwner",
                        "$($DomainSID)-519 Allow GenericAll",
                        "S-1-5-32-557 Allow ExtendedRight",
                        "S-1-5-32-554 Allow ReadProperty, ReadControl",
                        "S-1-5-32-554 Allow ReadProperty",
                        "S-1-5-32-554 Allow ListChildren",
                        "S-1-5-32-554 Allow GenericRead",
                        "$($DomainSID)-498 Allow ExtendedRight",
                        "$($DomainSID)-516 Allow ExtendedRight",
                        "$($DomainSID)-522 Allow ExtendedRight",
                        "$($DomainSID)-526 Allow ReadProperty, WriteProperty",
                        "$($DomainSID)-527 Allow ReadProperty, WriteProperty",
                        "$($DomainSID)-516 Allow CreateChild, Self, WriteProperty, ExtendedRight, GenericRead, WriteDacl, WriteOwner",
                        "$($DomainSID)-516 Allow CreateChild, Self, WriteProperty, ExtendedRight, Delete, GenericRead, WriteDacl, WriteOwner",
                        "$($DomainSID)-516 Allow Readproperty, WriteProperty"
                        "$($DomainSID)-516 Allow Readproperty, WriteProperty, ExtendedRight"
                        "$($DomainSID)-516 Allow Readproperty"
                        "$($DomainSID)-516 Allow GenericRead"
                        "$($DomainSID)-516 Allow GenericAll"
                        "$($DomainSID)-516 Allow WriteProperty"
                        "$($DomainSID)-516 Allow Self"
                        "S-1-1-0 Allow ReadProperty",
                        "S-1-3-0 Allow Self",
                        "S-1-5-10 Allow ReadProperty, WriteProperty",
                        "S-1-5-10 Allow ReadProperty, WriteProperty, ExtendedRight",
                        "S-1-5-10 Allow Self",
                        "S-1-5-10 Allow WriteProperty",
                        "S-1-5-11 Allow ExtendedRight",
                        "S-1-5-11 Allow GenericRead",
                        "S-1-5-18 Allow GenericAll",
                        "S-1-5-32-544 Allow CreateChild, Self, WriteProperty, ExtendedRight, Delete, GenericRead, WriteDacl, WriteOwner",
                        "S-1-5-32-544 Allow ExtendedRight",
                        "S-1-5-32-544 Allow GenericRead",
                        "S-1-5-32-544 Allow ListChildren",
                        "S-1-5-32-544 Allow ReadProperty, ReadControl",
                        "S-1-5-9 Allow ExtendedRight",
                        "S-1-5-9 Allow GenericRead",
                        "S-1-5-9 Allow ReadProperty"
                    )
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

                    $ADDrive = New-PSDrive -name 'AD' -PSProvider ActiveDirectory -Root '//RootDSE/' @Arguments
                    $ADRoot = (Get-ADDomain @Arguments).DistinguishedName
                    $ADRootAcl = Get-Acl -Path "$($ADDrive.Name):$($ADRoot)"

                    foreach ($ACE in $ADRootAcl.Access) {
                        if ($ACE.IdentityReference -notmatch 'S-1-[1235]-\d{1,2}(-\d+)*') {
                            $Account = New-Object System.Security.Principal.NTAccount($ACE.IdentityReference)
                            $ACESID = $Account.Translate([System.Security.Principal.SecurityIdentifier]).Value
                        }

                        $ACERights = $ACE.ActiveDirectoryRights
                        $ACEType = $ACE.AccessControlType
                        $ACEString = "{0} {1} {2}" -f $ACESID, $ACEType, $ACERights

                        if ($standardACEs -notcontains $ACEString) {
                            $NonStandardACEs += $ACEString
                        }
                    }
                    foreach ($ACE in $NonStandardACEs) {
                        $ACE = $ACE.split(' ')
                        $ObjectSID = New-Object System.Security.Principal.SecurityIdentifier($ACE.split(' ')[0])
                        $OutputObject += New-Object PSObject -Property @{
                            'DistinguishedName' = (Get-ADObject -Filter { ObjectSID -eq $ObjectSID } @Arguments -Properties DistinguishedName).DistinguishedName
                            'SID'               = $ACE[0]
                            'Type'              = $ACE[1]
                            'Permissions'       = ($ACE[2..($ACE.Length - 1)] -join ' ').split(',') | Where-Object { $_ -ne '' }
                        }
                    }

                    $OutputObject = $OutputObject | Select-Object SID, DistinguishedName, Type, Permissions
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
