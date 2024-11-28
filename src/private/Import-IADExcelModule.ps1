function Import-IADExcelModule {
    <#
    .SYNOPSIS
        Imports the ImportExcel module.

    .DESCRIPTION
        The Import-IADExcelModule function checks if the ImportExcel module is installed, installs it if necessary, and then imports it.

    .EXAMPLE
        PS C:\> Import-IADExcelModule

        This command will import the ImportExcel module, installing it first if it's not already present.

    .LINK
        https://www.powershellgallery.com/packages/ImportExcel/
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
                    If (-not (Get-Module ImportExcel)) {
                        Write-Verbose "ImportExcel module not found. Installing..."
                        Install-Module ImportExcel -Scope CurrentUser -Force
                    }

                    Write-Verbose "Importing ImportExcel module..."
                    Import-Module ImportExcel
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
