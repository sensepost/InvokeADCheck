#Requires -Version 5
[CmdletBinding(DefaultParameterSetName = 'Build')]
param (
    [parameter(Position = 0, ParameterSetName = 'Build')]
    [switch]$BuildModule,
    [parameter(Position = 1,ParameterSetName = 'Build')]
    [switch]$TestBuildAndInstallModule,
    [parameter(Position = 2, ParameterSetName = 'UpdateRelease')]
    [switch]$UpdateRelease,
    [parameter(Position = 3, ParameterSetName = 'UpdateRelease')]
    [version]$NewVersion,
    [parameter(Position = 4, ParameterSetName = 'UpdateRelease')]
    [string]$ReleaseNotes,
    [parameter(Position = 5, ParameterSetName = 'UpdateRelease')]
    [switch]$UploadPSGallery,
    [parameter(Position = 6, ParameterSetName = 'CBH')]
    [switch]$AddMissingCBH,
    [parameter(Position = 7, ParameterSetName = 'Tests')]
    [switch]$Test,
    [parameter(Position = 8,ParameterSetName = 'Tests')]
    [switch]$TestMetaOnly,
    [parameter(Position = 9,ParameterSetName = 'Tests')]
    [switch]$TestUnitOnly,
    [parameter(Position = 10,ParameterSetName = 'Tests')]
    [switch]$TestIntergrationOnly
)

function PrerequisitesLoaded {
    # Install required modules if missing
    try {
        if ((get-module PSDepend -ListAvailable) -eq $null) {
            Write-Host "Attempting to install the PSDepend module..." -NoNewLine
            $null = Install-Module PSDepend -MinimumVersion 0.3.2 -MaximumVersion 0.3.2 -Scope:CurrentUser
            Write-Host 'Installed!'
        }
        if (get-module PSDepend -ListAvailable) {
            Write-Host "Importing PSDepend module..." -NoNewLine
            Import-Module PSDepend -Force
            Write-Host 'Loaded!'

            Write-Host 'Installing dependencies...' -NoNewLine
            Invoke-PSDepend -Path $(Join-Path $(Get-Location) 'Requirements.psd1') -Test
            Invoke-PSDepend -Path $(Join-Path $(Get-Location) 'Requirements.psd1') -Force
            Invoke-PSDepend -Path $(Join-Path $(Get-Location) 'Requirements.psd1') -Import -Force
            Write-Host 'Installed!'
            return $true
        }
        else {
            return $false
        }
    }
    catch {
        return $false
    }
}

function CleanUp {
    try {
        Write-Host ''
        Write-Host 'Attempting to clean up the session (loaded modules and such)...'
        Invoke-Build -Task BuildSessionCleanup
        Remove-Module InvokeBuild
    }
    catch {}
}

if (-not (PrerequisitesLoaded)) {
    throw 'Unable to load InvokeBuild!'
}

switch ($psCmdlet.ParameterSetName) {
    'Build' {
        # If no parameters were specified or the build action was manually specified then kick off a standard build
        if (($psboundparameters.count -eq 0) -or ($BuildModule)) {
            try {
                Invoke-Build
            }
            catch {
                Write-Host 'Build Failed with the following error:'
                throw $_
            }
        }

        # Test, Build Installd and test load the module
        if ($TestBuildAndInstallModule) {
            try {
                Invoke-Build -Task TestBuildAndInstallModule
            }
            catch {
                Write-Host 'Test, Build Installd and test load the module of the module failed:'
                throw $_
            }
        }
    }
    'CBH' {
        if ($AddMissingCBH) {
            try {
                Invoke-Build -Task AddMissingCBH
            }
            catch {
                throw $_
            }
        }
    }
     'UpdateRelease' {
        if ($UpdateRelease) {
            try {
                Invoke-Build -Task UpdateRelease -NewVersion $NewVersion -ReleaseNotes $ReleaseNotes
            }
            catch {
                throw $_
            }
        }

        if ($UploadPSGallery) {
            try {
                Invoke-Build -Task PublishPSGallery
            }
            catch {
                throw 'Unable to upload project to the PowerShell Gallery!'
            }
        }
    }
    'Tests' {
        if ($test) {
            try {
                Invoke-Build -Task tests
            }
            catch {
                throw
            }
        }
        if ($TestMetaOnly) {
            try {
                Invoke-Build -Task RunMetaTests
            }
            catch {
                throw
            }
        }
        if ($TestUnitOnly) {
            try {
                Invoke-Build -Task RunUnitTests
            }
            catch {
                throw
            }
        }
        if ($TestIntergrationOnly) {
            try {
                Invoke-Build -Task RunIntergrationTests
            }
            catch {
                throw
            }
        }
    }
}

