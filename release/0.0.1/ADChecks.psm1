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

## PUBLIC MODULE FUNCTIONS AND DATA ##

Function Invoke-ADCheck {
    <#
        .EXTERNALHELP ADChecks-help.xml
        .LINK
            https://github.com/ocd-nl/ADChecks/tree/master/release/0.0.1/docs/Invoke-ADCheck.md
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


