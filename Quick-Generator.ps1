<#
.SYNOPSIS
    PowerShell OpenAPI Wrapper Generator - QUICK START Version
    
.DESCRIPTION
    Simplified version that works without complex enhancements.
    Perfect for getting started quickly!

.PARAMETER OpenAPIPath
    Path to OpenAPI/Swagger JSON file

.PARAMETER OutputPath  
    Where to create the module

.PARAMETER ModuleName
    Name for the PowerShell module

.EXAMPLE
    .\Quick-Generator.ps1 -OpenAPIPath ".\examples\swagger.json" -OutputPath ".\MyModule" -ModuleName "PetStoreAPI"
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [ValidateScript({Test-Path $_})]
    [string]$OpenAPIPath,
    
    [Parameter(Mandatory = $true)]
    [string]$OutputPath,
    
    [Parameter(Mandatory = $true)]
    [ValidatePattern('^[A-Za-z][A-Za-z0-9]*$')]
    [string]$ModuleName
)

Write-Host "🚀 Quick PowerShell API Wrapper Generator" -ForegroundColor Green
Write-Host "=========================================" -ForegroundColor Green

try {
    # Parse OpenAPI spec
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
    
    Write-Host "✅ Loaded: $($spec.info.title) v$($spec.info.version)" -ForegroundColor Green
    
    # Create output directory
    Write-Host "📂 Creating module directory..." -ForegroundColor Yellow
    if (Test-Path $OutputPath) {
        Remove-Item $OutputPath -Recurse -Force
    }
    New-Item -Path $OutputPath -ItemType Directory -Force | Out-Null
    
    # Generate functions
    Write-Host "⚡ Generating functions..." -ForegroundColor Yellow
    $functions = @()
    $functionContents = @()
    $totalOperations = 0
    
    # Count total operations first for progress tracking
    # Handle both JSON (PSObject) and YAML (Hashtable) parsing
    $pathNames = if ($spec.paths -is [System.Collections.Hashtable]) {
        $spec.paths.Keys
    } else {
        $spec.paths.PSObject.Properties.Name
    }
    
    foreach ($pathName in $pathNames) {
        $pathItem = $spec.paths.$pathName
        $httpMethods = if ($pathItem -is [System.Collections.Hashtable]) {
            $pathItem.Keys
        } else {
            $pathItem.PSObject.Properties.Name
        }
        
        foreach ($httpMethod in @('get', 'post', 'put', 'delete', 'patch', 'head', 'options')) {
            if ($httpMethods -contains $httpMethod) {
                $totalOperations++
            }
        }
    }
    
    Write-Host "📊 Processing $totalOperations operations..." -ForegroundColor Cyan
    $currentOperation = 0
    
    foreach ($pathName in $pathNames) {
        $pathItem = $spec.paths.$pathName
        $httpMethods = if ($pathItem -is [System.Collections.Hashtable]) {
            $pathItem.Keys
        } else {
            $pathItem.PSObject.Properties.Name
        }
        
        foreach ($httpMethod in @('get', 'post', 'put', 'delete', 'patch', 'head', 'options')) {
            if ($httpMethods -contains $httpMethod) {
                $currentOperation++
                $operation = $pathItem.$httpMethod
                
                # Progress indicator for large APIs
                if ($totalOperations -gt 50 -and $currentOperation % 10 -eq 0) {
                    $percent = [math]::Round(($currentOperation / $totalOperations) * 100)
                    Write-Host "   Progress: $currentOperation/$totalOperations ($percent%)" -ForegroundColor Gray
                }
                
                # Generate function name with PowerShell verbs
                $verb = switch ($httpMethod.ToUpper()) {
                    'GET' { 'Get' }
                    'POST' { 'New' }
                    'PUT' { 'Set' }
                    'DELETE' { 'Remove' }
                    'PATCH' { 'Update' }
                }
                
                $operationId = $operation.operationId
                if ($operationId) {
                    # Clean up operationId for PowerShell
                    $noun = $operationId -replace "^$httpMethod", '' -replace '[^a-zA-Z0-9]', ''
                    if (-not $noun) { $noun = 'Resource' }
                    $functionName = "$verb-$noun"
                } else {
                    # Generate from path
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
                
                # Generate function content
                $summary = $operation.summary ?? "Executes $httpMethod $pathName"
                $description = $operation.description ?? $summary
                
                $functionContent = @"
<#
.SYNOPSIS
    $summary

.DESCRIPTION
    $description

.PARAMETER BaseUri
    Base URI for the API (e.g., 'https://petstore.swagger.io/v2')

.PARAMETER Headers
    Additional headers as hashtable

.EXAMPLE
    $functionName -BaseUri 'https://petstore.swagger.io/v2'
#>
function $functionName {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = `$true)]
        [string]`$BaseUri,
        
        [Parameter()]
        [hashtable]`$Headers = @{}
    )
    
    `$uri = "`$BaseUri$pathName"
    `$method = '$($httpMethod.ToUpper())'
    
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
                $functionContents += $functionContent
                
                # Memory optimization for very large APIs
                if ($functions.Count % 100 -eq 0 -and $functions.Count -gt 0) {
                    Write-Host "   Generated $($functions.Count) functions..." -ForegroundColor Gray
                    [System.GC]::Collect() # Force garbage collection for memory management
                }
                
                Write-Host "  ✅ $functionName" -ForegroundColor Gray
            }
        }
    }
    
    # Create module files
    Write-Host "📄 Creating module files..." -ForegroundColor Yellow
    
    # For large APIs, create separate function files instead of one large .psm1
    if ($functions.Count -gt 50) {
        Write-Host "🗂️  Large API detected ($($functions.Count) functions) - creating modular structure..." -ForegroundColor Cyan
        
        # Create Functions subdirectory
        $functionsDir = Join-Path $OutputPath "Functions"
        New-Item -Path $functionsDir -ItemType Directory -Force | Out-Null
        
        # Create individual function files
        for ($i = 0; $i -lt $functions.Count; $i++) {
            $functionName = $functions[$i]
            $functionContent = $functionContents[$i]
            
            $functionFile = Join-Path $functionsDir "$functionName.ps1"
            $functionContent | Out-File -FilePath $functionFile -Encoding UTF8
            
            if ($i % 20 -eq 0) {
                $percent = [math]::Round(($i / $functions.Count) * 100)
                Write-Host "   Creating function files: $i/$($functions.Count) ($percent%)" -ForegroundColor Gray
            }
        }
        
        # Create main .psm1 that imports all functions
        $moduleContent = @"
# $ModuleName - Generated PowerShell Module (Modular Structure)
# Source: $($spec.info.title) v$($spec.info.version)
# Generated: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')
# Functions: $($functions.Count)

# Import all function files
`$functionsPath = Join-Path `$PSScriptRoot 'Functions'
if (Test-Path `$functionsPath) {
    Get-ChildItem `$functionsPath -Filter '*.ps1' | ForEach-Object {
        . `$_.FullName
    }
}

# Export all functions
Export-ModuleMember -Function @($($functions | ForEach-Object { "'$_'" } | Join-String -Separator ', '))
"@
    } else {
        # Create single .psm1 file for smaller APIs
        $moduleContent = @"
# $ModuleName - Generated PowerShell Module
# Source: $($spec.info.title) v$($spec.info.version)
# Generated: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')

$($functionContents -join "`n")

# Export all functions
Export-ModuleMember -Function @($($functions | ForEach-Object { "'$_'" } | Join-String -Separator ', '))
"@
    }
    
    $moduleFile = Join-Path $OutputPath "$ModuleName.psm1"
    $moduleContent | Out-File -FilePath $moduleFile -Encoding UTF8
    
    # Create .psd1 manifest
    $guid = [System.Guid]::NewGuid()
    
    # Normalize version string for PowerShell module requirements
    $version = $spec.info.version ?? '1.0.0'
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
    
    $manifestContent = @"
@{
    RootModule = '$ModuleName.psm1'
    ModuleVersion = '$version'
    GUID = '$guid'
    Author = 'PowerShell OpenAPI Generator'
    Description = '$($spec.info.description ?? "Generated from $($spec.info.title)")'
    PowerShellVersion = '5.1'
    FunctionsToExport = @($($functions | ForEach-Object { "'$_'" } | Join-String -Separator ', '))
    CmdletsToExport = @()
    VariablesToExport = @()
    AliasesToExport = @()
}
"@
    
    $manifestFile = Join-Path $OutputPath "$ModuleName.psd1"
    $manifestContent | Out-File -FilePath $manifestFile -Encoding UTF8
    
    # Success!
    Write-Host "`n🎉 Module generation completed!" -ForegroundColor Green
    Write-Host "📍 Location: $OutputPath" -ForegroundColor Cyan
    Write-Host "📦 Module: $ModuleName" -ForegroundColor Cyan
    Write-Host "🎯 Functions: $($functions.Count)" -ForegroundColor Cyan
    Write-Host "📊 Operations: $totalOperations" -ForegroundColor Cyan
    
    if ($functions.Count -gt 50) {
        Write-Host "🗂️  Structure: Modular (Functions in separate files)" -ForegroundColor Cyan
    } else {
        Write-Host "📄 Structure: Single file" -ForegroundColor Cyan
    }
    
    # Show some statistics
    $verbStats = $functions | Group-Object { ($_ -split '-')[0] } | Sort-Object Count -Descending
    Write-Host "`n📈 Function Statistics:" -ForegroundColor Yellow
    $verbStats | Select-Object -First 5 | ForEach-Object {
        Write-Host "   $($_.Name): $($_.Count) functions" -ForegroundColor Gray
    }
    
    Write-Host "`n🚀 To use your module:" -ForegroundColor Yellow
    Write-Host "   Import-Module '$manifestFile'" -ForegroundColor White
    Write-Host "   Get-Command -Module $ModuleName | Measure-Object" -ForegroundColor White
    
    if ($spec.host) {
        $baseUrl = "https://$($spec.host)"
        if ($spec.basePath) { $baseUrl += $spec.basePath }
        Write-Host "`n💡 Example usage:" -ForegroundColor Yellow
        Write-Host "   $($functions[0]) -BaseUri '$baseUrl'" -ForegroundColor White
        
        if ($functions.Count -gt 10) {
            Write-Host "   # Use Get-Command to explore all $($functions.Count) available functions" -ForegroundColor Gray
        }
    }
    
    # Performance info for large APIs
    if ($functions.Count -gt 100) {
        Write-Host "`n⚡ Performance tip:" -ForegroundColor Yellow
        Write-Host "   Large API detected! Consider using specific function imports:" -ForegroundColor Gray
        Write-Host "   Import-Module '$manifestFile' -Function 'Get-*'" -ForegroundColor White
    }
    
}
catch {
    Write-Error "❌ Generation failed: $($_.Exception.Message)"
    exit 1
}