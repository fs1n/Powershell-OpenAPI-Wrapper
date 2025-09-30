<#
.SYNOPSIS
    PowerShell OpenAPI Wrapper Generator - Main Entry Point

.DESCRIPTION
    This is the main entry point for generating PowerShell modules from OpenAPI specifications.
    It orchestrates all the enhancement modules and provides a clean, unified interface.

.PARAMETER OpenAPIPath
    Path to the OpenAPI specification file (JSON or YAML)

.PARAMETER OutputPath
    Directory where the generated PowerShell module will be created

.PARAMETER ModuleName
    Name for the generated PowerShell module

.PARAMETER BaseUri
    Default base URI for the API (optional, can be configured later)

.PARAMETER IncludeEnhancements
    Array of enhancements to include. Available options:
    - VerbMapping: Enhanced PowerShell verb mapping
    - ParameterFlattening: Advanced parameter handling
    - ErrorHandling: Enterprise-grade error handling
    - TypeSystem: Strong typing with custom classes
    - All: Include all enhancements (default)

.PARAMETER GenerateReadme
    Switch to generate a README.md file for the module

.PARAMETER Force
    Overwrite existing output directory if it exists

.EXAMPLE
    .\New-PowerShellAPIWrapper.ps1 -OpenAPIPath ".\examples\petstore.json" -OutputPath ".\MyPetStoreModule" -ModuleName "PetStore"

.EXAMPLE
    .\New-PowerShellAPIWrapper.ps1 -OpenAPIPath ".\swagger.yaml" -OutputPath ".\Output" -ModuleName "MyAPI" -IncludeEnhancements @("VerbMapping", "ErrorHandling") -GenerateReadme

.NOTES
    Author: PowerShell OpenAPI Wrapper Generator
    Version: 2.0.0
    Requires: PowerShell 5.1 or higher

.FUNCTIONALITY
    OpenAPI, Swagger, PowerShell, Module Generation, API Wrapper
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
    [ValidateSet('VerbMapping', 'ParameterFlattening', 'ErrorHandling', 'TypeSystem', 'All')]
    [string[]]$IncludeEnhancements = @('All'),
    
    [Parameter()]
    [switch]$GenerateReadme,
    
    [Parameter()]
    [switch]$Force,
    
    [Parameter()]
    [switch]$Interactive
)

# Set strict mode for better error handling
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# Script root directory
$ScriptRoot = $PSScriptRoot

Write-Host "🚀 PowerShell OpenAPI Wrapper Generator v2.0.0" -ForegroundColor Green
Write-Host "================================================" -ForegroundColor Green

# Interactive Wizard if no parameters provided or Interactive switch used
if (-not $OpenAPIPath -or -not $OutputPath -or -not $ModuleName -or $Interactive) {
    Write-Host "🧙‍♂️ Interactive Setup Wizard" -ForegroundColor Cyan
    Write-Host "─────────────────────────────" -ForegroundColor Cyan
    
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
    
    # 5. Enhancements
    Write-Host "`n🔧 Step 5: Select Enhancements" -ForegroundColor Yellow
    Write-Host "Available enhancements:" -ForegroundColor Gray
    Write-Host "  [1] VerbMapping - Enhanced PowerShell verb mapping" -ForegroundColor White
    Write-Host "  [2] ParameterFlattening - Advanced parameter handling" -ForegroundColor White
    Write-Host "  [3] ErrorHandling - Enterprise-grade error handling" -ForegroundColor White
    Write-Host "  [4] TypeSystem - Strong typing with custom classes" -ForegroundColor White
    Write-Host "  [5] All - Include all enhancements (recommended)" -ForegroundColor White
    
    $enhancementInput = Read-Host "Select enhancements (comma-separated numbers or 5 for all) [default: 5]"
    if (-not $enhancementInput) { $enhancementInput = "5" }
    
    $enhancementOptions = @('VerbMapping', 'ParameterFlattening', 'ErrorHandling', 'TypeSystem', 'All')
    $selectedEnhancements = @()
    
    foreach ($num in ($enhancementInput -split '[,\s]+')) {
        if ($num -match '^\d+$') {
            $index = [int]$num - 1
            if ($index -ge 0 -and $index -lt $enhancementOptions.Count) {
                $selectedEnhancements += $enhancementOptions[$index]
            }
        }
    }
    
    if ($selectedEnhancements) {
        $IncludeEnhancements = $selectedEnhancements
        Write-Host "✅ Selected: $($selectedEnhancements -join ', ')" -ForegroundColor Green
    }
    
    # 6. README Generation
    Write-Host "`n📄 Step 6: Generate README?" -ForegroundColor Yellow
    $readmeChoice = Read-Host "Generate README.md for the module? [Y/n]"
    if ($readmeChoice -notmatch '^n') {
        $GenerateReadme = $true
        Write-Host "✅ README will be generated!" -ForegroundColor Green
    }
    
    Write-Host "`n🎯 Configuration Summary:" -ForegroundColor Cyan
    Write-Host "────────────────────────" -ForegroundColor Cyan
    Write-Host "OpenAPI File: $OpenAPIPath" -ForegroundColor White
    Write-Host "Module Name: $ModuleName" -ForegroundColor White
    Write-Host "Output Path: $OutputPath" -ForegroundColor White
    Write-Host "Base URI: $(if ($BaseUri) { $BaseUri } else { 'Not set' })" -ForegroundColor White
    Write-Host "Enhancements: $($IncludeEnhancements -join ', ')" -ForegroundColor White
    Write-Host "Generate README: $(if ($GenerateReadme) { 'Yes' } else { 'No' })" -ForegroundColor White
    
    $confirm = Read-Host "`nProceed with generation? [Y/n]"
    if ($confirm -match '^n') {
        Write-Host "❌ Generation cancelled by user" -ForegroundColor Yellow
        exit 0
    }
}

try {
    # Validate parameters first
    if ($OpenAPIPath -and -not (Test-Path $OpenAPIPath)) {
        throw "OpenAPI file not found: $OpenAPIPath"
    }
    
    if ($OpenAPIPath -and $OpenAPIPath -notmatch '\.(json|yaml|yml)$') {
        throw "OpenAPI file must be JSON or YAML: $OpenAPIPath"
    }
    
    if ($ModuleName -and $ModuleName -notmatch '^[A-Za-z][A-Za-z0-9]*$') {
        throw "Module name must start with a letter and contain only letters and numbers"
    }
    
    if ($BaseUri -and -not [System.Uri]::TryCreate($BaseUri, [System.UriKind]::Absolute, [ref]$null)) {
        throw "Invalid BaseUri format: $BaseUri"
    }
    
    # Import core modules
    Write-Host "📦 Loading core modules..." -ForegroundColor Yellow
    
    $coreModules = @(
        "$ScriptRoot\src\Core\UtilityFunctions.ps1"
        "$ScriptRoot\src\Core\OpenAPIParser.ps1"
        "$ScriptRoot\src\Core\ModuleGenerator.ps1"
    )
    
    foreach ($module in $coreModules) {
        if (Test-Path $module) {
            Write-Verbose "Loading: $module"
            . $module
        } else {
            throw "Required core module not found: $module"
        }
    }
    
    # Load enhancements based on user selection
    Write-Host "🔧 Loading enhancements..." -ForegroundColor Yellow
    
    $enhancementMap = @{
        'VerbMapping' = "$ScriptRoot\src\Enhancements\VerbMappingEnhancement.ps1"
        'ParameterFlattening' = "$ScriptRoot\src\Enhancements\ParameterEnhancement.ps1"
        'ErrorHandling' = "$ScriptRoot\src\Enhancements\ErrorHandlingEnhancement.ps1"
        'TypeSystem' = "$ScriptRoot\src\Enhancements\TypeSystemEnhancement.ps1"
    }
    
    $activeEnhancements = if ($IncludeEnhancements -contains 'All') {
        $enhancementMap.Keys
    } else {
        $IncludeEnhancements
    }
    
    foreach ($enhancement in $activeEnhancements) {
        $enhancementPath = $enhancementMap[$enhancement]
        if (Test-Path $enhancementPath) {
            Write-Verbose "Loading enhancement: $enhancement"
            . $enhancementPath
        } else {
            Write-Warning "Enhancement not found: $enhancementPath"
        }
    }
    
    # Validate and prepare paths
    Write-Host "📂 Preparing output directory..." -ForegroundColor Yellow
    
    $OpenAPIPath = Resolve-Path $OpenAPIPath
    $OutputPath = [System.IO.Path]::GetFullPath($OutputPath)
    
    if (Test-Path $OutputPath) {
        if ($Force) {
            Write-Warning "Removing existing output directory: $OutputPath"
            Remove-Item $OutputPath -Recurse -Force
        } else {
            throw "Output directory already exists: $OutputPath. Use -Force to overwrite."
        }
    }
    
    New-Item -Path $OutputPath -ItemType Directory -Force | Out-Null
    
    # Parse OpenAPI specification
    Write-Host "📖 Parsing OpenAPI specification..." -ForegroundColor Yellow
    $openApiSpec = Import-OpenAPISpecification -Path $OpenAPIPath
    
    # Generate module configuration
    $moduleConfig = @{
        Name = $ModuleName
        Path = $OutputPath
        BaseUri = $BaseUri
        Enhancements = $activeEnhancements
        OpenAPISpec = $openApiSpec
        GenerateReadme = $GenerateReadme.IsPresent
    }
    
    # Generate the PowerShell module
    Write-Host "⚡ Generating PowerShell module..." -ForegroundColor Yellow
    $result = New-PowerShellModule @moduleConfig
    
    # Generate README if requested
    if ($GenerateReadme) {
        Write-Host "📄 Generating module README..." -ForegroundColor Yellow
        $readmePath = "$ScriptRoot\src\Core\ReadmeGenerator.ps1"
        if (Test-Path $readmePath) {
            . $readmePath
            New-ModuleReadme -ModuleConfig $moduleConfig -OutputPath (Join-Path $OutputPath "README.md")
        }
    }
    
    # Success summary
    Write-Host "`n✅ Module generation completed successfully!" -ForegroundColor Green
    Write-Host "📍 Output location: $OutputPath" -ForegroundColor Cyan
    Write-Host "📦 Module name: $ModuleName" -ForegroundColor Cyan
    Write-Host "🔧 Active enhancements: $($activeEnhancements -join ', ')" -ForegroundColor Cyan
    
    if ($result.Functions) {
        Write-Host "🎯 Generated functions: $($result.Functions.Count)" -ForegroundColor Cyan
        $result.Functions | ForEach-Object { Write-Host "   • $_" -ForegroundColor Gray }
    }
    
    Write-Host "`n🚀 To use your new module:" -ForegroundColor Yellow
    Write-Host "   Import-Module '$OutputPath\$ModuleName.psd1'" -ForegroundColor White
    Write-Host "   Get-Command -Module $ModuleName" -ForegroundColor White
    
}
catch {
    Write-Error "❌ Module generation failed: $($_.Exception.Message)"
    Write-Error "💡 Use -Verbose for detailed error information"
    exit 1
}