param (
    [Parameter(HelpMessage = 'If you are initializing this file or want to force overwrite the persistent export data use this flag.')]
    [switch]$ForcePersist
)
<#
 Update $Script:BuildEnv to suit your PowerShell module build. If you make sufficient changes to your build environment json file (via the module commands or otherwise) you should update this as well so those that inherit your project in the future are able to rebuild it from scratch.
#>

# If the variable is already defined then essentially do nothing.
# Otherwise we create a baseline variable first in case this is a first time run, then
# check for an exported .xml file with persistent settings for any run thereafter
if ((Get-Variable 'BuildEnv' -ErrorAction:SilentlyContinue) -eq $null) {
    $Script:BuildEnv = New-Object -TypeName PSObject -Property @{
        FirstRun = $True
        Force = $False
        ForceInstallModule = $False
        Encoding = 'utf8'
        ModuleToBuild = 'ADChecks'
        ModuleVersion = '0.0.1'
        ModuleWebsite = 'https://github.com/ocd-nl/ADChecks'
        ModuleCopyright = "(c) $((get-date).Year.ToString()) Justin Perdok. All rights reserved."
        ModuleLicenseURI = 'https://github.com/ocd-nl/ADChecks/LICENSE.md'
        ModuleTags = 'ActiveDirectory' -split ','
        ModuleAuthor = 'Justin Perdok'
        ModuleDescription = 'PowerShell module to check the security of Active Directory'

        # Options - These affect how your build will be run.
        OptionAnalyzeCode = $True
        OptionCodeHealthReport = $false
        OptionCombineFiles = $TRUE
        OptionTranscriptEnabled = $false
        OptionTranscriptLogFile = 'BuildTranscript.Log'

        # PlatyPS has been the cause of most of my build failures. This can help you isolate which function's CBH is causing you grief.
        OptionRunPlatyPSVerbose = $false

        # If you want to prescan and fail a build upon finding any proprietary strings
        # enable this option and define some strings.
        OptionSanitizeSensitiveTerms = $True
        OptionSensitiveTerms = @($env:username, $env:userdomain, $env:userdnsdomain) | Where {$null -ne $_}
        OptionSensitiveTermsInitialized = $false

        # If you want to update your current module build version automatically
        # after a successful psgallery publish set this to $true
        OptionUpdateVersionAfterPublishing = $False

        # Additional paths in the source module which should be copied over to the final build release
        AdditionalModulePaths = @('plugins')

        # Generate a yml file in the root folder of this project for readthedocs.org integration
        OptionGenerateReadTheDocs = $False
        # Most of the following options you probably don't need to change
        BaseSourceFolder = 'src'               # Base source path
        PublicFunctionSource = "src\public"    # Public functions (to be exported by file name as the function name)
        PrivateFunctionSource = "src\private"  # Private function source.
        OtherModuleSource = "src\other"        # Other module source.
        BaseReleaseFolder = 'release'          # Releases directory.
        BuildToolFolder = 'build'              # Build tool path.
        BuildReportsFolder = 'build\reports'   # Location where PSCodeHealth stores its reports.
        ScratchFolder = 'temp'                 # Scratch path - this is where all our scratch work occurs. It will be cleared out at every run.
        FunctionTemplates = "src\templates"    # Location of function template files (*.tem)

        # If you will be publishing to the PowerShell Gallery you will need a Nuget API key (can get from the website)
        # You should NOT enter this key here but rather manually enter it in the ADChecks.buildenvironment.json file with: Set-MBBuildEnvironment -NugetAPIKey '<key>'

        NugetAPIKey  = ''
    }

    ########################################
    # !! Please leave anything below this line alone !!
    ########################################
    $PersistentBuildFile = join-path $PSScriptRoot "ADChecks.buildenvironment.json"

    # Load any persistent data (overrides anything in BuildEnv if the hash element exists)
    if ((Test-Path $PersistentBuildFile)) {
        try {
            $LoadedBuildEnv = Get-Content $PersistentBuildFile | ConvertFrom-Json
        }
        catch {
            throw "Unable to load $PersistentBuildFile"
        }
        $BaseSettings = ($Script:BuildEnv | Get-Member -Type 'NoteProperty').Name
        $BuildSettings = ($LoadedBuildEnv | Get-Member -Type 'NoteProperty').Name
        ForEach ($Key in $BuildSettings) {
            if ($BaseSettings -contains $Key) {
                Write-Verbose "Updating profile setting '$key' from $PersistentBuildFile"
                ($Script:BuildEnv).$Key = $LoadedBuildEnv.$Key
            }
            else {
                Write-Verbose "Adding profile setting '$key' from $PersistentBuildFile"
                Add-Member -InputObject $Script:BuildEnv -MemberType 'NoteProperty' -Name $Key -Value $LoadedBuildEnv.$Key
            }
        }

        # Look for any settings in the base settings that are not in the saved configuration and
        # force a persist if found.
        ForEach ($BaseSetting in $BaseSettings) {
            if ($BuildSettings -notcontains $BaseSetting) {
                Write-Verbose "  Base setting to be added to json configuration file: $BaseSetting"
                $BuildExport = $True
            }
        }
    }
    else {
        # No persistent file was found so we are going to create one
        $BuildExport = $True
    }

    # We create this helper function here as a quasi private function which can be used without loading the modulebuild module
    function Script:Save-BuildData {
        $Script:BuildEnv | ConvertTo-Json | Out-File -FilePath $PersistentBuildFile -Encoding $Script:BuildEnv.Encoding -Force
    }

    # If we don't have a persistent file, we are forcing a persist, or properties were not the same between
    # the loaded json and our defined BuildEnv file then push a new persistent file export.
    if ((-not (Test-path $PersistentBuildFile)) -or $BuildExport -or $ForcePersist -or ($Script:BuildEnv.FirstRun)) {
        $Script:BuildEnv.FirstRun = $false
        Write-Verbose "Exporting the BuildEnv data!"
        $Script:BuildEnv | ConvertTo-Json | Out-File -FilePath $PersistentBuildFile -Encoding $Script:BuildEnv.Encoding -Force
    }
}
