Function Get-ADBackupStatus {
   <#
    .SYNOPSIS
		TBD
    .DESCRIPTION
      TBD
    .PARAMETER Domain
      TBD
    .PARAMETER ADDomainInfo
      TBD
    .EXAMPLE
		TBD
   #>

   [CmdletBinding(SupportsShouldProcess=$True)]
   Param (
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        $Domain,
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        $ADDomainInfo
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
                  $DomainDC             = $ADDomainInfo.PDCEmulator
                  $ADDomainName         = $ADDomainInfo.DNSRoot
                  [string[]]$Partitions = (Get-ADRootDSE -Server $DomainDC).namingContexts
                  $contextType          = [System.DirectoryServices.ActiveDirectory.DirectoryContextType]::Domain
                  $context              = new-object System.DirectoryServices.ActiveDirectory.DirectoryContext($contextType,$ADDomainName)
                  $domainController     = [System.DirectoryServices.ActiveDirectory.DomainController]::findOne($context)
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
                    ForEach($partition in $partitions) {
                        $domainControllerMetadata = $domainController.GetReplicationMetadata($partition)
                        $dsaSignature             = $domainControllerMetadata.Item("dsaSignature")
                        # Add results to Output Obj
                        $outputobj += $dsaSignature
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