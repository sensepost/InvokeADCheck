
function Get-ProtectedUsersGroup {
    <#
    .SYNOPSIS

        This function enumerates the Protected Users group for the current (or specified) domain.

    .DESCRIPTION

        This function enumerates the Protected Users group for the current (or specified) domain.

    .PARAMETER Recursive

        Recursively gather members of the Protected Users group.

    .PARAMETER Server

        Specifies an AD domain controller to bind to.

    .PARAMETER Credential

        A [Management.Automation.PSCredential] object of alternate credentials
        for connection to the remote system.

    .EXAMPLE

        Get-ProtectedUsersGroup

        Name              : ELDON_KIRBY
        DistinguishedName : CN=ELDON_KIRBY,OU=Devices,OU=OGC,OU=Tier 2,DC=offsec,DC=local
        SamAccountName    : ELDON_KIRBY
        objectClass       : user
        SID               : 1648

        Name              : MILLARD_KNIGHT
        DistinguishedName : CN=MILLARD_KNIGHT,OU=Groups,OU=BDE,OU=Tier 2,DC=offsec,DC=local
        SamAccountName    : MILLARD_KNIGHT
        objectClass       : user
        SID               : 3024

    .EXAMPLE

        $SecurePassword = ConvertTo-SecureString 'Welcome01!' -AsPlainText -Force
        $Credential = New-Object System.Management.Automation.PSCredential('OFFSEC\test', $SecurePassword)

        Get-ProtectedUsersGroup

    #>

   [CmdletBinding(SupportsShouldProcess=$True)]
   param (
    [Parameter(Mandatory=$false)]
    [switch]
    $Recursive,

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

                if ($PSBoundParameters['Recursive']) { $Arguments['Recursive'] = $true }
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
                    $ProtectedUsersGroupUsers = Get-ADGroupMember "$((get-addomain).DomainSID.Value)-525" @Arguments

                    foreach ($GroupMember in $ProtectedUsersGroupUsers) {
                        $obj = New-Object System.Object
                        $obj | Add-Member -type NoteProperty -Name 'Name' -Value $GroupMember.Name
                        $obj | Add-Member -type NoteProperty -Name 'DistinguishedName' -Value $GroupMember.DistinguishedName
                        $obj | Add-Member -type NoteProperty -Name 'SamAccountName' -Value $GroupMember.SamAccountName
                        $obj | Add-Member -type NoteProperty -Name 'objectClass' -Value $GroupMember.objectClass
                        $obj | Add-Member -type NoteProperty -Name 'SID' -Value $($GroupMember.SID -split '-')[-1]
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
