$UACEnum = @{
    "SCRIPT"                          =   1
    "ACCOUNTDISABLE"                  =   2
    "HOMEDIR_REQUIRED"                =   8
    "LOCKOUT"                         =   16
    "PASSWD_NOTREQD"                  =   32
    "PASSWD_CANT_CHANGE"              =   64
    "ENCRYPTED_TEXT_PWD_ALLOWED"      =   128
    "TEMP_DUPLICATE_ACCOUNT"          =   256
    "NORMAL_ACCOUNT"                  =   512
    "INTERDOMAIN_TRUST_ACCOUNT"       =   2048
    "WORKSTATION_TRUST_ACCOUNT"       =   4096
    "SERVER_TRUST_ACCOUNT"            =   8192
    "DONT_EXPIRE_PASSWORD"            =   65536
    "MNS_LOGON_ACCOUNT"               =   131072
    "SMARTCARD_REQUIRED"              =   262144
    "TRUSTED_FOR_DELEGATION"          =   524288
    "NOT_DELEGATED"                   =   1048576
    "USE_DES_KEY_ONLY"                =   2097152
    "DONT_REQ_PREAUTH"                =   4194304
    "PASSWORD_EXPIRED"                =   8388608
    "TRUSTED_TO_AUTH_FOR_DELEGATION"  =   16777216
    "PARTIAL_SECRETS_ACCOUNT"         =   67108864
}

function Find-DomainObject {
    #https://github.com/PowerShellMafia/PowerSploit/blob/master/Recon/PowerView.ps1
    [OutputType('System.DirectoryServices.DirectorySearcher')]
    [CmdletBinding()]
    param (
        [ValidateNotNullOrEmpty()]
        [String]
        $SearchBase,

        [ValidateNotNullOrEmpty()]
        [String]
        $LDAPFilter
    )


    if ($PSBoundParameters['SearchBase']) {
        $SearchBasePath = $SearchBase
    }
    
    $CurrentDomain = [System.DirectoryServices.ActiveDirectory.Domain]::GetCurrentDomain()
    $ConnString = "DC=$($CurrentDomain.Name.Replace('.', ',DC='))"
    $ConnString = "LDAP://" + $SearchBasePath + $ConnString

    # write-host $ConnString

    $DomainSearcher = New-Object System.DirectoryServices.DirectorySearcher([ADSI]$ConnString)

    if ($PSBoundParameters['LDAPFilter']) {
        $DomainSearcher.filter = $LDAPFilter
    }

    $DomainSearcher
}


# function Convert-LDAPProps2Hashtable {
#     #https://github.com/PowerShellMafia/PowerSploit/blob/master/Recon/PowerView.ps1
#     [CmdletBinding()]
#     Param(
#         [Parameter(Mandatory = $True, ValueFromPipeline = $True)]
#         [ValidateNotNullOrEmpty()]
#         $Properties
#     )

#     $ObjectProperties = @{}

#     #fix properties index
#     $Properties.PropertyNames | ForEach-Object {
#         # if ($Properties[$_] = "serviceprincipalname") {
            
#         # }

#         Write-Output $Properties[$_]

#         $ObjectProperties[$_] = $Properties[$_][0]
#     }


#     try {
#         New-Object -TypeName PSObject -Property $ObjectProperties
#     }
#     catch {
#         Write-Warning "LDAP properties could not be parsed: $_"
#     }
# }

function Convert-LDAPProperty {
    <#
    .SYNOPSIS
    
    Helper that converts specific LDAP property result fields and outputs
    a custom psobject.
    
    Author: Will Schroeder (@harmj0y)  
    License: BSD 3-Clause  
    Required Dependencies: None  
    
    .DESCRIPTION
    
    Converts a set of raw LDAP properties results from ADSI/LDAP searches
    into a proper PSObject. Used by several of the Get-Domain* function.
    
    .PARAMETER Properties
    
    Properties object to extract out LDAP fields for display.
    
    .OUTPUTS
    
    System.Management.Automation.PSCustomObject
    
    A custom PSObject with LDAP hashtable properties translated.
    #>
    
        [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSShouldProcess', '')]
        [OutputType('System.Management.Automation.PSCustomObject')]
        [CmdletBinding()]
        Param(
            [Parameter(Mandatory = $True, ValueFromPipeline = $True)]
            [ValidateNotNullOrEmpty()]
            $Properties
        )
    
        $ObjectProperties = @{}
    
        $Properties.PropertyNames | ForEach-Object {
            if ($_ -ne 'adspath') {
                if (($_ -eq 'objectsid') -or ($_ -eq 'sidhistory')) {
                    # convert all listed sids (i.e. if multiple are listed in sidHistory)
                    $ObjectProperties[$_] = $Properties[$_] | ForEach-Object { (New-Object System.Security.Principal.SecurityIdentifier($_, 0)).Value }
                }
                elseif ($_ -eq 'grouptype') {
                    $ObjectProperties[$_] = $Properties[$_][0] #-as $GroupTypeEnum
                }
                elseif ($_ -eq 'samaccounttype') {
                    $ObjectProperties[$_] = $Properties[$_][0] #-as $SamAccountTypeEnum
                }
                elseif ($_ -eq 'objectguid') {
                    # convert the GUID to a string
                    $ObjectProperties[$_] = (New-Object Guid (,$Properties[$_][0])).Guid
                }
                elseif ($_ -eq 'useraccountcontrol') {
                    $ObjectProperties[$_] = $Properties[$_][0] #-as $UACEnum
                }
                elseif ($_ -eq 'ntsecuritydescriptor') {
                    # $ObjectProperties[$_] = New-Object Security.AccessControl.RawSecurityDescriptor -ArgumentList $Properties[$_][0], 0
                    $Descriptor = New-Object Security.AccessControl.RawSecurityDescriptor -ArgumentList $Properties[$_][0], 0
                    if ($Descriptor.Owner) {
                        $ObjectProperties['Owner'] = $Descriptor.Owner
                    }
                    if ($Descriptor.Group) {
                        $ObjectProperties['Group'] = $Descriptor.Group
                    }
                    if ($Descriptor.DiscretionaryAcl) {
                        $ObjectProperties['DiscretionaryAcl'] = $Descriptor.DiscretionaryAcl
                    }
                    if ($Descriptor.SystemAcl) {
                        $ObjectProperties['SystemAcl'] = $Descriptor.SystemAcl
                    }
                }
                elseif ($_ -eq 'accountexpires') {
                    if ($Properties[$_][0] -gt [DateTime]::MaxValue.Ticks) {
                        $ObjectProperties[$_] = "NEVER"
                    }
                    else {
                        $ObjectProperties[$_] = [datetime]::fromfiletime($Properties[$_][0])
                    }
                }
                elseif ( ($_ -eq 'lastlogon') -or ($_ -eq 'lastlogontimestamp') -or ($_ -eq 'pwdlastset') -or ($_ -eq 'lastlogoff') -or ($_ -eq 'badPasswordTime') ) {
                    # convert timestamps
                    if ($Properties[$_][0] -is [System.MarshalByRefObject]) {
                        # if we have a System.__ComObject
                        $Temp = $Properties[$_][0]
                        [Int32]$High = $Temp.GetType().InvokeMember('HighPart', [System.Reflection.BindingFlags]::GetProperty, $Null, $Temp, $Null)
                        [Int32]$Low  = $Temp.GetType().InvokeMember('LowPart',  [System.Reflection.BindingFlags]::GetProperty, $Null, $Temp, $Null)
                        $ObjectProperties[$_] = ([datetime]::FromFileTime([Int64]("0x{0:x8}{1:x8}" -f $High, $Low)))
                    }
                    else {
                        # otherwise just a string
                        $ObjectProperties[$_] = ([datetime]::FromFileTime(($Properties[$_][0])))
                    }
                }
                elseif ($Properties[$_][0] -is [System.MarshalByRefObject]) {
                    # try to convert misc com objects
                    $Prop = $Properties[$_]
                    try {
                        $Temp = $Prop[$_][0]
                        [Int32]$High = $Temp.GetType().InvokeMember('HighPart', [System.Reflection.BindingFlags]::GetProperty, $Null, $Temp, $Null)
                        [Int32]$Low  = $Temp.GetType().InvokeMember('LowPart',  [System.Reflection.BindingFlags]::GetProperty, $Null, $Temp, $Null)
                        $ObjectProperties[$_] = [Int64]("0x{0:x8}{1:x8}" -f $High, $Low)
                    }
                    catch {
                        Write-Verbose "[Convert-LDAPProperty] error: $_"
                        $ObjectProperties[$_] = $Prop[$_]
                    }
                }
                elseif ($Properties[$_].count -eq 1) {
                    $ObjectProperties[$_] = $Properties[$_][0]
                }
                else {
                    $ObjectProperties[$_] = $Properties[$_]
                }
            }
        }
        try {
            New-Object -TypeName PSObject -Property $ObjectProperties
        }
        catch {
            Write-Warning "[Convert-LDAPProperty] Error parsing LDAP properties : $_"
        }
    }

function Find-DomainUserObject {
    #https://github.com/PowerShellMafia/PowerSploit/blob/master/Recon/PowerView.ps1
    [CmdletBinding()]
    param (
        [ValidateNotNullOrEmpty()]
        [String]
        $samAccountName
    )


    $FilterArgs = @{}
        if ($PSBoundParameters['samAccountName']) {
        $FilterArgs.LDAPFilter = "(samAccountName=$($samAccountName))"
    }
    
    $DomainUserFinder = Find-DomainObject @FilterArgs

    $Results = $DomainUserFinder.FindAll()

    $Results  | foreach-object {
        # Edit
        Convert-LDAPProperty $_.properties
    }
}

function Find-DomainComputerObject {
    #https://github.com/PowerShellMafia/PowerSploit/blob/master/Recon/PowerView.ps1
    [CmdletBinding()]
    param (
        [ValidateNotNullOrEmpty()]
        [String]
        $samAccountName,
        [ValidateNotNullOrEmpty()]
        [String]
        $LDAPFilter
    )

    $FilterArgs = @{}

    $FilterArgs.LDAPFilter = "(&(objectCategory=computer))"

    if ($PSBoundParameters['samAccountName']) {
        $FilterArgs.LDAPFilter = "(samAccountName=$($samAccountName))"
    }
   
    if ($PSBoundParameters['LDAPFilter']) {
        $FilterArgs.LDAPFilter = "$($LDAPFilter)"
    }
        
    $DomainComputerFinder = Find-DomainObject @FilterArgs

    $Results = $DomainComputerFinder.FindAll()

    $Results  | foreach-object {
        # Edit (Fix multiple SPNs)
        Convert-LDAPProperty $_.properties
    }
}

function Get-DomainControllerOS {
    $DCList = Find-DomainComputerObject -LDAPFilter `
        "(userAccountControl:1.2.840.113556.1.4.803:=8192)"

    $Results = @{}

    foreach ($DC in $DCList) {
        $Results.Add($DC.Name, $DCList.OperatingSystem)
    }   

    $outputObj = $Results.GetEnumerator() |
    ForEach-Object {
        [PSCustomObject]@{
            "Domain Controller" = $_.Key
            "Operating System" = $_.Value
            }
        }

    $outputObj
}


function Get-KRBTGTAccount {
    $Krbtgt = Find-DomainUserObject -samAccountName "krbtgt"

    $outputObj = [PSCustomObject]@{
        'samAccountName' = $Krbtgt.samaccountname
        'distinguishedName' = $Krbtgt.distinguishedname
        'passwordLastSet' = $Krbtgt.pwdlastset #[DateTime]::FromFileTime([string]$Krbtgt.pwdlastset)
        'msds-keyversionnumber' = $Krbtgt.'msds-keyversionnumber'
        'whenCreated' = $Krbtgt.whencreated
    }

    $outputObj
}

function Get-TombstoneLife {
    $SearchRootObj = Find-DomainObject -SearchBase `
        "CN=Directory Service,CN=Windows NT,CN=Services,CN=Configuration,"

    $TombstoneLifetime = $SearchRootObj.SearchRoot.tombstoneLifetime

    $outputObj = [PSCustomObject]@{
        'TombstoneLifetime' = $TombstoneLifetime[0]
    }

    $outputObj
}

function Get-ADBackup {
    $context = New-Object System.DirectoryServices.ActiveDirectory.DirectoryContext("Domain",$env:USERDNSDOMAIN)
    $domainController = [System.DirectoryServices.ActiveDirectory.DomainController]::findOne($context)

    $Results = @{}

    ForEach($partition in $domainController.Partitions) {
        $DomainControllerMetadata = $domainController.GetReplicationMetadata($partition)
        $DsaSignature = $domainControllerMetadata.Item("dsaSignature")
        $BackupDate = $dsaSignature.LastOriginatingChangeTime.DateTime

        $Results.Add($partition, $BackupDate)
    }

    $outputObj = $Results.GetEnumerator() |
    ForEach-Object {
        [PSCustomObject]@{
            "Partition" = $_.Key
            "Last Backup Date" = $_.Value
            }
        }

    $outputObj
}

function Get-FunctionalLevel {
    BEGIN {
        $Levels = @("WIN2000", "WIN2003_WITH_MIXED_DOMAINS",
        "WIN2003", "WIN2008", "WIN2008R2", "WIN2012",
        "WIN2012R2", "WIN2016"
        )
    }

    PROCESS {
        $Forest = [System.DirectoryServices.ActiveDirectory.Forest]::GetCurrentForest()
        $Domain = [System.DirectoryServices.ActiveDirectory.Domain]::GetCurrentDomain()

        $outputObj = [PSCustomObject]@{
            'Forest Functional Level' = $Levels[$Forest.ForestModeLevel]
            'Domain Functional Level' = $Levels[$Domain.DomainModeLevel]
        }

        $outputObj
    }
}

function Get-GPPPassword {
    $Items = Get-ChildItem \\$env:USERDNSDOMAIN\SYSVOL\$env:USERDNSDOMAIN -Recurse
    $Path = ($Items | Select-String "cpassword").Path

    $Path
}


# function Get-DomainTrust {
#     try {
#         $DomainContext = New-Object System.DirectoryServices.ActiveDirectory.DirectoryContext('Domain', $env:USERDNSDOMAIN)
#         $DomainObject = [System.DirectoryServices.ActiveDirectory.Domain]::GetDomain($DomainContext)
#         if ($DomainObject) {
#             $DomainObject.GetAllTrustRelationships() | Select-Object -ExpandProperty TargetName
#         }
#     }
#     catch {
#         Write-Verbose "'$Domain' could not be contacted : $_"
#     }
# }

function Find-DuplicateSPNs {
    # https://www.powershellbros.com/find-duplicated-spns-active-directory/
    $SPNArray = @()

    $AllSPNsObjects = (Find-DomainObject -LDAPFilter "(objectClass=user)").FindAll()

    $AllSPNsObjects = $AllSPNsObjects | ForEach-Object {
        Convert-LDAPProperty $_.properties | Select-Object SamAccountName, ServicePrincipalName
    }

    foreach ($SPNObject in $AllSPNsObjects)
    {
       $SamAccountName = $SPNObject.SamAccountName
       $SPNs = $SPNObject.ServicePrincipalName
      
       foreach ($SPN in $SPNs)
       {
            if ($SPNArray.ServicePrincipalName -like "$SPN")
            {
                $MatchedSPNs = $SPNArray.ServicePrincipalName -like "$SPN"
                foreach ($MatchSPN in $MatchedSPNs)
                {
                    $MatchSamAccountName = $MatchSPN.SamAccountName
                    if ($MatchSamAccountName -ne $SamAccountName)
                    {
                       Write-Warning "Duplicated SPN has been found for $SPN!!!"
                    }
                }
            }
            else
            {
                $Properties =  @{
                    "SamAccountName" = $SamAccountName
                    "ServicePrincipalName" = $SPN
                }
           
                 $SPNArrayRow = New-Object PSObject -Property $Properties
                 $SPNArray += $SPNArrayRow
            }
       }
    }
}


function Get-DefaultAdministratorAccount {
    $Administrator = Find-DomainUserObject -samAccountName "Administrator"

    $outputObj = [PSCustomObject]@{
        'Name' = $Administrator.samaccountname
        'Enabled' = ($Administrator.useraccountcontrol -band $UACEnum['ACCOUNTDISABLE']) -ne 2
        'Created' = $Administrator.whencreated
        'PasswordLastSet' = $Administrator.pwdlastset
        'LastLogonDate' = $Administrator.lastlogon
        'ServicePrincipalNames' = $Administrator.servicePrincipalName
    }

    $outputObj
}

function Get-MachineAccountQuota {
    $Result = (Find-DomainObject).FindAll()[0].Properties | 
        Convert-LDAPProperty
    
    $outputObj = [PSCustomObject]@{
        'ms-DS-MachineAccountQuota' = $Result."ms-ds-machineaccountquota"
    }

    $outputObj
}


function Get-KerberosDelegation {
    # Filter users and computers
    $Results = (Find-DomainObject -LDAPFilter "(&(objectClass=computer)(objectClass=person)").FindAll()
    $Results = $Results  | foreach-object {
        Convert-LDAPProperty $_.properties
    }

    foreach ($object in $Results) {
        # if (($object.primarygroupid -ne 515) -or ($object.primarygroupid -ne 521) ) {
            if ($object.UserAccountControl -BAND 0x0080000)
                { $KerberosDelegationServices = 'All Services' ; $KerberosType = 'Unconstrained' }
            else 
                { $KerberosDelegationServices = 'Specific Services' ; $KerberosType = 'Constrained' } 
            if ($object.UserAccountControl -BAND 0x1000000)
                { $KerberosDelegationAllowedProtocols = 'Any (Protocol Transition)' ; $KerberosType = 'Constrained with Protocol Transition' }
            else
                { $KerberosDelegationAllowedProtocols = 'Kerberos' }
            if ($object.'msDS-AllowedToActOnBehalfOfOtherIdentity')
                { $KerberosType = 'Resource-Based Constrained Delegation'  } 

            $object | Add-Member -MemberType NoteProperty -Name Domain -Value $Domain -Force
            $object | Add-Member -MemberType NoteProperty -Name KerberosDelegationServices -Value $KerberosDelegationServices -Force
            $object | Add-Member -MemberType NoteProperty -Name DelegationType -Value $KerberosType -Force
            $object | Add-Member -MemberType NoteProperty -Name KerberosDelegationAllowedProtocols -Value $KerberosDelegationAllowedProtocols -Force
            
            [array]$KerberosDelegationArray += $object
        # }     
    }

    $KerberosDelegationArray
}


Function Get-KerberosEncryptionTypes {
    # https://raw.githubusercontent.com/jeremyts/ActiveDirectoryDomainServices/master/Audit/Get-UserSupportedEncryptionTypes.ps1
    param (
        [int]$key
    )
    switch ($key) {
        "1" { $SupportedEncryptionTypes = @("DES_CRC") }
        "2" { $SupportedEncryptionTypes = @("DES_MD5") }
        "3" { $SupportedEncryptionTypes = @("DES_CRC", "DES_MD5") }
        "4" { $SupportedEncryptionTypes = @("RC4") }
        "8" { $SupportedEncryptionTypes = @("AES128") }
        "16" { $SupportedEncryptionTypes = @("AES256") }
        "24" { $SupportedEncryptionTypes = @("AES128", "AES256") }
        "28" { $SupportedEncryptionTypes = @("RC4", "AES128", "AES256") }
        "31" { $SupportedEncryptionTypes = @("DES_CRC", "DES_MD5", "RC4", "AES128", "AES256") }
        default { $SupportedEncryptionTypes = @("Undefined value of $key") }
    }
    $SupportedEncryptionTypes            
}

Function Get-KerberosEncryption {
    # https://raw.githubusercontent.com/jeremyts/ActiveDirectoryDomainServices/master/Audit/Get-UserSupportedEncryptionTypes.ps1

    $Results = (Find-DomainObject -LDAPFilter `
        "(&(msDS-SupportedEncryptionTypes=*)(!msDS-SupportedEncryptionTypes=0))").FindAll()   
    $Results = $Results  | foreach-object {
        Convert-LDAPProperty $_.properties
    }

    $Results | Select-Object Name, @{N = "EncryptionTypes"; 
        E = { Get-KerberosEncryptionTypes $($_."msDS-SupportedEncryptionTypes") } }

    ForEach ($User in $Results) {
        ForEach ($EncryptionType in $User.EncryptionTypes) {
            $EncryptionType
        }
    }
}




Get-KRBTGTAccount
Get-TombstoneLife | Format-Table
Get-ADBackup  | Format-Table
Get-FunctionalLevel  | Format-Table
Get-MachineAccountQuota
# Get-DomainTrust
Get-DomainControllerOS  | Format-Table
# Get-GPPPassword
Find-DuplicateSPNs
Get-DefaultAdministratorAccount
Get-KerberosDelegation | Sort-Object DelegationType | Select-Object DistinguishedName,DelegationType,Name,ServicePrincipalName | Format-list
Get-KerberosEncryption