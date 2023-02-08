@{
    PSDependOptions = @{
        Target = '$DependencyFolder'
        AddToPath = $True
    }
    PSScriptAnalyzer = @{
        version = '1.18.3'
        source = 'PSGalleryModule'
    }
    PlatyPS = @{
        version = '0.14.0'
        source = 'PSGalleryModule'
    }
    'Powershell-YAML' = @{
        version = '0.4.1'
        source = 'PSGalleryModule'
    }
    PSCodeHealth = @{
        version = '0.2.26'
        source = 'PSGalleryModule'
    }
    ModuleBuildTools = @{
        version = '0.0.1'
        source = 'PSGalleryModule'
    }
}