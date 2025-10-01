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
        
        [Parameter()]
        [string]$BaseUri,
        
        [Parameter()]
        [string[]]$Enhancements = @(),
        
        [Parameter(Mandatory = $true)]
        [object]$OpenAPISpec,
        
        [Parameter()]
        [bool]$GenerateReadme = $false
    )
    
    Write-Verbose "Generating PowerShell module: $Name"
    Write-Verbose "Output path: $Path"
    Write-Verbose "Enhancements: $($Enhancements -join ', ')"
    
    # Parse the OpenAPI specification using the core parser
    if ($OpenAPISpec -is [string] -and (Test-Path $OpenAPISpec)) {
        $spec = Import-OpenAPISpecification -Path $OpenAPISpec
    } else {
        # Assume it's already a parsed spec, but ensure it's properly processed
        $spec = $OpenAPISpec
        
        # Check if it needs processing (works for both hashtables and PSObjects)
        $needsProcessing = $false
        if ($spec -is [hashtable]) {
            $needsProcessing = -not $spec.ContainsKey('_resolvedDefinitions')
        } else {
            $needsProcessing = -not (Get-Member -InputObject $spec -Name '_resolvedDefinitions' -ErrorAction SilentlyContinue)
        }
        
        if ($needsProcessing) {
            # Convert hashtable to PSCustomObject first if needed
            if ($spec -is [hashtable]) {
                $spec = Convert-HashtableToPSObject $spec
            }
            $spec = Resolve-OpenAPISpecification -Specification $spec
        }
    }
    
    # Get API information
    $apiInfo = Get-OpenAPIInfo -Specification $spec
    $paths = Get-OpenAPIPaths -Specification $spec
    $definitions = Get-OpenAPIDefinitions -Specification $spec
    
    # Generate functions for each path/operation
    $functions = @()
    $functionContent = @()
    
    # Handle both PSObject and hashtable for paths iteration
    $pathKeys = if ($paths -is [hashtable]) { $paths.Keys } else { $paths.PSObject.Properties.Name }
    
    foreach ($pathKey in $pathKeys) {
        $pathItem = $paths[$pathKey]
        
        # Handle both PSObject and hashtable for methods iteration
        $methodKeys = if ($pathItem -is [hashtable]) { $pathItem.Keys } else { $pathItem.PSObject.Properties.Name }
        
        foreach ($methodKey in $methodKeys) {
            if ($methodKey -in @('get', 'post', 'put', 'patch', 'delete', 'head', 'options')) {
                $operation = if ($pathItem -is [hashtable]) { $pathItem[$methodKey] } else { $pathItem.$methodKey }
                
                # Generate function for this operation using simplified approach
                $functionInfo = New-SimpleOperationFunction -Path $pathKey -Method $methodKey -Operation $operation -Definitions $definitions -Enhancements $Enhancements
                
                if ($functionInfo) {
                    $functions += $functionInfo.Name
                    $functionContent += $functionInfo.Content
                }
            }
        }
    }
    
    # Create the module structure
    New-Item -Path $Path -ItemType Directory -Force | Out-Null
    
    # Generate module files
    $moduleFiles = New-ModuleFiles -Name $Name -Path $Path -Functions $functions -FunctionContent $functionContent -ApiInfo $apiInfo -BaseUri $BaseUri
    
    # Return generation results
    return @{
        ModulePath = $Path
        Functions = $functions
        Files = $moduleFiles
        ApiInfo = $apiInfo
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

function New-SimpleOperationFunction {
    [CmdletBinding()]
    param(
        [string]$Path,
        [string]$Method,
        [object]$Operation,
        [hashtable]$Definitions = @{},
        [string[]]$Enhancements = @()
    )
    
    # Generate PowerShell verb from HTTP method
    $verb = switch ($Method.ToUpper()) {
        'GET' { 'Get' }
        'POST' { 'New' }
        'PUT' { 'Set' }
        'DELETE' { 'Remove' }
        'PATCH' { 'Update' }
        default { 'Invoke' }
    }
    
    # Get operation details with safe property access
    $operationId = if ($Operation -is [hashtable]) { $Operation['operationId'] } else { $Operation.operationId }
    $summary = if ($Operation -is [hashtable]) { $Operation['summary'] } else { $Operation.summary }
    $description = if ($Operation -is [hashtable]) { $Operation['description'] } else { $Operation.description }
    
    # Generate function name
    if ($operationId) {
        $noun = $operationId -replace "^$Method", '' -replace '[^a-zA-Z0-9]', ''
        if (-not $noun) { $noun = 'Resource' }
        $functionName = "$verb-$noun"
    } else {
        $pathParts = $Path -split '/' | Where-Object { $_ -and $_ -notmatch '^\{' }
        $noun = ($pathParts | Select-Object -Last 1) -replace '[^a-zA-Z0-9]', ''
        if (-not $noun) { $noun = 'Resource' }
        $functionName = "$verb-$noun"
    }
    
    $summary = if ($summary) { $summary } else { "Executes $Method $Path" }
    $description = if ($description) { $description } else { $summary }
    
    # Generate basic function content
    $functionContent = @"
<#
.SYNOPSIS
    $summary

.DESCRIPTION
    $description

.PARAMETER BaseUri
    Base URI for the API

.PARAMETER Headers
    Additional headers as hashtable

.EXAMPLE
    $functionName -BaseUri 'https://api.example.com'
#>
function $functionName {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = `$true)]
        [string]`$BaseUri,
        
        [Parameter()]
        [hashtable]`$Headers = @{}
    )
    
    `$uri = "`$BaseUri$Path"
    `$method = '$($Method.ToUpper())'
    
    try {
        `$params = @{
            Uri = `$uri
            Method = `$method
            Headers = `$Headers
        }
        
        `$response = Invoke-RestMethod @params
        return `$response
    }
    catch {
        Write-Error "API call to `$uri failed: `$(`$_.Exception.Message)"
    }
}

"@
    
    return @{
        Name = $functionName
        Content = $functionContent
    }
}

function New-ModuleFiles {
    [CmdletBinding()]
    param(
        [string]$Name,
        [string]$Path,
        [string[]]$Functions,
        [string[]]$FunctionContent,
        [object]$ApiInfo,
        [string]$BaseUri
    )
    
    # Create module content with safe property access
    $title = if ($ApiInfo -is [hashtable]) {
        if ($ApiInfo['title']) { $ApiInfo['title'] } else { "Generated API" }
    } else {
        if ($ApiInfo.title) { $ApiInfo.title } else { "Generated API" }
    }
    
    $version = if ($ApiInfo -is [hashtable]) {
        if ($ApiInfo['version']) { $ApiInfo['version'] } else { "1.0.0" }
    } else {
        if ($ApiInfo.version) { $ApiInfo.version } else { "1.0.0" }
    }
    
    $description = if ($ApiInfo -is [hashtable]) {
        if ($ApiInfo['description']) { $ApiInfo['description'] } else { "Generated from $title" }
    } else {
        if ($ApiInfo.description) { $ApiInfo.description } else { "Generated from $title" }
    }
    
    $moduleContent = @"
# $Name - Generated PowerShell Module
# Source: $title v$version
# Generated: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')

$($FunctionContent -join "`n")

# Export all functions
Export-ModuleMember -Function @($($Functions | ForEach-Object { "'$_'" } | Join-String -Separator ', '))
"@
    
    $moduleFile = Join-Path $Path "$Name.psm1"
    $moduleContent | Out-File -FilePath $moduleFile -Encoding UTF8
    
    # Create manifest with safe property access
    $guid = [System.Guid]::NewGuid()
    $manifestVersion = if ($version -match '^\d+(\.\d+)*$') { $version } else { '1.0.0' }
    
    $manifestContent = @"
@{
    RootModule = '$Name.psm1'
    ModuleVersion = '$manifestVersion'
    GUID = '$guid'
    Author = 'PowerShell OpenAPI Generator'
    Description = '$($description -replace "'", "''")'
    PowerShellVersion = '5.1'
    FunctionsToExport = @($($Functions | ForEach-Object { "'$_'" } | Join-String -Separator ', '))
    CmdletsToExport = @()
    VariablesToExport = @()
    AliasesToExport = @()
}
"@
    
    $manifestFile = Join-Path $Path "$Name.psd1"
    $manifestContent | Out-File -FilePath $manifestFile -Encoding UTF8
    
    return @($moduleFile, $manifestFile)
}