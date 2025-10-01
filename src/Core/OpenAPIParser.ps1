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
                Write-Verbose "Parsing JSON specification"
                $spec = $content | ConvertFrom-Json -Depth 200
            }
            {$_ -in '.yaml', '.yml'} {
                Write-Verbose "Parsing YAML specification"
                if (-not (Get-Command -Name ConvertFrom-Yaml -ErrorAction SilentlyContinue)) {
                    if (Get-Module -ListAvailable -Name powershell-yaml) {
                        Import-Module powershell-yaml -ErrorAction Stop
                    } else {
                        throw "ConvertFrom-Yaml not available. Please use PowerShell 7+ or install powershell-yaml module"
                    }
                }
                $spec = ConvertFrom-Yaml -Yaml $content
            }
            default {
                throw "Unsupported file format: $extension. Only .json, .yaml, and .yml are supported."
            }
        }
        
        # Convert hashtable to PSCustomObject for consistent handling
        if ($spec -is [hashtable]) {
            $spec = Convert-HashtableToPSObject $spec
        }
        
        # Normalize and resolve the specification
        $normalizedSpec = Resolve-OpenAPISpecification -Specification $spec
        
        return $normalizedSpec
    }
    catch {
        Write-Error "Failed to parse OpenAPI specification: $($_.Exception.Message)"
        throw
    }
}

function Convert-HashtableToPSObject {
    param([hashtable]$InputObject)
    
    $psObject = New-Object PSCustomObject
    
    foreach ($key in $InputObject.Keys) {
        $value = $InputObject[$key]
        
        # Recursively convert nested hashtables
        if ($value -is [hashtable]) {
            $value = Convert-HashtableToPSObject $value
        }
        elseif ($value -is [System.Collections.IEnumerable] -and $value -isnot [string]) {
            # Handle arrays of hashtables
            $convertedArray = @()
            foreach ($item in $value) {
                if ($item -is [hashtable]) {
                    $convertedArray += Convert-HashtableToPSObject $item
                } else {
                    $convertedArray += $item
                }
            }
            $value = $convertedArray
        }
        
        $psObject | Add-Member -NotePropertyName $key -NotePropertyValue $value
    }
    
    return $psObject
}

function Resolve-OpenAPISpecification {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [object]$Specification
    )
    
    # Resolve definitions from different OpenAPI versions
    $definitions = @{}
    
    # OpenAPI 3.x uses components/schemas
    if ($Specification.components -and $Specification.components.schemas) {
        foreach ($key in $Specification.components.schemas.PSObject.Properties.Name) {
            $definitions[$key] = $Specification.components.schemas.$key
        }
    }
    
    # OpenAPI 2.x uses definitions
    if ($Specification.definitions) {
        foreach ($key in $Specification.definitions.PSObject.Properties.Name) {
            $definitions[$key] = $Specification.definitions.$key
        }
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
    
    # Handle both PSObject and hashtable access
    if ($Specification -is [hashtable]) {
        return if ($Specification.ContainsKey('_resolvedDefinitions')) { $Specification['_resolvedDefinitions'] } else { @{} }
    } else {
        return if ($Specification._resolvedDefinitions) { $Specification._resolvedDefinitions } else { @{} }
    }
}

function Get-OpenAPIInfo {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [object]$Specification
    )
    
    # Handle both PSObject and hashtable access
    if ($Specification -is [hashtable]) {
        return if ($Specification.ContainsKey('info')) { $Specification['info'] } else { @{
            title = "Generated API"
            version = "1.0.0"
            description = "PowerShell module generated from OpenAPI specification"
        }}
    } else {
        return if ($Specification.info) { $Specification.info } else { @{
            title = "Generated API"
            version = "1.0.0"
            description = "PowerShell module generated from OpenAPI specification"
        }}
    }
}