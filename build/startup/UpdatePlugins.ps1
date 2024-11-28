Write-Description White "Updating plugins in Plugin folder using PSDepend" -level 3
Push-Location -Path .\plugins
ForEach ($RequirementsFile in $(Get-ChildItem -Recurse -Depth 1 -Filter "Requirements.psd1")) {
    Write-Description White "Updating $($($RequirementsFile.FullName.split('\'))[$($RequirementsFile.FullName.split('\').count)-2])" -level 4
    Invoke-PSDepend -Path $RequirementsFile.FullName -Force
}