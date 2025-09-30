<#
.SYNOPSIS
    Core PowerShell Module Generator
    
.DESCRIPTION
    Creates PowerShell modules from parsed OpenAPI specifications.
    This is the core generation engine that creates the actual module files.
#>

function New-PowerShellModule {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Name,
        
        [Parameter(Mandatory = $true)]
        [string]$Path,
        
        [Parameter(Mandatory = $true)]
        [object]$OpenAPISpec,
        
        [Parameter()]
        [string]$BaseUri,
        
        [Parameter()]
        [string[]]$Enhancements = @('All'),
        
        [Parameter()]
        [bool]$GenerateReadme = $false
    )
    
    Write-Verbose "Starting module generation for: $Name"
    
    # Create module directory structure
    $moduleDir = $Path
    $functionsDir = Join-Path $moduleDir "Functions"
    $classesDir = Join-Path $moduleDir "Classes"
    
    New-Item -Path $functionsDir -ItemType Directory -Force | Out-Null
    New-Item -Path $classesDir -ItemType Directory -Force | Out-Null
    
    # Get API info
    $apiInfo = Get-OpenAPIInfo -Specification $OpenAPISpec
    $paths = Get-OpenAPIPaths -Specification $OpenAPISpec
    $definitions = Get-OpenAPIDefinitions -Specification $OpenAPISpec
    
    $generatedFunctions = @()
    $exportedFunctions = @()
    
    # Generate functions for each path/operation
    foreach ($pathKey in $paths.PSObject.Properties.Name) {
        $pathItem = $paths.$pathKey
        
        foreach ($method in @('get', 'post', 'put', 'patch', 'delete', 'options', 'head')) {
            if ($pathItem.PSObject.Properties.Name -contains $method) {
                $operation = $pathItem.$method
                
                # Generate function name
                $functionName = Get-PowerShellFunctionName -Method $method -Path $pathKey -Operation $operation
                
                # Generate function content
                $functionContent = New-PowerShellFunction -Name $functionName -Method $method -Path $pathKey -Operation $operation -BaseUri $BaseUri
                
                # Save function to file
                $functionFile = Join-Path $functionsDir "$functionName.ps1"
                $functionContent | Out-File -FilePath $functionFile -Encoding UTF8
                
                $generatedFunctions += $functionName
                $exportedFunctions += $functionName
                
                Write-Verbose "Generated function: $functionName"
            }
        }
    }
    
    # Generate module manifest (.psd1)
    $manifestContent = New-ModuleManifest -Name $Name -Functions $exportedFunctions -ApiInfo $apiInfo
    $manifestFile = Join-Path $moduleDir "$Name.psd1"
    $manifestContent | Out-File -FilePath $manifestFile -Encoding UTF8
    
    # Generate main module file (.psm1)
    $moduleContent = New-ModuleFile -Name $Name -Functions $exportedFunctions
    $moduleFile = Join-Path $moduleDir "$Name.psm1"
    $moduleContent | Out-File -FilePath $moduleFile -Encoding UTF8
    
    Write-Verbose "Module generation completed: $($generatedFunctions.Count) functions generated"
    
    return @{
        Name = $Name
        Path = $moduleDir
        Functions = $generatedFunctions
        ManifestFile = $manifestFile
        ModuleFile = $moduleFile
    }
}

function Get-PowerShellFunctionName {
    [CmdletBinding()]
    param(
        [string]$Method,
        [string]$Path,
        [object]$Operation
    )
    
    # Use enhanced verb mapping if available
    if (Get-Command Get-EnhancedPowerShellVerbForHttpMethod -ErrorAction SilentlyContinue) {
        return Get-EnhancedPowerShellVerbForHttpMethod -Method $Method -Path $Path -OperationId $Operation.operationId -Operation $Operation
    }
    
    # Fallback to basic mapping
    $verb = switch ($Method.ToUpper()) {
        'GET' { 'Get' }
        'POST' { 'New' }
        'PUT' { 'Set' }
        'PATCH' { 'Update' }
        'DELETE' { 'Remove' }
        default { 'Invoke' }
    }
    
    # Extract noun from path or operationId
    $noun = if ($Operation.operationId) {
        ConvertTo-PascalCase $Operation.operationId
    } else {
        $pathSegments = ($Path -split '/' | Where-Object { $_ -and $_ -notmatch '^\{.*\}$' })
        if ($pathSegments.Count -gt 0) {
            ConvertTo-PascalCase $pathSegments[-1]
        } else {
            'Resource'
        }
    }
    
    return "$verb-$noun"
}

function New-PowerShellFunction {
    [CmdletBinding()]
    param(
        [string]$Name,
        [string]$Method,
        [string]$Path,
        [object]$Operation,
        [string]$BaseUri
    )
    
    $summary = $Operation.summary ?? "Executes $Method $Path"
    $description = $Operation.description ?? $summary
    
    return @"
<#
.SYNOPSIS
    $summary

.DESCRIPTION
    $description

.PARAMETER BaseUri
    The base URI for the API

.EXAMPLE
    $Name -BaseUri "https://api.example.com"

.NOTES
    Generated from OpenAPI specification
    Method: $($Method.ToUpper())
    Path: $Path
#>
function $Name {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = `$true)]
        [string]`$BaseUri
    )
    
    `$uri = "`$BaseUri$Path"
    
    try {
        `$response = Invoke-RestMethod -Uri `$uri -Method $($Method.ToUpper()) -ContentType 'application/json'
        return `$response
    }
    catch {
        Write-Error "API call failed: `$(`$_.Exception.Message)"
    }
}
"@
}

function New-ModuleManifest {
    [CmdletBinding()]
    param(
        [string]$Name,
        [string[]]$Functions,
        [object]$ApiInfo
    )
    
    $guid = New-PowerShellGuid
    $version = $ApiInfo.version ?? "1.0.0"
    $description = $ApiInfo.description ?? "PowerShell module generated from OpenAPI specification"
    
    $functionList = if ($Functions.Count -gt 0) {
        $Functions | ForEach-Object { "'$_'" } | Join-String ', '
    } else {
        "''"
    }
    
    return @"
@{
    RootModule = '$Name.psm1'
    ModuleVersion = '$version'
    GUID = '$guid'
    Author = 'PowerShell OpenAPI Wrapper Generator'
    Description = '$description'
    PowerShellVersion = '5.1'
    FunctionsToExport = @($functionList)
    CmdletsToExport = @()
    VariablesToExport = @()
    AliasesToExport = @()
    PrivateData = @{
        PSData = @{
            Tags = @('API', 'REST', 'OpenAPI', 'Swagger')
            ReleaseNotes = 'Generated from OpenAPI specification'
        }
    }
}
"@
}

function New-ModuleFile {
    [CmdletBinding()]
    param(
        [string]$Name,
        [string[]]$Functions
    )
    
    $functionList = if ($Functions.Count -gt 0) {
        $Functions | ForEach-Object { "'$_'" } | Join-String ', '
    } else {
        "''"
    }
    
    return @"
# $Name PowerShell Module
# Generated from OpenAPI specification

# Import all functions
`$functionPath = Join-Path `$PSScriptRoot 'Functions'
if (Test-Path `$functionPath) {
    Get-ChildItem `$functionPath -Filter '*.ps1' | ForEach-Object {
        . `$_.FullName
    }
}

# Export module members
Export-ModuleMember -Function @($functionList)
"@
}