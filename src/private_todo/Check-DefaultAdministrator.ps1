$Domain = (Get-ADDomain).DNSRoot
$ADDomainInfo = Get-ADDomain $Domain
$DomainDC = $ADDomainInfo.PDCEmulator
$DomainAdminAccountSID = "$($ADDomainInfo.DomainSID)-500"
$DomainDefaultAdminAccount = Get-ADUser $DomainAdminAccountSID -Server $DomainDC -Properties Name,Enabled,Created,PasswordLastSet,LastLogonDate,ServicePrincipalName,SID
Write-Output "$Domain Default Domain Administrator Account:"
$DomainDefaultAdminAccount | Select Name,Enabled,Created,PasswordLastSet,LastLogonDate,ServicePrincipalName | Format-Table -AutoSize