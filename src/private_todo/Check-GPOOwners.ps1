$Domain = (Get-ADDomain).DNSRoot
[Array]$DomainGPOs = Get-GPO -All -Domain $Domain
$DomainGPOs | Select-Object DisplayName, Owner | Format-Table -AutoSize