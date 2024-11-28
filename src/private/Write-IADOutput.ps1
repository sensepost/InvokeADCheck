Function Write-IADOutput {
	<#
	.SYNOPSIS
		Formats and outputs objects as a table.

	.DESCRIPTION
		The Write-IADOutput function takes input objects, collects them, and then outputs them as a formatted table.

	.PARAMETER InputObject
		The object or objects to be formatted and output.

	.EXAMPLE
		PS C:\> $ColeredObject.IADDefaultAdministrator | Write-IADOutput

		This example gets Default Administrator information and passes it to Write-IADOutput for formatting and display.

	.NOTES
		This function is a helper function to Write-IADChecksToCLI.
	#>

    [CmdletBinding(SupportsShouldProcess=$true)]
    Param(
        [Parameter(Mandatory= $true, ValueFromPipeline = $true)]
        [ValidateNotNullOrEmpty()]
        [PSObject]$InputObject
    )
    Begin {
        $FunctionName = $MyInvocation.MyCommand.Name
        Write-Debug "$($FunctionName) - Begin."
        Try {
            If ($script:ThisModuleLoaded -eq $true) {
                Get-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState
            }
            $OutputObject = @()
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
                $OutputObject+= $InputObject
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
                    $OutputObject | Format-Table -AutoSize -Wrap
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
