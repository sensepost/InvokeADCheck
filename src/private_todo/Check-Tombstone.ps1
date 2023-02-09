$Domain = (Get-ADDomain).DNSRoot
$ADDomainInfo = Get-ADDomain $Domain
$DomainDC = $ADDomainInfo.PDCEmulator
$ADRootDSE = get-adrootdse  -Server $DomainDC
$ADConfigurationNamingContext = $ADRootDSE.configurationNamingContext
$ForestRootDN = $ADRootDSE.rootDomainNamingContext
$ForestNCs = $ADRootDSE.NamingContexts
$DomainControllerSiteNameDN = "CN=Sites,$ADConfigurationNamingContext"
$TombstoneObjectInfo = Get-ADObject -Identity "CN=Directory Service,CN=Windows NT,CN=Services,$ADConfigurationNamingContext" -Partition "$ADConfigurationNamingContext" -Properties *
[int]$TombstoneLifetime = $TombstoneObjectInfo.tombstoneLifetime
IF ($TombstoneLifetime -eq 0) { $TombstoneLifetime = 60 }
Write-Output "The AD Forest Tombstone lifetime is set to $TombstoneLifetime days."