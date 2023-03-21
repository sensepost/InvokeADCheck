

$OutputObject = @()

$Prop = @('Name', 'ObjectClass', 'PrimaryGroupID', 'UserAccountControl',
    'ServicePrincipalName', 'msDS-AllowedToDelegateTo', 'msDS-AllowedToActOnBehalfOfOtherIdentity')

$KRBDelegationObjects = Get-ADObject -filter { ((UserAccountControl -BAND 0x0080000) -OR (UserAccountControl -BAND 0x1000000) -OR
     (msDS-AllowedToDelegateTo -like '*') -OR (msDS-AllowedToActOnBehalfOfOtherIdentity -like '*'))
    -AND (PrimaryGroupID -ne '516') -AND (PrimaryGroupID -ne '521') } -Properties $Prop


foreach ($Object in $KRBDelegationObjects) {

    if ($Object.UserAccountControl -BAND 0x0080000) {
        $KRBDelegationServices = 'All Services'
        $KRBType = 'Unconstrained'
    }
    else {
        $KRBDelegationServices = 'Specific Services'
        $KRBType = 'Constrained'
    }

    if ($Object.UserAccountControl -BAND 0x1000000) {
        $KRBDelegationAllowedProtocols = 'Any (Protocol Transition)'
        $KRBType = 'Constrained with Protocol Transition'
    }
    else {
        $KRBDelegationAllowedProtocols = 'Kerberos'
    }

    if ($Object.'msDS-AllowedToActOnBehalfOfOtherIdentity') {
        $KRBType = 'Resource-Based Constrained Delegation'
    }

    $obj = New-Object System.Object

    $obj | Add-Member -MemberType NoteProperty -Name DistinguishedName -Value $Object.DistinguishedName -Force
    $obj | Add-Member -MemberType NoteProperty -Name Name -Value $Object.Name -Force
    $obj | Add-Member -MemberType NoteProperty -Name ServicePrincipalName -Value $Object.ServicePrincipalName -Force
    $obj | Add-Member -MemberType NoteProperty -Name KerberosDelegationServices -Value $KRBDelegationServices -Force
    $obj | Add-Member -MemberType NoteProperty -Name DelegationType -Value $KRBType -Force
    $obj | Add-Member -MemberType NoteProperty -Name KerberosDelegationAllowedProtocols -Value $KRBDelegationAllowedProtocols -Force
    $OutputObject += $obj
}

$OutputObject