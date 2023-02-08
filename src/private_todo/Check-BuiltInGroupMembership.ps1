$Domain = (Get-ADDomain).DNSRoot
$ADDomainInfo = Get-ADDomain $Domain
$DomainDC = $ADDomainInfo.PDCEmulator
$ADPrivGroupArray = @(
 'Administrators',
 'Domain Admins',
 'Enterprise Admins',
 'Schema Admins',
 'Account Operators',
 'Server Operators',
 'Group Policy Creator Owners',
 'DNSAdmins',
 'Enterprise Key Admins',
 # Exchange Privileged Groups
 'Exchange Domain Servers',
 'Exchange Enterprise Servers',
 'Exchange Admins',
 'Organization Management',
 'Exchange Windows Permissions'
)

ForEach ($ADPrivGroupItem in $ADPrivGroupArray) {
    $ADPrivGroupItemGroupMembership = @()
    TRY 
     { 
        $ADPrivGroupItemGroupMembership = Get-ADGroupMember $ADPrivGroupItem -Server $DomainDC 
        IF ($ADPrivGroupItemGroupMembership.count -ge 1)
         {
            Write-Output "$Domain Domain $ADPrivGroupItem Group:"
            $ADPrivGroupItemGroupMembership | Select name,DistinguishedName,objectClass | Format-List
         }
        ELSE
         { Write-Output "$Domain domain $ADPrivGroupItem Group:  No members" }
     }
    CATCH
     { Write-Warning "An error occured when attempting to enumerate group membership for the group $ADPrivGroupItem in the domain $Domain using the DC $DomainDC" }
    
    Write-Output ""
}