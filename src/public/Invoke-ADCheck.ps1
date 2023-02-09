Function Invoke-ADCheck {
    <#
    .SYNOPSIS
        TBD
    .DESCRIPTION
        TBD
    .PARAMETER a
        TBD
    .EXAMPLE
        TBD
    #>
    [CmdletBinding(SupportsShouldProcess=$True)]
    Param (
        [Parameter()]
        $a
    )
    Begin {
        $FunctionName = $MyInvocation.MyCommand.Name
        Write-Debug "$($FunctionName) - Begin."
        Try {
            Try {
                If ($script:ThisModuleLoaded -eq $true) {
                    Get-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState
                }
                If ($PSCmdlet.ShouldProcess("$($FunctionName) - Begin WhatIf")) {
                    $OutputObject = @()
                }
                # Startup Logic here
            }
            Catch {
                Write-Error -Message "$($FunctionName) - $($PSItem)" -ErrorAction Stop
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
                    # Process logic ere
                    # Get-ADBacksups etc
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