    $SupportedEncryptionTypes = @{
        0x0 = "Not defined - defaults to RC4_HMAC_MD5"
        0x1 = "DES_CBC_CRC"
        0x2 = "DES_CBC_MD5"
        0x3 = "DES_CBC_CRC, DES_CBC_MD5"
        0x4 = "RC4"
        0x5 = "DES_CBC_CRC, RC4"
        0x6 = "DES_CBC_MD5, RC4"
        0x7 = "DES_CBC_CRC, DES_CBC_MD5, RC4"
        0x8 = "AES 128"
        0x9 = "DES_CBC_CRC, AES 128"
        0xA = "DES_CBC_MD5, AES 128"
        0xB = "DES_CBC_CRC, DES_CBC_MD5, AES 128"
        0xC = "RC4, AES 128"
        0xD = "DES_CBC_CRC, RC4, AES 128"
        0xE = "DES_CBC_MD5, RC4, AES 128"
        0xF = "DES_CBC_CBC, DES_CBC_MD5, RC4, AES 128"
        0x10 = "AES 256"
        0x11 = "DES_CBC_CRC, AES 256"
        0x12 = "DES_CBC_MD5, AES 256"
        0x13 = "DES_CBC_CRC, DES_CBC_MD5, AES 256"
        0x14 = "RC4, AES 256"
        0x15 = "DES_CBC_CRC, RC4, AES 256"
        0x16 = "DES_CBC_MD5, RC4, AES 256"
        0x17 = "DES_CBC_CRC, DES_CBC_MD5, RC4, AES 256"
        0x18 = "AES 128, AES 256"
        0x19 = "DES_CBC_CRC, AES 128, AES 256"
        0x1A = "DES_CBC_MD5, AES 128, AES 256"
        0x1B = "DES_CBC_MD5, DES_CBC_MD5, AES 128, AES 256"
        0x1C = "RC4, AES 128, AES 256"
        0x1D = "DES_CBC_CRC, RC4, AES 128, AES 256"
        0x1E = "DES_CBC_MD5, RC4, AES 128, AES 256"
        0x1F = "DES+A1:C33_CBC_MD5, DES_CBC_MD5, RC4, AES 128, AES 256"
    }

$OutputObject = @()

$ADObjects = Get-ADObject -LDAPFilter "(&(|(objectclass=user)(objectClass=Computer)))" -Properties *

foreach ($ADObj in $ADObjects) {
    if ($SupportedEncryptionTypes.Keys -contains $ADObj.'msDS-SupportedEncryptionTypes') {
        $obj = New-Object System.Object
        $obj | Add-Member -type NoteProperty -Name 'Name' -Value $ADObj.Name
        $obj | Add-Member -type NoteProperty -Name 'msDS-SupportedEncryptionTypes' -Value $SupportedEncryptionTypes[$ADObj.'msDS-SupportedEncryptionTypes']
        $obj | Add-Member -type NoteProperty -Name 'ObjectClass' -Value $ADObj.ObjectClass
        $OutputObject += $obj
    }
}

$OutputObject