$UserLogonAge = 180
$UserPasswordAge = 180
$Domain = (Get-ADDomain).DNSRoot
$ADDomainInfo = Get-ADDomain $Domain
$DomainDC = $ADDomainInfo.PDCEmulator
$LastLoggedOnDate = $(Get-Date) - $(New-TimeSpan -days $UserLogonAge)
$PasswordStaleDate = $(Get-Date) - $(New-TimeSpan -days $UserPasswordAge)
$ADLimitedProperties = @("Name", "Enabled", "SAMAccountname", "DisplayName", "Enabled", "LastLogonDate", "PasswordLastSet", "PasswordNeverExpires", "PasswordNotRequired", "PasswordExpired", "SmartcardLogonRequired", "AccountExpirationDate", "AdminCount", "Created", "Modified", "LastBadPasswordAttempt", "badpwdcount", "mail", "CanonicalName", "DistinguishedName", "ServicePrincipalName", "SIDHistory", "PrimaryGroupID", "UserAccountControl", "DoesNotRequirePreAuth")

[array]$DomainUsers = Get-ADUser -Filter * -Property $ADLimitedProperties -Server $DomainDC
[array]$DomainEnabledUsers = $DomainUsers | Where-Object{ $_.Enabled -eq $True }
[array]$DomainEnabledInactiveUsers = $DomainEnabledUsers | Where-Object{ ($_.LastLogonDate -le $LastLoggedOnDate) -AND ($_.PasswordLastSet -le $PasswordStaleDate) }

[array]$DomainUsersWithReversibleEncryptionPasswordArray = $DomainEnabledUsers | Where-Object{ $_.UserAccountControl -band 0x0080 }
[array]$DomainUserPasswordNotRequiredArray = $DomainEnabledUsers | Where-Object{ $_.PasswordNotRequired -eq $True }
[array]$DomainUserPasswordNeverExpiresArray = $DomainEnabledUsers | Where-Object{ $_.PasswordNeverExpires -eq $True }
[array]$DomainKerberosDESUsersArray = $DomainEnabledUsers | Where-Object{ $_.UserAccountControl -band 0x200000 }
[array]$DomainUserDoesNotRequirePreAuthArray = $DomainEnabledUsers | Where-Object{ $_.DoesNotRequirePreAuth -eq $True }
[array]$DomainUsersWithSIDHistoryArray = $DomainEnabledUsers | Where-Object{ $_.SIDHistory -like "*" }

$DomainUserReport =
@"
$Domain Domain User Report:

Total Users: $($DomainUsers.Count)
Enabled Users: $($DomainEnabledUsers.Count)

Enabled Users Identified as Inactive: $($DomainEnabledInactiveUsers.Count)
Enabled Users With Reversible Encryption Password: $($DomainUsersWithReversibleEncryptionPasswordArray.Count)
Enabled Users With Password Not Required: $($DomainUserPasswordNotRequiredArray.Count)
Enabled Users With Password Never Expires: $($DomainUserPasswordNeverExpiresArray.Count)
Enabled Users With Kerberos DES: $($DomainKerberosDESUsersArray.Count)
Enabled Users With SID History: $($DomainUsersWithSIDHistoryArray.Count)

"@
$DomainUserReport