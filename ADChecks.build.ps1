param (
    [parameter(Position = 0)]
    [string]$BuildFile = @(Get-ChildItem 'build\*.buildenvironment.ps1')[0].FullName,
    [parameter()]
    [version]$NewVersion = $null,
    [parameter()]
    [string]$ReleaseNotes,
    [parameter()]
    [switch]$Force
)

Function Write-Description {
    # Basic indented descriptive build output. $Description can contain Newlines.
    Param (
        [string]$color = 'White',
        [string]$Description = '',
        [int]$Level = 0,
        [int]$indent = 1,
        [switch]$accent,
        [string]$AccentL = '* ',
        [string]$AccentR = ''
    )

    $thisindent = (' ' * $indent) * $level
    If ($accent) {
        $accentleft = $AccentL
        $accentright = $AccentR
    }

    $Description -split '\r\n|\n' | ForEach-Object { Write-Build $color "$accentleft$thisindent$($_)$accentright" }
}

if (Test-Path $BuildFile) {
    . $BuildFile
}
else {
    throw "Without a build environment file we are at a loss as to what to do!"
}

if ($Script:BuildEnv.OptionTranscriptEnabled) {
    Write-Output 'Transcript logging: TRUE'
    $BuildToolPath = Join-Path $BuildRoot $Script:BuildEnv.BuildToolFolder
    $TranscriptLog = Join-Path $BuildToolPath $Script:BuildEnv.OptionTranscriptLogFile
    Write-Output "TranscriptLog: $($TranscriptLog)"
    Start-Transcript -Path $TranscriptLog -Append -WarningAction:SilentlyContinue
}

#$Script:BuildRoot = $BuildRoot
#region Configure
#Synopsis: Validate system requirements are met
task ValidateRequirements {
    Write-Description White 'Validating System Requirements for Build' -accent
    assert ($PSVersionTable.PSVersion.Major.ToString() -eq '5') 'Powershell 5 is required for this build to function properly (you can comment this assert out if you are able to work around this requirement)'
}

# Synopsis: Run pre-build scripts (such as other builds)
task PreBuildTasks {
    Write-Description White 'Running any Pre-Build scripts' -accent
    $BuildToolPath = Join-Path $BuildRoot $Script:BuildEnv.BuildToolFolder
    $PreBuildPath = Join-Path $BuildToolPath 'startup'
    # Dot source any pre build scripts.
    Get-ChildItem -Path $PreBuildPath -Recurse -Filter "*.ps1" -File | Foreach {
        Write-Description White "Dot sourcing pre-build script file: $($_.Name)" -level 2
        . $_.FullName
    }
}

# Synopsis: Import the current module manifest file for processing
task LoadModuleManifest {
    Write-Description White 'Loading the existing module manifest for this module' -accent

    $ModuleManifestFullPath = Join-Path $BuildRoot "$($Script:BuildEnv.ModuleToBuild).psd1"
    assert (test-path $ModuleManifestFullPath) "Unable to locate the module manifest file: $ModuleManifestFullPath"
    $Script:Manifest = Test-ModuleManifest -Path $ModuleManifestFullPath
}

#Synopsis: Load required build modules using PSDepend
task LoadRequiredModules {
    Write-Description White 'Loading all required modules for the build framework' -accent

    if ((Get-Module PSDepend -ListAvailable) -eq $null) {
        Write-Description White "Installing PSDepend Module" -Level 2
        $null = Install-Module PSDepend -Scope:CurrentUser
    }

    $PSDependFolder = $(Join-Path $Script:BuildEnv.BuildToolFolder 'dependencies\PSDepend')
    $PSDependBuildFile = $(Join-Path $PSDependFolder 'build.depend.psd1')
    Invoke-PSDepend -Path $PSDependBuildFile -Force
    $Script:PSDependBuildModules = Invoke-PSDepend -Path $PSDependBuildFile -Test | Select-Object Version,DependencyName,DependencyType
    Invoke-PSDepend -Path $PSDependBuildFile -Import -Force
    $Script:PSDependBuildModules | ForEach-Object {
        Write-Description White "Installed version $($_.Version) of $($_.DependencyName) from $($_.DependencyType)" -Level 2
    }
}

# Synopsis: Load the module project
task LoadModule {
    Write-Description White 'Attempting to load the project module.' -Accent

    $ModuleFullPath = Join-Path $BuildRoot "$($Script:BuildEnv.ModuleToBuild).psm1"
    try {
        $Script:Module = Import-Module $ModuleFullPath -Force -PassThru
    }
    catch {
        throw "Unable to load the project module: $($ModuleFullPath)"
    }
}

# Synopsis: Valiates there is no version mismatch.
task VersionCheck LoadModuleManifest, {
    Write-Description White 'Validating manifest, build, and gallery module versions.' -accent

    assert ( ($Script:Manifest).Version.ToString() -eq (($Script:BuildEnv.ModuleVersion)) ) "The module manifest version ( $(($Script:Manifest).Version.ToString()) ) and release version ($($Script:BuildEnv.ModuleVersion)) are mismatched. These must be the same before continuing. Consider running the UpdateRelease task to make the module manifest version the same as the release version."
    Write-Description White 'Manifest version and the release version in the build configuration file are the same.' -Level 2
    $GalleryVersion = find-module ($Script:BuildEnv.ModuleToBuild) -ErrorAction:SilentlyContinue
    if ($null -ne $GalleryVersion) {
        if ($GalleryVersion.Version -gt [version]($Script:BuildEnv.ModuleVersion)) {
            throw "The current module version is less than or equal to the one published in powershell gallary. You should bump up your module version to be at least greater than $($GalleryVersion.Version.ToString()) before building this module."
        }
    }
    else {
        Write-Description White 'This module has not been published to the gallery so any version is ok to build at this point.' -Level 2
    }
}

#Synopsis: Validate script requirements are met, load required modules, load project manifest and module.
task Configure ValidateRequirements, PreBuildTasks, LoadRequiredModules, LoadModuleManifest, LoadModule, VersionCheck,  {
    # If we made it this far then we are configured!
    Write-Description White 'Configuring build environment' -accent
}
#endregion

#region Helpers
#Synopsis: Create a CodeHealthReport of your existing code
task CodeHealthReport -if {$Script:BuildEnv.OptionCodeHealthReport} ValidateRequirements, LoadRequiredModules, {
    $BuildReportsFolder = Join-Path $BuildRoot $(Join-Path $Script:BuildEnv.BuildReportsFolder $Script:BuildEnv.ModuleVersion)
    Write-Description White "Creating a prebuild code health report of your public functions to $($BuildReportsFolder)" -accent

    if (-not (Test-Path $BuildReportsFolder)) {
        [void](New-Item -Path $BuildReportsFolder -ItemType:Directory)
    }

    Write-Description White 'Creating a code health report of your public functions' -level 2
    $CodeHealthScanPathPublic = Join-Path $BuildRoot $Script:BuildEnv.PublicFunctionSource
    $CodeHealthScanTestPathPublic = $CodeHealthScanPathPublic -replace  'src', 'tests\\unit'
    $CodeHealthReportPublic = Join-Path $BuildReportsFolder 'CodeHealthReport-Public.html'
    Invoke-PSCodeHealth -Path $CodeHealthScanPathPublic -HtmlReportPath $CodeHealthReportPublic -TestsPath $CodeHealthScanTestPathPublic

    if (Test-Path $CodeHealthReportPublic) {
        (Get-Content -Path $CodeHealthReportPublic -raw) -replace [regex]::escape((Resolve-Path $CodeHealthScanPathPublic)), $Script:BuildEnv.PublicFunctionSource | Out-File -FilePath $CodeHealthReportPublic -Encoding $Script:BuildEnv.Encoding -Force
    }

    Write-Description White 'Creating a code health report of your private functions' -level 2
    $CodeHealthScanPathPrivate = Join-Path $BuildRoot $Script:BuildEnv.PrivateFunctionSource
    $CodeHealthScanTestPathPrivate = $CodeHealthScanPathPrivate -replace  'src', 'tests\\unit'
    $CodeHealthReportPrivate = Join-Path $BuildReportsFolder 'CodeHealthReport-Private.html'
    Invoke-PSCodeHealth -Path $CodeHealthScanPathPrivate -HtmlReportPath $CodeHealthReportPrivate -TestsPath $CodeHealthScanTestPathPrivate

    if (Test-Path $CodeHealthReportPrivate) {
        (Get-Content -Path $CodeHealthReportPrivate -raw) -replace [regex]::escape((Resolve-Path $CodeHealthScanPathPrivate)), $Script:BuildEnv.PrivateFunctionSource | Out-File -FilePath $CodeHealthReportPrivate -Encoding $Script:BuildEnv.Encoding -Force
    }
}

# Synopsis: Create base content tree in scratch staging area
task PrepareStage CleanScratchDirectory, {
    Write-Description White 'Creating staging folder structure' -accent

    $BuildDocsPath = Join-Path $BuildRoot "$($Script:BuildEnv.BuildToolFolder)\docs\"
    $ScratchPath = Join-Path $BuildRoot $Script:BuildEnv.ScratchFolder
    $StageReleasePath = Join-Path $ScratchPath $Script:BuildEnv.BaseReleaseFolder

    # Create the directories
    $null = New-Item "$($ScratchPath)\src" -ItemType:Directory -Force
    $null = New-Item $StageReleasePath -ItemType:Directory -Force

    Copy-Item -Path "$($BuildRoot)\*.psm1" -Destination $ScratchPath
    Copy-Item -Path "$($BuildRoot)\*.psd1" -Destination $ScratchPath
    Copy-Item -Path "$($BuildRoot)\$($Script:BuildEnv.PublicFunctionSource)" -Recurse -Destination "$($ScratchPath)\$($Script:BuildEnv.PublicFunctionSource)"
    Copy-Item -Path "$($BuildRoot)\$($Script:BuildEnv.PrivateFunctionSource)" -Recurse -Destination "$($ScratchPath)\$($Script:BuildEnv.PrivateFunctionSource)"
    Copy-Item -Path "$($BuildRoot)\$($Script:BuildEnv.OtherModuleSource)" -Recurse -Destination "$($ScratchPath)\$($Script:BuildEnv.OtherModuleSource)"
    Copy-Item -Path (Join-Path $BuildDocsPath 'en-US') -Recurse -Destination $ScratchPath
    $Script:BuildEnv.AdditionalModulePaths | ForEach-Object {
        if (Test-Path $_) {
            Copy-Item -Path $_ -Recurse -Destination $ScratchPath -Force
        }
    }
}

# Synopsis:  Collect a list of our public methods for later module manifest updates
task GetPublicFunctions {
    Write-Description White 'Parsing for public (exported) function names' -accent
    $Exported = @()
    Get-ChildItem (Join-Path $BuildRoot $Script:BuildEnv.PublicFunctionSource) -Recurse -Filter "*.ps1" -File | Sort-Object Name | ForEach-Object {
        $Exported += ([System.Management.Automation.Language.Parser]::ParseInput((Get-Content -Path $_.FullName -Raw), [ref]$null, [ref]$null)).FindAll( { $args[0] -is [System.Management.Automation.Language.FunctionDefinitionAst] }, $false) | ForEach-Object {$_.Name}
    }

    if ($Exported.Count -eq 0) {
        Write-Error 'There are no public functions to export!'
    }
    $Script:FunctionsToExport = $Exported
    Write-Description White "Number of exported functions found = $($Exported.Count)" -Level 2
}

# Synopsis: Validate that sensitive strings are not found in your code
task SanitizeCode -if {$Script:BuildEnv.OptionSanitizeSensitiveTerms} {
    Write-Description White 'Attempting to find sensitive terms in the code' -accent
    $ScratchPath = Join-Path $BuildRoot $Script:BuildEnv.ScratchFolder
    $StageReleasePath = Join-Path $ScratchPath $Script:BuildEnv.BaseReleaseFolder

    ForEach ($Term in $Script:BuildEnv.OptionSensitiveTerms) {
        Write-Description White "Checking Files for sensitive string: $Term" -level 2
        $TermsFound = Get-ChildItem -Path $ScratchPath -Recurse -File | Where-Object {$_.FullName -notlike "$($StageReleasePath)*"} | Select-String -Pattern $Term
        if ($TermsFound.Count -gt 0) {
            Write-Description white "Sensitive string found in the following files:" -Level 3
            $TermsFound | ForEach-Object {
                Write-Description yellow $_ -level 4
            }
            throw "Sensitive Terms found!"
        }
    }
}

# Synopsis: Removes script signatures before creating a combined PSM1 file
task RemoveScriptSignatures {
    Write-Description White 'Removing any script signatures for function files (if they exist)' -Accent

    $ScratchPath = Join-Path $BuildRoot $Script:BuildEnv.ScratchFolder

    if ($Script:BuildEnv.OptionCombineFiles) {
        Write-Description White 'Remove script signatures from all files' -Level 2
        Get-ChildItem -Path "$($ScratchPath)\$($Script:BuildEnv.BaseSourceFolder)" -Recurse -File | ForEach-Object {Remove-MBTSignature -FilePath $_.FullName}
    }
}

# Synopsis: Run PSScriptAnalyzer against the public source files.
task RunPSScriptAnalyzeOnPublicSrcFunctions {
    Write-Description White "Analyzing the public source files with ScriptAnalyzer." -accent
    $Analysis = Invoke-ScriptAnalyzer -Path (Join-Path $BuildRoot $Script:BuildEnv.PublicFunctionSource) -Settings (Join-Path $BuildRoot "PSScriptAnalyzerSettings.psd1")
    if ($Analysis.Count) {
        Write-Description White "Note that this was from the script analysis run against $($Script:BuildEnv.PublicFunctionSource)" -level 2
        Write-Description Red "$($Analysis.Count) linting errors or warnings were found:" -level 2
        $Analysis | Format-Table -AutoSize
    }
}
#endregion

#region Tests
task RunMetaTests LoadRequiredModules, {
    Write-Description White 'Running meta tests with Pester' -accent
    $ENV:BuildRoot = $BuildRoot
    $invokePesterParams = @{
        Strict = $true
        PassThru = $true
        Verbose = $false
        EnableExit = $false
    }
    $testResults = Invoke-Pester -Tag 'MetaTest' $(Join-Path $BuildRoot 'Tests') @invokePesterParams
    $numberFails = $testResults.FailedCount
    assert($numberFails -eq 0) ('Failed "{0}" meta tests.' -f $numberFails)
}

task RunUnitTests LoadRequiredModules, {
    Write-Description White 'Running Unit tests with Pester' -accent
    $ENV:BuildRoot = $BuildRoot
    $invokePesterParams = @{
        Strict = $true
        PassThru = $true
        Verbose = $false
        EnableExit = $false
    }
    $testResults = Invoke-Pester -tag 'UnitTest' $(Join-Path $BuildRoot 'Tests') @invokePesterParams
    $numberFails = $testResults.FailedCount
    assert($numberFails -eq 0) ('Failed "{0}" unit tests.' -f $numberFails)
}

task RunIntergrationTests LoadRequiredModules, {
    Write-Description White 'Running Intergration tests with Pester' -accent
    $ENV:BuildRoot = $BuildRoot
    $invokePesterParams = @{
        Strict = $true
        PassThru = $true
        Verbose = $false
        EnableExit = $false
    }
    $testResults = Invoke-Pester -tag 'IntergrationTest' $(Join-Path $BuildRoot 'Tests') @invokePesterParams
    $numberFails = $testResults.FailedCount
    assert($numberFails -eq 0) ('Failed "{0}" unit tests.' -f $numberFails)
}
#endregion

#region Documentation/Help files
# Synopsis: Build the markdown help files with PlatyPS
task CreateMarkdownHelp GetPublicFunctions, {
    Write-Description White 'Creating markdown documentation with PlatyPS' -accent

    $BuildToolPath = Join-Path $BuildRoot $Script:BuildEnv.BuildToolFolder
    $ScratchPath = Join-Path $BuildRoot $Script:BuildEnv.ScratchFolder
    $StageReleasePath = Join-Path $ScratchPath $Script:BuildEnv.BaseReleaseFolder
    Copy-Item -Path (Join-Path $ScratchPath "en-US") -Recurse -Destination $StageReleasePath -Force
    $OnlineModuleLocation = "$($Script:BuildEnv.ModuleWebsite)/$($Script:BuildEnv.BaseReleaseFolder)"
    $FwLink = "$($OnlineModuleLocation)/$($Script:BuildEnv.ModuleToBuild)/docs/$($Script:BuildEnv.ModuleToBuild).md"
    $ModulePage = "$($StageReleasePath)\docs\$($Script:BuildEnv.ModuleToBuild).md"

    # If the current module we are building is also loaded as a dependency with PSDepend,
    # Unload it temporally and reload it from the scratchpath to build markdown files from.
    if (Get-Module $Script:BuildEnv.ModuleToBuild  | Where-Object {$_.Path -like "*PSDepend\$($Script:BuildEnv.ModuleToBuild)*"}) {
        $TempDeload = $true
        #Write-Verbose "$($(Get-Module $Script:BuildEnv.ModuleToBuild).Path)"
        #Get-Command | Where-Object { $_.source -eq 'ModuleBuildTools'} | ForEach-Object {
        #    Remove-Item -Path Function:\$($_.Name)
        #}
        #while ($(Get-Module $Script:BuildEnv.ModuleToBuild)) {
        Get-Module $Script:BuildEnv.ModuleToBuild | Remove-Module
        #}
        $TempModule = Join-Path $ScratchPath "$($Script:BuildEnv.ModuleToBuild).psd1"
        try {
            [void](Import-Module $TempModule -Force)
        }
        catch {
            throw "Unable to load the project module: $($TempModule)"
        }
        Write-Verbose $($(Get-Module $Script:BuildEnv.ModuleToBuild).Path)

    }

    # Create the function .md files and the generic module page md as well for the distributable module
    $null = New-MarkdownHelp -module $Script:BuildEnv.ModuleToBuild -OutputFolder "$($StageReleasePath)\docs\" -Force -WithModulePage -Locale 'en-US' -FwLink $FwLink -HelpVersion $Script:BuildEnv.ModuleVersion -Encoding ([System.Text.Encoding]::($Script:BuildEnv.Encoding))
    $null = Update-MarkdownHelpModule -Path "$($StageReleasePath)\docs\" -Force -RefreshModulePage
    <#
     Replace each missing element we need for a proper generic module page .md file
     Also replace the blank Guid 00000000-0000-0000-0000-000000000000 with the actual module guid
     (PlatyPS won't know what this is as our module in memory is loaded from the psm1 file not the actual manifest file)
    #>
    $ModulePageFileContent = Get-Content -raw $ModulePage
    $ModulePageFileContent = $ModulePageFileContent -replace '{{ Fill in the Description }}', $Script:Manifest.Description -replace '00000000-0000-0000-0000-000000000000', ($Script:Manifest.Guid).ToString()
    $ModulePageFileContent | Out-File $ModulePage -Force -Encoding $Script:BuildEnv.Encoding
    $MissingDocumentation = Select-String -Path "$($StageReleasePath)\docs\*.md" -Pattern "({{.*}})"

    if ($MissingDocumentation.Count -gt 0) {
        Write-Build Yellow ''
        Write-Build Yellow '   The documentation that got generated resulted in missing sections which should be filled out.'
        Write-Build Yellow '   Please review the following sections in your comment based help, fill out missing information and rerun this build:'
        Write-Build Yellow '   (Note: This can happen if the .EXTERNALHELP CBH is defined for a function before running this build.)'
        Write-Build White ''
        Write-Build Yellow "Path of files with issues: $($StageReleasePath)\docs\"
        Write-Build White ''
        $MissingDocumentation | Select-Object Path, LineNumber, Line | Format-Table -auto
        Write-Build Yellow ''
        pause

        throw 'Missing documentation. Please review and rebuild.'
    }
    # If modules where unloaded, reload them with PSDepend
    if ($TempDeload) {
        while ($(Get-Module $Script:BuildEnv.ModuleToBuild)) {
            Get-Module $Script:BuildEnv.ModuleToBuild | Remove-Module
        }
        Invoke-PSDepend -Path $(Join-Path $BuildToolPath 'dependencies\PSDepend\build.depend.psd1') -Import -Force
    }
}

# Synopsis: Build the markdown help files with PlatyPS
task CreateExternalHelp {
    Write-Description White 'Creating markdown help files' -accent
    $ScratchPath = Join-Path $BuildRoot $Script:BuildEnv.ScratchFolder
    $StageReleasePath = Join-Path $ScratchPath $Script:BuildEnv.BaseReleaseFolder

    $PlatyPSVerbose = @{}
    if ($Script:BuildEnv.OptionRunPlatyPSVerbose) {
        $PlatyPSVerbose.Verbose = $true
    }
    $null = New-ExternalHelp "$($StageReleasePath)\docs" -OutputPath "$($StageReleasePath)\en-US\" -Force @PlatyPSVerbose
}

# Synopsis: Build the help file CAB with PlatyPS
task CreateUpdateableHelpCAB {
    Write-Description White "Creating updateable help cab file" -accent

    $ScratchPath = Join-Path $BuildRoot $Script:BuildEnv.ScratchFolder
    $StageReleasePath = Join-Path $ScratchPath $Script:BuildEnv.BaseReleaseFolder

    $PlatyPSVerbose = @{}
    if ($Script:BuildEnv.OptionRunPlatyPSVerbose) {
        $PlatyPSVerbose.Verbose = $true
    }
    $LandingPage = "$($StageReleasePath)\docs\$($Script:BuildEnv.ModuleToBuild).md"
    $null = New-ExternalHelpCab -CabFilesFolder "$($StageReleasePath)\en-US\" -LandingPagePath $LandingPage -OutputFolder "$($StageReleasePath)\en-US\" @PlatyPSVerbose
}

# Synopsis: Build the markdown help for the functions using PlatyPS for the core project docs.
task BuildProjectHelpFiles {
    Write-Description White 'Creating markdown documentation with PlatyPS for the core project' -accent
    $BuildToolPath = Join-Path $BuildRoot $Script:BuildEnv.BuildToolFolder
    $ScratchPath = Join-Path $BuildRoot $Script:BuildEnv.ScratchFolder

    $OnlineModuleLocation = "$($Script:BuildEnv.ModuleWebsite)/$($Script:BuildEnv.BaseReleaseFolder)"
    $FwLink = "$($OnlineModuleLocation)/docs/Functions/$($Script:BuildEnv.ModuleToBuild).md"

    # If the current module we are building is also loaded as a dependency with PSDepend,
    # Unload it temporally and reload it from the scratchpath to build markdown files from.
    if (Get-Module $Script:BuildEnv.ModuleToBuild  | Where-Object {$_.Path -like "*PSDepend\$($Script:BuildEnv.ModuleToBuild)*"}) {
        $TempDeload = $true
        #Write-Verbose "$($(Get-Module $Script:BuildEnv.ModuleToBuild).Path)"
        #Get-Command | Where-Object { $_.source -eq 'ModuleBuildTools'} | ForEach-Object {
        #    Remove-Item -Path Function:\$($_.Name)
        #}
        #while ($(Get-Module $Script:BuildEnv.ModuleToBuild)) {
        Get-Module $Script:BuildEnv.ModuleToBuild | Remove-Module
        #}
        $TempModule = Join-Path $ScratchPath "$($Script:BuildEnv.ModuleToBuild).psd1"
        try {
            [void](Import-Module $TempModule -Force)
        }
        catch {
            throw "Unable to load the project module: $($TempModule)"
        }
    }

    # Create the function .md files for the core project documentation
    $null = New-MarkdownHelp -module $Script:BuildEnv.ModuleToBuild -OutputFolder "$($BuildRoot)\docs\Functions\" -Force -Locale 'en-US' -FwLink $FwLink -HelpVersion $Script:BuildEnv.ModuleVersion -Encoding ([System.Text.Encoding]::($Script:BuildEnv.Encoding)) #-OnlineVersionUrl "$($Script:BuildEnv.ModuleWebsite)/docs/Functions"

    # If modules where unloaded, reload them with PSDepend
    if ($TempDeload) {
        while ($(Get-Module $Script:BuildEnv.ModuleToBuild)) {
            Get-Module $Script:BuildEnv.ModuleToBuild | Remove-Module
        }
        Invoke-PSDepend -Path $(Join-Path $BuildToolPath 'dependencies\PSDepend\build.depend.psd1') -Import -Force
    }
}

# Synopsis: Add additional doc files to the final project document folder
task AddAdditionalDocFiles {
    Write-Description White "Add additional doc files to the project document folder" -accent

    $BuildDocsPath = Join-Path $BuildRoot "$($Script:BuildEnv.BuildToolFolder)\docs\"
    Copy-Item -Path (Join-Path $BuildDocsPath 'Additional\*.md') -Destination (Join-Path $BuildRoot 'docs') -Force
}

# Synopsis: Update ReadTheDocs project documentation
task UpdateReadTheDocs -if {$Script:BuildEnv.OptionGenerateReadTheDocs} {
    Write-Description White 'Copy ReadTheDocs markdown files to project root document folder' -accent

    $BuildDocsPath = Join-Path $BuildRoot "$($Script:BuildEnv.BuildToolFolder)\docs\"
    $ProjectDocsPath = Join-Path $BuildRoot 'docs'
    $ReadTheDocsPath = Join-Path $BuildDocsPath 'ReadTheDocs'
    $DocsReleasePath = Join-Path $Script:BuildEnv.BaseReleaseFolder $Script:BuildEnv.ModuleToBuild

    $RTDFolders = Get-ChildItem -Path $ReadTheDocsPath -Directory | Sort-Object -Property Name

    ForEach ($RTDFolder in $RTDFolders) {
        # First copy over to our project document root
        Copy-Item -Path $RTDFolder.FullName -Destination $ProjectDocsPath -Force -Recurse
    }
}

# Synopsis: Build ReadTheDocs yml file
task CreateReadTheDocsYML -if {$Script:BuildEnv.OptionGenerateReadTheDocs} Configure, {
    Write-Description White 'Create ReadTheDocs definition file and saving to the root project site.' -accent

    $DocsReleasePath = Join-Path $Script:BuildEnv.BaseReleaseFolder $Script:BuildEnv.ModuleToBuild
    $ProjectDocsPath = Join-Path $BuildRoot 'docs'

    $YMLFile = Join-Path $BuildRoot 'mkdocs.yml'

    if (-not (Test-Path $YMLFile)) {
        $Pages = @()

        $RTDFolders = Get-ChildItem -Path $ProjectDocsPath -Directory | Sort-Object -Property Name
        $RTDPages = Get-ChildItem -Path $ProjectDocsPath -File -Filter '*.md' | Sort-Object -Property Name

        ForEach ($RTDPage in $RTDPages) {
            $Pages += @{$RTDPage.BaseName = $RTDPage.Name}
        }

        ForEach ($RTDFolder in $RTDFolders) {
            $RTDocs = @(Get-ChildItem -Path $RTDFolder.FullName -Filter '*.md' | Sort-Object Name)
            if ($RTDocs.Count -gt 1) {
                $NewSection = @()
                Foreach ($RTDDoc in $RTDocs) {
                    $NewSection += @{$RTDDoc.Basename = "$($RTDFolder.Name)/$($RTDDoc.Name)"}
                }
                $Pages += @{$RTDFolder.Name = $NewSection}
            }
            else {
                $Pages += @{$RTDFolder.Name = "$($RTDFolder.Name)/$($RTDocs.Name)"}
            }
        }

        $RTD = @{
            site_author = $Script:BuildEnv.ModuleAuthor
            site_name = "$($Script:BuildEnv.ModuleToBuild) Docs"
            repo_url = $Script:BuildEnv.ModuleWebsite
            use_directory_urls = $false
            theme = "readthedocs"
            copyright = "$($Script:BuildEnv.ModuleToBuild) is licensed under <a href='$($Script:BuildEnv.ModuleWebsite)/blob/master/License.md'>this</a> license"
            pages = $Pages
        }

        $RTD | ConvertTo-Yaml | Out-File -Encoding $Script:BuildEnv.Encoding -FilePath $YMLFile -Force
    }
    else {
        Write-Warning "Skipping ReadTheDocs manifest file creation as it already exists. Please remove the following file if you want it to be regenerated: $YMLFile"
    }
}

# Synopsis: Replace comment based help with external help in all public functions for this project
task UpdateCBH {
    Write-Description White 'Updating Comment Based Help in functions to point to external help links' -accent

    $ExternalHelp = @"
<#
        .EXTERNALHELP $($Script:BuildEnv.ModuleToBuild)-help.xml
        .LINK
            {{LINK}}
        #>
"@

    $ScratchPath = Join-Path $BuildRoot $Script:BuildEnv.ScratchFolder
    $CBHPattern = "(?ms)(\<`#.*\.SYNOPSIS.*?`#>)"
    Get-ChildItem -Path "$($ScratchPath)\$($Script:BuildEnv.PublicFunctionSource)\*.ps1" -File | ForEach-Object {
        $FormattedOutFile = $_.FullName
        $FileName = $_.Name
        Write-Description White "Replacing CBH in file: $($FileName)" -level 2
        $FunctionName = $FileName -replace '.ps1', ''
        $NewExternalHelp = $ExternalHelp -replace '{{LINK}}', ($Script:BuildEnv.ModuleWebsite + "/tree/master/$($Script:BuildEnv.BaseReleaseFolder)/$($Script:BuildEnv.ModuleVersion)/docs/$($FunctionName).md")
        $UpdatedFile = (get-content  $FormattedOutFile -raw) -replace $CBHPattern, $NewExternalHelp
        $UpdatedFile | Out-File -FilePath $FormattedOutFile -force -Encoding $Script:BuildEnv.Encoding
    }
}

# Synopsis: Update public functions to include a template comment based help.
task InsertCBHInPublicFunctions {
    Write-Description White "Attempting to insert comment based help into functions" -accent

    $ScratchPath = Join-Path $BuildRoot $Script:BuildEnv.ScratchFolder
    $CBHPattern = "(?ms)(^\s*\<`#.*\.SYNOPSIS.*?`#>)"
    $CBHUpdates = 0

    # Create the directories
    $null = New-Item (Join-Path $ScratchPath "src") -ItemType:Directory -Force
    $null = New-Item (Join-Path $ScratchPath $Script:BuildEnv.PublicFunctionSource) -ItemType:Directory -Force
    Get-ChildItem (Join-Path $BuildRoot $Script:BuildEnv.PublicFunctionSource) -Filter *.ps1 | ForEach-Object {
        $FileName = $_.Name
        $FullFilePath = $_.FullName
        Write-Description White "Public function - $($FileName)" -level 2
        $currscript = Get-Content $FullFilePath -Raw
        $CBH = $currscript | New-MBTCommentBasedHelp
        $currscriptblock = [scriptblock]::Create($currscript)
        . $currscriptblock
        if([string]::IsNullOrEmpty($CBH))
        {
            Write-Error "Could not Add CBH, possibly duo having no parameters in $filename" -ErrorAction Stop
        } else {
            $currfunct = get-command $CBH.FunctionName
            if ($currfunct.definition -notmatch $CBHPattern) {
                $CBHUpdates++
                Write-Description White "Inserting template CBH and writing to : $($Script:BuildEnv.ScratchFolder)\$($Script:BuildEnv.PublicFunctionSource)\$($FileName)" -Level 3
                $UpdatedFunct = 'Function ' + $currfunct.Name + ' {' + "`r`n" + $CBH.CBH + "`r`n" + $currfunct.definition + "`r`n" + '}'
                $UpdatedFunct | Out-File "$($ScratchPath)\$($Script:BuildEnv.PublicFunctionSource)\$($FileName)" -Encoding $Script:BuildEnv.Encoding -force
            }
            else {
                Write-Description Yellow 'Comment based help already exists!' -Level 2
            }
        }
        Remove-Item Function:\$($currfunct.Name)
    }
    Write-Build White ''
    Write-Build  Yellow '****************************************************************************************************'
    Write-Build  Yellow "  Updated Functions: $CBHUpdates"
    if ($CBHUpdates -gt 0) {
        Write-Build White ''
        Write-Build Yellow "  Updated Function Location: $($ScratchPath)\$($Script:BuildEnv.PublicFunctionSource)"
        Write-Build White ''
        Write-Build Yellow "  NOTE: Please inspect these files closely. If they look good merge them back into your project"
    }
    Write-Build  Yellow '****************************************************************************************************'
    $null = Read-Host 'Press Enter to continue...'
}

# Synopsis: Put together all the various project help files
task CreateProjectHelp BuildProjectHelpFiles, AddAdditionalDocFiles, UpdateReadTheDocs, CreateReadTheDocsYML

# Synopsis: Build help files for module
task CreateHelp CreateMarkdownHelp, CreateExternalHelp, CreateUpdateableHelpCAB, CreateProjectHelp, AddAdditionalDocFiles
#endregion

#region Prepair module release
# Synopsis: Assemble the module for release
task CreateModulePSM1 RemoveScriptSignatures, UpdateCBH, {
    Write-Description White "Assembling module psm1 file" -Accent
    $ScratchPath = Join-Path $BuildRoot $Script:BuildEnv.ScratchFolder
    $StageReleasePath = Join-Path $ScratchPath $Script:BuildEnv.BaseReleaseFolder
    $ReleaseModule = "$($StageReleasePath)\$($Script:BuildEnv.ModuleToBuild).psm1"

    if ($Script:BuildEnv.OptionCombineFiles) {
        Write-Description White "Option to combine PSM1 is enabled, combining source files now..." -Level 2

        $CombineFiles = ''
        $PreloadFilePath = (Join-Path $ScratchPath "$($Script:BuildEnv.OtherModuleSource)\PreLoad.ps1")
        if (Test-Path $PreloadFilePath) {
            Write-Description White 'Starting with Preload.ps1' -Level 3
            $CombineFiles += "## Pre-Loaded Module code ##`r`n`r`n"
            Get-childitem $PreloadFilePath | ForEach-Object {
                $CombineFiles += (Get-content $_ -Raw) + "`r`n`r`n"
            }
        }
        Write-Description White 'Adding the private source files:' -Level 3

        $CombineFiles += "## PRIVATE MODULE FUNCTIONS AND DATA ##`r`n`r`n"

        Get-childitem  (Join-Path $ScratchPath "$($Script:BuildEnv.PrivateFunctionSource)\*.ps1") | ForEach-Object {
            Write-Description White $_.Name -Level 4
            $CombineFiles += (Get-content $_ -Raw) + "`r`n`r`n"
        }

        Write-Description White 'Adding the public source files:' -Level 3

        $CombineFiles += "## PUBLIC MODULE FUNCTIONS AND DATA ##`r`n`r`n"
        Get-childitem  (Join-Path $ScratchPath "$($Script:BuildEnv.PublicFunctionSource)\*.ps1") | ForEach-Object {
            Write-Description White $_.Name -Level 4
            $CombineFiles += (Get-content $_ -Raw) + "`r`n`r`n"
        }

        Write-Description White 'Finishing with Postload.ps1' -Level 3
        $CombineFiles += "## Post-Load Module code ##`r`n`r`n"
        $PostLoadPath = (Join-Path $ScratchPath "$($Script:BuildEnv.OtherModuleSource)\PostLoad.ps1")
        if (Test-Path $PostLoadPath) {
            Get-childitem  $PostLoadPath | ForEach-Object {
                $CombineFiles += (Get-content $_ -Raw) + "`r`n`r`n"
            }
        }

        Set-Content -Path $ReleaseModule -Value $CombineFiles -Encoding $Script:BuildEnv.Encoding
    }
    else {
        Write-Description White 'Option to combine PSM1 is NOT enabled, copying over file structure now...' -Level 2
        Copy-Item -Path (Join-Path $ScratchPath $Script:BuildEnv.OtherModuleSource) -Recurse -Destination $StageReleasePath -Force
        Copy-Item -Path (Join-Path $ScratchPath $Script:BuildEnv.PrivateFunctionSource) -Recurse -Destination $StageReleasePath -Force
        Copy-Item -Path (Join-Path $ScratchPath $Script:BuildEnv.PublicFunctionSource) -Recurse -Destination $StageReleasePath -Force
        Copy-Item -Path (Join-Path $ScratchPath $Script:BuildEnv.ModuleToBuild) -Destination $StageReleasePath -Force
    }

    if (($Script:BuildEnv.AdditionalModulePaths).Count -gt 0) {
        Write-Description White 'Copying over additional module paths now (if they exist).' -Level 2
        $Script:BuildEnv.AdditionalModulePaths | ForEach-Object {
            if (Test-Path $_) {
                Write-Description White "Copying $_" -Level 3
                Copy-Item -Path $_ -Recurse -Destination $StageReleasePath -Force
            }
        }
    }
}
# Synopsis: Create new module manifest with explicit function exports included
task CreateModuleManifest CreateModulePSM1, {
    Write-Description White 'Module manifest file updates' -accent
    $ModuleManifestFullPath = Join-Path $BuildRoot "$($Script:BuildEnv.ModuleToBuild).psd1"
    $StageReleasePath = Join-Path (Join-Path $BuildRoot $Script:BuildEnv.ScratchFolder) $Script:BuildEnv.BaseReleaseFolder

    $PSD1OutputFile = Join-Path $StageReleasePath "$($Script:BuildEnv.ModuleToBuild).psd1"
    $ThisPSD1OutputFile = "$BuildRoot\$($Script:BuildEnv.ScratchFolder)\$($Script:BuildEnv.BaseReleaseFolder)\$($Script:BuildEnv.ModuleToBuild).psd1"
    Write-Description White "Attempting to update the release module manifest file:  $ThisPSD1OutputFile" -Level 2
    $null = Copy-Item -Path $ModuleManifestFullPath -Destination $PSD1OutputFile -Force
    Update-ModuleManifest -Path $PSD1OutputFile -FunctionsToExport $Script:FunctionsToExport
}
# Synopsis: Run PSScriptAnalyzer against the assembled module
task AnalyzeModuleRelease -if {$Script:BuildEnv.OptionAnalyzeCode} {
    Write-Description White 'Analyzing the project with ScriptAnalyzer' -accent
    $StageReleasePath = Join-Path (Join-Path $BuildRoot $Script:BuildEnv.ScratchFolder) $Script:BuildEnv.BaseReleaseFolder
    $Analysis = Invoke-ScriptAnalyzer -Path $StageReleasePath -Settings (Join-Path $BuildRoot "PSScriptAnalyzerSettings.psd1")
    if ($Analysis.Count) {
        Write-Description White "Note that this was from the script analysis run against $StageReleasePath" -level 2
        Write-Description Red "$($Analysis.Count) linting errors or warnings were found:" -level 2
        $Analysis | Format-Table -AutoSize
        Write-Error "$($Analysis.Count) linting errors or warnings were found. The build cannot continue." -ErrorAction Stop
    }
}
# Synopsis: Create a new version release directory for our release and copy our contents to it
task PushVersionRelease {
    Write-Description White "Attempting to push a version release of the module" -accent

    $ReleasePath = Join-Path $BuildRoot $Script:BuildEnv.BaseReleaseFolder
    $ThisReleasePath = Join-Path $ReleasePath $Script:BuildEnv.ModuleVersion
    $ThisBuildReleasePath = ".\$($Script:BuildEnv.BaseReleaseFolder)\$($Script:BuildEnv.ModuleVersion)"
    $StageReleasePath = Join-Path (Join-Path $BuildRoot $Script:BuildEnv.ScratchFolder) $Script:BuildEnv.BaseReleaseFolder

    $null = Remove-Item $ThisReleasePath -Force -Recurse -ErrorAction 0
    $null = New-Item $ThisReleasePath -ItemType:Directory -Force
    Copy-Item -Path "$($StageReleasePath)\*" -Destination $ThisReleasePath -Recurse
    #Out-MBTZip $StageReleasePath (Join-Path $ReleasePath "$($Script:BuildEnv.ModuleToBuild)-$($Script:BuildEnv.ModuleVersion).zip") -overwrite
}
# Synopsis: Create the current release directory and copy this build to it.
task PushCurrentRelease {
    Write-Description White "Attempting to push a current release of the module" -accent

    $ReleasePath = Join-Path $BuildRoot $Script:BuildEnv.BaseReleaseFolder
    $CurrentReleasePath = Join-Path $ReleasePath $Script:BuildEnv.ModuleToBuild
    $ThisBuildCurrentReleasePath = ".\$($Script:BuildEnv.BaseReleaseFolder)\$($Script:BuildEnv.ModuleToBuild)"
    $StageReleasePath = Join-Path (Join-Path $BuildRoot $Script:BuildEnv.ScratchFolder) $Script:BuildEnv.BaseReleaseFolder

    $MostRecentRelease = (Get-ChildItem $ReleasePath -Directory | Where-Object {$_.Name -like "*.*.*"} | Select-Object Name).name | ForEach-Object {[version]$_} | Sort-Object -Descending | Select-Object -First 1
    $ProcessCurrentRelease = $true
    if ($MostRecentRelease) {
        if ($MostRecentRelease -gt [version]$Script:BuildEnv.ModuleVersion) {
            $ProcessCurrentRelease = $false
        }
    }
    if ($ProcessCurrentRelease -or $Force -or $Script:BuildEnv.Force) {
        Write-Description White "Pushing a version release to $($ThisBuildCurrentReleasePath)" -level 2
        $null = Remove-Item $CurrentReleasePath -Force -Recurse -ErrorAction 0
        $null = New-Item $CurrentReleasePath -ItemType:Directory -Force
        Copy-Item -Path "$($StageReleasePath)\*" -Destination $CurrentReleasePath -Recurse -force
        Out-MBTZip $StageReleasePath "$ReleasePath\$($Script:BuildEnv.ModuleToBuild)-current.zip" -overwrite
    }
    else {
        Write-Warning 'Unable to push this version as a current release as it is not the most recent version in the release directory! Re-run this task with the -Force flag to overwrite it.'
    }
}
#endregion

#region Postbuild PSGallery and Version management
# Synopsis: Run post-build scripts (such as file transformations or deployments)
task PostBuildTasks {
    Write-Description White 'Running any Post-Build scripts' -accent
    $BuildToolPath = Join-Path $BuildRoot $Script:BuildEnv.BuildToolFolder
    $CleanupPath = Join-Path $BuildToolPath 'shutdown'
    # Dot source any post build cleanup scripts.
    Get-ChildItem -Path $CleanupPath -Recurse -Filter "*.ps1" -File | Foreach {
        Write-Description White "Dot sourcing shutdown script file: $($_.Name)" -Level 3
        . $_.FullName
    }
}

# Synopsis: Install the current built module to the local machine
task InstallModule VersionCheck, {
    Write-Description White "Attempting to install the current module" -accent
    $CurrentModulePath = Join-Path $Script:BuildEnv.BaseReleaseFolder $Script:BuildEnv.ModuleVersion
    assert (Test-Path $CurrentModulePath) 'The current version module has not been built yet!'

    $MyModulePath = "$((Get-MBTSpecialPath)['MyDocuments'])\WindowsPowerShell\Modules\"
    $ModuleInstallPath = "$($MyModulePath)$($Script:BuildEnv.ModuleToBuild)"
    if (Test-Path $ModuleInstallPath) {
        Write-Description White "Removing installed module $($Script:BuildEnv.ModuleToBuild)" -Level 2
        if ($Force -or $Script:BuildEnv.ForceInstallModule) {
            Remove-Item -Path $ModuleInstallPath -Force -Recurse
        }
        else {
            Remove-Item -Path $ModuleInstallPath -Confirm -Recurse
        }
        assert (-not (Test-Path $ModuleInstallPath)) 'Module already installed and you opted not to remove it. Cancelling install operation!'
    }

    Write-Description White "Installing current module:" -Level 2
    Write-Description White "Source - $($CurrentModulePath)" -Level 3
    Write-Description White "Destination - $($ModuleInstallPath)" -Level 3
    Copy-Item -Path $CurrentModulePath -Destination $ModuleInstallPath -Recurse
}

# Synopsis: Test import the current module
task TestImportInstalledModule VersionCheck, {
    Write-Description White "Test importing the current module version $($Script:BuildEnv.ModuleVersion)" -accent

    $InstalledModules = @(Get-Module -ListAvailable $Script:BuildEnv.ModuleToBuild)
    assert ($InstalledModules.Count -gt 0) 'Unable to find that the module is installed!'
    if ($InstalledModules.Count -gt 1) {
        Write-Warning 'There are multiple installed modules found for this project (shown below). Be aware that this may skew the test results: '
    }
    Import-Module -Name $Script:BuildEnv.ModuleToBuild -MinimumVersion $Script:BuildEnv.ModuleVersion -Force
}

# Synopsis: Push the current release of the project to PSScriptGallery
task PublishPSGallery LoadRequiredModules, InstallModule, {
    Write-Description White 'Publishing recent module release to the PowerShell Gallery' -accent

    $ReleasePath = Join-Path $BuildRoot $Script:BuildEnv.BaseReleaseFolder
    $CurrentReleasePath = Join-Path $ReleasePath $Script:BuildEnv.ModuleToBuild
    if (Get-Module $Script:BuildEnv.ModuleToBuild) {
        Write-Description White "This module is already installed $($Script:BuildEnv.ModuleToBuild). Removing it" -Level 2
        Write-Verbose "$($(Get-Module $Script:BuildEnv.ModuleToBuild).Path)"
        Get-Module $Script:BuildEnv.ModuleToBuild | ForEach-Object {
            Remove-Module $_.Name
        }
    }

    # Try to import the current module
    $CurrentModule = Join-Path $CurrentReleasePath "$($Script:BuildEnv.ModuleToBuild).psd1"
    if (Test-Path $CurrentModule) {
        Import-Module -Name $CurrentModule

        Write-Description White "Uploading project to PSGallery: $($Script:BuildEnv.ModuleToBuild)"
        Publish-MBTProjectToPSGallery -Name $Script:BuildEnv.ModuleToBuild -NuGetApiKey $Script:BuildEnv.NuGetApiKey -RequiredVersion $Script:BuildEnv.ModuleVersion
    }

    else {
        Write-Warning "Unable to publish the module as a current release is not available in $CurrentModule"
    }
}

# Synopsis: Set a new version of the module
task NewVersion LoadRequiredModules, LoadModuleManifest, {
    Write-Description White 'Updating module build version' -accent
    $ModuleManifestFullPath = Join-Path $BuildRoot "$($Script:BuildEnv.ModuleToBuild).psd1"
    $ReleasePath = Join-Path $BuildRoot $Script:BuildEnv.BaseReleaseFolder
    $AllReleases = @((Get-ChildItem $ReleasePath -Directory | Where-Object {$_.Name -match '^([0-9].[0-9].[0-9])$'} | Select-Object).Name | ForEach-Object {[version]$_})

    # if a new version wasn't passed as a parameter then prompt for one
    if ($null -eq $NewVersion) {
        do {
            $NewVersion = Read-Host -Prompt 'Enter the version (ie 0.0.8) for your build release'
            if ([string]::IsNullOrEmpty($NewVersion)) {
                Write-Build Red "You need to enter a valid module version (ie. 1.2.0)" -level 2
            }
        } while ( [string]::IsNullOrEmpty($NewVersion) -and ($NewVersion -notmatch '\d+\.\d+\.\d+') )
    }
    if ($AllReleases -contains $NewVersion) {
        if ((-not $Force) -and (-not $Script:BuildEnv.Force)) {
            throw 'The module version already has been released (the folder exists within the releases folder. In order to set your build project to this version you will need to pass the -Force switch to this build script with the -NewVersion parameter'
        }
    }

    $Script:BuildEnv.ModuleVersion = $NewVersion.ToString()

    Write-Description White 'Saving persistent build file with new module version' -level 2
    Save-BuildData

    Write-Description White 'Updating module manifest with new module version' -level 2
    try {
        Update-ModuleManifest -Path $ModuleManifestFullPath -ModuleVersion $NewVersion
    }
    catch {
        throw $_
    }
}

# Synopsis: Update current module manifest with the version defined in the build config file (if they differ)
task UpdateRelease NewVersion, LoadRequiredModules, LoadModuleManifest, {
    Write-Description White 'Updating the release notes of this module' -accent

    $ModuleManifestFullPath = Join-Path $BuildRoot "$($Script:BuildEnv.ModuleToBuild).psd1"
    # If there is a version mismatch then we need to put in some release notes and update the module manifest
    if ($null -eq $ReleaseNotes) {
        do {
            $ReleaseNotes = Read-Host -Prompt 'Enter brief release notes for this new version'
            if ([string]::IsNullOrEmpty($ReleaseNotes)) {
                Write-Build Red "You need to enter some kind of notes for your new release to update the manifest with!" -level 2
            }
        } while ([string]::IsNullOrEmpty($ReleaseNotes))
    }

    try {
        Update-ModuleManifest -Path $ModuleManifestFullPath -ReleaseNotes $ReleaseNotes
    }
    catch {
        throw $_
    }
}

# Synopsis: Update the current build patch version
task AutoIncreaseVersionBuildLevel -after PublishPSGallery -if {$Script:BuildEnv.OptionUpdateVersionAfterPublishing} {
    Write-Description White 'Attempting to update the module build version' -accent

    $ModuleManifestFullPath = Join-Path $BuildRoot "$($Script:BuildEnv.ModuleToBuild).psd1"
    $ReleasePath = Join-Path $BuildRoot $Script:BuildEnv.BaseReleaseFolder
    $AllReleases = @((Get-ChildItem $ReleasePath -Directory | Where-Object {$_.Name -match '^([0-9].[0-9].[0-9])$'} | Select-Object).Name | ForEach-Object {[version]$_})

    $NewestRelease = $AllReleases | Sort-Object -Descending | Select-Object -First 1
    $ProposedNewRelease = [version]("$($NewestRelease.Major).$($NewestRelease.Minor).$($NewestRelease.Build + 1)")

    $Script:BuildEnv.ModuleVersion = $ProposedNewRelease.ToString()

    Write-Description White 'Saving persistent build file with new module version' -level 2
    Save-BuildData

    $NewReleaseNotes = "$($ProposedNewRelease.ToString()) release"

    Write-Description White 'Updating module manifest with new module version' -level 2
    try {
        Update-ModuleManifest -Path $ModuleManifestFullPath -ModuleVersion $ProposedNewRelease -ReleaseNotes $NewReleaseNotes
    }
    catch {
        throw $_
    }

    Write-Description Green "Module build version has been updated to $($ProposedNewRelease.ToString())" -level 2
}

# Synopsis: Push to github
task GithubPush VersionCheck, {
    exec { git add . }
    if ($ReleaseNotes -ne $null) {
        exec { git commit -m "$ReleaseNotes"}
    }
    else {
        exec { git commit -m "$($Script:BuildEnv.ModuleVersion)"}
    }
    exec { git push origin master }
    $changes = exec { git status --short }
    assert (-not $changes) "Please, commit changes."
}

# Synopsis: Push with a version tag.
task GitPushRelease VersionCheck, {
    $changes = exec { git status --short }
    assert (-not $changes) "Please, commit changes."

    exec { git push }
    exec { git tag -a "v$($Script:BuildEnv.ModuleVersion)" -m "v$($Script:BuildEnv.ModuleVersion)" }
    exec { git push origin "v$($Script:BuildEnv.ModuleVersion)" }
}
#endregion

#region Cleanup
# Synopsis: Regenerate scratch staging directory
task CleanScratchDirectory {
    Write-Description White "Clean up our scratch/staging directory $($Script:BuildEnv.ScratchFolder)" -accent

    $ScratchPath = Join-Path $BuildRoot $Script:BuildEnv.ScratchFolder
    $null = Remove-Item $ScratchPath -Force -Recurse -ErrorAction 0
    $null = New-Item $ScratchPath -ItemType:Directory -Force
}

# Synopsis: Remove session artifacts like loaded modules and variables
task BuildSessionCleanup CleanScratchDirectory, {
    Write-Description White 'Cleaning up the build session' -accent

    Write-Description White "Removing $($Script:BuildEnv.ModuleToBuild) module (if loaded)." -Level 3
    Remove-Module $Script:BuildEnv.ModuleToBuild -Erroraction Ignore

    $Script:PSDependBuildModules | Foreach-Object {
        Write-Description White "Removing $($_.DependencyName) module (if loaded)." -Level 3
        Remove-Module $_ -Erroraction Ignore -Force
    }

    if ($Script:BuildEnv.OptionTranscriptEnabled) {
        Stop-Transcript -WarningAction:Ignore
    }
}
#endregion

#region Main tasks
# Synopsis: Run all tests
task Tests RunMetaTests, RunUnitTests, RunIntergrationTests, {

}
# Synopsis: Build the module
task Build Configure, CodeHealthReport, PrepareStage, GetPublicFunctions, SanitizeCode, CreateHelp, CreateModulePSM1, CreateModuleManifest, AnalyzeModuleRelease, PushVersionRelease, PushCurrentRelease, CreateProjectHelp, PostBuildTasks, BuildSessionCleanup, {

}

# Synopsis: Test, Build, install and Test load the module.
task TestBuildAndInstallModule Tests, Build, InstallModule, TestImportInstalledModule, BuildSessionCleanup, {

}

# Synopsis: Test, Build, Install, Test load and Publish the module
task BuildInstallTestAndPublishModule TestBuildAndInstallModule, PublishPSGallery, BuildSessionCleanup, {

}

# Synopsis: Insert Comment Based Help where it doesn't already exist (output to scratch directory)
task AddMissingCBH Configure, CleanScratchDirectory, InsertCBHInPublicFunctions, BuildSessionCleanup, {

}

# Synopsis: Default task when running Invoke-Build
task . Build
#endregion



