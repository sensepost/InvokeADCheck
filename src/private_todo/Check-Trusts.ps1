$Domain = (Get-ADDomain).DNSRoot
$ADDomainInfo = Get-ADDomain $Domain
$DomainDC = $ADDomainInfo.PDCEmulator
$ADTrusts = Get-ADTrust -Filter * -Server $DomainDC
Write-Host "$Domain Active Directory Trusts:"
$ADTrusts | Select-Object Source, Target, Direction, IntraForest, SelectiveAuth, SIDFilteringForestAware, SIDFilteringQuarantined | Format-Table -AutoSize