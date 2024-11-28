Function Update-IADOutputObjectColor {
	<#
	.SYNOPSIS
		Updates the color of a specified property in an input object.

	.DESCRIPTION
		This function takes an input object and updates the color of a specified property
		using ANSI escape codes.

	.PARAMETER InputObject
		The input object to be processed.

	.PARAMETER PropertyToUpdate
		The name of the property in the input object that should be updated with color.

	.PARAMETER Esc
		The escape character used for ANSI color codes. Default is ASCII 27 (escape).

	.PARAMETER Color
		The ANSI color code to be applied. Default is 91 (Bright Red).

	.EXAMPLE
		PS C:\> [void]($ColeredObject.IADDomainController | Update-IADOutputObjectColor -PropertyToUpdate OperatingSystem)

		This example updates the "OperatingSystem" property of the input object with the default color (Bright Red).
	#>

    [CmdletBinding(SupportsShouldProcess=$true)]
    Param(
        [Parameter(Mandatory=$true, ValueFromPipeline=$true)]
        [ValidateNotNullOrEmpty()]
        [PSObject]$InputObject,

        [Parameter(Mandatory)]
        [String]$PropertyToUpdate,

        [Parameter()]
        [Char]$Esc= 27,

        [Parameter()]
        $Color = 91 # Bright Red
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

                    if ($NoColorUpdate) {
                        break
                    }

                    if ($InputObject.$PropertyToUpdate -is [System.Collections.ArrayList]) {
                        $InputObject.$($PropertyToUpdate) = "$esc[${Color}m$($InputObject.$($PropertyToUpdate) -join "`n")$esc[0m"
                    } else {
                        $InputObject.$($PropertyToUpdate) = "$esc[${Color}m$($InputObject.$($PropertyToUpdate))$esc[0m"
                    }

                    $OutputObject+=$InputObject
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
