## Pre-Loaded Module code ##

<#
 Put all code that must be run prior to function dot sourcing here.

 This is a good place for module variables as well. The only rule is that no 
 variable should rely upon any of the functions in your module as they 
 will not have been loaded yet. Also, this file cannot be completely
 empty. Even leaving this comment is good enough.
#>

## PRIVATE MODULE FUNCTIONS AND DATA ##

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

    [CmdletBinding(SupportsShouldProcess = $True)]
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
                    $DomainDC = $ADDomainInfo.PDCEmulator
                    $ADDomainName = $ADDomainInfo.DNSRoot
                    [string[]]$Partitions = (Get-ADRootDSE -Server $DomainDC).namingContexts
                    $contextType = [System.DirectoryServices.ActiveDirectory.DirectoryContextType]::Domain
                    $context = new-object System.DirectoryServices.ActiveDirectory.DirectoryContext($contextType, $ADDomainName)
                    $domainController = [System.DirectoryServices.ActiveDirectory.DomainController]::findOne($context)
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
                    ForEach ($partition in $partitions) {
                        $domainControllerMetadata = $domainController.GetReplicationMetadata($partition)
                        $dsaSignature = $domainControllerMetadata.Item("dsaSignature")
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


function Get-DefaultAdministrator {
    <#
    .SYNOPSIS
        This function enumerates the default Administrator account for the current (or specified) domain and returns all relevant account information.
    .DESCRIPTION
        This function enumerates the default Administrator account for the current (or specified) domain and returns all relevant account information.
    .PARAMETER Server
        Specifies an AD domain controller to bind to.
    .PARAMETER Credential
        A [Management.Automation.PSCredential] object of alternate credentials
        for connection to the remote system.
    .EXAMPLE
        PS C:\ > Get-DefaultAdministrator

        Name                 : Administrator
        Enabled              : True
        Created              : 30/01/2023 10:55:56
        PasswordLastSet      : 30/01/2023 10:49:30
        LastLogonDate        : 30/01/2023 11:02:51
        ServicePrincipalName : {MSSQLSvc/myhost-2.offsec.local:1432, MSSQLSvc/myhost.offsec.local:1433}
    .EXAMPLE
        PS C:\ > $SecurePassword = ConvertTo-SecureString 'Welcome01!' -AsPlainText -Force
        PS C:\ > $Credential = New-Object System.Management.Automation.PSCredential('OFFSEC\test', $SecurePassword)
        PS C:\ > Get-DefaultAdministrator -Credential $Credential

        Name                 : Administrator
        Enabled              : True
        Created              : 30/01/2023 10:55:56
        PasswordLastSet      : 30/01/2023 10:49:30
        LastLogonDate        : 30/01/2023 11:02:51
        ServicePrincipalName : {MSSQLSvc/myhost-2.offsec.local:1432, MSSQLSvc/myhost.offsec.local:1433}
    #>

    [CmdletBinding(SupportsShouldProcess = $True)]
    param (
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
                $Arguments = @{}

                if ($PSBoundParameters['Server']) { $Arguments['Server'] = $Server }
                if ($PSBoundParameters['Credential']) { $Arguments['Credential'] = $Credential }
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
                    $Administrator = Get-ADUser "$((get-addomain).DomainSID.Value)-500" -Properties 'Name', 'Enabled', 'Created', 'PasswordLastSet', 'LastLogonDate', 'ServicePrincipalName' @Arguments

                    $OutputObject = [PSCustomObject]@{
                        'Name'                 = $Administrator.Name
                        'Enabled'              = $Administrator.Enabled
                        'Created'              = $Administrator.Created
                        'PasswordLastSet'      = $Administrator.PasswordLastSet
                        'LastLogonDate'        = $Administrator.LastLogonDate
                        'ServicePrincipalName' = $Administrator.ServicePrincipalName
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


function Get-FunctionalLevel {
    <#
    .SYNOPSIS
        This function enumerates the Forest and Domain Functional Levels.
    .DESCRIPTION
        This function enumerates the Forest and Domain Functional Levels.
    .PARAMETER Server
        Specifies an AD domain controller to bind to.
    .PARAMETER Credential
        A [Management.Automation.PSCredential] object of alternate credentials for connection to the remote system.
    .EXAMPLE
        PS C:\ > Get-FunctionalLevel

        Forest Functional Level Domain Functional Level
        ----------------------- -----------------------
            Windows2012Forest       Windows2012Domain
    .EXAMPLE
        PS C:\ > $SecurePassword = ConvertTo-SecureString 'Welcome01!' -AsPlainText -Force
        PS C:\ > $Credential = New-Object System.Management.Automation.PSCredential('OFFSEC\test', $SecurePassword)
        PS C:\ > Get-FunctionalLevel

        Forest Functional Level Domain Functional Level
        ----------------------- -----------------------
            Windows2012Forest       Windows2012Domain
    #>

    [CmdletBinding(SupportsShouldProcess = $True)]
    param (
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
                $Arguments = @{}

                if ($PSBoundParameters['Server']) { $Arguments['Server'] = $Server }
                if ($PSBoundParameters['Credential']) { $Arguments['Credential'] = $Credential }
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
                    $ADForestFunctionalLevel = (Get-ADForest @Arguments).ForestMode
                    $ADDomainFunctionalLevel = (Get-ADDomain @Arguments).DomainMode

                    $OutputObject = [PSCustomObject]@{
                        'Forest Functional Level' = $ADForestFunctionalLevel
                        'Domain Functional Level' = $ADDomainFunctionalLevel
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
       Get-CallerPreference function sets variables in its callers' scope, even if that caller is in a different
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
    param (
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
        if ($null -ne $Name) {
            foreach ($string in $Name) {
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

        foreach ($entry in $vars.GetEnumerator()) {
            if (([string]::IsNullOrEmpty($entry.Value) -or -not $Cmdlet.MyInvocation.BoundParameters.ContainsKey($entry.Value)) -and
                ($PSCmdlet.ParameterSetName -eq 'AllVariables' -or $filterHash.ContainsKey($entry.Name))) {

                $variable = $Cmdlet.SessionState.PSVariable.Get($entry.Key)

                if ($null -ne $variable) {
                    if ($SessionState -eq $ExecutionContext.SessionState) {
                        Set-Variable -Scope 1 -Name $variable.Name -Value $variable.Value -Force -Confirm:$false -WhatIf:$false
                    }
                    else {
                        $SessionState.PSVariable.Set($variable.Name, $variable.Value)
                    }
                }
            }
        }

        if ($PSCmdlet.ParameterSetName -eq 'Filtered') {
            foreach ($varName in $filterHash.Keys) {
                if (-not $vars.ContainsKey($varName)) {
                    $variable = $Cmdlet.SessionState.PSVariable.Get($varName)

                    if ($null -ne $variable) {
                        if ($SessionState -eq $ExecutionContext.SessionState) {
                            Set-Variable -Scope 1 -Name $variable.Name -Value $variable.Value -Force -Confirm:$false -WhatIf:$false
                        }
                        else {
                            $SessionState.PSVariable.Set($variable.Name, $variable.Value)
                        }
                    }
                }
            }
        }
    }
}


function Get-KerberosServiceAccount {
    <#
    .SYNOPSIS
        This function enumerates the KRBTGT account for the current (or specified) domain and returns all relevant account information.
    .DESCRIPTION
        This function enumerates the KRBTGT account for the current (or specified) domain and returns all relevant account information.
    .PARAMETER Server
        Specifies an AD domain controller to bind to.
    .PARAMETER Credential
        A [Management.Automation.PSCredential] object of alternate credentials for connection to the remote system.
    .EXAMPLE
        PS C:\ > Get-KerberosServiceAccount

        Name                  : krbtgt
        DistinguishedName     : CN=krbtgt,CN=Users,DC=offsec,DC=local
        Created               : 30/01/2023 10:56:34
        PasswordLastSet       : 30/01/2023 10:56:34
        msds-keyversionnumber : 2

    .EXAMPLE
        PS C:\ > $SecurePassword = ConvertTo-SecureString 'Welcome01!' -AsPlainText -Force
        PS C:\ > $Credential = New-Object System.Management.Automation.PSCredential('OFFSEC\test', $SecurePassword)
        PS C:\ > Get-KerberosServiceAccount -Credential $Credential

        Name                  : krbtgt
        DistinguishedName     : CN=krbtgt,CN=Users,DC=offsec,DC=local
        Created               : 30/01/2023 10:56:34
        PasswordLastSet       : 30/01/2023 10:56:34
        msds-keyversionnumber : 2
    #>

   [CmdletBinding(SupportsShouldProcess=$True)]
   param (
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

                if ($PSBoundParameters['Server']) { $Arguments['Server'] = $Server }
                if ($PSBoundParameters['Credential']) { $Arguments['Credential'] = $Credential }
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

                    $OutputObject = [PSCustomObject]@{
                        'Name' = $KRBTGT.Name
                        'DistinguishedName' = $KRBTGT.DistinguishedName
                        'Created' = $KRBTGT.Created
                        'PasswordLastSet' = $KRBTGT.PasswordLastSet
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

## PUBLIC MODULE FUNCTIONS AND DATA ##

Function Invoke-ADCheck {
    <#
        .EXTERNALHELP InvokeADCheck-help.xml
        .LINK
            https://github.com/ocd-nl/InvokeADCheck/tree/master/release/0.0.1/docs/Invoke-ADCheck.md
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


