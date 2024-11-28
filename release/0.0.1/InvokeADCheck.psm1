## Pre-Loaded Module code ##

<#
 Put all code that must be run prior to function dot sourcing here.

 This is a good place for module variables as well. The only rule is that no 
 variable should rely upon any of the functions in your module as they 
 will not have been loaded yet. Also, this file cannot be completely
 empty. Even leaving this comment is good enough.
#>

## PRIVATE MODULE FUNCTIONS AND DATA ##

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


function Get-CallerPreference {
    <#
    .Synopsis
        Fetches "Preference" variable values from the caller's scope.
    .DESCRIPTION
       Script module functions do not automatically inherit their caller's variables, but they can be
       obtained through the $PSCmdlet variable in Advanced Functions.  This function is a helper function
       for any script module Advanced Function; by passing in the values of $ExecutionContext.SessionState
       and $PSCmdlet, Get-CallerPreference will set the caller's preference variables locally.
    .PARAMETER Cmdlet
       The $PSCmdlet object from a script module Advanced Function.
    .PARAMETER SessionState
       The $ExecutionContext.SessionState object from a script module Advanced Function.  This is how the
       Get-CallerPreference function sets variables in its callers' scope, even If that caller is in a different
       script module.
    .PARAMETER Name
       Optional array of parameter names to retrieve from the caller's scope.  Default is to retrieve all
       Preference variables as defined in the about_Preference_Variables help file (as of PowerShell 4.0)
       This parameter may also specify names of variables that are not in the about_Preference_Variables
       help file, and the function will retrieve and set those as well.
    .EXAMPLE
       Get-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState

       Imports the default PowerShell preference variables from the caller into the local scope.
    .EXAMPLE
       Get-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState -Name 'ErrorActionPreference','SomeOtherVariable'

       Imports only the ErrorActionPreference and SomeOtherVariable variables into the local scope.
    .EXAMPLE
       'ErrorActionPreference','SomeOtherVariable' | Get-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState

       Same as Example 2, but sends variable names to the Name parameter via pipeline input.
    .INPUTS
       String
    .OUTPUTS
       None.  This function does not produce pipeline output.
    .LINK
       about_Preference_Variables
    #>

    [CmdletBinding(DefaultParameterSetName = 'AllVariables')]
    Param (
        [Parameter(Mandatory = $true)]
        [ValidateScript({ $_.GetType().FullName -eq 'System.Management.Automation.PSScriptCmdlet' })]
        $Cmdlet,

        [Parameter(Mandatory = $true)]
        [System.Management.Automation.SessionState]$SessionState,

        [Parameter(ParameterSetName = 'Filtered', ValueFromPipeline = $true)]
        [string[]]$Name
    )

    begin {
        $filterHash = @{}
    }

    process {
        If ($null -ne $Name) {
            ForEach ($string in $Name) {
                $filterHash[$string] = $true
            }
        }
    }

    end {
        # List of preference variables taken from the about_Preference_Variables help file in PowerShell version 4.0

        $vars = @{
            'ErrorView'                     = $null
            'FormatEnumerationLimit'        = $null
            'LogCommandHealthEvent'         = $null
            'LogCommandLifecycleEvent'      = $null
            'LogEngineHealthEvent'          = $null
            'LogEngineLifecycleEvent'       = $null
            'LogProviderHealthEvent'        = $null
            'LogProviderLifecycleEvent'     = $null
            'MaximumAliasCount'             = $null
            'MaximumDriveCount'             = $null
            'MaximumErrorCount'             = $null
            'MaximumFunctionCount'          = $null
            'MaximumHistoryCount'           = $null
            'MaximumVariableCount'          = $null
            'OFS'                           = $null
            'OutputEncoding'                = $null
            'ProgressPreference'            = $null
            'PSDefaultParameterValues'      = $null
            'PSEmailServer'                 = $null
            'PSModuleAutoLoadingPreference' = $null
            'PSSessionApplicationName'      = $null
            'PSSessionConfigurationName'    = $null
            'PSSessionOption'               = $null

            'ErrorActionPreference'         = 'ErrorAction'
            'DebugPreference'               = 'Debug'
            'ConfirmPreference'             = 'Confirm'
            'WhatIfPreference'              = 'WhatIf'
            'VerbosePreference'             = 'Verbose'
            'WarningPreference'             = 'WarningAction'
        }

        ForEach ($enTry in $vars.GetEnumerator()) {
            If (([string]::IsNullOrEmpty($enTry.Value) -or -not $Cmdlet.MyInvocation.BoundParameters.ContainsKey($enTry.Value)) -and
                ($PSCmdlet.ParameterSetName -eq 'AllVariables' -or $filterHash.ContainsKey($enTry.Name))) {

                $variable = $Cmdlet.SessionState.PSVariable.Get($enTry.Key)

                If ($null -ne $variable) {
                    If ($SessionState -eq $ExecutionContext.SessionState) {
                        Set-Variable -Scope 1 -Name $variable.Name -Value $variable.Value -Force -Confirm:$false -WhatIf:$false
                    }
                    Else {
                        $SessionState.PSVariable.Set($variable.Name, $variable.Value)
                    }
                }
            }
        }

        If ($PSCmdlet.ParameterSetName -eq 'Filtered') {
            ForEach ($varName in $filterHash.Keys) {
                If (-not $vars.ContainsKey($varName)) {
                    $variable = $Cmdlet.SessionState.PSVariable.Get($varName)

                    If ($null -ne $variable) {
                        If ($SessionState -eq $ExecutionContext.SessionState) {
                            Set-Variable -Scope 1 -Name $variable.Name -Value $variable.Value -Force -Confirm:$false -WhatIf:$false
                        }
                        Else {
                            $SessionState.PSVariable.Set($variable.Name, $variable.Value)
                        }
                    }
                }
            }
        }
    }
}

Function Get-IADADBackupStatus {
    <#
    .SYNOPSIS
        Retrieves the Active Directory backup status for the current or specified domain.

    .DESCRIPTION
        The Get-IADADBackupStatus function enumerates the Active Directory backup status for each partition in the current or specified domain. It provides information about the last backup date for each partition.

    .PARAMETER Server
        Specifies the Active Directory Domain Controller to connect to. If not provided, the function will use the default Domain Controller for the current domain.

    .PARAMETER Credential
        Specifies a PSCredential object containing alternate credentials for connecting to the remote system. If not provided, the current user's credentials will be used.

    .EXAMPLE
        PS C:\> Get-IADADBackupStatus

        Retrieves the last backup date for AD partitions of the current domain using the current user's credentials.

    .EXAMPLE
        PS C:\> $SecurePassword = ConvertTo-SecureString 'Welcome01!' -AsPlainText -Force
        PS C:\> $Credential = New-Object System.Management.Automation.PSCredential('AD\User', $SecurePassword)
        PS C:\> Get-IADADBackupStatus -Credential $Credential -Server dc01.ad.domain.tld

        Retrieves the last backup date from the specified domain controller 'dc01.ad.domain.tld' using the provided alternate credentials.

    .LINK
        https://learn.microsoft.com/en-us/windows/win32/ad/backing-up-an-active-directory-server

    .NOTES
        This file includes code derived from the project Invoke-TrimarcADChecks available at https://github.com/Trimarc/Invoke-TrimarcADChecks, licensed under the MIT License.
        The code has been modified and adapted for use in this project.
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

                    $Domain = (Get-ADDomainController @Arguments).Domain

                    If ($Arguments['Credential']) {
                        $CredentialUser = ($Credential.UserName.ToString())
                        $CredentialPassword = ($Credential.GetNetworkCredential().Password.ToString())

                        $Context = New-Object System.DirectoryServices.ActiveDirectory.DirectoryContext("Domain", $Domain, $CredentialUser, $CredentialPassword)
                    }
                    Else {
                        $Context = New-Object System.DirectoryServices.ActiveDirectory.DirectoryContext("Domain", $Domain)
                    }

                    $DomainController = [System.DirectoryServices.ActiveDirectory.DomainController]::findOne($Context)

                    ForEach ($Partition in $DomainController.Partitions) {
                        $DomainControllerMetadata = $DomainController.GetReplicationMetadata($partition)
                        $DsaSignature = $DomainControllerMetadata.Item("dsaSignature")
                        $BackupDate = $dsaSignature.LastOriginatingChangeTime.DateTime

                        $OutputObject += New-Object PSObject -Property @{
                            "Partition"      = $Partition
                            "LastBackupDate" = $BackupDate
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


function Get-IADBuiltInGroupMembership {
    <#
    .SYNOPSIS
        Enumerates the members of built-in Active Directory groups for the current or specified domain.

    .DESCRIPTION
        The Get-IADBuiltInGroupMembership function enumerates the members of built-in Active Directory groups for the current (or specified) domain. It provides information about the number of users in comparison to the default number of users.

    .PARAMETER Server
        Specifies the Active Directory Domain Controller to connect to. If not provided, the function will use the default Domain Controller for the current domain.

    .PARAMETER Credential
        Specifies a PSCredential object containing alternate credentials for connecting to the remote system. If not provided, the current user's credentials will be used.

    .EXAMPLE
        PS C:\> Get-IADBuiltInGroupMembership

        Retrieves the members of built-in Active Directory groups using the current user's credentials.

    .EXAMPLE
        PS C:\> $SecurePassword = ConvertTo-SecureString 'P@ssw0rd' -AsPlainText -Force
        PS C:\> $Credential = New-Object System.Management.Automation.PSCredential('AD\User', $SecurePassword)
        PS C:\> Get-IADBuiltInGroupMembership -Credential $Credential

        Retrieves the members of built-in Active Directory groups using the provided alternate credentials.

    .LINK
        https://learn.microsoft.com/en-us/windows-server/identity/ad-ds/plan/security-best-practices/implementing-least-privilege-administrative-models

    .NOTES
        This file includes code derived from the project Invoke-TrimarcADChecks available at https://github.com/Trimarc/Invoke-TrimarcADChecks, licensed under the MIT License.
        The code has been modified and adapted for use in this project.
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

                    $ADGroups = @()
                    $BuiltInADGroupSIDs = @{
                        'Administrators'              = '544'
                        'Domain Admins'               = '512'
                        'Enterprise Admins'           = '519'
                        'Schema Admins'               = '518'
                        'Account Operators'           = '548'
                        'Server Operators'            = '549'
                        'Group Policy Creator Owners' = '520'
                        'DNSAdmins'                   = '1101'
                        'Enterprise Key Admins'       = '527'
                        # 'Exchange Domain Servers' =
                        # 'Exchange Enterprise Servers' =
                        # 'Exchange Admins' =
                        # 'Organization Management' =
                        # 'Exchange Windows Permissions' =
                    }
                    $Notes = @{
                        '544'  = 'By default this group has 3 Member(s)'
                        '512'  = 'By default this group has 1 Member(s)'
                        '519'  = 'By default this group has 1 Member(s)'
                        '518'  = 'By default this group has 1 Member(s)'
                        '548'  = 'By default this group has 0 Member(s)'
                        '549'  = 'By default this group has 0 Member(s)'
                        '520'  = 'By default this group has 1 Member(s)'
                        '1101' = 'By default this group has 0 Member(s)'
                        '527'  = 'By default this group has 0 Member(s)'
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
    Process {
        Write-Debug "$($FunctionName) - Process."
        Try {
            If ($PSCmdlet.ShouldProcess("$($FunctionName) - Process WhatIf")) {
                Try {
                    ForEach ($SID in $BuiltInADGroupSIDs.Values) {
                        $DN = Get-ADGroup -Filter * @Arguments -Properties Name, SID |
                        Where-Object -Property SID -like "*S-1-5*-$($SID)"
                        $ADGroups += $DN
                    }

                    ForEach ($ADGroup in $ADGroups) {
                        $Members = @(Get-ADObject -LDAPFilter "(&(memberOf:1.2.840.113556.1.4.1941:=$($ADGroup.DistinguishedName)))" @Arguments -Properties DistinguishedName, Name, sAMAccountName, Description)

                        $OutputObject += New-Object PSObject -Property @{
                            "Group"        = $ADGroup.Name
                            "Members"      = $Members
                            "MembersCount" = $(($Members | Measure-Object).Count)
                            "Notes"        = $Notes["$((($ADGroup.SID.Value.ToString()).Split('-'))[-1])"]
                        }
                    }

                    $OutputObject = $OutputObject | Select-Object Group, MembersCount, Notes, Members | Sort-Object MembersCount -Descending
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


function Get-IADDefaultAdministrator {
    <#
    .SYNOPSIS
        Enumerates the default Active Directory administrator account for the current or specified domain, and returns all relevant account information.

    .DESCRIPTION
        The Get-IADDefaultAdministrator cmdlet enumerates the default Active Directory administrator account. It provides information about the current status of the account.

    .PARAMETER Server
        Specifies the Active Directory Domain Controller to connect to. If not provided, the function will use the default Domain Controller for the current domain.

    .PARAMETER Credential
        Specifies a PSCredential object containing alternate credentials for connecting to the remote system. If not provided, the current user's credentials will be used.

    .EXAMPLE
        PS C:\> Get-IADDefaultAdministrator

        Retrieves information about the default administrator account using the current user's credentials.

    .EXAMPLE
        PS C:\> $SecurePassword = ConvertTo-SecureString 'P@ssw0rd' -AsPlainText -Force
        PS C:\> $Credential = New-Object System.Management.Automation.PSCredential('AD\User', $SecurePassword)
        PS C:\> Get-IADDefaultAdministrator -Credential $Credential

        Retrieves information about the default administrator account using the provided alternate credentials.

    .LINK
        https://learn.microsoft.com/en-us/windows-server/identity/ad-ds/plan/security-best-practices/appendix-d--securing-built-in-administrator-accounts-in-active-directory

    .NOTES
        This file includes code derived from the project Invoke-TrimarcADChecks available at https://github.com/Trimarc/Invoke-TrimarcADChecks, licensed under the MIT License.
        The code has been modified and adapted for use in this project.
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
                    $Administrator = Get-ADUser "$((Get-ADDomain @Arguments).DomainSID.Value)-500" -Properties 'Name', 'Enabled', 'Created', 'PasswordLastSet', 'LastLogonDate', 'ServicePrincipalName', 'UserAccountControl' @Arguments

                    $OutputObject += New-Object PSObject -Property @{
                        'Name'                 = $Administrator.Name
                        'Enabled'              = $Administrator.Enabled
                        'Created'              = $Administrator.Created
                        'PasswordLastSet'      = $Administrator.PasswordLastSet
                        'LastLogonDate'        = $Administrator.LastLogonDate
                        'ServicePrincipalName' = $Administrator.ServicePrincipalName
                        'MarkedAsSensitive'    = [bool]($Administrator.UserAccountControl -band 0x100000)
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


function Get-IADDefaultDomainPasswordPolicy {
    <#
    .SYNOPSIS
        Enumerates the default domain password policy in the current or specified domain.

    .DESCRIPTION
        The Get-IADDefaultPasswordPolicy function enumerates the default domain password policy in the current or specified domain.

    .PARAMETER Server
        Specifies the Active Directory Domain Controller to connect to. If not provided, the function will use the default Domain Controller for the current domain.

    .PARAMETER Credential
        Specifies a PSCredential object containing alternate credentials for connecting to the remote system. If not provided, the current user's credentials will be used.

    .EXAMPLE
        PS C:\> Get-IADDefaultPasswordPolicy

        Retrieves the default domain password policy for the current user's domain using the current user's credentials.

    .EXAMPLE
        PS C:\> $SecurePassword = ConvertTo-SecureString 'P@ssw0rd' -AsPlainText -Force
        PS C:\> $Credential = New-Object System.Management.Automation.PSCredential('AD\User', $SecurePassword)
        PS C:\> Get-IADDefaultPasswordPolicy  -Credential $Credential

        Retrieves the default domain  password policy for the user's domain using the provided alternate credentials.
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
                    $DefaultDomainPasswordPolicy = Get-ADDefaultDomainPasswordPolicy @Arguments

                    $OutputObject += New-Object PSObject -Property @{
                        'ComplexityEnabled'             = $DefaultDomainPasswordPolicy.ComplexityEnabled
                        'LockoutDuration'               = $DefaultDomainPasswordPolicy.LockoutDuration
                        'LockoutObservationWindow'      = $DefaultDomainPasswordPolicy.LockoutObservationWindow
                        'LockoutThreshold'              = $DefaultDomainPasswordPolicy.LockoutThreshold
                        'MaxPasswordAge'                = $DefaultDomainPasswordPolicy.MaxPasswordAge.Days
                        'MinPasswordAge'                = $DefaultDomainPasswordPolicy.MinPasswordAge.Days
                        'MinPasswordLength'             = $DefaultDomainPasswordPolicy.MinPasswordLength
                        'PasswordHistoryCount'          = $DefaultDomainPasswordPolicy.PasswordHistoryCount
                        'ReversibleEncryptionEnabled'   = $DefaultDomainPasswordPolicy.ReversibleEncryptionEnabled
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


function Get-IADDomainController {
    <#
    .SYNOPSIS
        Enumerates the Domain Controllers in the current or specified domain.

    .DESCRIPTION
        The Get-IADDomainController function enumerates the Domain Controllers in the current or specified domain. It also provides information about the domain.

    .PARAMETER Server
        Specifies the Active Directory Domain Controller to connect to. If not provided, the function will use the default Domain Controller for the current domain.

    .PARAMETER Credential
        Specifies a PSCredential object containing alternate credentials for connecting to the remote system. If not provided, the current user's credentials will be used.

    .EXAMPLE
        PS C:\> Get-IADDomainController

        Retrieves information about the domain controllers for the current user's domain using the current user's credentials.

    .EXAMPLE
        PS C:\> $SecurePassword = ConvertTo-SecureString 'P@ssw0rd' -AsPlainText -Force
        PS C:\> $Credential = New-Object System.Management.Automation.PSCredential('AD\User', $SecurePassword)
        PS C:\> Get-IADDomainController  -Credential $Credential

        Retrieves information about the domain controllers for the user's domain using the provided alternate credentials.

    .NOTES
        This file includes code derived from the project Invoke-TrimarcADChecks available at https://github.com/Trimarc/Invoke-TrimarcADChecks, licensed under the MIT License.
        The code has been modified and adapted for use in this project.
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
                    $DomainControllers = Get-ADDomainController -filter * @Arguments

                    ForEach ($DC in $DomainControllers) {
                        $OutputObject += New-Object PSObject -Property @{
                            'Hostname'        = $DC.HostName
                            'OperatingSystem' = $DC.OperatingSystem
                            'Domain'          = $DC.Domain
                            'Forest'          = $DC.Forest
                            'FSMORoles'       = ([string]$DC.OperationMasterRoles).replace(' ', '; ')
                            'GlobalCatalogue' = $DC.IsGlobalCatalog
                            'Read-Only'       = $DC.IsReadOnly
                            'Site'            = $DC.Site
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


function Get-IADDomainTrust {
    <#
    .SYNOPSIS
        Enumerates the Domain Trusts for the current or specified domain.

    .DESCRIPTION
        The Get-IADDomainTrust function enumerates the Domain Trusts for the current or specified domain. It provides infromation about the configured Active Directory trust.

    .PARAMETER Server
        Specifies the Active Directory Domain Controller to connect to. If not provided, the function will use the default Domain Controller for the current domain.

    .PARAMETER Credential
        Specifies a PSCredential object containing alternate credentials for connecting to the remote system. If not provided, the current user's credentials will be used.

    .EXAMPLE
        PS C:\> Get-IADDomainTrust

        Retrieves information about domain trusts for the current user's domain using the current user's credentials.

    .EXAMPLE
        PS C:\> $SecurePassword = ConvertTo-SecureString 'P@ssw0rd' -AsPlainText -Force
        PS C:\> $Credential = New-Object System.Management.Automation.PSCredential('AD\User', $SecurePassword)
        PS C:\> Get-IADDomainTrust -Credential $Credential

        Retrieves information about domain trusts for the user's domain using the provided alternate credentials.

    .LINK
        https://learn.microsoft.com/en-us/entra/identity/domain-services/concepts-forest-trust

    .LINK
        https://carlwebster.com/finding-domain-trusts-active-directory-forest-using-microsoft-powershell/
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
                    $DomainTrusts = Get-ADObject -Filter { ObjectClass -eq "trustedDomain" } -Properties * @Arguments

                    ForEach ($Trust in $DomainTrusts) {
                        Try {
                            $TrustedDCs = (Get-ADDomainController -Filter * -Server $Trust.Name -ErrorAction SilentlyContinue).HostName
                        }
                        Catch {
                            $TrustedDCs = "Unable to contact Domain"
                        }

                        Switch ($Trust.TrustType) {
                            1 {
                                $TrustType = "Downlevel (Windows NT domain external)"
                            }
                            2 {
                                $TrustType = "Uplevel (Active Directory domain - parent-child, root domain, shortcut, external, or forest)"
                            }
                            3 {
                                $TrustType = "MIT (non-Windows) Kerberos version 5 realm"
                            }
                            4 {
                                $TrustType = "DCE (Theoretical trust type - DCE refers to Open Group's Distributed Computing Environment specification)"
                            }
                            Default {
                                $TrustType = $TrustTypeNumber
                            }
                        }

                        Switch ($Trust.TrustAttributes) {
                            1 {
                                $TrustAttributes = "Non-Transitive"
                            }
                            2 {
                                $TrustAttributes = "Uplevel clients only (Windows 2000 or newer"
                            }
                            4 {
                                $TrustAttributes = "Quarantined Domain (External)"
                            }
                            8 {
                                $TrustAttributes = "Forest Trust"
                            }
                            16 {
                                $TrustAttributes = "Cross-Organizational Trust (Selective Authentication)"
                            }
                            32 {
                                $TrustAttributes = "Intra-Forest Trust (trust within the forest)"
                            }
                            64 {
                                $TrustAttributes = "Inter-Forest Trust (trust with another forest)"
                            }
                            Default {
                                $TrustAttributes = $TrustAttributesNumber
                            }
                        }

                        Switch ($Trust.TrustDirection) {
                            0 {
                                $TrustDirection = "Disabled (The trust relationship exists but has been disabled)"
                            }
                            1 {
                                $TrustDirection = "Inbound (TrustING domain)"
                            }
                            2 {
                                $TrustDirection = "Outbound (TrustED domain)"
                            }
                            3 {
                                $TrustDirection = "Bidirectional (two-way trust)"
                            }
                            Default {
                                $TrustDirection = $TrustDirectionNumber
                            }
                        }

                        $OutputObject += New-Object PSObject -Property @{
                            'Name'                 = $Trust.Name
                            'DCs'                  = $TrustedDCs
                            'Direction'            = $Trust.TrustDirection
                            'DirectionTranslated'  = $TrustDirection
                            'Attributes'           = $Trust.TrustAttributes
                            'AttributesTranslated' = $TrustAttributes
                            'TrustType'            = $Trust.TrustType
                            'TrustTypeTranslated'  = $TrustType
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


function Get-IADFunctionalLevel {
    <#
    .SYNOPSIS
        Enumerates the Forest and Domain Functional Levels.

    .DESCRIPTION
        The Get-IADFunctionalLevel function enumerates the Forest and Domain Functional Levels.

    .PARAMETER Server
        Specifies the Active Directory Domain Controller to connect to. If not provided, the function will use the default Domain Controller for the current domain.

    .PARAMETER Credential
        Specifies a PSCredential object containing alternate credentials for connecting to the remote system. If not provided, the current user's credentials will be used.

    .EXAMPLE
        PS C:\> Get-IADFunctionalLevel

        Retrieves information about the Domain and Forest functional levels using the current user's credentials.

    .EXAMPLE
        PS C:\> $SecurePassword = ConvertTo-SecureString 'P@ssw0rd' -AsPlainText -Force
        PS C:\> $Credential = New-Object System.Management.Automation.PSCredential('AD\User', $SecurePassword)
        PS C:\> Get-IADFunctionalLevel -Credential $Credential

        Retrieves information about the Domain and Forest functional levels using the provided alternate credentials.

    .LINK
        https://learn.microsoft.com/en-us/windows-server/identity/ad-ds/active-directory-functional-levels

    .NOTES
        This file includes code derived from the project Invoke-TrimarcADChecks available at https://github.com/Trimarc/Invoke-TrimarcADChecks, licensed under the MIT License.
        The code has been modified and adapted for use in this project.
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
                    $OutputObject+= New-Object PSObject -Property @{
                        'ForestFunctionalLevel' = $((Get-ADForest @Arguments).ForestMode).ToString()
                        'DomainFunctionalLevel' = $((Get-ADDomain @Arguments).DomainMode).ToString()
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


function Get-IADGPO {
    <#
    .SYNOPSIS
        Enumerates the Group Policy Objects in the current or specified domain.

    .DESCRIPTION
        The Get-IADGPO function enumerates the Group Policy Objects in the current or specified domain.

    .PARAMETER Server
        Specifies the Active Directory Domain Controller to connect to. If not provided, the function will use the default Domain Controller for the current domain.

    .EXAMPLE
        PS C:\> Get-IADGPO

        Retrieves information about the Group Policy Objects for the current user's domain using the current user's credentials.
    #>

    [CmdletBinding(SupportsShouldProcess = $True)]
    Param (
        [Parameter(Mandatory = $false)]
        [ValidateNotNullOrEmpty()]
        [string]
        $Server
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
                    $GPOObjects = Get-GPO -all @Arguments

                    ForEach ($GPO in $GPOObjects) {
                        $OutputObject += New-Object PSObject -Property @{
                            'DisplayName'  = $GPO.DisplayName
                            'DomainName'   = $GPO.DomainName
                            'Owner'        = $GPO.Owner
                            'Id'           = $GPO.Id
                            'Description'  = $GPO.Description
                            'CreationTime' = $GPO.CreationTime
                        }
                    }

                    $OutputObject = $OutputObject | Select-Object Id, DisplayName, Owner, Description, DomainName, CreationTime
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


function Get-IADGPOPermission {
    <#
    .SYNOPSIS
        Enumerates the Group Policy Object permissions in the current or specified domain.

    .DESCRIPTION
        The Get-IADGPOPermission function enumerates the Group Policy Object permissions in the current or specified domain.
        Filters out any standard group which has GPO permissions by default.

    .PARAMETER Server
        Specifies the Active Directory Domain Controller to connect to. If not provided, the function will use the default Domain Controller for the current domain.

    .EXAMPLE
        PS C:\> Get-IADGPOPermission

        Retrieves information about the Group Policy Object permissions for the current user's domain using the current user's credentials.
    #>

    [CmdletBinding(SupportsShouldProcess = $True)]
    Param (
        [Parameter(Mandatory = $false)]
        [ValidateNotNullOrEmpty()]
        [string]
        $Server
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
                    $StandardTrustees = @('Domain Admins', 'Enterprise Admins', 'Administrator', 'SYSTEM', 'Authenticated Users', 'ENTERPRISE DOMAIN CONTROLLERS')
                    $GPOObjects = Get-GPO -all @Arguments

                    ForEach ($GPO in $GPOObjects) {
                        $GPOPermissions = Get-GPPermissions -Guid $GPO.id -All @Arguments
                        foreach ($GPOPermission in $GPOPermissions) {
                            if ($StandardTrustees -notcontains $GPOPermission.Trustee.Name) {
                                $OutputObject += New-Object PSObject -Property @{
                                    'DisplayName' = $GPO.DisplayName
                                    'Id'          = $GPO.Id
                                    'Trustee'     = $GPOPermission.Trustee.Name
                                    'TrusteeType' = $GPOPermission.Trustee.SidType
                                    'Permission'  = $GPOPermission.Permission
                                    'Inherited'   = $GPOPermission.Inherited
                                }
                            }
                        }
                    }

                    $OutputObject = $OutputObject | Select-Object Id, DisplayName, Trustee, TrusteeType, Permission, Inherited
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


function Get-IADGPPPassword {
    <#
    .SYNOPSIS
        Enumerates the SYSVOL directory for GPP passwords in the current or specified domain.

    .DESCRIPTION
        The Get-IADGPPPassword function enumerates the SYSVOL directory for GPP passwords in the current or specified domain.

    .PARAMETER Server
        Specifies the Active Directory Domain Controller to connect to. If not provided, the function will use the default Domain Controller for the current domain.

    .PARAMETER Credential
        Specifies a PSCredential object containing alternate credentials for connecting to the remote system. If not provided, the current user's credentials will be used.

    .EXAMPLE
        PS C:\> Get-IADGPPPassword

        Retrieves all AD Group Policy passwords for the user's domain using the current user's credentials.

    .EXAMPLE
        PS C:\> $SecurePassword = ConvertTo-SecureString 'P@ssw0rd' -AsPlainText -Force
        PS C:\> $Credential = New-Object System.Management.Automation.PSCredential('AD\User', $SecurePassword)
        PS C:\> Get-IADGPPPassword -Credential $Credential

        Retrieves all AD Group Policy passwords for the user's domain using the provided alternate credentials.

    .LINK
        https://learn.microsoft.com/en-us/defender-for-identity/reversible-passwords-group-policy
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
                        $Arguments['Credential']    = $Credential
                    }

                    $Domain = Get-ADDomain @Arguments

                    $DriveParams = @{
                        'Root'       = "\\$($Domain.InfrastructureMaster)\SYSVOL\"
                        'PSProvider' = 'FileSystem'
                        'Name'       = 'IADSYSVOL'
                    }

                    If ($PSBoundParameters['Credential']) {
                        $DriveParams.Credential  = $Credential
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
    Process {
        Write-Debug "$($FunctionName) - Process."
        Try {
            If ($PSCmdlet.ShouldProcess("$($FunctionName) - Process WhatIf")) {
                Try {

                    [void](New-PSDrive @DriveParams)

                    $CpasswordFiles = Get-ChildItem -Path "$($DriveParams.Name):$($Domain.DNSroot)\Policies\*.xml" -Recurse | Select-String -Pattern 'cpassword'

                    ForEach ($File in $CpasswordFiles) {
                        $OutputObject += New-Object PSObject -Property @{
                            "FilePath" = $($File.toString().split(':'))[0]
                            "Row"      = $($File.toString().split(':'))[1]
                            "Value"    = $($File.toString().split(':'))[2]
                        }
                    }

                    if ((Get-PSDrive $DriveParams.Name)) {
                        Remove-PSDrive -Name $DriveParams.Name -Force
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


function Get-IADGuestAccount {
    <#
    .SYNOPSIS
        Enumerates the Guest account for the current or specified domain.
    .DESCRIPTION
        The Get-IADGuestAccount function enumerates the Guest account for the current or specified domain and returns all relevant account information.

    .PARAMETER Server
        Specifies the Active Directory Domain Controller to connect to. If not provided, the function will use the default Domain Controller for the current domain.

    .PARAMETER Credential
        Specifies a PSCredential object containing alternate credentials for connecting to the remote system. If not provided, the current user's credentials will be used.

    .EXAMPLE
        PS C:\> Get-IADGuestAccount

        Retrieves information about the Guest account using the current user's credentials.

    .EXAMPLE
        PS C:\> $SecurePassword = ConvertTo-SecureString 'P@ssw0rd' -AsPlainText -Force
        PS C:\> $Credential = New-Object System.Management.Automation.PSCredential('AD\User', $SecurePassword)
        PS C:\> Get-IADGuestAccount -Credential $Credential

        Retrieves information about the Guest account using the provided alternate credentials.

    .LINK
        https://learn.microsoft.com/en-us/windows-server/identity/ad-ds/manage/understand-default-user-accounts
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
                    $GuestAccount = Get-ADUser -Properties 'Created', 'Enabled', 'PasswordLastSet' -filter "ObjectSID -eq `"$((Get-ADDomain @Arguments).DomainSID.Value)-501`"" @Arguments
                    If ([string]::IsNullOrEmpty($GuestAccount.PasswordLastSet)) {
                        $PasswordLastSet = 'Never'
                    }
                    Else {
                        $PasswordLastSet = $GuestAccount.PasswordLastSet
                    }
                    $OutputObject+= New-Object PSObject -Property @{
                        'Name'              = $GuestAccount.Name
                        'DistinguishedName' = $GuestAccount.DistinguishedName
                        'Enabled'           = $GuestAccount.Enabled
                        'Created'           = $GuestAccount.Created
                        'PasswordLastSet'   = $PasswordLastSet
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


function Get-IADKerberosDelegation {
    <#
    .SYNOPSIS
        Enumerates any Kerberos delegation on the current or specified domain.

    .DESCRIPTION
        The Get-IADKerberosDelegation function enumerates any Kerberos delegation on the current (or specified) domain.

    .PARAMETER Server
        Specifies the Active Directory Domain Controller to connect to. If not provided, the function will use the default Domain Controller for the current domain.

    .PARAMETER Credential
        Specifies a PSCredential object containing alternate credentials for connecting to the remote system. If not provided, the current user's credentials will be used.

    .EXAMPLE
        PS C:\> Get-IADKerberosDelegation

        Retrieves information about Kerberos delegation for the current user's domain using the current user's credentials.

    .EXAMPLE
        PS C:\> $SecurePassword = ConvertTo-SecureString 'P@ssw0rd' -AsPlainText -Force
        PS C:\> $Credential = New-Object System.Management.Automation.PSCredential('AD\User', $SecurePassword)
        PS C:\> Get-IADKerberosDelegation -Credential $Credential

        Retrieves information about Kerberos delegation using the provided alternate credentials.

    .LINK
        https://learn.microsoft.com/en-us/defender-for-identity/security-assessment-unconstrained-kerberos

    .NOTES
        This file includes code derived from the project Invoke-TrimarcADChecks available at https://github.com/Trimarc/Invoke-TrimarcADChecks, licensed under the MIT License.
        The code has been modified and adapted for use in this project.
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

                    $Properties = @(
                        'Name',
                        'ObjectClass',
                        'PrimaryGroupID',
                        'UserAccountControl',
                        'ServicePrincipalName',
                        'msDS-AllowedToDelegateTo',
                        'msDS-AllowedToActOnBehalfOfOtherIdentity'
                    )

                    $Arguments['Property'] = $Properties
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
                    $KRBDelegationObjects = Get-ADObject -filter { ((UserAccountControl -BAND 0x0080000) -OR (UserAccountControl -BAND 0x1000000) -OR
                        (msDS-AllowedToDelegateTo -like '*') -OR (msDS-AllowedToActOnBehalfOfOtherIdentity -like '*'))
                        -AND (PrimaryGroupID -ne '516') -AND (PrimaryGroupID -ne '521') } @Arguments

                    ForEach ($KRBObject in $KRBDelegationObjects) {
                        If ($KRBObject.UserAccountControl -BAND 0x0080000) {
                            $KRBDelegationServices = 'All Services'
                            $KRBType = 'Unconstrained'
                        }
                        Else {
                            $KRBDelegationServices = 'Specific Services'
                            $KRBType = 'Constrained'
                        }

                        If ($KRBObject.UserAccountControl -BAND 0x1000000) {
                            $KRBDelegationAllowedProtocols = 'Any (Protocol Transition)'
                            $KRBType = 'Constrained with Protocol Transition'
                        }
                        Else {
                            $KRBDelegationAllowedProtocols = 'Kerberos'
                        }

                        If ($KRBObject.'msDS-AllowedToActOnBehalfOfOtherIdentity') {
                            $KRBType = 'Resource-Based Constrained Delegation'
                        }

                        $OutputObject+= New-Object PSObject -Property @{
                            'DistinguishedName'                  = $KRBObject.DistinguishedName
                            'Name'                               = $KRBObject.Name
                            'ServicePrincipalName'               = $KRBObject.ServicePrincipalName
                            'KerberosDelegationServices'         = $KRBDelegationServices
                            'DelegationType'                     = $KRBType
                            'KerberosDelegationAllowedProtocols' = $KRBDelegationAllowedProtocols
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


function Get-IADKerberosEncryptionType {
    <#
    .SYNOPSIS
        Enumerates Kerberos encryption types for the current or specified domain.

    .DESCRIPTION
        The Get-IADKerberosEncryptionType function enumerates Kerberos encryption types for the current or specified domain.

    .PARAMETER Server
        Specifies the Active Directory Domain Controller to connect to. If not provided, the function will use the default Domain Controller for the current domain.

    .PARAMETER Credential
        Specifies a PSCredential object containing alternate credentials for connecting to the remote system. If not provided, the current user's credentials will be used.

    .EXAMPLE
        PS C:\> Get-IADKerberosEncryptionType

        Retrieves information about Kerberos encryption types for the current user's domain using the current user's credentials.

    .EXAMPLE
        PS C:\> $SecurePassword = ConvertTo-SecureString 'P@ssw0rd' -AsPlainText -Force
        PS C:\> $Credential = New-Object System.Management.Automation.PSCredential('AD\User', $SecurePassword)
        PS C:\> Get-IADKerberosEncryptionType -Credential $Credential

        Retrieves information about Kerberos kerberos encryption types using the provided alternate credentials.

    .LINK
        https://learn.microsoft.com/en-us/previous-versions/windows/it-pro/windows-10/security/threat-protection/security-policy-settings/network-security-configure-encryption-types-allowed-for-kerberos
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

                    $SupportedEncryptionTypes = @{
                        0x0  = "Not defined - Default value"
                        0x1  = "DES_CBC_CRC"
                        0x2  = "DES_CBC_MD5"
                        0x3  = "DES_CBC_CRC, DES_CBC_MD5"
                        0x4  = "RC4"
                        0x5  = "DES_CBC_CRC, RC4"
                        0x6  = "DES_CBC_MD5, RC4"
                        0x7  = "DES_CBC_CRC, DES_CBC_MD5, RC4"
                        0x8  = "AES 128"
                        0x9  = "DES_CBC_CRC, AES 128"
                        0xA  = "DES_CBC_MD5, AES 128"
                        0xB  = "DES_CBC_CRC, DES_CBC_MD5, AES 128"
                        0xC  = "RC4, AES 128"
                        0xD  = "DES_CBC_CRC, RC4, AES 128"
                        0xE  = "DES_CBC_MD5, RC4, AES 128"
                        0xF  = "DES_CBC_CBC, DES_CBC_MD5, RC4, AES 128"
                        0x10 = "AES 256"
                        0x11 = "DES_CBC_CRC, AES 256"
                        0x12 = "DES_CBC_MD5, AES 256"
                        0x13 = "DES_CBC_CRC, DES_CBC_MD5, AES 256"
                        0x14 = "RC4, AES 256"
                        0x15 = "DES_CBC_CRC, RC4, AES 256"
                        0x16 = "DES_CBC_MD5, RC4, AES 256"
                        0x17 = "DES_CBC_CRC, DES_CBC_MD5, RC4, AES 256"
                        0x18 = "AES 128, AES 256"
                        0x19 = "DES_CBC_CRC, AES 128, AES 256"
                        0x1A = "DES_CBC_MD5, AES 128, AES 256"
                        0x1B = "DES_CBC_MD5, DES_CBC_MD5, AES 128, AES 256"
                        0x1C = "RC4, AES 128, AES 256"
                        0x1D = "DES_CBC_CRC, RC4, AES 128, AES 256"
                        0x1E = "DES_CBC_MD5, RC4, AES 128, AES 256"
                        0x1F = "DES+A1:C33_CBC_MD5, DES_CBC_MD5, RC4, AES 128, AES 256"
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
    Process {
        Write-Debug "$($FunctionName) - Process."
        Try {
            If ($PSCmdlet.ShouldProcess("$($FunctionName) - Process WhatIf")) {
                Try {
                    $ADObjects = Get-ADObject -LDAPFilter "(&(|(objectclass=user)(objectClass=Computer)))" -Properties * @Arguments

                    ForEach ($ADObj in $ADObjects) {
                        If ($SupportedEncryptionTypes.Keys -contains $ADObj.'msDS-SupportedEncryptionTypes') {
                            $OutputObject+= New-Object PSObject -Property @{
                                'Name'                             = $ADObj.Name
                                'msDS-SupportedEncryptionTypes'    = $SupportedEncryptionTypes[$ADObj.'msDS-SupportedEncryptionTypes']
                                'raw-msDS-SupportedEncryptionTypes'= $ADObj.'msDS-SupportedEncryptionTypes'
                                'ObjectClass'                      = $ADObj.ObjectClass
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


function Get-IADKerberosServiceAccount {
    <#
    .SYNOPSIS
        Enumerates the KRBTGT account for the current or specified domain.

    .DESCRIPTION
        The Get-IADKerberosServiceAccount function enumerates the KRBTGT account for the current (or specified) domain and returns all relevant account information.

    .PARAMETER Server
        Specifies the Active Directory Domain Controller to connect to. If not provided, the function will use the default Domain Controller for the current domain.

    .PARAMETER Credential
        Specifies a PSCredential object containing alternate credentials for connecting to the remote system. If not provided, the current user's credentials will be used.

    .EXAMPLE
        PS C:\> Get-IADKerberosServiceAccount

        Retrieves information about the KRBTGT account using the current user's credentials.

    .EXAMPLE
        PS C:\> $SecurePassword = ConvertTo-SecureString 'P@ssw0rd' -AsPlainText -Force
        PS C:\> $Credential = New-Object System.Management.Automation.PSCredential('AD\User', $SecurePassword)
        PS C:\> Get-IADKerberosServiceAccount -Credential $Credential

        Retrieves information about the KRBTGT account using the provided alternate credentials.

    .LINK
        https://learn.microsoft.com/en-us/windows-server/identity/ad-ds/manage/understand-default-user-accounts

    .LINK
        https://techcommunity.microsoft.com/t5/core-infrastructure-and-security/faqs-from-the-field-on-krbtgt-reset/ba-p/2367838

    .NOTES
        This file includes code derived from the project Invoke-TrimarcADChecks available at https://github.com/Trimarc/Invoke-TrimarcADChecks, licensed under the MIT License.
        The code has been modified and adapted for use in this project.
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
                    $KRBTGT = Get-ADUser 'krbtgt' -Properties 'msds-keyversionnumber', 'Created', 'PasswordLastSet' @Arguments

                    $OutputObject+= New-Object PSObject -Property @{
                        'Name'                  = $KRBTGT.Name
                        'DistinguishedName'     = $KRBTGT.DistinguishedName
                        'Created'               = $KRBTGT.Created
                        'PasswordLastSet'       = $KRBTGT.PasswordLastSet
                        'msds-keyversionnumber' = $KRBTGT.'msds-keyversionnumber'
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


function Get-IADMSDSMachineQuota {
    <#
    .SYNOPSIS
        Enumerates the ms-DS-MachineAccountQuota attribute for the current or specified domain.

    .DESCRIPTION
        The Get-IADMSDSMachineQuota function enumerates the ms-DS-MachineAccountQuota attribute for the current or specified domain.

    .PARAMETER Server
        Specifies the Active Directory Domain Controller to connect to. If not provided, the function will use the default Domain Controller for the current domain.

    .PARAMETER Credential
        Specifies a PSCredential object containing alternate credentials for connecting to the remote system. If not provided, the current user's credentials will be used.

    .EXAMPLE
        PS C:\> Get-IADMSDSMachineQuota

        Retrieves the value of the ms-DS-MachineAccountQuota attribute using the current user's credentials.

    .EXAMPLE
        PS C:\> $SecurePassword = ConvertTo-SecureString 'P@ssw0rd' -AsPlainText -Force
        PS C:\> $Credential = New-Object System.Management.Automation.PSCredential('AD\User', $SecurePassword)
        PS C:\> Get-IADMSDSMachineQuota -Credential $Credential

        Retrieves the value of the ms-DS-MachineAccountQuota attribute using the provided alternate credentials.
    .LINK
        https://learn.microsoft.com/en-us/troubleshoot/windows-server/active-directory/default-workstation-numbers-join-domain
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
                    $MAQ = Get-ADObject -Identity ((Get-ADDomain @Arguments).DistinguishedName) -Properties 'DistinguishedName', 'ms-DS-MachineAccountQuota' @Arguments

                    $OutputObject = New-Object PSObject -Property @{
                        'DistinguishedName'         = $MAQ.'DistinguishedName'
                        'ms-DS-MachineAccountQuota' = $MAQ."ms-ds-machineaccountquota"
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


function Get-IADProtectedUsersGroup {
    <#
    .SYNOPSIS
        Enumerates the Protected Users group for the current or specified domain.

    .DESCRIPTION
        The Get-IADProtectedUsersGroup function enumerates the Protected Users group for the current or specified domain.

    .PARAMETER Recursive
        Gathers members of the Protected Users group recursively.

    .PARAMETER Server
        Specifies the Active Directory Domain Controller to connect to. If not provided, the function will use the default Domain Controller for the current domain.

    .PARAMETER Credential
        Specifies a PSCredential object containing alternate credentials for connecting to the remote system. If not provided, the current user's credentials will be used.

    .EXAMPLE
        PS C:\> Get-IADProtectedUsersGroup

        Retrieves the members of built-in Active Directory Protected Users group using the current user's credentials.

    .EXAMPLE
        PS C:\> $SecurePassword = ConvertTo-SecureString 'P@ssw0rd' -AsPlainText -Force
        PS C:\> $Credential = New-Object System.Management.Automation.PSCredential('AD\User', $SecurePassword)
        PS C:\> Get-IADProtectedUsersGroup -Credential $Credential

        Retrieves the members of built-in Active Directory Protected Users group using the provided alternate credentials.

    .LINK
        https://learn.microsoft.com/en-us/windows-server/security/credentials-protection-and-management/protected-users-security-group
    #>

    [CmdletBinding(SupportsShouldProcess = $True)]
    Param (
        [Parameter(Mandatory = $false)]
        [switch]
        $Recursive,

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

                    If ($PSBoundParameters['Recursive']) {
                        $Arguments['Recursive'] = $true
                    }
                    If ($PSBoundParameters['Server']) {
                        $Arguments['Server'] = $Server
                    }
                    If ($PSBoundParameters['Credential']) {
                        $Arguments['Credential'] = $Credential
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
    Process {
        Write-Debug "$($FunctionName) - Process."
        Try {
            If ($PSCmdlet.ShouldProcess("$($FunctionName) - Process WhatIf")) {
                Try {
                    $ProtectedUsersGroup = Get-ADObject -filter "ObjectSID -eq `"$((get-addomain @Arguments).DomainSID.Value)-525`"" @Arguments

                    $ProtectedUsersGroupUsers = @(Get-ADObject -LDAPFilter "(&(memberOf:1.2.840.113556.1.4.1941:=$($ProtectedUsersGroup.DistinguishedName)))" -Properties * @Arguments)

                    ForEach ($GroupMember in $ProtectedUsersGroupUsers) {
                        $OutputObject+= New-Object PSObject -Property @{
                            'Name'              = $GroupMember.Name
                            'DistinguishedName' = $GroupMember.DistinguishedName
                            'SamAccountName'    = $GroupMember.SamAccountName
                            'objectClass'       = $GroupMember.ObjectClass
                            'SID'               = ($($GroupMember.objectSid.value).split('-')[-1])
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


function Get-IADTombstoneLifetime {
    <#
    .SYNOPSIS
        Enumerates the Tombstone Lifetime attribute for the current or specified domain.

    .DESCRIPTION
        The Get-IADTombstoneLifetime function enumerates the Tombstone Lifetime attribute for the current or specified domain.

    .PARAMETER Server
        Specifies the Active Directory Domain Controller to connect to. If not provided, the function will use the default Domain Controller for the current domain.

    .PARAMETER Credential
        Specifies a PSCredential object containing alternate credentials for connecting to the remote system. If not provided, the current user's credentials will be used.

    .EXAMPLE
        PS C:\> Get-IADTombstoneLifetime

        Retrieves the value of the Tombstone Lifetime attribute using the current user's credentials.

    .EXAMPLE
        PS C:\> $SecurePassword = ConvertTo-SecureString 'P@ssw0rd' -AsPlainText -Force
        PS C:\> $Credential = New-Object System.Management.Automation.PSCredential('AD\User', $SecurePassword)
        PS C:\> Get-IADTombstoneLifetime -Credential $Credential

        Retrieves the value of the Tombstone Lifetime attribute using the provided alternate credentials.

    .LINK
        https://learn.microsoft.com/en-us/previous-versions/technet-magazine/cc137800(v=msdn.10)?redirectedfrom=MSDN

    .NOTES
        This file includes code derived from the project Invoke-TrimarcADChecks available at https://github.com/Trimarc/Invoke-TrimarcADChecks, licensed under the MIT License.
        The code has been modified and adapted for use in this project.
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
                    $ADConfigurationNamingContext = (Get-ADRootDSE @Arguments).configurationNamingContext
                    $TombstoneLifetime = Get-ADObject -Identity "CN=Directory Service,CN=Windows NT,CN=Services,$($ADConfigurationNamingContext)" -Partition "$ADConfigurationNamingContext" -Properties TombstoneLifetime @Arguments

                    $OutputObject+= New-Object PSObject -Property @{
                        'TombstoneLifetime' = $TombstoneLifetime.tombstoneLifetime
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


function Get-IADUserAccountHealth {
    <#
    .SYNOPSIS
        Enumerates common user object attributes for the current or specified domain.

    .DESCRIPTION
        The Get-IADUserAccountHealth function enumerates common user object attributes for the current or specified domain.

    .PARAMETER Server
        Specifies the Active Directory Domain Controller to connect to. If not provided, the function will use the default Domain Controller for the current domain.

    .PARAMETER Credential
        Specifies a PSCredential object containing alternate credentials for connecting to the remote system. If not provided, the current user's credentials will be used.

    .PARAMETER InactiveDate
        Used to determine the cutoff point for inactive accounts. Defaults to 180 days ( $((Get-Date) - (New-TimeSpan -Days 180)) )

    .EXAMPLE
        PS C:\> Get-IADUserAccountHealth

        Enumerates user objects attribute using the current user's credentials.

    .EXAMPLE
        PS C:\> $SecurePassword = ConvertTo-SecureString 'P@ssw0rd' -AsPlainText -Force
        PS C:\> $Credential = New-Object System.Management.Automation.PSCredential('AD\User', $SecurePassword)
        PS C:\> Get-IADUserAccountHealth -Credential $Credential

        Enumerates user objects attribute using the provided alternate credentials.

    .EXAMPLE
        PS C:\> Get-IADUserAccountHealth -InactiveDate $((Get-Date) - (New-TimeSpan -Days 30))

        Enumerates user objects attribute with the inactive date parameter using the provided alternate credentials.

    .NOTES
        This file includes code derived from the project Invoke-TrimarcADChecks available at https://github.com/Trimarc/Invoke-TrimarcADChecks, licensed under the MIT License.
        The code has been modified and adapted for use in this project.
    #>

    [CmdletBinding(SupportsShouldProcess = $True)]
    Param (
        [Parameter(Mandatory = $false)]
        [ValidateNotNullOrEmpty()]
        [String]
        $Server,

        [Parameter(Mandatory = $false)]
        [Management.Automation.PSCredential]
        [Management.Automation.CredentialAttribute()]
        $Credential = [Management.Automation.PSCredential]::Empty,

        [Parameter(Mandatory = $false)]
        [DateTime]
        $InactiveDate = $((Get-Date) - (New-TimeSpan -days 180))
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

                    $Properties = @(
                        "Name",
                        "Enabled",
                        "SAMAccountname",
                        "DisplayName",
                        "Enabled",
                        "LastLogonDate",
                        "PasswordLastSet",
                        "PasswordNeverExpires",
                        "PasswordNotRequired",
                        "PasswordExpired",
                        "SmartcardLogonRequired",
                        "AccountExpirationDate",
                        "AdminCount",
                        "Created",
                        "Modified",
                        "LastBadPasswordAttempt",
                        "badpwdcount",
                        "CanonicalName",
                        "DistinguishedName",
                        "ServicePrincipalName",
                        "SID",
                        "SIDHistory",
                        "PrimaryGroupID",
                        "UserAccountControl",
                        "DoesNotRequirePreAuth"
                    )

                    $Arguments['Property'] = $Properties

                    $InactiveDate = (Get-Date) - (New-TimeSpan -days 180)
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
                    $DomainUsers = Get-ADUser -Filter * @Arguments | Where-Object { $_.CanonicalName -notmatch '\$$' } | Select-Object DistinguishedName, Enabled, GivenName, Name, ObjectClass, ObjectGUID, SamAccountName, @{Name = "SID"; Expression = { $_.SID.ToString() } }, Surname, UserPrincipalName, LastLogonDate, UserAccountControl, PasswordNotRequired, PasswordNeverExpires, DoesNotRequirePreAuth, SIDHistory
                    $OutputObject += [PSCustomObject]@{
                        'AllUsers'                      = $DomainUsers
                        'Enabled'                       = $DomainUsers | Where-Object { $_.Enabled -eq $True }
                        'Disabled'                      = $DomainUsers | Where-Object { $_.Enabled -eq $False }
                        'Inactive'                      = $DomainUsers | Where-Object { ($_.LastLogonDate -le $InactiveDate) -and ($_.PasswordLastSet -le $InactiveDate) }
                        'ReversibleEncryption'          = $DomainUsers | Where-Object { $_.UserAccountControl -band 0x0080 }
                        'PasswordNotRequired'           = $DomainUsers | Where-Object { $_.PasswordNotRequired -eq $True }
                        'PasswordNeverExpires'          = $DomainUsers | Where-Object { $_.PasswordNeverExpires -eq $True }
                        'KerberosDES'                   = $DomainUsers | Where-Object { $_.UserAccountControl -band 0x200000 }
                        'KerberosDoesNotRequirePreAuth' = $DomainUsers | Where-Object { $_.DoesNotRequirePreAuth -eq $True }
                        'SIDHistory'                    = $DomainUsers | Where-Object { $_.SIDHistory -like "*" }
                        'MarkedAsSensitive'             = $DomainUsers | Where-Object { $_.UserAccountControl -band 0x100000 }
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


function Import-IADADModule {
    <#
    .SYNOPSIS
        Imports the AD Module RSAT and installs the module if necessary.

    .DESCRIPTION
        The Import-IADADModule function checks if the Active Directory RSAT are available on the machine.
        If not, it prompts the user to install them. Then, it imports the ActiveDirectory module.

    .EXAMPLE
        PS C:\> Import-IADADModule

        This command will check for the ActiveDirectory module, prompt for installation if needed, and then import it.

    .NOTES
        Requires elevation to install RSAT if they are not already present.

    .LINK
        https://docs.microsoft.com/en-us/powershell/module/activedirectory
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

                    If (-not (Get-Module -Listavailable -Name "ActiveDirectory")) {

                        Write-IADColor -Text "`n[!] It appears that the Active Directory Remote Server Administration Tools are missing from this machine." -Color Red
                        Write-IADColor -Text "[!] Would you like to proceed with the installation of the Active Directory Remote Server Administration Tools? (Y/N) " -Color Red -NoNewline
                        $Confirmed = Read-Host

                        if ($Confirmed.ToLower() -notin @('yes', 'y')) {
                            exit
                        }

                        Start-Process Powershell.exe -Wait -Verb runas -ArgumentList 'Add-WindowsCapability -Name "Rsat.ActiveDirectory.DS-LDS.Tools~~~~0.0.1.0" -Online'
                    }

                    Import-Module -Name "ActiveDirectory"
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


function Import-IADGPOModule {
    <#
    .SYNOPSIS
        Imports the GPO Management Module RSAT and installs the module if necessary.

    .DESCRIPTION
        The Import-IADADModule function checks if the GPO Management Module RSAT are available on the machine.
        If not, it prompts the user to install them. Then, it imports the GPO Management module.

    .EXAMPLE
        PS C:\> Import-IADADModule

        This command will check for the GPO Management module, prompt for installation if needed, and then import it.

    .NOTES
        Requires elevation to install RSAT if they are not already present.

    .LINK
        https://learn.microsoft.com/en-us/powershell/module/grouppolicy/
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

                    If (-not (Get-Module -Listavailable -Name "GroupPolicy")) {

                        Write-IADColor -Text "`n[!] It appears that the Group Policy Management Remote Server Administration Tools are missing from this machine." -Color Red
                        Write-IADColor -Text "[!] Would you like to proceed with the installation of the Group Policy Management Remote Server Administration Tools? (Y/N) " -Color Red -NoNewline
                        $Confirmed = Read-Host

                        if ($Confirmed.ToLower() -notin @('yes', 'y')) {
                            exit
                        }

                        Start-Process Powershell.exe -Wait -Verb runas -ArgumentList 'Add-WindowsCapability -Name "Rsat.GroupPolicy.Management.Tools~~~~0.0.1.0" -Online'
                    }

                    Import-Module -Name "GroupPolicy"
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


function Invoke-IADCheck {
    <#
    .SYNOPSIS
        Parses Invoke-ADCheck checks and executes the private functions for the selected checks.

    .DESCRIPTION
        The Invoke-IADCheck function parses Invoke-ADCheck checks and executes the private functions for the selected checks.
        Once the chosen checks have been completed, the PSCustomObject OutputObject with results is returned to the public Invoke-ADCheck function.

    .EXAMPLE
        PS C:\> Invoke-IADCheck -Checks $Checks

        This command will parse the $Checks array and execute any selected checks and return the results.
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
        $Credential = [Management.Automation.PSCredential]::Empty,

        [Parameter(Mandatory=$True)]
        [String[]]$Checks
    )

    Begin {
        $FunctionName = $MyInvocation.MyCommand.Name
        Write-Debug "$($FunctionName) - Begin."
        Try {
            If ($script:ThisModuleLoaded -eq $true) {
                Get-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState
            }
            If ($PSCmdlet.ShouldProcess("$($FunctionName) - Begin WhatIf")) {

                If ($PSBoundParameters['Server']) {
                    $Arguments['Server'] = $Server
                }

                If ($PSBoundParameters['Credential']) {
                    $Arguments['Credential']    = $Credential
                }

                Write-Verbose "$($FunctionName) - Setup empty OutputObject with predefined structure."

                $OutputObject = [PSCustomObject] @{
                    IADADBackupStatus              = $null
                    IADBuiltInGroupMembership      = $null
                    IADDefaultAdministrator        = $null
                    IADDefaultDomainPasswordPolicy = $null
                    IADDomainController            = $null
                    IADDomainTrust                 = $null
                    IADFunctionalLevel             = $null
                    IADGPO                         = $null
                    IADGPOPermission               = $null
                    IADGPPPassword                 = $null
                    IADGuestAccount                = $null
                    IADKerberosDelegation          = $null
                    IADKerberosEncryptionType      = $null
                    IADKerberosServiceAccount      = $null
                    IADMSDSMachineQuota            = $null
                    IADProtectedUsersGroup         = $null
                    IADRootACL                     = $null
                    IADTombstoneLifetime           = $null
                    IADUserAccountHealth           = $null
                }

                Write-Verbose "$($FunctionName) - Setup functions hashtable."

                $checkFunctions = @{
                    "ADBackupStatus"              = { $OutputObject.IADADBackupStatus = Get-IADADBackupStatus @Arguments }
                    "BuiltInGroupMembership"      = { $OutputObject.IADBuiltInGroupMembership = Get-IADBuiltInGroupMembership @Arguments }
                    "DefaultAdministrator"        = { $OutputObject.IADDefaultAdministrator = Get-IADDefaultAdministrator @Arguments }
                    "DefaultDomainPasswordPolicy" = { $OutputObject.IADDefaultDomainPasswordPolicy = Get-IADDefaultDomainPasswordPolicy @Arguments }
                    "DomainController"            = { $OutputObject.IADDomainController = Get-IADDomainController @Arguments }
                    "DomainTrust"                 = { $OutputObject.IADDomainTrust = Get-IADDomainTrust @Arguments }
                    "FunctionalLevel"             = { $OutputObject.IADFunctionalLevel = Get-IADFunctionalLevel @Arguments }
                    "GPO"                         = { if ($EnableGPOChecks) { $OutputObject.IADGPO = Get-IADGPO } }
                    "GPOPermission"               = { if ($EnableGPOChecks) { $OutputObject.IADGPOPermission = Get-IADGPOPermission } }
                    "GPPPassword"                 = { $OutputObject.IADGPPPassword = Get-IADGPPPassword @Arguments }
                    "GuestAccount"                = { $OutputObject.IADGuestAccount = Get-IADGuestAccount @Arguments }
                    "KerberosDelegation"          = { $OutputObject.IADKerberosDelegation = Get-IADKerberosDelegation @Arguments }
                    "KerberosEncryptionType"      = { $OutputObject.IADKerberosEncryptionType = Get-IADKerberosEncryptionType @Arguments }
                    "KerberosServiceAccount"      = { $OutputObject.IADKerberosServiceAccount = Get-IADKerberosServiceAccount @Arguments }
                    "MachineQuota"                = { $OutputObject.IADMSDSMachineQuota = Get-IADMSDSMachineQuota @Arguments }
                    "ProtectedUsersGroup"         = { $OutputObject.IADProtectedUsersGroup = Get-IADProtectedUsersGroup @Arguments }
                    "RootACL"                     = { $OutputObject.IADRootACL = Get-IADRootACL @Arguments }
                    "TombStone"                   = { $OutputObject.IADTombstoneLifetime = Get-IADTombstoneLifetime @Arguments }
                    "UserAccountHealth"           = { $OutputObject.IADUserAccountHealth = Get-IADUserAccountHealth @Arguments }
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
                    Write-Verbose "$($FunctionName) - Loop through selected checks."

                    foreach ($Check in $CheckFunctions.Keys) {
                        if ($Checks -contains "All" -or $Checks -contains $Check) {
                            $CheckFunctions[$Check].Invoke()
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
                    return $OutputObject
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


function Write-IADChecksToCLI {
    <#
    .SYNOPSIS
        Writes the results of various Active Directory checks to the command-line interface.

    .DESCRIPTION
        The Write-IADChecksToCLI function takes the results of multiple Active Directory checks and writes them to the console in a formatted manner. It covers various aspects of AD health and security, including backup status, group memberships, account settings, and more.

    .PARAMETER Object
        A PSCustomObject containing the results of various AD checks.

    .PARAMETER Domain
        Specifies the name of the Active Directory domain being checked.

    .PARAMETER ADBackupThreshold
        Specifies the threshold date for considering AD backups as outdated. Default is 90 days ago.

    .PARAMETER PwdLastSetThreshold
        Specifies the threshold date for considering passwords as outdated. Default is 365 days ago.

    .PARAMETER LastLogonDateThreshold
        Specifies the threshold date for considering user accounts as inactive. Default is 365 days ago.

    .PARAMETER OutdatedWinVersions
        Specifies which Windows versions are considered outdated. Default is @("2000", "2003", "2008", "2012", "2016").

    .PARAMETER OutdatedFuncVersions
        Specifies which functional levels are considered outdated. Default is @("2000", "2003", "2008", "2012").

    .PARAMETER AbusableKerberosDelegationTypes
        Specifies which Kerberos delegation types are considered abusable. Default is @('Resource-Based Constrained Delegation', 'Unconstrained').

    .PARAMETER SecureKerberosEncTypes
        Specifies which Kerberos encryption types are considered secure. Default is @('8', '16', '24').

    .PARAMETER TombstoneLifetimeThreshold
        Specifies the threshold (in days) for considering the tombstone lifetime as too short. Default is 180 days.

    .EXAMPLE
        PS C:\> $CLIArgs = @{
                'Object'                          = $OutputObject
                'Domain'                          = $ADFQDN
                'ADBackupThreshold'               = $ADBackupThreshold
                'PwdLastSetThreshold'             = $PwdLastSetThreshold
                'LastLogonDateThreshold'          = $LastLogonDateThreshold
                'TombstoneLifetimeThreshold'      = $TombstoneLifetimeThreshold
                'OutdatedFuncVersions'            = $OutdatedFuncVersions
                'OutdatedWinVersions'             = $OutdatedWinVersions
                'AbusableKerberosDelegationTypes' = $AbusableKerberosDelegationTypes
                'SecureKerberosEncTypes'          = $SecureKerberosEncTypes
            }
        PS C:\> Write-IADChecksToCLI $CLIArgs

        This example runs AD health checks and then writes the results to the console with specific thresholds and criteria.

    .NOTES
        This function is part of a larger AD health checking module and relies on other functions like Update-IADOutputObjectColor and Write-IADOutput for formatting and displaying results.

    .NOTES
        This file includes code derived from the project Invoke-TrimarcADChecks available at https://github.com/Trimarc/Invoke-TrimarcADChecks, licensed under the MIT License.
        The code has been modified and adapted for use in this project.
    #>

    [CmdletBinding(SupportsShouldProcess = $True)]
    Param (
        [Parameter(Mandatory = $true)]
        [PSCustomObject]$Object,

        [Parameter(Mandatory = $true)]
        [string]$Domain,

        [Parameter(Mandatory = $true)]
        [bool]$EnableGPOChecks,

        [Parameter(Mandatory = $true)]
        [datetime]$ADBackupThreshold,

        [Parameter(Mandatory = $true)]
        [datetime]$PwdLastSetThreshold,

        [Parameter(Mandatory = $true)]
        [datetime]$LastLogonDateThreshold,

        [Parameter(Mandatory = $true)]
        [int]$TombstoneLifetimeThreshold,

        [Parameter(Mandatory = $true)]
        [array]$OutdatedFuncVersions,

        [Parameter(Mandatory = $true)]
        [array]$OutdatedWinVersions,

        [Parameter(Mandatory = $true)]
        [array]$AbusableKerberosDelegationTypes,

        [Parameter(Mandatory = $true)]
        [array]$SecureKerberosEncTypes
    )

    Begin {
        $FunctionName = $MyInvocation.MyCommand.Name
        Write-Debug "$($FunctionName) - Begin."
        Try {
            If ($script:ThisModuleLoaded -eq $true) {
                Get-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState
            }
            If ($PSCmdlet.ShouldProcess("$($FunctionName) - Begin WhatIf")) {

                $Domain = $Domain.ToString().ToUpper()

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
                    $ColeredObject = [Management.Automation.PSSerializer]::DeSerialize(
                        [Management.Automation.PSSerializer]::Serialize($Object)
                    )

                    If (($Checks -contains "All") -or
                        ($Checks -contains "ADBackupStatus")) {
                        Write-Host "[+] Active Directory Backup ($Domain):"
                        $tmp = @()
                        $ColeredObject.IADADBackupStatus | ForEach-Object {
                            If ($_.LastBackupDate -lt $ADBackupThreshold) {
                                $tmp += $_ | Update-IADOutputObjectColor -PropertyToUpdate 'LastBackupDate'
                            }
                            Else {
                                $tmp += $_
                            }
                        }

                        $tmp | Write-IADOutput
                    }
                    If (($Checks -contains "All") -or
                        ($Checks -contains "BuiltInGroupMembership")) {
                        Write-Host "[+] Default Active Directory Security Groups ($Domain):"
                        $ColeredObject.IADBuiltInGroupMembership | Select-Object Group, @{N = 'MembershipCount'; E = { $_.MembersCount } }, Notes |
                        Sort-Object -Property 'MembershipCount' -Descending | Write-IADOutput
                    }
                    If (($Checks -contains "All") -or
                        ($Checks -contains "DefaultAdministrator")) {
                        Write-Host "[+] Default Administrator Account ($Domain):"

                        If ($ColeredObject.IADDefaultAdministrator.Enabled -ne $true) {
                            [void]($ColeredObject.IADDefaultAdministrator | Update-IADOutputObjectColor -PropertyToUpdate Enabled)
                        }

                        If ($ColeredObject.IADDefaultAdministrator.MarkedAsSensitive -ne $true) {
                            [void]($ColeredObject.IADDefaultAdministrator | Update-IADOutputObjectColor -PropertyToUpdate MarkedAsSensitive)
                        }

                        If ($ColeredObject.IADDefaultAdministrator.LastLogonDate -gt $LastLogonDateThreshold) {
                            [void]($ColeredObject.IADDefaultAdministrator | Update-IADOutputObjectColor -PropertyToUpdate LastLogonDate)
                        }

                        If ($ColeredObject.IADDefaultAdministrator.PasswordLastSet -lt $PwdLastSetThreshold) {
                            [void]($ColeredObject.IADDefaultAdministrator | Update-IADOutputObjectColor -PropertyToUpdate PasswordLastSet)
                        }

                        If ($ColeredObject.IADDefaultAdministrator.ServicePrincipalName.Count -gt 0) {
                            [void]($ColeredObject.IADDefaultAdministrator | Update-IADOutputObjectColor -PropertyToUpdate ServicePrincipalName)
                        }
                        $ColeredObject.IADDefaultAdministrator | Select-Object name, Enabled, LastLogonDate, MarkedAsSensitive, created, PasswordLastSet, ServicePrincipalName | Write-IADOutput
                    }

                    If (($Checks -contains "All") -or
                        ($Checks -contains "DefaultDomainPasswordPolicy")) {
                        Write-Host "[+] Default Domain Password Policy ($Domain):"

                        If ($ColeredObject.IADDefaultDomainPasswordPolicy.ComplexityEnabled -ne $true) {
                            [void]($ColeredObject.IADDefaultDomainPasswordPolicy | Update-IADOutputObjectColor -PropertyToUpdate ComplexityEnabled)
                        }

                        If ($ColeredObject.IADDefaultDomainPasswordPolicy.ReversibleEncryptionEnabled -eq $true) {
                            [void]($ColeredObject.IADDefaultDomainPasswordPolicy | Update-IADOutputObjectColor -PropertyToUpdate ReversibleEncryptionEnabled)
                        }

                        If (($ColeredObject.IADDefaultDomainPasswordPolicy.MaxPasswordAge.TotalDays -lt 180) -or ($ColeredObject.IADDefaultDomainPasswordPolicy.MaxPasswordAge.TotalDays -gt 365)) {
                            [void]($ColeredObject.IADDefaultDomainPasswordPolicy | Update-IADOutputObjectColor -PropertyToUpdate MaxPasswordAge)
                        }

                        If ($ColeredObject.IADDefaultDomainPasswordPolicy.MinPasswordAge.TotalDays -le 1) {
                            [void]($ColeredObject.IADDefaultDomainPasswordPolicy | Update-IADOutputObjectColor -PropertyToUpdate MinPasswordAge)
                        }

                        If ($ColeredObject.IADDefaultDomainPasswordPolicy.MinPasswordLength -lt 12) {
                            [void]($ColeredObject.IADDefaultDomainPasswordPolicy | Update-IADOutputObjectColor -PropertyToUpdate MinPasswordLength)
                        }

                        If ($ColeredObject.IADDefaultDomainPasswordPolicy.PasswordHistoryCount -lt 24) {
                            [void]($ColeredObject.IADDefaultDomainPasswordPolicy | Update-IADOutputObjectColor -PropertyToUpdate PasswordHistoryCount)
                        }

                        If ($ColeredObject.IADDefaultDomainPasswordPolicy.LockoutDuration.TotalMinutes -lt 10) {
                            [void]($ColeredObject.IADDefaultDomainPasswordPolicy | Update-IADOutputObjectColor -PropertyToUpdate LockoutDuration)
                        }

                        If ($ColeredObject.IADDefaultDomainPasswordPolicy.LockoutObservationWindow.TotalMinutes -lt 10) {
                            [void]($ColeredObject.IADDefaultDomainPasswordPolicy | Update-IADOutputObjectColor -PropertyToUpdate LockoutObservationWindow)
                        }

                        If ($ColeredObject.IADDefaultDomainPasswordPolicy.LockoutThreshold -gt 5) {
                            [void]($ColeredObject.IADDefaultDomainPasswordPolicy | Update-IADOutputObjectColor -PropertyToUpdate LockoutThreshold)
                        }

                        $ColeredObject.IADDefaultDomainPasswordPolicy | Write-IADOutput
                    }
                    If (($Checks -contains "All") -or
                        ($Checks -contains "DomainController")) {
                        Write-Host "[+] Domain Controller(s) ($Domain):"
                        $OutdatedWinVersions | ForEach-Object {
                            If ($ColeredObject.IADDomainController.OperatingSystem.toLower().Contains($_.ToLower())) {
                                [void]($ColeredObject.IADDomainController | Update-IADOutputObjectColor -PropertyToUpdate OperatingSystem)
                            }
                        }
                        $ColeredObject.IADDomainController | Write-IADOutput
                    }
                    If (($Checks -contains "All") -or
                        ($Checks -contains "DomainTrust")) {
                        Write-Host "[+] Active Directory Domain Trusts ($Domain):"
                        If ($ColeredObject.IADDomainTrust) {
                            [void]($ColeredObject.IADDomainTrust | Update-IADOutputObjectColor -PropertyToUpdate Dcs)
                            $ColeredObject.IADDomainTrust | Write-IADOutput
                        }
                        Else {
                            Write-Host "    [!] No Active Directory Domain Trusts found." -ForegroundColor Green
                            Write-Host
                            Write-Host
                        }
                    }
                    If (($Checks -contains "All") -or
                        ($Checks -contains "FunctionalLevel")) {
                        Write-Host "[+] Forest and Domain Functional level ($Domain):"
                        $OutdatedFuncVersions | ForEach-Object {
                            If ($ColeredObject.IADFunctionalLevel.ForestFunctionalLevel.toLower().Contains($_.toLower())) {
                                [void]($ColeredObject.IADFunctionalLevel | Update-IADOutputObjectColor -PropertyToUpdate ForestFunctionalLevel)
                            }

                            If ($Object.IADFunctionalLevel.DomainFunctionalLevel.toLower().Contains($_.toLower())) {
                                [void]($ColeredObject.IADFunctionalLevel | Update-IADOutputObjectColor -PropertyToUpdate DomainFunctionalLevel)
                            }
                        }
                        $ColeredObject.IADFunctionalLevel | Write-IADOutput
                    }
                    if ($EnableGPOChecks) {
                        if (($Checks -contains "All") -or ($Checks -contains "GPO")) {
                            Write-Host "[+] Group Policy Objects ($Domain):"
                            if ($ColeredObject.IADGPO) {
                                $ColeredObject.IADGPO | Write-IADOutput
                            } else {
                                Write-Host "    [!] No Group Policy Objects found." -ForegroundColor Red
                                Write-Host
                                Write-Host
                            }
                        }
                        if (($Checks -contains "All") -or ($Checks -contains "GPOPermission")) {
                            Write-Host "[+] Non-default Group Policy Object permissions ($Domain):"
                            if ($ColeredObject.IADGPOPermission) {
                                $ColeredObject.IADGPOPermission | Write-IADOutput
                            } else {
                                Write-Host "    [!] No custom Group Policy Object permissions found." -ForegroundColor Green
                                Write-Host
                                Write-Host
                            }
                        }
                    }
                    If (($Checks -contains "All") -or
                        ($Checks -contains "GPPPassword")) {
                        Write-Host "[+] Group Policy Password ($Domain):"
                        If ($ColeredObject.IADGPPPassword) {
                            [void]($ColeredObject.IADGPPPassword | Update-IADOutputObjectColor -PropertyToUpdate Value)
                            $ColeredObject.IADGPPPassword | Write-IADOutput
                        }
                        Else {
                            Write-Host "    [!] No Group Policy passwords found." -ForegroundColor Green
                            Write-Host
                            Write-Host
                        }
                    }
                    If (($Checks -contains "All") -or
                        ($Checks -contains "GuestAccount")) {
                        Write-Host "[+] Guest Account ($Domain):"
                        If ($ColeredObject.IADGuestAccount.Enabled) {
                            [void]($ColeredObject.IADGuestAccount | Update-IADOutputObjectColor -PropertyToUpdate Enabled)
                        }
                        If ($ColeredObject.IADGuestAccount.PasswordLastSet) {
                            [void]($ColeredObject.IADGuestAccount | Update-IADOutputObjectColor -PropertyToUpdate PasswordLastSet)
                        }
                        $ColeredObject.IADGuestAccount | Write-IADOutput
                    }
                    If (($Checks -contains "All") -or
                        ($Checks -contains "KerberosDelegation")) {
                        Write-Host "[+] Kerberos Delegation ($Domain):"
                        If ($ColeredObject.IADKerberosDelegation) {
                            $ColeredObject.IADKerberosDelegation | ForEach-Object {
                                If ($AbusableKerberosDelegationTypes.Contains($_.DelegationType)) {
                                    [void]($ColeredObject.IADKerberosDelegation | Update-IADOutputObjectColor -PropertyToUpdate KerberosDelegationServices)
                                    [void]($ColeredObject.IADKerberosDelegation | Update-IADOutputObjectColor -PropertyToUpdate DelegationType)
                                }
                                $ColeredObject.IADKerberosDelegation | Write-IADOutput
                            }
                        }
                        Else {
                            Write-Host "    [!] No Kerberos delegations found." -ForegroundColor Green
                            Write-Host
                            Write-Host
                        }
                    }
                    If (($Checks -contains "All") -or
                        ($Checks -contains "KerberosEncryptionType")) {
                        Write-Host "[+] Kerberos Encryption Types ($Domain):"
                        $tmp = @()
                        $ColeredObject.IADKerberosEncryptionType | Where-Object { $_.'raw-msDS-SupportedEncryptionTypes' -cnotin $SecureKerberosEncTypes } | ForEach-Object {
                            $tmp += $_ | Update-IADOutputObjectColor -PropertyToUpdate 'msDS-SupportedEncryptionTypes'
                        }
                        $ColeredObject.IADKerberosEncryptionType | Where-Object { $_.'raw-msDS-SupportedEncryptionTypes' -cin $SecureKerberosEncTypes } | ForEach-Object {
                            $tmp += $_
                        }
                        Write-Host "Unique Kerberos Encryption Types active in $Domain for User Objects:"
                        $tmp | Where-Object { $_.ObjectClass -eq 'user' } | Select-Object -Unique 'msDS-SupportedEncryptionTypes' | Write-IADOutput

                        Write-Host "Unique Kerberos Encryption Types active in $Domain for Computer Objects"
                        $tmp | Where-Object { $_.ObjectClass -eq 'computer' } | Select-Object -Unique 'msDS-SupportedEncryptionTypes' | Write-IADOutput
                    }
                    If (($Checks -contains "All") -or
                        ($Checks -contains "KerberosServiceAccount")) {
                        Write-Host "[+] KRBTGT Account ($Domain):"
                        If ($ColeredObject.IADKerberosServiceAccount.PasswordLastSet -lt $PwdLastSetThreshold) {
                            [void]($ColeredObject.IADKerberosServiceAccount | Update-IADOutputObjectColor -PropertyToUpdate PasswordLastSet)
                        }
                        $ColeredObject.IADKerberosServiceAccount | Write-IADOutput
                    }
                    If (($Checks -contains "All") -or
                        ($Checks -contains "MachineQuota")) {
                        Write-Host "[+] ms-DS-Machine-Account-Quota ($Domain):"
                        If ($ColeredObject.IADMSDSMachineQuota.'ms-DS-MachineAccountQuota' -ne 0) {
                            [void]($ColeredObject.IADMSDSMachineQuota | Update-IADOutputObjectColor -PropertyToUpdate 'ms-DS-MachineAccountQuota')
                        }
                        $ColeredObject.IADMSDSMachineQuota | Write-IADOutput
                    }
                    If (($Checks -contains "All") -or
                        ($Checks -contains "ProtectedUsersGroup")) {
                        Write-Host "[+] Protected Users Security Group ($Domain):"
                        If ($ColeredObject.IADProtectedUsersGroup) {
                            $ColeredObject.IADProtectedUsersGroup | Write-IADOutput
                        }
                        Else {
                            Write-Host "    [x] No members found in the Protected Users security group." -ForegroundColor Red
                            Write-Host
                            Write-Host
                        }
                    }

                    If (($Checks -contains "All") -or
                        ($Checks -contains "RootACL")) {
                        Write-Host "[+] Interesting Active Directory domain permissions ($Domain):"
                        if ($ColeredObject.IADRootACL) {
                            $ColeredObject.IADRootACL | Write-IADOutput
                        } else {
                            Write-Host "    [x] No interesting domain permissions found." -ForegroundColor Green
                            Write-Host
                        }
                    }

                    If (($Checks -contains "All") -or
                        ($Checks -contains "TombStone")) {
                        Write-Host "[+] Tombstone Lifetime ($Domain):"
                        If ($ColeredObject.IADTombstoneLifetime.TombstoneLifetime -lt $TombstoneLifetimeThreshold) {
                            [void]($ColeredObject.IADTombstoneLifetime | Update-IADOutputObjectColor -PropertyToUpdate TombstoneLifetime)
                        }
                        $ColeredObject.IADTombstoneLifetime | Write-IADOutput
                    }
                    If (($Checks -contains "All") -or
                        ($Checks -contains "UserAccountHealth")) {
                        Write-Host "[+] User Account Health ($Domain):"

                        $totalAccounts = $($Object.IADUserAccountHealth.AllUsers | Measure-Object).Count
                        $enabledAccounts = $($Object.IADUserAccountHealth.Enabled | Measure-Object).Count
                        $disabledAccounts = $($Object.IADUserAccountHealth.Disabled | Measure-Object).Count

                        Write-Host "   [-] Total Accounts: $totalAccounts"
                        Write-Host "   [-] Enabled Accounts: $enabledAccounts"
                        Write-Host "   [-] Disabled Accounts: $disabledAccounts"

                        $inactiveCount = $($Object.IADUserAccountHealth.Inactive | Measure-Object).Count
                        Write-IADAccountHealth -Label "Accounts Identified as Inactive" -Count $inactiveCount

                        $markedAsSensitiveCount = $($Object.IADUserAccountHealth.MarkedAsSensitive | Measure-Object).Count
                        Write-IADAccountHealth -Label "Accounts Marked as Sensitive" -Count $markedAsSensitiveCount -warningThreshold 0 -ForceRedOnZeroThreshold

                        $passwordNotRequiredCount = $($Object.IADUserAccountHealth.PasswordNotRequired | Measure-Object).Count
                        Write-IADAccountHealth -Label "Accounts with Password Not Required" -Count $passwordNotRequiredCount

                        $passwordNeverExpiresCount = $($Object.IADUserAccountHealth.PasswordNeverExpires | Measure-Object).Count
                        Write-IADAccountHealth -Label "Accounts with Password Never Expires" -Count $passwordNeverExpiresCount

                        $reversibleEncryptionCount = $($Object.IADUserAccountHealth.ReversibleEncryption | Measure-Object).Count
                        Write-IADAccountHealth -Label "Accounts with Reversible Encryption" -Count $reversibleEncryptionCount

                        $kerberosRequirePreAuthCount = $($Object.IADUserAccountHealth.KerberosRequirePreAuth | Measure-Object).Count
                        Write-IADAccountHealth -Label "Accounts which do not require Kerberos Pre-auth" -Count $kerberosRequirePreAuthCount

                        $kerberosDESCount = $($Object.IADUserAccountHealth.KerberosDES | Measure-Object).Count
                        Write-IADAccountHealth -Label "Accounts with Kerberos DES" -Count $kerberosDESCount

                        $sidHistoryCount = $($Object.IADUserAccountHealth.SIDHistory | Measure-Object).Count
                        Write-IADAccountHealth -Label "Accounts with SID History" -Count $sidHistoryCount
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


Function Write-IADColor {
    <#
    .SYNOPSIS
        Writes text to the console with multiple colors on a single line.

    .DESCRIPTION
        The Write-IADColor function allows you to write text to the console using different colors for each part of the text. It provides a way to create colorful output in PowerShell scripts.

    .PARAMETER Text
        An array of strings to be written to the console. Each element can have a different color.

    .PARAMETER Color
        An array of ConsoleColor values corresponding to the colors for each element in the Text array.

    .PARAMETER NoNewline
        If specified, prevents adding a new line at the end of the output.

    .EXAMPLE
        PS C:\> Write-IADColor -Text "Hello", " ", "World" -Color Red, White, Blue

        Outputs "Hello World" with "Hello" in red, a space in white, and "World" in blue.

    .EXAMPLE
        PS C:\> Write-IADColor -Text "Status:", " OK" -Color Yellow, Green -NoNewline

        Outputs "Status: OK" with "Status:" in yellow and "OK" in green, without adding a new line.

    .NOTES
        The number of elements in the Text and Color arrays should match.

    .LINK
        https://www.reddit.com/r/PowerShell/comments/5pdepn/writecolor_multiple_colors_on_a_single_line/
    #>
    Param (
        [String[]]$Text,
        [ConsoleColor[]]$Color,
        [Switch]$NoNewline = $false
    )

    For ([int]$i = 0; $i -lt $Text.Length; $i++) {
        Write-Host $Text[$i] -Foreground $Color[$i] -NoNewLine
    }

    If ($NoNewline -eq $false) {
        Write-Host ''
    }
}


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


## PUBLIC MODULE FUNCTIONS AND DATA ##

Function Invoke-ADCheck {
    <#
        .EXTERNALHELP InvokeADCheck-help.xml
        .LINK
            https://github.com/sensepost/InvokeADCheck/tree/master/release/0.0.1/docs/Invoke-ADCheck.md
        #>
    [CmdletBinding(SupportsShouldProcess = $True)]
    Param (
        [Parameter(Mandatory = $false)]
        [ValidateNotNullOrEmpty()]
        [String]
        $Server,

        [Parameter(Mandatory = $false)]
        [Management.Automation.PSCredential]
        [Management.Automation.CredentialAttribute()]
        $Credential = [Management.Automation.PSCredential]::Empty,

        [Parameter()]
        [String[]]
        [ValidateSet(
            'All',
            'ADBackupStatus',
            'BuiltInGroupMembership',
            'DefaultAdministrator',
            'DefaultDomainPasswordPolicy',
            'DomainController',
            'DomainTrust',
            'FunctionalLevel',
            'GPO',
            'GPOPermission',
            'GPPPassword',
            'GuestAccount',
            'KerberosEncryptionType',
            'KerberosDelegation',
            'KerberosServiceAccount',
            'MachineQuota',
            'ProtectedUsersGroup',
            'RootACL',
            'TombStone',
            'UserAccountHealth'
        )]
        $Checks = 'All',

        [Parameter()]
        [String[]]
        [ValidateSet(
            'All',
            'CLI',
            'XLSX',
            'JSON',
            'PSObject',
            'TXT'
        )]
        $OutputTypes = 'CLI',

        [Parameter()]
        [String]
        $OutputPath = $ENV:TEMP,

        [Parameter()]
        [String]
        $OutputFolderName = "Invoke-ADCheck_output_$([DateTimeOffset]::Now.ToUnixTimeSeconds())",

        [Parameter()]
        $ADBackupThreshold = $((Get-Date) - (New-TimeSpan -Days 90)),

        [Parameter()]
        $PwdLastSetThreshold = $((Get-Date) - (New-TimeSpan -Days 365)).Date,

        [Parameter()]
        $LastLogonDateThreshold = $((Get-Date) - (New-TimeSpan -Days 365)).Date,

        [Parameter()]
        $OutdatedWinVersions = @("2000", "2003", "2008", "2012", "2016"),

        [Parameter()]
        $OutdatedFuncVersions = @("2000", "2003", "2008", "2012"),

        [Parameter()]
        $AbusableKerberosDelegationTypes = @('Resource-Based Constrained Delegation', 'Unconstrained'),

        [Parameter()]
        $SecureKerberosEncTypes = @('8', '16', '24'), # resolves to @("RC4_HMAC", "AES128", "AES256")

        [Parameter()]
        $TombstoneLifetimeThreshold = 180

    )
    Begin {
        $FunctionName = $MyInvocation.MyCommand.Name
        Write-Debug "$($FunctionName) - Begin."
        Try {
            If ($script:ThisModuleLoaded -eq $true) {
                Get-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState
            }
            If ($PSCmdlet.ShouldProcess("$($FunctionName) - Begin WhatIf")) {
                Try {
                    Write-Verbose "$($FunctionName) - Setup splat using parameters."
                    $Arguments = @{}
                    If ($PSBoundParameters['Credential']) {
                        $Arguments['Credential'] = $Credential
                    }
                    If ($PSBoundParameters['Server']) {
                        $Arguments['Server'] = $Server
                    }

                    Write-Verbose "$($FunctionName) - Import Active Directory PowerShell module."
                    try {
                        Import-IADADModule
                    }
                    catch {
                        Write-Error -Message "Importing Active Directory PowerShell module went wrong. - $($PSItem)"
                    }

                    $EnableGPOChecks = -not [String]::IsNullOrWhiteSpace($ENV:USERDNSDOMAIN) -and -not $PSBoundParameters['Credential']

                    if ($EnableGPOChecks) {
                        Write-Verbose "$($FunctionName) - Import Group Policy Management PowerShell module."
                        try {
                            Import-IADGPOModule
                        }
                        catch {
                            Write-Error -Message "Importing Group Policy Management PowerShell module went wrong. - $($PSItem)"
                        }
                    }
                    else {
                        Write-Host ""
                        Write-Warning "[!] $($FunctionName) - The Group Policy Object checks have been disabled. These checks do not support the '-Credential' parameter and can only be run from a domain-joined machine.`n`n"
                    }

                    Write-Verbose "$($FunctionName) - Check if env variable exists, otherwise attempt to query Domain Controller."

                    if ($Server) {
                        $ADFQDN = (Get-ADDomainController @Arguments).Domain
                    }

                    if (([String]::IsNullOrWhiteSpace($ADFQDN)) -and (-not [String]::IsNullOrWhiteSpace($ENV:USERDNSDOMAIN))) {
                        $ADFQDN = $ENV:USERDNSDOMAIN
                    }

                    if ([String]::IsNullOrWhiteSpace($ADFQDN)) {
                        Write-Error -Message "Unable to identify the target domain. Consider using the '-Server' parameter. $($PSItem)"
                        break
                    }

                    Write-Verbose "$($FunctionName) - Check if running on a domain-joined workstation, otherwise disable GPO checks."

                    Write-Verbose "$($FunctionName) - Ensure the supplied output directory exists."
                    try {
                        $OutputDirectory = Join-Path $OutputPath $OutputFolderName
                        If (!(Test-Path -Path $OutputDirectory -Type Container)) {
                            [void](New-Item -ItemType Directory -Path $OutputDirectory)
                            $FileName = "Invoke-ADCheck_$($ADFQDN.Replace('.','_'))"
                        }
                    }
                    catch {
                        Write-Error -Message "File path is invalid. Please provide a valid file path. - $($PSItem)"
                    }

                    If (($OutputTypes -contains 'All') -or ($OutputTypes -contains 'XLSX')) {
                        Write-Verbose "$($FunctionName) - Ensure ImportExcel is installed if required."

                        Import-IADExcelModule

                        Write-Verbose "$($FunctionName) - Setting up splat for ImportExcel formatting options."
                        $ExcelFormatOptions = @{
                            'AutoSize'     = $true
                            'AutoFilter'   = $true
                            'FreezeTopRow' = $true
                            'BoldTopRow'   = $true
                        }
                    }

                    Write-Verbose "$($FunctionName) - Start a Transcript log if TXT is selected as output type."
                    If (($OutputTypes -contains 'All') -or ($OutputTypes -contains 'TXT')) {
                        [void](Start-Transcript -Path $(Join-Path $OutputDirectory "$($FileName).txt"))
                    }

                    Write-Verbose "$($FunctionName) - Setup console for CLI/TXT output type."
                    If (($OutputTypes -contains 'All') -or ($OutputTypes -contains 'CLI') -or ($OutputTypes -contains 'TXT')) {
                        Enable-IADVirtualTerminal
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
    Process {
        Write-Debug "$($FunctionName) - Process."
        Try {
            If ($PSCmdlet.ShouldProcess("$($FunctionName) - Process WhatIf")) {
                Try {
                    $OutputObject = Invoke-IADCheck -Checks $Checks @Arguments

                    Write-Verbose "$($FunctionName) - Prepare variables for CLI/TXT output type.."
                    If (($OutputTypes -contains 'All') -or ($OutputTypes -contains 'CLI') -or ($OutputTypes -contains 'TXT')) {
                        $CLIArgs = @{
                            'Object'                          = $OutputObject
                            'EnableGPOChecks'                 = $EnableGPOChecks
                            'Domain'                          = $ADFQDN
                            'ADBackupThreshold'               = $ADBackupThreshold
                            'PwdLastSetThreshold'             = $PwdLastSetThreshold
                            'LastLogonDateThreshold'          = $LastLogonDateThreshold
                            'TombstoneLifetimeThreshold'      = $TombstoneLifetimeThreshold
                            'OutdatedFuncVersions'            = $OutdatedFuncVersions
                            'OutdatedWinVersions'             = $OutdatedWinVersions
                            'AbusableKerberosDelegationTypes' = $AbusableKerberosDelegationTypes
                            'SecureKerberosEncTypes'          = $SecureKerberosEncTypes
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
                    Write-Verbose "$($FunctionName) - Export the results to a XLSX if XLSX is selected as an output type."
                    If (($OutputTypes -contains "All") -or
                        ($OutputTypes -contains 'XLSX')) {

                        Write-Verbose "$($FunctionName) - Set up splat for Excel file."
                        $ExcelSetup = @{
                            'Object'             = $OutputObject
                            'Path'               = $OutputDirectory
                            'FileName'           = $FileName
                            'ExcelFormatOptions' = $ExcelFormatOptions
                        }

                        Export-IADExcel @ExcelSetup

                    }
                    Write-Verbose "$($FunctionName) - Export to JSON if JSON is selected as output type."
                    If (($OutputTypes -contains "All") -or
                        ($OutputTypes -contains 'JSON')) {
                        $OutputObject | ConvertTo-Json -Depth 10 | Out-File -FilePath $(Join-Path $OutputDirectory "$($FileName).json")
                    }
                    If (($OutputTypes -contains "All") -or
                        ($OutputTypes -contains 'cli')) {

                        Write-IADChecksToCLI @CLIArgs

                    }
                    Write-Verbose "$($FunctionName) - Stop the Transcript log incase TXT is selected as output type."
                    If (($OutputTypes -contains 'All') -or
                        ($OutputTypes -contains 'TXT')) {
                        [void](Stop-Transcript)

                        $(Get-Content $(Join-Path $OutputDirectory "$($FileName).txt")) -replace '[\x1B]|\[91m|\[0m', '' | Set-Content $(Join-Path $OutputDirectory "$($FileName).txt")

                    }
                    Write-Verbose "$($FunctionName) - Print file path with a quick Invoke-Item command."
                    If (($OutputTypes -contains "All") -or
                        ($OutputTypes -contains 'XLSX') -or
                        ($OutputTypes -contains 'JSON') -or
                        ($OutputTypes -contains 'TXT')) {

                        Write-IADColor '[', 'IAD', '] ', 'Outputted the following files' -Color Green, Magenta, Green, White
                        Get-ChildItem -Path $OutputDirectory | ForEach-Object {
                            Write-IADColor '    [', '+', '] ', "$($_.Name)" -Color Green, DarkGray, Green, White
                        }
                        Write-IADColor '[', 'IAD', '] ', "Run '", "ii $OutputDirectory", "' to open the output folder." -Color Green, Magenta, Green, White, Green, White
                    }
                    Write-Verbose "$($FunctionName) - Return the full PSObject if PSObject is selected as output type."
                    If (($OutputTypes -contains "All") -or
                        ($OutputTypes -contains 'PSObject')) {
                        Return $OutputObject
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
        Write-Debug "$($FunctionName) - End."
    }
}



## Post-Load Module code ##

# Use this variable for any path-sepecific actions (like loading dlls and such) to ensure it will work in testing and after being built
$MyModulePath = $(
    Function Get-ScriptPath {
        $Invocation = (Get-Variable MyInvocation -Scope 1).Value
        if($Invocation.PSScriptRoot) {
            $Invocation.PSScriptRoot
        }
        Elseif($Invocation.MyCommand.Path) {
            Split-Path $Invocation.MyCommand.Path
        }
        elseif ($Invocation.InvocationName.Length -eq 0) {
            (Get-Location).Path
        }
        else {
            $Invocation.InvocationName.Substring(0,$Invocation.InvocationName.LastIndexOf("\"));
        }
    }

    Get-ScriptPath
)

# Load any plugins found in the plugins directory
if (Test-Path (Join-Path $MyModulePath 'plugins')) {
    Get-ChildItem (Join-Path $MyModulePath 'plugins') -Directory | ForEach-Object {
        if (Test-Path (Join-Path $_.FullName "Load.ps1")) {
            Invoke-Command -NoNewScope -ScriptBlock ([Scriptblock]::create(".{$(Get-Content -Path (Join-Path $_.FullName "Load.ps1") -Raw)}")) -ErrorVariable errmsg 2>$null
        }
    }
}

$ExecutionContext.SessionState.Module.OnRemove = {
    # Action to take if the module is removed
    # Unload any plugins found in the plugins directory
    if (Test-Path (Join-Path $MyModulePath 'plugins')) {
        Get-ChildItem (Join-Path $MyModulePath 'plugins') -Directory | ForEach-Object {
            if (Test-Path (Join-Path $_.FullName "UnLoad.ps1")) {
                Invoke-Command -NoNewScope -ScriptBlock ([Scriptblock]::create(".{$(Get-Content -Path (Join-Path $_.FullName "UnLoad.ps1") -Raw)}")) -ErrorVariable errmsg 2>$null
            }
        }
    }
}

$null = Register-EngineEvent -SourceIdentifier ( [System.Management.Automation.PsEngineEvent]::Exiting ) -Action {
    # Action to take if the whole pssession is killed
    # Unload any plugins found in the plugins directory
    if (Test-Path (Join-Path $MyModulePath 'plugins')) {
        Get-ChildItem (Join-Path $MyModulePath 'plugins') -Directory | ForEach-Object {
            if (Test-Path (Join-Path $_.FullName "UnLoad.ps1")) {
                Invoke-Command -NoNewScope -ScriptBlock [Scriptblock]::create(".{$(Get-Content -Path (Join-Path $_.FullName "UnLoad.ps1") -Raw)}") -ErrorVariable errmsg 2>$null
            }
        }
    }
}

# Use this in your scripts to check if the function is being called from your module or independantly.
# Call it immediately to avoid PSScriptAnalyzer 'PSUseDeclaredVarsMoreThanAssignments'
$ThisModuleLoaded = $true
$ThisModuleLoaded

# Non-function exported public module members might go here.
#Export-ModuleMember -Variable SomeVariable -Function  *


