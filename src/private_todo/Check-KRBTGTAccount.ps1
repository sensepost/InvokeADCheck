$Domain = (Get-ADDomain).DNSRoot
$ADDomainInfo = Get-ADDomain $Domain
$DomainKRBTGTAccount = Get-ADUser 'krbtgt' -Server $DomainDC -Properties 'msds-keyversionnumber',Created,PasswordLastSet

Write-Output "$Domain Domain Kerberos Service Account (KRBTGT): `n"
$DomainKRBTGTAccount | Select-Object DistinguishedName,Created,PasswordLastSet,'msds-keyversionnumber' | Format-List