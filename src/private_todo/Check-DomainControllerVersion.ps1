Function Get-ListFromArray {
    Param(
        $Array
    )

    $ArrayList = $NULL
    ForEach ($ArrayItem in $Array) {
        [string]$ArrayList += "$ArrayItem; "
    }
    IF ($ArrayList) {
        $ArrayList = $ArrayList.Substring(0, $ArrayList.Length - 2)
    }
    Return $ArrayList
}

$Domain = (Get-ADDomain).DNSRoot
$ADDomainInfo = Get-ADDomain $Domain
$DomainDC = $ADDomainInfo.PDCEmulator
$DomainDCs = Get-ADDomainController -filter * -Server $DomainDC
$DomainDCs | Select-Object HostName, OperatingSystem | Format-Table -AutoSize

$DomainDCArray = @()
ForEach ($DomainDCItem in $DomainDCs) {
    $DomainDCItem | Add-Member -MemberType NoteProperty -Name FSMORolesList -Value (Get-ListFromArray $DomainDCItem.OperationMasterRoles) -Force
    $DomainDCItem | Add-Member -MemberType NoteProperty -Name PartitionsList -Value (Get-ListFromArray $DomainDCItem.Partitions) -Force
    [array]$DomainDCArray += $DomainDCItem
}

$DomainDCArray | Where-Object { $_.FSMORolesList -ne $NULL } | fl FSMORolesList, Hostname, OperatingSystem