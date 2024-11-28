---
external help file: InvokeADCheck-help.xml
Module Name: InvokeADCheck
online version:
schema: 2.0.0
---

# InvokeADCheck

## SYNOPSIS
Performs various checks on an Active Directory environment and outputs the results.

## SYNTAX

```
InvokeADCheck [[-Server] <String>] [[-Credential] <PSCredential>] [[-Checks] <String[]>]
 [[-OutputTypes] <String[]>] [[-OutputPath] <String>] [[-OutputFolderName] <String>]
 [[-ADBackupThreshold] <Object>] [[-PwdLastSetThreshold] <Object>] [[-LastLogonDateThreshold] <Object>]
 [[-OutdatedWinVersions] <Object>] [[-OutdatedFuncVersions] <Object>]
 [[-AbusableKerberosDelegationTypes] <Object>] [[-SecureKerberosEncTypes] <Object>]
 [[-TombstoneLifetimeThreshold] <Object>] [-WhatIf] [-Confirm] [<CommonParameters>]
```

## DESCRIPTION
The InvokeADCheck function runs a series of checks on an Active Directory environment to assess its health, security, and configuration.
It can perform multiple checks and output the results in various formats.

## EXAMPLES

### EXAMPLE 1
```
InvokeADCheck
```

This example runs all checks and outputs the results only to the console (CLI).

### EXAMPLE 2
```
InvokeADCheck -Checks ADBackupStatus, DomainController -OutputTypes CLI, JSON -OutputPath C:\Temp
```

This example runs the ADBackupStatus and DomainController checks, outputs the results to the console and a JSON file, and saves the output in C:\Temp.

### EXAMPLE 3
```
InvokeADCheck -OutputTypes CLI, XLSX -OutputPath C:\Temp
```

This example runs all checks and outputs the results to both the console (CLI) and an Excel file, saving the Excel file in the C:\Temp directory.

### EXAMPLE 4
```
InvokeADCheck -OutputTypes CLI -Server "dc.domain.tld" -Credential (Get-Credential)
```

This example runs all checks, except for the GPO* checks, against the specified domain controller (dc.domain.tld) using the provided credentials, and outputs the results to the console (CLI).

## PARAMETERS

### -Server
Specifies the Active Directory Domain Services instance to connect to.
If not specified, the function will use the default server for the current domain.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 1
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Credential
Specifies the user account credentials to use when performing the checks.
If not provided, the current user's credentials will be used.

```yaml
Type: PSCredential
Parameter Sets: (All)
Aliases:

Required: False
Position: 2
Default value: [Management.Automation.PSCredential]::Empty
Accept pipeline input: False
Accept wildcard characters: False
```

### -Checks
Specifies which checks to perform.
Valid options are: 'All', 'ADBackupStatus', 'BuiltInGroupMembership', 'DefaultAdministrator', 'DefaultDomainPasswordPolicy', 'DomainController', 'DomainTrust', 'FunctionalLevel', 'GPO', 'GPOPermission', 'GPPPassword', 'GuestAccount', 'KerberosEncryptionType', 'KerberosDelegation', 'KerberosServiceAccount', 'MachineQuota', 'ProtectedUsersGroup', 'RootACL', 'TombStone', 'UserAccountHealth'.
Default is 'All'.
Checks related to GPOs are only performed when running on a domain-joined workstation.
Note that the '-Credential' parameter is not supported when running GPO checks.

```yaml
Type: String[]
Parameter Sets: (All)
Aliases:

Required: False
Position: 3
Default value: All
Accept pipeline input: False
Accept wildcard characters: False
```

### -OutputTypes
Specifies the output format(s) for the results.
Valid options are: 'All', 'CLI', 'XLSX', 'JSON', 'PSObject', 'TXT'.
Default is 'CLI'.

```yaml
Type: String[]
Parameter Sets: (All)
Aliases:

Required: False
Position: 4
Default value: CLI
Accept pipeline input: False
Accept wildcard characters: False
```

### -OutputPath
Specifies the path where output files will be saved.
Default is the user's temp directory.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 5
Default value: $ENV:TEMP
Accept pipeline input: False
Accept wildcard characters: False
```

### -OutputFolderName
Specifies the name of the folder where output files will be saved.
Default is "InvokeADCheck_output_" followed by a Unix timestamp.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 6
Default value: "InvokeADCheck_output_$([DateTimeOffset]::Now.ToUnixTimeSeconds())"
Accept pipeline input: False
Accept wildcard characters: False
```

### -ADBackupThreshold
Specifies the threshold date for considering AD backups as outdated.
Default is 90 days ago.

```yaml
Type: Object
Parameter Sets: (All)
Aliases:

Required: False
Position: 7
Default value: $((Get-Date) - (New-TimeSpan -Days 90))
Accept pipeline input: False
Accept wildcard characters: False
```

### -PwdLastSetThreshold
Specifies the threshold date for considering passwords as outdated.
Default is 365 days ago.

```yaml
Type: Object
Parameter Sets: (All)
Aliases:

Required: False
Position: 8
Default value: $((Get-Date) - (New-TimeSpan -Days 365)).Date
Accept pipeline input: False
Accept wildcard characters: False
```

### -LastLogonDateThreshold
Specifies the threshold date for considering user accounts as inactive.
Default is 365 days ago.

```yaml
Type: Object
Parameter Sets: (All)
Aliases:

Required: False
Position: 9
Default value: $((Get-Date) - (New-TimeSpan -Days 365)).Date
Accept pipeline input: False
Accept wildcard characters: False
```

### -OutdatedWinVersions
Specifies which Windows versions are considered outdated.
Default is @("2000", "2003", "2008", "2012", "2016").

```yaml
Type: Object
Parameter Sets: (All)
Aliases:

Required: False
Position: 10
Default value: @("2000", "2003", "2008", "2012", "2016")
Accept pipeline input: False
Accept wildcard characters: False
```

### -OutdatedFuncVersions
Specifies which functional levels are considered outdated.
Default is @("2000", "2003", "2008", "2012").

```yaml
Type: Object
Parameter Sets: (All)
Aliases:

Required: False
Position: 11
Default value: @("2000", "2003", "2008", "2012")
Accept pipeline input: False
Accept wildcard characters: False
```

### -AbusableKerberosDelegationTypes
Specifies which Kerberos delegation types are considered abusable.
Default is @('Resource-Based Constrained Delegation', 'Unconstrained').

```yaml
Type: Object
Parameter Sets: (All)
Aliases:

Required: False
Position: 12
Default value: @('Resource-Based Constrained Delegation', 'Unconstrained')
Accept pipeline input: False
Accept wildcard characters: False
```

### -SecureKerberosEncTypes
Specifies which Kerberos encryption types are considered secure.
Default is @('8', '16', '24').

```yaml
Type: Object
Parameter Sets: (All)
Aliases:

Required: False
Position: 13
Default value: @('8', '16', '24')
Accept pipeline input: False
Accept wildcard characters: False
```

### -TombstoneLifetimeThreshold
Specifies the threshold (in days) for considering the tombstone lifetime as too short.
Default is 180 days.

```yaml
Type: Object
Parameter Sets: (All)
Aliases:

Required: False
Position: 14
Default value: 180
Accept pipeline input: False
Accept wildcard characters: False
```

### -WhatIf
Shows what would happen if the cmdlet runs.
The cmdlet is not run.

```yaml
Type: SwitchParameter
Parameter Sets: (All)
Aliases: wi

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Confirm
Prompts you for confirmation before running the cmdlet.

```yaml
Type: SwitchParameter
Parameter Sets: (All)
Aliases: cf

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

## OUTPUTS

## NOTES
This function requires the Active Directory module to be installed and may require elevated privileges in some environments.
The Group Policy PowerShell Module may be required based on the specific checks you choose to perform.

Failure to meet the specified requirements may lead to inconsistent or unexpected results, potentially impacting the script's functionality or reliability.
This script is provided "as-is" with no support or guarantees.

## RELATED LINKS
