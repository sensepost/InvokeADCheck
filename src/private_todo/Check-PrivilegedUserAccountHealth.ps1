$Domain = (Get-ADDomain).DNSRoot
$ADDomainInfo = Get-ADDomain $Domain
$DomainDC = $ADDomainInfo.PDCEmulator
$ADAdminArray = @()
$ADAdminMembers = Get-ADGroupMember Administrators -Recursive -Server $DomainDC
ForEach ($ADAdminMemberItem in $ADAdminMembers) {
    Try {
        Switch ($ADAdminMemberItem.objectClass) {
            'User' { [array]$ADAdminArray += Get-ADUser $ADAdminMemberItem -Properties LastLogonDate, PasswordLastSet, ServicePrincipalName -Server $DomainDC }
            'Computer' { [array]$ADAdminArray += Get-ADComputer $ADAdminMemberItem -Properties LastLogonDate, PasswordLastSet -Server $DomainDC }
            'msDS-GroupManagedServiceAccount' { [array]$ADAdminArray += Get-ADServiceAccount $ADAdminMemberItem -Properties LastLogonDate, PasswordLastSet -Server $DomainDC }
        }
    }
    Catch
    { Write-Warning "The security principal member ($ADAdminMemberItem) may be in another domain or is unreachable" ; $ADAdminArray += $ADAdminMemberItem }
}

Write-Output "$ADDomainName AD Admins: "
$ADAdminArray | Sort-ObjectPasswordLastSet | Select-Object Name, DistinguishedName, PasswordLastSet, LastLogonDate, ObjectClass | Format-Table -AutoSize

Write-Output "$ADDomainName AD Admin Accounts with SPNs:"
$ADAdminArray | Where-Object{ $_.ServicePrincipalName } | Select-Object Name, DistinguishedName, ServicePrincipalName | Format-Table -AutoSize
Write-Output ""