$EncTypes = @("Not defined - defaults to RC4_HMAC_MD5", "DES_CBC_CRC", "DES_CBC_MD5", "DES_CBC_CRC | DES_CBC_MD5", "RC4", "DES_CBC_CRC | RC4", "DES_CBC_MD5 | RC4", "DES_CBC_CRC | DES_CBC_MD5 | RC4", "AES 128", "DES_CBC_CRC | AES 128", "DES_CBC_MD5 | AES 128", "DES_CBC_CRC | DES_CBC_MD5 | AES 128", "RC4 | AES 128", "DES_CBC_CRC | RC4 | AES 128", "DES_CBC_MD5 | RC4 | AES 128", "DES_CBC_CBC | DES_CBC_MD5 | RC4 | AES 128", "AES 256", "DES_CBC_CRC | AES 256", "DES_CBC_MD5 | AES 256", "DES_CBC_CRC | DES_CBC_MD5 | AES 256", "RC4 | AES 256", "DES_CBC_CRC | RC4 | AES 256", "DES_CBC_MD5 | RC4 | AES 256", "DES_CBC_CRC | DES_CBC_MD5 | RC4 | AES 256", "AES 128 | AES 256", "DES_CBC_CRC | AES 128 | AES 256", "DES_CBC_MD5 | AES 128 | AES 256", "DES_CBC_MD5 | DES_CBC_MD5 | AES 128 | AES 256", "RC4 | AES 128 | AES 256", "DES_CBC_CRC | RC4 | AES 128 | AES 256", "DES_CBC_MD5 | RC4 | AES 128 | AES 256", "DES+A1:C33_CBC_MD5 | DES_CBC_MD5 | RC4 | AES 128 | AES 256")


$DomainUsers = Get-ADUser -LdapFilter "(&(objectclass=user)(objectcategory=user)(msDS-SupportedEncryptionTypes=*)(!msDS-SupportedEncryptionTypes=0))" -properties *
foreach ($etype in $DomainUsers) {
    $etype.Name + "," + $EncTypes[$etype.'msDS-SupportedEncryptionTypes']
}


$Computers = Get-ADComputer -properties msDS-SupportedEncryptionTypes -filter *
foreach ($etype in $Computers) {
    $etype.Name + "," + $EncTypes[$etype.'msDS-SupportedEncryptionTypes']
}