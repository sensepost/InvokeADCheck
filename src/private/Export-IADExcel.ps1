function Export-IADExcel {
    <#
    .SYNOPSIS
    Exports Active Directory data to Excel worksheets.

    .DESCRIPTION
    The Export-IADExcel function exports various Active Directory data to an Excel file. It creates different worksheets based on the properties of the input object, handling special cases for certain data types.

    .PARAMETER Object
    Specifies the PSCustomObject containing Active Directory data to be exported.

    .PARAMETER Path
    Specifies the directory path where the Excel file will be saved.

    .PARAMETER FileName
    Specifies the name of the Excel file to be created.

    .PARAMETER ExcelFormatOptions
    Specifies a hashtable of additional formatting options.

    .EXAMPLE
    Export-IADExcel -Object $OutputObject -Path "C:\Temp" -FileName "ADReport" -ExcelFormatOptions @{AutoSize = $true; FreezeTopRow = $true}

    This example exports AD data to an Excel file named "ADReport.xlsx" in the C:\Temp directory, with auto-sized columns and a frozen top row.

    .NOTES
        https://www.powershellgallery.com/packages/ImportExcel/
    #>

    [CmdletBinding(SupportsShouldProcess = $True)]
    Param (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [PSCustomObject]
        $Object,

        [Parameter(Mandatory = $true)]
        [string]
        $Path,

        [Parameter(Mandatory = $true)]
        [String]
        $FileName,

        [Parameter()]
        [hashtable]
        $ExcelFormatOptions
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
                    Write-Verbose "$($FunctionName) - Dynamiclly create worksheets for each property icluded in the object."
                    ForEach ($OutputObjName in $Object.PSObject.Properties.Name) {
                        Write-Verbose "$($FunctionName) - Ensure sheets are only created if the object has collected data for a specific check."
                        If ($Object.$OutputObjName -ne $null) {
                            If ($OutputObjName -eq 'IADBuiltInGroupMembership') {
                                Write-Verbose "$($FunctionName) - Create multiple sheets for $OutputObjName. One with a general count of members, then for each group that has members, a worksheet with the group members."
                                $Object.$OutputObjName | Select-Object Group, MembersCount, Notes | Export-Excel -Path $(Join-Path $Path "$($FileName).xlsx") -WorkSheetName $OutputObjName @ExcelFormatOptions
                                $Object.$OutputObjName | ForEach-Object {
                                    If ($_.Members -ne $null) {
                                        $_.Members | Select-Object  DistinguishedName, Name, sAMAccountName, Description, ObjectClass | Export-Excel -Path $(Join-Path $Path "$($FileName).xlsx") -WorkSheetName "$($_.Group)" @ExcelFormatOptions
                                    }
                                }
                            }
                            ElseIf ($OutputObjName -eq 'IADDefaultAdministrator') {
                                Write-Verbose "$($FunctionName) - Ensure that the array of Service Principal Names from $OutputObjName are joined together as a string."
                                $Object.$OutputObjName | Select-Object Name, Created, Enabled,
                                    MarkedAsSensitive, LastLogonDate, PasswordLastSet,
                                        @{Name = "ServicePrincipalName"; Expression = { $(($_.ServicePrincipalName) -Join ", ") } } | Export-Excel -Path $(Join-Path $Path "$($FileName).xlsx") -WorkSheetName $OutputObjName @ExcelFormatOptions
                            }

                            ElseIf ($OutputObjName -eq 'IADRootACL') {
                                Write-Verbose "$($FunctionName) - Ensure that array of permissions from $OutputObjName are joined together as a string."
                                $Object.$OutputObjName | Select-Object SID, DistinguishedName, Type,
                                    @{Name = "Permissions"; Expression = { $(($_.Permissions) -Join ", ") } } | Export-Excel -Path $(Join-Path $Path "$($FileName).xlsx") -WorkSheetName $OutputObjName @ExcelFormatOptions
                            }

                            ElseIf ($OutputObjName -eq 'IADUserAccountHealth') {
                                Write-Verbose "$($FunctionName) - Create a worksheet with every recorded count in $OutputObjName."
                                $CountObj = @()
                                ForEach ($SubObj in $Object.$OutputObjName.PSObject.Properties) {
                                    $CountObj += New-Object PSObject -Property @{
                                        'Name'  = $SubObj.Name
                                        'Count' = $($Object.$OutputObjName.$($SubObj.Name) | Measure-Object).Count
                                    }
                                }
                                $CountObj | Export-Excel -Path $(Join-Path $Path "$($FileName).xlsx") -WorkSheetName $OutputObjName @ExcelFormatOptions

                                Write-Verbose "$($FunctionName) - For each check that is not empty, create a worksheet with the users that are caught by that filter."
                                ForEach ($SubObj in $Object.$OutputObjName.PSObject.Properties) {
                                    If ($Object.$OutputObjName.$($SubObj.Name) -ne $null) {
                                        $Object.$OutputObjName.$($SubObj.Name) | Select-Object DistinguishedName, Enabled, Name, ObjectClass, SamAccountName, SID, UserPrincipalName,
                                            LastLogonDate, UserAccountControl, PasswordNotRequired, PasswordNeverExpires,
                                                DoesNotRequirePreAuth, @{Name = "SIDHistory"; Expression = { $(($_.SIDHistory) -Join ", ") } } | Export-Excel -Path $(Join-Path $Path "$($FileName).xlsx") -WorkSheetName "$($SubObj.Name)" @ExcelFormatOptions
                                    }
                                }
                            }
                            Else {
                                Write-Verbose "$($FunctionName) - Export $OutputObjName results as-is."
                                $Object.$OutputObjName | Export-Excel -Path $(Join-Path $Path "$($FileName).xlsx") -WorkSheetName $OutputObjName @ExcelFormatOptions
                            }
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
