Function Get-KerberosEncryptionTypes {
    # https://raw.githubusercontent.com/jeremyts/ActiveDirectoryDomainServices/master/Audit/Get-UserSupportedEncryptionTypes.ps1
    param (
        [int]$key
    )
    switch ($key) {
        "1" { $SupportedEncryptionTypes = @("DES_CRC") }
        "2" { $SupportedEncryptionTypes = @("DES_MD5") }
        "3" { $SupportedEncryptionTypes = @("DES_CRC", "DES_MD5") }
        "4" { $SupportedEncryptionTypes = @("RC4") }
        "8" { $SupportedEncryptionTypes = @("AES128") }
        "16" { $SupportedEncryptionTypes = @("AES256") }
        "24" { $SupportedEncryptionTypes = @("AES128", "AES256") }
        "28" { $SupportedEncryptionTypes = @("RC4", "AES128", "AES256") }
        "31" { $SupportedEncryptionTypes = @("DES_CRC", "DES_MD5", "RC4", "AES128", "AES256") }
        default { $SupportedEncryptionTypes = @("Undefined value of $key") }
    }
    $SupportedEncryptionTypes            
}
$Users = Get-ADUser -Properties * -LdapFilter "(&(objectclass=user)(objectcategory=user)(msDS-SupportedEncryptionTypes=*)(!msDS-SupportedEncryptionTypes=0))" | Select-Object Name, @{N = "EncryptionTypes"; E = { Get-KerberosEncryptionTypes $($_."msDS-SupportedEncryptionTypes") } }
ForEach ($User in $Users) {
    $User.Name
    ForEach ($EncryptionType in $User.EncryptionTypes) {
        $EncryptionType
    }
}

$computers = Get-ADComputer -properties msDS-SupportedEncryptionTypes -filter *
$computers | Sort-Object -Unique  msDS-SupportedEncryptionTypes | ForEach-Object {
    Write-Output "Found $($_.'msDS-SupportedEncryptionTypes'), which resolves to $(Get-KerberosEncryptionTypes -key $_.'msDS-SupportedEncryptionTypes')"
}