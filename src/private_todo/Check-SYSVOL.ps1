$Domain = (Get-ADDomain).DNSRoot
Write-Output "$Domain SYSVOL Scan for Group Policy Preference Passwords:"
$DomainSYSVOLShareScan = "\\$Domain\SYSVOL\$Domain\Policies\*.xml"
$GPPPasswordData = findstr /S /I cpassword $DomainSYSVOLShareScan
$GPPPasswordData