# OpenAPI Parser Module
# Core functionality for parsing OpenAPI/Swagger specifications

<#
.SYNOPSIS
    Parses OpenAPI/Swagger specifications into PowerShell objects

.DESCRIPTION
    This module provides functions to parse OpenAPI 2.0 and 3.0 specifications
    from JSON or YAML files and convert them into structured PowerShell objects
    that can be used by the module generator.
#>

function Import-OpenAPISpecification {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateScript({Test-Path $_})]
        [string]$Path
    )
    
    Write-Verbose "Parsing OpenAPI specification from: $Path"
    
    try {
        $content = Get-Content -Path $Path -Raw -Encoding UTF8
        
        # Determine file format and parse accordingly
        $extension = [System.IO.Path]::GetExtension($Path).ToLower()
        
        switch ($extension) {
            '.json' {
                $spec = $content | ConvertFrom-Json
            }
            {$_ -in @('.yaml', '.yml')} {
                # For YAML parsing, we'll use a simple approach
                # In production, you might want to use a proper YAML parser
                if (Get-Command ConvertFrom-Yaml -ErrorAction SilentlyContinue) {
                    $spec = $content | ConvertFrom-Yaml
                } else {
                    throw "YAML parsing requires PowerShell-Yaml module. Please install it with: Install-Module PowerShell-Yaml"
                }
            }
            default {
                throw "Unsupported file format: $extension. Only JSON and YAML are supported."
            }
        }
        
        # Validate OpenAPI structure
        if (-not $spec.swagger -and -not $spec.openapi) {
            throw "Invalid OpenAPI specification: Missing 'swagger' or 'openapi' field"
        }
        
        # Normalize specification structure
        $normalizedSpec = Resolve-OpenAPIReferences -Specification $spec
        
        Write-Verbose "Successfully parsed OpenAPI specification (version: $($spec.swagger ?? $spec.openapi))"
        return $normalizedSpec
    }
    catch {
        throw "Failed to parse OpenAPI specification: $($_.Exception.Message)"
    }
}

function Resolve-OpenAPIReferences {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [object]$Specification
    )
    
    Write-Verbose "Resolving OpenAPI references..."
    
    $definitions = @{}
    
    # Handle Swagger 2.0 definitions
    if ($Specification.definitions) {
        Write-Verbose "Found Swagger 2.0 definitions"
        $definitions = $Specification.definitions
    }
    
    # Handle OpenAPI 3.0 components/schemas
    if ($Specification.components -and $Specification.components.schemas) {
        Write-Verbose "Found OpenAPI 3.0 components/schemas"
        $definitions = $Specification.components.schemas
    }
    
    # Add resolved definitions to the specification
    $Specification | Add-Member -NotePropertyName '_resolvedDefinitions' -NotePropertyValue $definitions -Force
    
    return $Specification
}

function Get-OpenAPIPaths {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [object]$Specification
    )
    
    if (-not $Specification.paths) {
        Write-Warning "No paths found in OpenAPI specification"
        return @{}
    }
    
    return $Specification.paths
}

function Get-OpenAPIDefinitions {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [object]$Specification
    )
    
    return $Specification._resolvedDefinitions ?? @{}
}

function Get-OpenAPIInfo {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [object]$Specification
    )
    
    return $Specification.info ?? @{
        title = "Generated API"
        version = "1.0.0"
        description = "PowerShell module generated from OpenAPI specification"
    }
}