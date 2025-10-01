<#
.SYNOPSIS
    PowerShell OpenAPI Wrapper Generator - Universal Generator Engine

.DESCRIPTION
    Unified, universal generator with CLI and interactive modes.
    Uses a single generation engine with configurable output modes.

.PARAMETER OpenAPIPath
    Path to the OpenAPI specification file (JSON or YAML)

.PARAMETER OutputPath
    Directory where the generated PowerShell module will be created

.PARAMETER ModuleName
    Name for the generated PowerShell module

.PARAMETER BaseUri
    Default base URI for the API (optional)

.PARAMETER EnhancementLevel
    Level of enhancements to include:
    - Basic: Simple functions with BaseUri and Headers only
    - Standard: Include common parameters and basic validation
    - Advanced: Full parameter extraction with validation and types
    - Expert: All features including custom error handling

.PARAMETER GenerateReadme
    Switch to generate a README.md file for the module

.PARAMETER Force
    Overwrite existing output directory if it exists

.PARAMETER Interactive
    Launch interactive wizard mode

.PARAMETER QuickMode
    Alias for -EnhancementLevel Basic

.EXAMPLE
    # Basic mode (equivalent to old Quick mode)
    .\PowerShell-OpenAPI-Generator.ps1 -OpenAPIPath ".\examples\swagger.json" -OutputPath ".\MyModule" -ModuleName "PetStoreAPI"

.EXAMPLE
    # Advanced mode with parameter extraction
    .\PowerShell-OpenAPI-Generator.ps1 -OpenAPIPath ".\examples\midata.yaml" -OutputPath ".\MiData" -ModuleName "MiDataAPI" -EnhancementLevel Advanced

.EXAMPLE
    # Interactive wizard mode
    .\PowerShell-OpenAPI-Generator.ps1 -Interactive
#>

[CmdletBinding(SupportsShouldProcess)]
param(
    [Parameter(Position = 0)]
    [string]$OpenAPIPath,
    
    [Parameter(Position = 1)]
    [string]$OutputPath,
    
    [Parameter(Position = 2)]
    [string]$ModuleName,
    
    [Parameter()]
    [string]$BaseUri,
    
    [Parameter()]
    [ValidateSet('Basic', 'Standard', 'Advanced', 'Expert')]
    [string]$EnhancementLevel = 'Basic',
    
    [Parameter()]
    [switch]$GenerateReadme,
    
    [Parameter()]
    [switch]$Force,
    
    [Parameter()]
    [switch]$Interactive,
    
    [Parameter()]
    [switch]$QuickMode
)

# Set strict mode for better error handling
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# Script root directory
$ScriptRoot = $PSScriptRoot

# Initialize enhancement system based on new parameter
if ($QuickMode) {
    $EnhancementLevel = 'Basic'
}

Write-Host "🚀 PowerShell OpenAPI Wrapper Generator v3.0.0" -ForegroundColor Green
Write-Host "===============================================" -ForegroundColor Green

# Determine mode
$isInteractiveMode = $Interactive -or (-not $OpenAPIPath -or -not $OutputPath -or -not $ModuleName)
$useEnhancements = $EnhancementLevel -ne 'Basic'

if ($isInteractiveMode) {
    Write-Host "🧙‍♂️ Interactive Setup Wizard" -ForegroundColor Cyan
    Write-Host "─────────────────────────────" -ForegroundColor Cyan
} else {
    $mode = if ($useEnhancements) { "Enhanced CLI" } else { "Quick CLI" }
    Write-Host "⚡ $mode Mode" -ForegroundColor Cyan
    $lineLength = ("⚡ $mode Mode").Length + 2
    Write-Host ("─" * $lineLength) -ForegroundColor Cyan
}

# Interactive Wizard
if ($isInteractiveMode) {
    # 1. OpenAPI Path
    if (-not $OpenAPIPath) {
        Write-Host "`n📄 Step 1: OpenAPI Specification" -ForegroundColor Yellow
        Write-Host "Available examples:" -ForegroundColor Gray
        
        $examplePath = Join-Path $ScriptRoot "examples"
        if (Test-Path $examplePath) {
            $examples = Get-ChildItem $examplePath | Where-Object { $_.Extension -match '\.(json|yaml|yml)$' } | Select-Object -First 5
            for ($i = 0; $i -lt $examples.Count; $i++) {
                Write-Host "  [$($i+1)] $($examples[$i].Name)" -ForegroundColor White
            }
        }
        
        do {
            $input = Read-Host "Enter path to OpenAPI file (or number for example)"
            
            # Check if it's a number for example selection
            if ($input -match '^\d+$') {
                $index = [int]$input - 1
                if ($index -ge 0 -and $index -lt $examples.Count) {
                    $OpenAPIPath = $examples[$index].FullName
                    Write-Host "✅ Selected: $($examples[$index].Name)" -ForegroundColor Green
                    break
                } else {
                    Write-Host "❌ Invalid selection. Please try again." -ForegroundColor Red
                }
            } else {
                # Resolve relative paths
                if (-not [System.IO.Path]::IsPathRooted($input)) {
                    $input = Join-Path $PWD.Path $input
                }
                
                if (Test-Path $input) {
                    if ($input -match '\.(json|yaml|yml)$') {
                        $OpenAPIPath = $input
                        Write-Host "✅ OpenAPI file found!" -ForegroundColor Green
                        break
                    } else {
                        Write-Host "❌ File must be JSON or YAML format" -ForegroundColor Red
                    }
                } else {
                    Write-Host "❌ File not found: $input" -ForegroundColor Red
                }
            }
        } while ($true)
    }
    
    # 2. Module Name
    if (-not $ModuleName) {
        Write-Host "`n📦 Step 2: Module Name" -ForegroundColor Yellow
        do {
            $ModuleName = Read-Host "Enter PowerShell module name (e.g., 'PetStoreAPI')"
            if ($ModuleName -match '^[A-Za-z][A-Za-z0-9]*$') {
                Write-Host "✅ Valid module name!" -ForegroundColor Green
                break
            } else {
                Write-Host "❌ Module name must start with a letter and contain only letters and numbers" -ForegroundColor Red
            }
        } while ($true)
    }
    
    # 3. Output Path
    if (-not $OutputPath) {
        Write-Host "`n📂 Step 3: Output Directory" -ForegroundColor Yellow
        $defaultOutput = Join-Path $PWD.Path $ModuleName
        $input = Read-Host "Enter output directory [default: $defaultOutput]"
        $OutputPath = if ($input) { $input } else { $defaultOutput }
        
        if (-not [System.IO.Path]::IsPathRooted($OutputPath)) {
            $OutputPath = Join-Path $PWD.Path $OutputPath
        }
        
        Write-Host "✅ Output directory: $OutputPath" -ForegroundColor Green
    }
    
    # 4. Base URI (optional)
    if (-not $BaseUri) {
        Write-Host "`n🌐 Step 4: Base URI (Optional)" -ForegroundColor Yellow
        $BaseUri = Read-Host "Enter default base URI [optional, can be configured later]"
        if ($BaseUri) {
            Write-Host "✅ Base URI set!" -ForegroundColor Green
        }
    }
    
    # 5. Generation Mode Selection
    Write-Host "`n⚡ Step 5: Enhancement Level" -ForegroundColor Yellow
    Write-Host "Choose enhancement level:" -ForegroundColor Gray
    Write-Host "  [1] Basic - Simple HTTP requests, fast generation" -ForegroundColor White
    Write-Host "  [2] Standard - Includes timeout and header management" -ForegroundColor White
    Write-Host "  [3] Advanced - Full parameter extraction and body handling" -ForegroundColor White
    Write-Host "  [4] Expert - Enterprise-grade with retry logic and error handling" -ForegroundColor White
    
    $levelInput = Read-Host "Select enhancement level [1-4] [default: 1]"
    if (-not $levelInput) { $levelInput = "1" }
    
    $EnhancementLevel = switch ($levelInput) {
        "1" { "Basic" }
        "2" { "Standard" }
        "3" { "Advanced" }
        "4" { "Expert" }
        default { "Basic" }
    }
    
    $useEnhancements = $EnhancementLevel -ne 'Basic'
    Write-Host "✅ Selected: $EnhancementLevel Level" -ForegroundColor Green
    
    # 6. README Generation
    Write-Host "`n📄 Step 6: Generate README?" -ForegroundColor Yellow
    $readmeChoice = Read-Host "Generate README.md for the module? [Y/n]"
    if ($readmeChoice -notmatch '^n') {
        $GenerateReadme = $true
        Write-Host "✅ README will be generated!" -ForegroundColor Green
    }
    
    # Configuration Summary
    Write-Host "`n🎯 Configuration Summary:" -ForegroundColor Cyan
    Write-Host "────────────────────────" -ForegroundColor Cyan
    Write-Host "OpenAPI File: $OpenAPIPath" -ForegroundColor White
    Write-Host "Module Name: $ModuleName" -ForegroundColor White
    Write-Host "Output Path: $OutputPath" -ForegroundColor White
    Write-Host "Base URI: $(if ($BaseUri) { $BaseUri } else { 'Not set' })" -ForegroundColor White
    Write-Host "Enhancement Level: $EnhancementLevel" -ForegroundColor White
    Write-Host "Generate README: $(if ($GenerateReadme) { 'Yes' } else { 'No' })" -ForegroundColor White
    
    $confirm = Read-Host "`nProceed with generation? [Y/n]"
    if ($confirm -match '^n') {
        Write-Host "❌ Generation cancelled by user" -ForegroundColor Yellow
        exit 0
    }
}

# ===========================================================================================
# UNIVERSAL HELPER FUNCTIONS
# ===========================================================================================

function ConvertTo-SafeProperty {
    <#
    .SYNOPSIS
        Safely access properties from objects that might be Hashtables or PSObjects
    #>
    param(
        [Parameter(Mandatory)]
        $Object,
        [Parameter(Mandatory)]
        [string]$PropertyName,
        $DefaultValue = $null
    )
    
    if ($Object -is [System.Collections.Hashtable]) {
        if ($Object.ContainsKey($PropertyName)) {
            return $Object[$PropertyName]
        }
    } elseif ($Object -and $Object.PSObject.Properties[$PropertyName]) {
        return $Object.$PropertyName
    }
    
    return $DefaultValue
}

function Get-SafeObjectKeys {
    <#
    .SYNOPSIS
        Get keys/property names from objects that might be Hashtables or PSObjects
    #>
    param([Parameter(Mandatory)]$Object)
    
    if ($Object -is [System.Collections.Hashtable]) {
        return $Object.Keys
    } elseif ($Object -and $Object.PSObject) {
        return $Object.PSObject.Properties.Name
    }
    
    return @()
}

function Get-OpenAPIParameters {
    <#
    .SYNOPSIS
        Extract parameters from OpenAPI operation for Advanced/Expert levels
    #>
    param(
        [Parameter(Mandatory)]$Operation,
        [Parameter(Mandatory)]$PathItem,
        [Parameter(Mandatory)]$Specification,
        [Parameter(Mandatory)]$Level
    )
    
    $parameters = @()
    
    if ($Level -in @('Advanced', 'Expert')) {
        # Get path-level parameters first
        $pathParams = ConvertTo-SafeProperty -Object $PathItem -PropertyName 'parameters' -DefaultValue @()
        
        # Get operation-level parameters
        $operationParams = ConvertTo-SafeProperty -Object $Operation -PropertyName 'parameters' -DefaultValue @()
        
        # Combine all parameters
        $allParams = @($pathParams) + @($operationParams)
        
        foreach ($param in $allParams) {
            $paramName = $null
            $paramType = 'string'
            $isRequired = $false
            $description = ''
            $paramIn = 'query'
            
            # Handle parameter reference
            if (ConvertTo-SafeProperty -Object $param -PropertyName '$ref') {
                $refPath = ConvertTo-SafeProperty -Object $param -PropertyName '$ref'
                if ($refPath -match '#/components/parameters/(.+)') {
                    $parameterName = $matches[1]
                    $refParam = ConvertTo-SafeProperty -Object $Specification.components.parameters -PropertyName $parameterName
                    if ($refParam) {
                        $paramName = ConvertTo-SafeProperty -Object $refParam -PropertyName 'name'
                        $paramType = ConvertTo-SafeProperty -Object $refParam.schema -PropertyName 'type' -DefaultValue 'string'
                        $isRequired = ConvertTo-SafeProperty -Object $refParam -PropertyName 'required' -DefaultValue $false
                        $description = ConvertTo-SafeProperty -Object $refParam -PropertyName 'description' -DefaultValue "Parameter: $paramName"
                        $paramIn = ConvertTo-SafeProperty -Object $refParam -PropertyName 'in' -DefaultValue 'query'
                    }
                }
            } else {
                # Direct parameter definition
                $paramName = ConvertTo-SafeProperty -Object $param -PropertyName 'name'
                $schema = ConvertTo-SafeProperty -Object $param -PropertyName 'schema'
                if ($schema) {
                    $paramType = ConvertTo-SafeProperty -Object $schema -PropertyName 'type' -DefaultValue 'string'
                }
                $isRequired = ConvertTo-SafeProperty -Object $param -PropertyName 'required' -DefaultValue $false
                $description = ConvertTo-SafeProperty -Object $param -PropertyName 'description' -DefaultValue "Parameter: $paramName"
                $paramIn = ConvertTo-SafeProperty -Object $param -PropertyName 'in' -DefaultValue 'query'
            }
            
            if ($paramName -and $paramIn -eq 'query') {
                # Convert OpenAPI types to PowerShell types
                $psType = switch ($paramType) {
                    'integer' { 'int' }
                    'number' { 'double' }
                    'boolean' { 'bool' }
                    'array' { 'string[]' }
                    default { 'string' }
                }
                
                $parameters += @{
                    Name = $paramName
                    Type = $psType
                    Required = $isRequired
                    Description = $description
                    In = $paramIn
                }
            }
        }
    }
    
    return $parameters
}

function New-UniversalFunction {
    <#
    .SYNOPSIS
        Generate PowerShell function with universal enhancement level support
    #>
    param(
        [Parameter(Mandatory)]
        [string]$FunctionName,
        [Parameter(Mandatory)]
        [string]$HttpMethod,
        [Parameter(Mandatory)]
        [string]$PathName,
        [Parameter(Mandatory)]
        $Operation,
        [Parameter(Mandatory)]
        $PathItem,
        [Parameter(Mandatory)]
        $Specification,
        [Parameter(Mandatory)]
        [ValidateSet('Basic', 'Standard', 'Advanced', 'Expert')]
        [string]$Level
    )
    
    $summary = ConvertTo-SafeProperty -Object $Operation -PropertyName 'summary' -DefaultValue "Executes $HttpMethod $PathName"
    $description = ConvertTo-SafeProperty -Object $Operation -PropertyName 'description' -DefaultValue $summary
    
    # Base parameters for all levels
    $parameterDefinitions = @(
        "[Parameter(Mandatory = `$true)]`n        [string]`$BaseUri"
    )
    
    $functionBody = @"
    `$uri = "`$BaseUri$PathName"
    `$method = '$($HttpMethod.ToUpper())'
    
    try {
        `$params = @{
            Uri = `$uri
            Method = `$method
            Headers = `$Headers
        }
"@
    
    # Enhancement level specific features
    switch ($Level) {
        'Basic' {
            $parameterDefinitions += "[Parameter()]`n        [hashtable]`$Headers = @{}"
        }
        
        'Standard' {
            $parameterDefinitions += "[Parameter()]`n        [hashtable]`$Headers = @{}"
            $parameterDefinitions += "[Parameter()]`n        [int]`$TimeoutSec = 30"
            
            $functionBody += "`n        if (`$TimeoutSec) { `$params.TimeoutSec = `$TimeoutSec }"
        }
        
        'Advanced' {
            $parameterDefinitions += "[Parameter()]`n        [hashtable]`$Headers = @{}"
            $parameterDefinitions += "[Parameter()]`n        [int]`$TimeoutSec = 30"
            $parameterDefinitions += "[Parameter()]`n        [hashtable]`$Body = @{}"
            
            # Add operation-specific parameters
            $operationParams = Get-OpenAPIParameters -Operation $Operation -PathItem $PathItem -Specification $Specification -Level $Level
            foreach ($param in $operationParams) {
                $mandatory = if ($param.Required) { "Mandatory = `$true" } else { "" }
                $helpText = $param.Description -replace "'", "''"
                $cleanParamName = $param.Name -replace '[^a-zA-Z0-9]', '_'
                $parameterDefinitions += "[Parameter($mandatory)]`n        [$($param.Type)]`$$cleanParamName"
            }
            
            $functionBody += "`n        if (`$TimeoutSec) { `$params.TimeoutSec = `$TimeoutSec }"
            $functionBody += "`n        if (`$Body.Count -gt 0) { `$params.Body = (`$Body | ConvertTo-Json -Depth 10) }"
            
            # Add query parameter handling
            if ($operationParams.Count -gt 0) {
                $functionBody += "`n        # Add query parameters"
                $functionBody += "`n        `$queryParams = @()"
                foreach ($param in $operationParams) {
                    $cleanParamVar = $param.Name -replace '[^a-zA-Z0-9]', '_'
                    $functionBody += "`n        if (`$PSBoundParameters.ContainsKey('$cleanParamVar')) { `$queryParams += '$($param.Name)=' + [System.Web.HttpUtility]::UrlEncode(`$$cleanParamVar) }"
                }
                $functionBody += "`n        if (`$queryParams.Count -gt 0) { `$params.Uri += '?' + (`$queryParams -join '&') }"
            }
        }
        
        'Expert' {
            $parameterDefinitions += "[Parameter()]`n        [hashtable]`$Headers = @{}"
            $parameterDefinitions += "[Parameter()]`n        [int]`$TimeoutSec = 30"
            $parameterDefinitions += "[Parameter()]`n        [hashtable]`$Body = @{}"
            $parameterDefinitions += "[Parameter()]`n        [switch]`$PassThru"
            $parameterDefinitions += "[Parameter()]`n        [ValidateSet('Default', 'Ignore', 'Retry')]`n        [string]`$ErrorHandling = 'Default'"
            
            # Add operation-specific parameters
            $operationParams = Get-OpenAPIParameters -Operation $Operation -PathItem $PathItem -Specification $Specification -Level $Level
            foreach ($param in $operationParams) {
                $mandatory = if ($param.Required) { "Mandatory = `$true" } else { "" }
                $helpText = $param.Description -replace "'", "''"
                $cleanParamName = $param.Name -replace '[^a-zA-Z0-9]', '_'
                $parameterDefinitions += "[Parameter($mandatory)]`n        [$($param.Type)]`$$cleanParamName"
            }
            
            $functionBody += @"

        if (`$TimeoutSec) { `$params.TimeoutSec = `$TimeoutSec }
        if (`$Body.Count -gt 0) { `$params.Body = (`$Body | ConvertTo-Json -Depth 10) }
        
        # Add query parameters
        `$queryParams = @()
"@
            
            if ($operationParams.Count -gt 0) {
                foreach ($param in $operationParams) {
                    $cleanParamVar = $param.Name -replace '[^a-zA-Z0-9]', '_'
                    $functionBody += "`n        if (`$PSBoundParameters.ContainsKey('$cleanParamVar')) { `$queryParams += '$($param.Name)=' + [System.Web.HttpUtility]::UrlEncode(`$$cleanParamVar) }"
                }
            }
            
            $functionBody += "`n        if (`$queryParams.Count -gt 0) { `$params.Uri += '?' + (`$queryParams -join '&') }"
            
            $functionBody += @"

        # Expert error handling
        if (`$ErrorHandling -eq 'Retry') {
            `$retryCount = 3
            do {
                try {
                    `$response = Invoke-RestMethod @params
                    break
                }
                catch {
                    `$retryCount--
                    if (`$retryCount -le 0) { throw }
                    Start-Sleep -Seconds 1
                }
            } while (`$retryCount -gt 0)
        }
"@
        }
    }
    
    # Complete function body
    if ($Level -ne 'Expert') {
        $functionBody += "`n        `$response = Invoke-RestMethod @params"
    }
    
    $functionBody += @"

        return `$response
    }
    catch {
        Write-Error "API call to `$uri failed: `$(`$_.Exception.Message)"
    }
"@
    
    # Build complete function
    $parameterBlock = $parameterDefinitions -join ",`n        "
    
    # Add parameter documentation for Advanced/Expert levels
    $parameterHelp = ""
    if ($Level -in @('Advanced', 'Expert')) {
        $operationParams = Get-OpenAPIParameters -Operation $Operation -PathItem $PathItem -Specification $Specification -Level $Level
        foreach ($param in $operationParams) {
            $cleanParamVar = $param.Name -replace '[^a-zA-Z0-9]', '_'
            $parameterHelp += "`n.PARAMETER $cleanParamVar`n    $($param.Description) (API parameter: $($param.Name))"
        }
    }
    
    return @"
<#
.SYNOPSIS
    $summary

.DESCRIPTION
    $description
    Enhancement Level: $Level

.PARAMETER BaseUri
    Base URI for the API (e.g., 'https://petstore.swagger.io/v2')
$parameterHelp

.EXAMPLE
    $FunctionName -BaseUri 'https://petstore.swagger.io/v2'
#>
function $FunctionName {
    [CmdletBinding()]
    param(
        $parameterBlock
    )
    
$functionBody
}

"@
}

function New-UniversalModule {
    <#
    .SYNOPSIS
        Generate PowerShell module with universal structure
    #>
    param(
        [Parameter(Mandatory)]
        [string]$ModuleName,
        [Parameter(Mandatory)]
        [string]$OutputPath,
        [Parameter(Mandatory)]
        $Specification,
        [Parameter(Mandatory)]
        [ValidateSet('Basic', 'Standard', 'Advanced', 'Expert')]
        [string]$Level,
        [string]$BaseUri = ''
    )
    
    $functions = @()
    $functionContents = @()
    
    # Process all operations
    $pathNames = Get-SafeObjectKeys -Object $Specification.paths
    
    foreach ($pathName in $pathNames) {
        $pathItem = ConvertTo-SafeProperty -Object $Specification.paths -PropertyName $pathName
        $httpMethods = Get-SafeObjectKeys -Object $pathItem
        
        foreach ($httpMethod in @('get', 'post', 'put', 'delete', 'patch', 'head', 'options')) {
            if ($httpMethods -contains $httpMethod) {
                $operation = ConvertTo-SafeProperty -Object $pathItem -PropertyName $httpMethod
                
                # Generate function name
                $verb = switch ($httpMethod.ToUpper()) {
                    'GET' { 'Get' }
                    'POST' { 'New' }
                    'PUT' { 'Set' }
                    'DELETE' { 'Remove' }
                    'PATCH' { 'Update' }
                    default { 'Invoke' }
                }
                
                $operationId = ConvertTo-SafeProperty -Object $operation -PropertyName 'operationId'
                if ($operationId) {
                    $noun = $operationId -replace "^$httpMethod", '' -replace '[^a-zA-Z0-9]', ''
                    if (-not $noun) { $noun = 'Resource' }
                    $functionName = "$verb-$noun"
                } else {
                    $pathParts = $pathName -split '/' | Where-Object { $_ -and $_ -notmatch '^\{' }
                    $noun = ($pathParts | Select-Object -Last 1) -replace '[^a-zA-Z0-9]', ''
                    if (-not $noun) { $noun = 'Resource' }
                    $functionName = "$verb-$noun"
                }
                
                # Ensure unique function names
                $originalName = $functionName
                $counter = 1
                while ($functions -contains $functionName) {
                    $functionName = "$originalName$counter"
                    $counter++
                }
                
                $functions += $functionName
                
                # Generate function with enhancement level
                $functionContent = New-UniversalFunction -FunctionName $functionName -HttpMethod $httpMethod -PathName $pathName -Operation $operation -PathItem $pathItem -Specification $Specification -Level $Level
                $functionContents += $functionContent
            }
        }
    }
    
    return @{
        Functions = $functions
        Content = $functionContents
        ModuleName = $ModuleName
        OutputPath = $OutputPath
        Level = $Level
    }
}

# ===========================================================================================
# MAIN EXECUTION
# ===========================================================================================

try {
    # Validate parameters
    if (-not (Test-Path $OpenAPIPath)) {
        throw "OpenAPI file not found: $OpenAPIPath"
    }
    
    if ($OpenAPIPath -notmatch '\.(json|yaml|yml)$') {
        throw "OpenAPI file must be JSON or YAML: $OpenAPIPath"
    }
    
    if ($ModuleName -notmatch '^[A-Za-z][A-Za-z0-9]*$') {
        throw "Module name must start with a letter and contain only letters and numbers"
    }
    
    if ($BaseUri -and -not [System.Uri]::TryCreate($BaseUri, [System.UriKind]::Absolute, [ref]$null)) {
        throw "Invalid BaseUri format: $BaseUri"
    }
    
    # Parse OpenAPI specification
    Write-Host "📖 Parsing OpenAPI specification..." -ForegroundColor Yellow
    $content = Get-Content -Path $OpenAPIPath -Raw
    
    # Determine file format and parse accordingly
    $extension = [System.IO.Path]::GetExtension($OpenAPIPath).ToLower()
    
    if ($extension -in @('.yaml', '.yml')) {
        Write-Host "📄 Detected YAML format" -ForegroundColor Gray
        
        # Check for YAML parsing capability
        if (Get-Command ConvertFrom-Yaml -ErrorAction SilentlyContinue) {
            $spec = $content | ConvertFrom-Yaml
        } else {
            Write-Warning "YAML parsing requires PowerShell-Yaml module"
            Write-Host "💡 Installing PowerShell-Yaml module..." -ForegroundColor Yellow
            
            try {
                Install-Module PowerShell-Yaml -Force -Scope CurrentUser -ErrorAction Stop
                Import-Module PowerShell-Yaml -ErrorAction Stop
                $spec = $content | ConvertFrom-Yaml
                Write-Host "✅ PowerShell-Yaml module installed successfully" -ForegroundColor Green
            }
            catch {
                throw "Failed to install or use PowerShell-Yaml module: $($_.Exception.Message). Please install manually: Install-Module PowerShell-Yaml"
            }
        }
    } else {
        Write-Host "📄 Detected JSON format" -ForegroundColor Gray
        $spec = $content | ConvertFrom-Json
    }
    
    $apiTitle = ConvertTo-SafeProperty -Object $spec.info -PropertyName 'title' -DefaultValue 'API'
    $apiVersion = ConvertTo-SafeProperty -Object $spec.info -PropertyName 'version' -DefaultValue '1.0.0'
    Write-Host "✅ Loaded: $apiTitle v$apiVersion" -ForegroundColor Green
    
    
    # Enhancement level is already set from CLI parameter or interactive mode
    Write-Host "⚡ Universal Generation Engine - Level: $EnhancementLevel" -ForegroundColor Cyan
    
    # Create output directory
    if (-not [System.IO.Path]::IsPathRooted($OutputPath)) {
        $OutputPath = Join-Path $PWD.Path $OutputPath
    }
    $OutputPath = [System.IO.Path]::GetFullPath($OutputPath)
    
    if (Test-Path $OutputPath) {
        if ($Force) {
            Remove-Item $OutputPath -Recurse -Force
        } else {
            throw "Output directory already exists: $OutputPath. Use -Force to overwrite."
        }
    }
    New-Item -Path $OutputPath -ItemType Directory -Force | Out-Null
    
    # Generate module using universal system
    Write-Host "🏗️  Generating module with universal engine..." -ForegroundColor Yellow
    $moduleResult = New-UniversalModule -ModuleName $ModuleName -OutputPath $OutputPath -Specification $spec -Level $EnhancementLevel -BaseUri $BaseUri
    
    Write-Host "� Creating module files..." -ForegroundColor Yellow
    
    # Determine structure based on function count
    $functionCount = $moduleResult.Functions.Count
    $useModularStructure = $functionCount -gt 50
    
    if ($useModularStructure) {
        Write-Host "🗂️  Large API detected ($functionCount functions) - creating modular structure..." -ForegroundColor Cyan
        
        # Create Functions subdirectory
        $functionsDir = Join-Path $OutputPath "Functions"
        New-Item -Path $functionsDir -ItemType Directory -Force | Out-Null
        
        # Create individual function files
        for ($i = 0; $i -lt $functionCount; $i++) {
            $functionName = $moduleResult.Functions[$i]
            $functionContent = $moduleResult.Content[$i]
            
            $functionFile = Join-Path $functionsDir "$functionName.ps1"
            $functionContent | Out-File -FilePath $functionFile -Encoding UTF8
            
            if ($i % 20 -eq 0) {
                $percent = [math]::Round(($i / $functionCount) * 100)
                Write-Host "   Creating function files: $i/$functionCount ($percent%)" -ForegroundColor Gray
            }
        }
        
        # Create main .psm1 that imports all functions
        $moduleContent = @"
# $ModuleName - Generated PowerShell Module (Modular Structure)
# Source: $apiTitle v$apiVersion
# Generated: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')
# Enhancement Level: $EnhancementLevel
# Functions: $functionCount

# Import all function files
`$functionsPath = Join-Path `$PSScriptRoot 'Functions'
if (Test-Path `$functionsPath) {
    Get-ChildItem `$functionsPath -Filter '*.ps1' | ForEach-Object {
        . `$_.FullName
    }
}

# Export all functions
Export-ModuleMember -Function @($($moduleResult.Functions | ForEach-Object { "'$_'" } | Join-String -Separator ', '))
"@
    } else {
        # Create single .psm1 file for smaller APIs
        $moduleContent = @"
# $ModuleName - Generated PowerShell Module
# Source: $apiTitle v$apiVersion
# Generated: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')
# Enhancement Level: $EnhancementLevel

$($moduleResult.Content -join "`n")

# Export all functions
Export-ModuleMember -Function @($($moduleResult.Functions | ForEach-Object { "'$_'" } | Join-String -Separator ', '))
"@
    }
    
    $moduleFile = Join-Path $OutputPath "$ModuleName.psm1"
    $moduleContent | Out-File -FilePath $moduleFile -Encoding UTF8
    
    # Create .psd1 manifest
    $guid = [System.Guid]::NewGuid()
    
    # Normalize version string for PowerShell module requirements
    $version = $apiVersion
    if ($version -match '^v?(\d+)$') {
        $version = "$($matches[1]).0.0"  # Convert v1 or 1 to 1.0.0
    } elseif ($version -match '^v?(\d+)\.(\d+)$') {
        $version = "$($matches[1]).$($matches[2]).0"  # Convert v1.2 to 1.2.0
    } elseif ($version -match '^v(.*)') {
        $version = $matches[1]  # Remove 'v' prefix
    }
    # If version is still not valid, fallback to 1.0.0
    try {
        [Version]::Parse($version) | Out-Null
    } catch {
        $version = '1.0.0'
    }
    
    # Prepare description safely
    $description = ConvertTo-SafeProperty -Object $spec.info -PropertyName 'description' -DefaultValue "Generated from $apiTitle"
    
    $manifestContent = @"
@{
    RootModule = '$ModuleName.psm1'
    ModuleVersion = '$version'
    GUID = '$guid'
    Author = 'PowerShell OpenAPI Generator v3.0.0'
    Description = '$description'
    PowerShellVersion = '5.1'
    FunctionsToExport = @($($moduleResult.Functions | ForEach-Object { "'$_'" } | Join-String -Separator ', '))
    CmdletsToExport = @()
    VariablesToExport = @()
    AliasesToExport = @()
    PrivateData = @{
        PSData = @{
            Tags = @('OpenAPI', 'REST', 'API', '$EnhancementLevel')
            ProjectUri = 'https://github.com/PowerShell-OpenAPI-Generator'
        }
    }
}
"@
    
    $manifestFile = Join-Path $OutputPath "$ModuleName.psd1"
    $manifestContent | Out-File -FilePath $manifestFile -Encoding UTF8
    
    # Generate README if requested
    if ($GenerateReadme) {
        Write-Host "📄 Generating README..." -ForegroundColor Yellow
        
        $readmeContent = @"
# $ModuleName

Generated PowerShell module for **$apiTitle** (v$apiVersion)

## Overview

- **Generated**: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')
- **Enhancement Level**: $EnhancementLevel
- **Functions**: $functionCount
- **Structure**: $(if ($useModularStructure) { 'Modular (Functions in separate files)' } else { 'Single file' })

## Installation

``````powershell
Import-Module '$OutputPath\$ModuleName.psd1'
``````

## Usage

``````powershell
# List all available functions
Get-Command -Module $ModuleName

# Example usage (replace with actual base URI)
$($moduleResult.Functions[0]) -BaseUri 'https://api.example.com'
``````

## Enhancement Levels

- **Basic**: Simple HTTP requests with basic parameters
- **Standard**: Includes timeout and header management
- **Advanced**: Full parameter extraction and body handling
- **Expert**: Enterprise-grade error handling with retry logic

Current level: **$EnhancementLevel**

## Functions

$($moduleResult.Functions | ForEach-Object { "- ``$_``" } | Join-String -Separator "`n")

---
Generated by PowerShell OpenAPI Generator v3.0.0
"@
        
        $readmeFile = Join-Path $OutputPath "README.md"
        $readmeContent | Out-File -FilePath $readmeFile -Encoding UTF8
        Write-Host "✅ README.md created!" -ForegroundColor Green
    }
    
    # Success output
    Write-Host "`n🎉 Universal module generation completed!" -ForegroundColor Green
    Write-Host "📍 Location: $OutputPath" -ForegroundColor Cyan
    Write-Host "📦 Module: $ModuleName" -ForegroundColor Cyan
    Write-Host "🎯 Functions: $functionCount" -ForegroundColor Cyan
    Write-Host "⚡ Enhancement Level: $EnhancementLevel" -ForegroundColor Cyan
    
    if ($useModularStructure) {
        Write-Host "🗂️  Structure: Modular (Functions in separate files)" -ForegroundColor Cyan
    } else {
        Write-Host "📄 Structure: Single file" -ForegroundColor Cyan
    }
    
    # Show some statistics
    $verbStats = $moduleResult.Functions | Group-Object { ($_ -split '-')[0] } | Sort-Object Count -Descending
    Write-Host "`n📈 Function Statistics:" -ForegroundColor Yellow
    $verbStats | Select-Object -First 5 | ForEach-Object {
        Write-Host "   $($_.Name): $($_.Count) functions" -ForegroundColor Gray
    }
    
    # Usage instructions
    Write-Host "`n🚀 To use your module:" -ForegroundColor Yellow
    Write-Host "   Import-Module '$OutputPath\$ModuleName.psd1'" -ForegroundColor White
    Write-Host "   Get-Command -Module $ModuleName" -ForegroundColor White
    
    # Check for host information
    $apiHost = ConvertTo-SafeProperty -Object $spec -PropertyName 'host'
    if ($apiHost) {
        $baseUrl = "https://$apiHost"
        $basePath = ConvertTo-SafeProperty -Object $spec -PropertyName 'basePath'
        if ($basePath) { $baseUrl += $basePath }
        
        Write-Host "`n💡 Example usage:" -ForegroundColor Yellow
        Write-Host "   # $EnhancementLevel level functionality" -ForegroundColor Gray
        if ($moduleResult.Functions -and $moduleResult.Functions.Count -gt 0) {
            Write-Host "   $($moduleResult.Functions[0]) -BaseUri '$baseUrl'" -ForegroundColor White
        }
    }
    
    # Performance info for large APIs
    if ($functionCount -gt 100) {
        Write-Host "`n⚡ Performance tip:" -ForegroundColor Yellow
        Write-Host "   Large API detected! Consider using specific function imports:" -ForegroundColor Gray
        Write-Host "   Import-Module '$OutputPath\$ModuleName.psd1' -Function 'Get-*'" -ForegroundColor White
    }
    
}
catch {
    Write-Error "❌ Generation failed: $($_.Exception.Message)"
    Write-Error "💡 Use -Verbose for detailed error information"
    exit 1
}