<#
.SYNOPSIS
    PowerShell Module README Generator for OpenAPI Wrappers
    
.DESCRIPTION
    Generates comprehensive README.md documentation for PowerShell modules created by
    the Module-GEN-Parser.ps1 script. Creates professional documentation including
    function listings, usage examples, authentication details, and complete API reference.
    
    Features:
    - Automatic function categorization by HTTP verbs
    - Authentication documentation
    - Installation instructions
    - Quick start examples
    - Complete function reference with help integration
    - Professional markdown formatting
    
.PARAMETER ModulePath
    Path to the PowerShell module (.psm1 file) to document
    
.PARAMETER SpecPath
    Path to the original OpenAPI specification file used to generate the module
    
.EXAMPLE
    .\Generate-README.ps1 -ModulePath .\export\MyAPI\MyAPI.psm1 -SpecPath .\api-spec.yaml
    
    Generates README.md for the MyAPI module using the original YAML specification
    
.EXAMPLE
    .\Generate-README.ps1 -ModulePath .\modules\Hera\Hera.psm1 -SpecPath .\swagger.json
    
    Creates documentation for the Hera module from a JSON OpenAPI spec
    
.INPUTS
    PowerShell module file (.psm1) and OpenAPI specification file
    
.OUTPUTS
    README.md file in the module directory
    
.NOTES
    Name:           Generate-README.ps1
    Author:         Generated PowerShell OpenAPI Wrapper
    Created:        2025-09-30
    Version:        1.0.0
    PowerShell:     7.0+ (ConvertFrom-Yaml support) or 5.1+ with powershell-yaml module
    
    Dependencies:
    - PowerShell 7.0+ (includes ConvertFrom-Yaml) OR
    - PowerShell 5.1+ with powershell-yaml module for YAML support
    - JSON specs work with any PowerShell version
    - Target module must be importable
    
    Generated README includes:
    - Module overview and statistics
    - Installation instructions
    - Authentication documentation
    - Categorized function listings
    - Usage examples and quick start guide
    - Complete function reference
    
.LINK
    https://github.com/PowerShell/PowerShell
    
.LINK
    https://swagger.io/specification/
    
.COMPONENT
    Documentation
    
.FUNCTIONALITY
    README Generation
#>

param(
    [Parameter(Mandatory = $true)]
    [string]$ModulePath,
    
    [Parameter(Mandatory = $true)]
    [string]$SpecPath
)

function Load-OpenApi {
	param([string]$Path)
	if (-not (Test-Path -Path $Path)) { throw "Spec file '$Path' not found" }
	$ext = [IO.Path]::GetExtension($Path).ToLower()
	$raw = Get-Content -Raw -Path $Path
	if ($ext -in '.yaml', '.yml') {
		if (-not (Get-Command -Name ConvertFrom-Yaml -ErrorAction SilentlyContinue)) {
			if (Get-Module -ListAvailable -Name powershell-yaml) {
				Import-Module powershell-yaml -ErrorAction Stop
			} else {
				throw "ConvertFrom-Yaml not available. Please use PowerShell 7+ or install powershell-yaml module"
			}
		}
		return ConvertFrom-Yaml -Yaml $raw
	} elseif ($ext -eq '.json') {
		return $raw | ConvertFrom-Json -Depth 200
	} else {
		throw "Unknown spec extension: $ext"
	}
}

function Generate-ModuleReadme {
    param(
        [string]$ModulePath,
        [string]$SpecPath
    )
    
    # Load the spec
    $spec = Load-OpenApi -Path $SpecPath
    
    # Get module info
    $moduleDir = Split-Path $ModulePath -Parent
    $moduleName = (Get-Item $ModulePath).BaseName
    
    # Load the module to get function info
    Import-Module $ModulePath -Force
    $functions = Get-Command -Module $moduleName
    
    # Get base URL from spec
    $baseUrl = if ($spec.servers -and $spec.servers.Count -gt 0) { $spec.servers[0].url } else { "https://api.example.com" }
    
    $title = if ($spec.info.title) { $spec.info.title } else { $moduleName }
    $version = if ($spec.info.version) { $spec.info.version } else { "unknown" }
    $description = if ($spec.info.description) { $spec.info.description } else { "PowerShell wrapper for $title API" }

    $readme = @()
    
    # Header
    $readme += "# $title PowerShell Module"
    $readme += ""
    $readme += "**Generated PowerShell API Wrapper**"
    $readme += ""
    $readme += "- **API Version**: $version"
    $readme += "- **Base URL**: ``$baseUrl``"
    $readme += "- **Generated Functions**: $($functions.Count)"
    $readme += "- **Generated**: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
    $readme += ""
    
    # Description
    $readme += "## Description"
    $readme += ""
    $readme += $description
    $readme += ""
    
    # Installation
    $readme += "## Installation"
    $readme += ""
    $readme += "``````powershell"
    $readme += "# Import the generated module"
    $readme += "Import-Module -Name `"$ModulePath`""
    $readme += ""
    $readme += "# Or install in PowerShell modules path"
    $readme += "Copy-Item -Path `"$moduleDir`" -Destination `"`$env:PSModulePath.Split(';')[0]`" -Recurse"
    $readme += "Import-Module -Name $moduleName"
    $readme += "``````"
    $readme += ""
    
    # Authentication
    $readme += "## Authentication"
    $readme += ""
    $readme += "This API uses **X-TOKEN** header authentication. All functions support the following authentication parameters:"
    $readme += ""
    $readme += "- **``-X_TOKEN``**: API token for authentication"
    $readme += "- **``-BaseUrl``**: Override the default base URL" 
    $readme += "- **``-NoThrow``**: Don't throw exceptions on HTTP errors, return `$null instead"
    $readme += ""
    
    # Function list
    $readme += "## Available Functions"
    $readme += ""
    $readme += "This module provides $($functions.Count) PowerShell functions:"
    $readme += ""
    
    # Group by HTTP method pattern
    $getFunctions = $functions | Where-Object { $_.Name -like "Get-*" } | Sort-Object Name
    $newFunctions = $functions | Where-Object { $_.Name -like "New-*" } | Sort-Object Name
    $setFunctions = $functions | Where-Object { $_.Name -like "Set-*" } | Sort-Object Name
    $removeFunctions = $functions | Where-Object { $_.Name -like "Remove-*" } | Sort-Object Name
    $otherFunctions = $functions | Where-Object { $_.Name -notlike "Get-*" -and $_.Name -notlike "New-*" -and $_.Name -notlike "Set-*" -and $_.Name -notlike "Remove-*" } | Sort-Object Name
    
    if ($getFunctions.Count -gt 0) {
        $readme += "### GET Operations (Retrieve Data)"
        $readme += ""
        foreach ($func in $getFunctions) {
            $readme += "- ``$($func.Name)``"
        }
        $readme += ""
    }
    
    if ($newFunctions.Count -gt 0) {
        $readme += "### POST Operations (Create Data)"
        $readme += ""
        foreach ($func in $newFunctions) {
            $readme += "- ``$($func.Name)``"
        }
        $readme += ""
    }
    
    if ($setFunctions.Count -gt 0) {
        $readme += "### PUT/PATCH Operations (Update Data)"
        $readme += ""
        foreach ($func in $setFunctions) {
            $readme += "- ``$($func.Name)``"
        }
        $readme += ""
    }
    
    if ($removeFunctions.Count -gt 0) {
        $readme += "### DELETE Operations (Delete Data)"
        $readme += ""
        foreach ($func in $removeFunctions) {
            $readme += "- ``$($func.Name)``"
        }
        $readme += ""
    }
    
    if ($otherFunctions.Count -gt 0) {
        $readme += "### Other Operations"
        $readme += ""
        foreach ($func in $otherFunctions) {
            $readme += "- ``$($func.Name)``"
        }
        $readme += ""
    }
    
    # Quick examples
    $readme += "## Quick Start Examples"
    $readme += ""
    $readme += "``````powershell"
    $readme += "# Set your API token"
    $readme += "`$apiToken = 'your-token-here'"
    $readme += ""
    
    if ($getFunctions.Count -gt 0) {
        $firstGetFunction = $getFunctions[0]
        $readme += "# Example: Get data"
        $readme += "Get-Help $($firstGetFunction.Name) -Full"
        $readme += "$($firstGetFunction.Name) -X_TOKEN `$apiToken"
        $readme += ""
    }
    
    $readme += "# List all available functions"
    $readme += "Get-Command -Module $moduleName"
    $readme += ""
    $readme += "# Get detailed help for any function"
    $readme += "Get-Help <FunctionName> -Full"
    $readme += "``````"
    $readme += ""
    
    # Function reference with help
    $readme += "## Function Reference"
    $readme += ""
    $readme += "Each function includes comprehensive help documentation. Use ``Get-Help <FunctionName> -Full`` for detailed information including:"
    $readme += ""
    $readme += "- Parameter descriptions and types"
    $readme += "- Required vs optional parameters"
    $readme += "- Usage examples" 
    $readme += "- API endpoint mapping"
    $readme += ""
    
    # Sample function documentation
    if ($functions.Count -gt 0) {
        $sampleFunction = $functions[0]
        $readme += "### Example Function Help"
        $readme += ""
        $readme += "``````powershell"
        $readme += "Get-Help $($sampleFunction.Name) -Full"
        $readme += "``````"
        $readme += ""
    }
    
    # Footer
    $readme += "## Notes"
    $readme += ""
    $readme += "- This module was automatically generated from the OpenAPI specification"
    $readme += "- All functions support ``-Verbose`` and ``-Debug`` parameters for troubleshooting"
    $readme += "- Functions include built-in error handling with optional ``-NoThrow`` parameter"
    $readme += "- Base URL can be overridden per function call using ``-BaseUrl`` parameter"
    $readme += ""
    $readme += "## Support"
    $readme += ""
    $readme += "For issues with the generated wrapper:"
    $readme += "1. Check function help: ``Get-Help <FunctionName> -Full``"
    $readme += "2. Use ``-Verbose`` flag for detailed request information"
    $readme += "3. Verify API token and base URL are correct"
    $readme += ""
    $readme += "---"
    $readme += "*Generated by PowerShell OpenAPI Wrapper Generator*"
    $readme += "*Generated on: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')*"

    return $readme -join "`n"
}

# Main execution
try {
    Write-Host "Generating README for module: $ModulePath"
    Write-Host "Using OpenAPI spec: $SpecPath"
    
    $readmeContent = Generate-ModuleReadme -ModulePath $ModulePath -SpecPath $SpecPath
    $moduleDir = Split-Path $ModulePath -Parent
    $readmePath = Join-Path $moduleDir "README.md"
    
    $readmeContent | Out-File -FilePath $readmePath -Encoding UTF8
    Write-Host "README.md created successfully: $readmePath"
    
} catch {
    Write-Error "Failed to generate README: $($_.Exception.Message)"
    exit 1
}