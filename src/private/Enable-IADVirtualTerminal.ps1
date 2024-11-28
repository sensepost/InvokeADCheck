function Enable-IADVirtualTerminal {
    <#
    .SYNOPSIS
        Enables Virtual Terminal processing for the current user.

    .DESCRIPTION
        The Enable-IADVirtualTerminal function enables Virtual Terminal processing by setting the VirtualTerminalLevel registry key to 1 in HKCU:\Console.

    .EXAMPLE
        Enable-IADVirtualTerminal

        Enables Virtual Terminal processing for the current user.

    .NOTES
        https://learn.microsoft.com/en-us/windows/console/console-virtual-terminal-sequences
    #>

    [CmdletBinding(SupportsShouldProcess = $True)]
    Param (

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
                    $Console = Get-ItemProperty -Path 'HKCU:\Console' -Name 'VirtualTerminalLevel' -ErrorAction Ignore

                    If ($Console.VirtualTerminalLevel -ne 1) {
                        Set-ItemProperty -Path 'HKCU:\Console' -Name 'VirtualTerminalLevel' -Type DWORD -Value 1
                        Write-Verbose "$($FunctionName) - Enabling Virtual Terminal in the user's registry settings."
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
