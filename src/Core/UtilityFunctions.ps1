# Utility Functions Module
# Common utility functions used throughout the OpenAPI wrapper generator

<#
.SYNOPSIS
    Common utility functions for the OpenAPI wrapper generator

.DESCRIPTION
    This module provides utility functions that are used across multiple
    components of the OpenAPI wrapper generator, including string manipulation,
    validation, and file operations.
#>

function ConvertTo-PascalCase {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Text
    )
    
    if ([string]::IsNullOrWhiteSpace($Text)) {
        return $Text
    }
    
    # Split on various separators and convert to PascalCase
    $words = $Text -split '[_\-\s\.]+'
    $result = ($words | ForEach-Object { 
        if ($_.Length -gt 0) {
            $_.Substring(0,1).ToUpper() + $_.Substring(1).ToLower()
        }
    }) -join ''
    
    # Ensure it starts with a letter (required for PowerShell function names)
    if ($result -match '^\d') {
        $result = "Item$result"
    }
    
    return $result
}

function ConvertTo-CamelCase {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Text
    )
    
    $pascalCase = ConvertTo-PascalCase $Text
    if ($pascalCase.Length -gt 0) {
        return $pascalCase.Substring(0,1).ToLower() + $pascalCase.Substring(1)
    }
    return $pascalCase
}

function Test-ValidPowerShellName {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Name
    )
    
    # PowerShell identifier rules: start with letter or underscore, followed by letters, digits, or underscores
    return $Name -match '^[A-Za-z_][A-Za-z0-9_]*$'
}

function Get-SafeFileName {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$FileName
    )
    
    # Remove invalid file name characters
    $invalidChars = [System.IO.Path]::GetInvalidFileNameChars() -join ''
    $safeFileName = $FileName -replace "[$([regex]::Escape($invalidChars))]", '_'
    
    # Ensure it's not too long
    if ($safeFileName.Length -gt 100) {
        $safeFileName = $safeFileName.Substring(0, 100)
    }
    
    return $safeFileName
}

function Write-GeneratorLog {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Message,
        
        [Parameter()]
        [ValidateSet('Info', 'Warning', 'Error', 'Success', 'Progress')]
        [string]$Level = 'Info'
    )
    
    $timestamp = Get-Date -Format 'HH:mm:ss'
    
    switch ($Level) {
        'Info' { 
            Write-Host "[$timestamp] $Message" -ForegroundColor White 
        }
        'Warning' { 
            Write-Host "[$timestamp] WARNING: $Message" -ForegroundColor Yellow 
        }
        'Error' { 
            Write-Host "[$timestamp] ERROR: $Message" -ForegroundColor Red 
        }
        'Success' { 
            Write-Host "[$timestamp] ✅ $Message" -ForegroundColor Green 
        }
        'Progress' { 
            Write-Host "[$timestamp] 🔄 $Message" -ForegroundColor Cyan 
        }
    }
}

function New-PowerShellGuid {
    [CmdletBinding()]
    param()
    
    return [System.Guid]::NewGuid().ToString()
}

function Test-PowerShellVersion {
    [CmdletBinding()]
    param(
        [Parameter()]
        [Version]$MinimumVersion = [Version]'5.1'
    )
    
    $currentVersion = $PSVersionTable.PSVersion
    
    if ($currentVersion -lt $MinimumVersion) {
        throw "PowerShell version $MinimumVersion or higher is required. Current version: $currentVersion"
    }
    
    return $true
}

function Format-PowerShellHelp {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Text,
        
        [Parameter()]
        [int]$IndentLevel = 0,
        
        [Parameter()]
        [int]$MaxWidth = 80
    )
    
    if ([string]::IsNullOrWhiteSpace($Text)) {
        return $Text
    }
    
    $indent = '    ' * $IndentLevel
    $availableWidth = $MaxWidth - $indent.Length
    
    # Split into lines and wrap
    $lines = $Text -split "`n" | ForEach-Object {
        $line = $_.Trim()
        if ($line.Length -le $availableWidth) {
            "$indent$line"
        } else {
            # Simple word wrapping
            $words = $line -split '\s+'
            $currentLine = ""
            $result = @()
            
            foreach ($word in $words) {
                if (($currentLine + " " + $word).Length -le $availableWidth) {
                    if ($currentLine) {
                        $currentLine += " $word"
                    } else {
                        $currentLine = $word
                    }
                } else {
                    if ($currentLine) {
                        $result += "$indent$currentLine"
                    }
                    $currentLine = $word
                }
            }
            
            if ($currentLine) {
                $result += "$indent$currentLine"
            }
            
            $result
        }
    }
    
    return $lines -join "`n"
}

function Resolve-RelativePath {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path,
        
        [Parameter()]
        [string]$BasePath = $PWD.Path
    )
    
    if ([System.IO.Path]::IsPathRooted($Path)) {
        return $Path
    }
    
    return [System.IO.Path]::GetFullPath([System.IO.Path]::Combine($BasePath, $Path))
}

function Get-PowerShellTypeName {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$OpenAPIType,
        
        [Parameter()]
        [string]$Format,
        
        [Parameter()]
        [object]$Schema
    )
    
    # Enhanced type mapping
    $typeMap = @{
        'string' = @{
            'default' = 'string'
            'date' = 'DateTime'
            'date-time' = 'DateTime'
            'byte' = 'byte[]'
            'binary' = 'byte[]'
            'uuid' = 'Guid'
            'uri' = 'Uri'
            'email' = 'string'
            'hostname' = 'string'
            'ipv4' = 'IPAddress'
            'ipv6' = 'IPAddress'
        }
        'integer' = @{
            'default' = 'int'
            'int32' = 'int'
            'int64' = 'long'
        }
        'number' = @{
            'default' = 'double'
            'float' = 'float'
            'double' = 'double'
            'decimal' = 'decimal'
        }
        'boolean' = @{
            'default' = 'bool'
        }
        'array' = @{
            'default' = 'object[]'
        }
        'object' = @{
            'default' = 'PSCustomObject'
        }
        'file' = @{
            'default' = 'System.IO.FileInfo'
        }
    }
    
    if ($typeMap[$OpenAPIType] -and $typeMap[$OpenAPIType][$Format]) {
        return $typeMap[$OpenAPIType][$Format]
    } elseif ($typeMap[$OpenAPIType]) {
        return $typeMap[$OpenAPIType]['default']
    }
    
    return 'object'
}