$Domain = (Get-ADDomain).DNSRoot
[Array]$DomainGPOs = Get-GPO -All -Domain $Domain
$DomainGPOs | Select DisplayName,Owner | Format-Table -AutoSize