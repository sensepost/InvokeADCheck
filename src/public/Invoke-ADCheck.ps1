Function Invoke-ADCheck {
    <#
    .SYNOPSIS
        Performs various checks against the target Active Directory environment and outputs the results.

    .DESCRIPTION
        The Invoke-ADCheck function runs a series of checks on an Active Directory environment to assess its health, security, and configuration. It can perform multiple checks and output the results in various formats.

    .PARAMETER Server
        Specifies the Active Directory Domain Services instance to connect to. If not specified, the function will use the default server for the current domain.

    .PARAMETER Credential
        Specifies the user account credentials to use when performing the checks. If not provided, the current user's credentials will be used.

    .PARAMETER Checks
        Specifies which checks to perform. Valid options are: 'All', 'ADBackupStatus', 'BuiltInGroupMembership', 'DefaultAdministrator', 'DefaultDomainPasswordPolicy', 'DomainController', 'DomainTrust', 'FunctionalLevel', 'GPO', 'GPOPermission', 'GPPPassword', 'GuestAccount', 'KerberosEncryptionType', 'KerberosDelegation', 'KerberosServiceAccount', 'MachineQuota', 'ProtectedUsersGroup', 'RootACL', 'TombStone', 'UserAccountHealth'. Default is 'All'.
        Checks related to GPOs are only performed when running on a domain-joined workstation. Note that the '-Credential' parameter is not supported when running GPO checks.

    .PARAMETER OutputTypes
        Specifies the output format(s) for the results. Valid options are: 'All', 'CLI', 'XLSX', 'JSON', 'PSObject', 'TXT'. Default is 'CLI'.

    .PARAMETER OutputPath
        Specifies the path where output files will be saved. Default is the user's temp directory.

    .PARAMETER OutputFolderName
        Specifies the name of the folder where output files will be saved. Default is "Invoke-ADCheck_output_" followed by a Unix timestamp.

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
       PS C:\> Invoke-ADCheck

        This example runs all checks and outputs the results only to the console (CLI).

    .EXAMPLE
        PS C:\> Invoke-ADCheck -Checks ADBackupStatus, DomainController -OutputTypes CLI, JSON -OutputPath C:\Temp

        This example runs the ADBackupStatus and DomainController checks, outputs the results to the console and a JSON file, and saves the output in C:\Temp.

    .EXAMPLE
        PS C:\> Invoke-ADCheck -OutputTypes CLI, XLSX -OutputPath C:\Temp

        This example runs all checks and outputs the results to both the console (CLI) and an Excel file, saving the Excel file in the C:\Temp directory.

    .EXAMPLE
        PS C:\> Invoke-ADCheck -OutputTypes CLI -Server "dc.domain.tld" -Credential (Get-Credential)

        This example runs all checks, except for the GPO* checks, against the specified domain controller (dc.domain.tld) using the provided credentials, and outputs the results to the console (CLI).

    .NOTES
        AUTHOR: Niels Hofland
        AUTHOR: Justin Perdok
        COMPANY: Orange Cyberdefense
        WEBSITE: https://www.orangecyberdefense.com

    .NOTES
        This function requires the Active Directory module to be installed and may require elevated privileges in some environments.
        The Group Policy PowerShell Module may be required based on the specific checks you choose to perform.

        Failure to meet the specified requirements may lead to inconsistent or unexpected results, potentially impacting the script's functionality or reliability.
        This script is provided "as-is" with no support or guarantees.
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
