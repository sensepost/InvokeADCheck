function Write-IADAccountHealth {
    <#
    .SYNOPSIS
        Writes acCount health information with color-coded output.

    .DESCRIPTION
        The Write-IADAcCountHealth function displays acCount health information
        with color-coded output based on the Count and warning threshold.
        It's designed to visually highlight potential issues in acCount health.

    .PARAMETER Label
        The Label describing the acCount health metric being displayed.

    .PARAMETER Count
        The numeric value of the acCount health metric.

    .PARAMETER warningThreshold
        The threshold at which the output should be displayed in red.
        Default is 0.

    .PARAMETER ForceRedOnZeroThreshold
        If set, forces the output to be red even when the Count is 0.

    .EXAMPLE
        Write-IADAcCountHealth -Label "Expired AcCounts" -Count 5 -warningThreshold 3

        This will display "   [-] Expired AcCounts: 5" in red.

    .EXAMPLE
        PS C:\> Write-IADAcCountHealth -Label "AcCounts Marked as Sensitive" -Count 0 -ForceRedOnZeroThreshold

        This will display "   [-] AcCounts Marked as Sensitive: 0" in red, even though the Count is 0.

    .NOTES
        This function uses Write-Host for output, which may not be suitable for all scenarios.
        Consider using Write-Output for more flexible output handling in scripts.
    #>

    [CmdletBinding(SupportsShouldProcess = $True)]
    Param (
        [string]$Label,
        [int]$Count,
        [int]$warningThreshold = 0,
        [switch]$ForceRedOnZeroThreshold
    )

    Begin {
        $FunctionName = $MyInvocation.MyCommand.Name
        Write-Debug "$($FunctionName) - Begin."
        Try {
            If ($script:ThisModuleLoaded -eq $true) {
                Get-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState
            }
            If ($PSCmdlet.ShouldProcess("$($FunctionName) - Begin WhatIf")) {

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

                    $ForegroundColor = if (($ForceRedOnZeroThreshold.IsPresent -and $Count -le 1)) {
                        'Red'
                    } elseif ($ForceRedOnZeroThreshold.IsPresent -and $Count -ge 1) {
                        'Gray'
                    } elseif ($Count -gt $warningThreshold) {
                        'Red'
                    } else {
                        'Gray'
                    }

                    Write-Host "   [-] $($Label): $Count" -ForegroundColor $ForegroundColor

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
