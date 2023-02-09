$Domain = (Get-ADDomain).DNSRoot
$ADDomainInfo = Get-ADDomain $Domain
$DomainDC = $ADDomainInfo.PDCEmulator
$ProtectedUsersGroupMembership = Get-ADGroupMember 'Protected Users'  -Server $DomainDC
Write-Output "Domain Protected Users Group Membership:"
$ProtectedUsersGroupMembership | Select-Object Name, DistinguishedName, objectClass | Format-Table
Write-Output ""
Write-Output "Domain Protected Users Group has $($ProtectedUsersGroupMembership.count) members"