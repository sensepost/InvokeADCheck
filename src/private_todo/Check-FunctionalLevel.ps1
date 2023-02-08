$Domain = (Get-ADDomain).DNSRoot
$ADForestFunctionalLevel = (Get-ADForest).ForestMode
$ADDomainFunctionalLevel = (Get-ADDomain $Domain).DomainMode
Write-Output "The AD Forest Functional Level is $ADForestFunctionalLevel"
Write-Output "The AD Domain Functional Level ($Domain) is $ADDomainFunctionalLevel"