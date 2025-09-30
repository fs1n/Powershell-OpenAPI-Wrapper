<#
.SYNOPSIS
    PowerShell OpenAPI Wrapper Module Generator
    
.DESCRIPTION
    Generates a comprehensive PowerShell API wrapper module from an OpenAPI 3.0.1+ specification.
    Supports both YAML and JSON input formats and creates professional PowerShell modules with
    proper parameter validation, comment-based help, and PowerShell naming conventions.
    
    Features:
    - Universal OpenAPI 3.0.1+ spec support (YAML/JSON)
    - PowerShell-idiomatic function names (Get-, New-, Set-, Remove-)
    - Comprehensive parameter validation and type checking
    - Built-in authentication support (X-TOKEN header)
    - Comment-based help documentation for all functions
    - Error handling with optional NoThrow parameter
    - Configurable base URL per function call
    
.PARAMETER SpecPath
    Path to the OpenAPI specification file (.yaml, .yml, or .json)
    
.PARAMETER OutDir
    Output directory for the generated module (default: .\export)
    
.PARAMETER AutoInstallYamlModule
    Automatically install the powershell-yaml module if ConvertFrom-Yaml is not available
    
.EXAMPLE
    .\Module-GEN-Parser.ps1 -SpecPath .\api-spec.yaml -OutDir .\modules
    
    Generates a PowerShell module from a YAML OpenAPI spec in the .\modules directory
    
.EXAMPLE
    .\Module-GEN-Parser.ps1 -SpecPath .\swagger.json -OutDir .\export -AutoInstallYamlModule
    
    Generates a module from JSON spec and auto-installs YAML module if needed
    
.INPUTS
    OpenAPI 3.0.1+ specification file (YAML or JSON format)
    
.OUTPUTS
    PowerShell module directory containing:
    - .psm1 module file with all API wrapper functions
    - .psd1 module manifest file
    
.NOTES
    Name:           Module-GEN-Parser.ps1
    Author:         Generated PowerShell OpenAPI Wrapper
    Created:        2025-09-30
    Version:        1.0.0
    PowerShell:     7.0+ (ConvertFrom-Yaml support) or 5.1+ with powershell-yaml module
    
    Dependencies:
    - PowerShell 7.0+ (includes ConvertFrom-Yaml) OR
    - PowerShell 5.1+ with powershell-yaml module for YAML support
    - JSON specs work with any PowerShell version
    
    Generated functions include:
    - Parameter validation and type checking
    - Comment-based help documentation
    - Error handling with optional -NoThrow parameter
    - Authentication support via -X_TOKEN parameter
    - Configurable base URL via -BaseUrl parameter
    
.LINK
    https://github.com/PowerShell/PowerShell
    
.LINK
    https://swagger.io/specification/
    
.COMPONENT
    OpenAPI
    
.FUNCTIONALITY
    API Wrapper Generation
#>

param(
	[Parameter(Mandatory = $true, Position = 0)]
	[string]$SpecPath,

	[string]$OutDir = '.\export',

	[switch]$AutoInstallYamlModule
)

function Write-Log {
	param([string]$Message)
	$ts = (Get-Date -Format o)
	Write-Host "[parser] $ts`t$Message"
}

function Load-OpenApi {
	param([string]$Path)
	if (-not (Test-Path -Path $Path)) { throw "Spec file '$Path' not found" }
	$ext = [IO.Path]::GetExtension($Path).ToLower()
	$raw = Get-Content -Raw -Path $Path
	if ($ext -in '.yaml', '.yml') {
		# Prefer built-in ConvertFrom-Yaml (PowerShell 7+), but allow installing a module as fallback
		if (-not (Get-Command -Name ConvertFrom-Yaml -ErrorAction SilentlyContinue)) {
			# try importing powershell-yaml module if available
			if (Get-Module -ListAvailable -Name powershell-yaml) {
				Import-Module powershell-yaml -ErrorAction Stop
			} elseif ($AutoInstallYamlModule) {
				Write-Log "ConvertFrom-Yaml not found — attempting Install-Module powershell-yaml (CurrentUser)..."
				try {
					Install-Module -Name powershell-yaml -Scope CurrentUser -Force -AllowClobber -ErrorAction Stop
					Import-Module powershell-yaml -ErrorAction Stop
				} catch {
					throw "Failed to install 'powershell-yaml'. Please install it manually or run this script in PowerShell 7+. Install command: Install-Module -Name powershell-yaml -Scope CurrentUser"
				}
			} else {
				throw "ConvertFrom-Yaml not available. Please use PowerShell 7+ or provide a JSON spec. To install a compatible module run: Install-Module -Name powershell-yaml -Scope CurrentUser"
			}
		}
		return ConvertFrom-Yaml -Yaml $raw
	} elseif ($ext -eq '.json') {
		return $raw | ConvertFrom-Json -Depth 200
	} else {
		throw "Unknown spec extension: $ext"
	}
}

function Safe-ParameterName {
	param([string]$name)
	# Convert parameter names with special characters to PowerShell-friendly names
	$safe = $name -replace '[\[\]()]', '_' -replace '[^A-Za-z0-9_]', '_'
	$safe = $safe -replace '_+', '_' -replace '^_|_$', ''
	if ($safe -match '^[0-9]') { $safe = '_' + $safe }
	return $safe
}

function Safe-Name {
	param([string]$s)
	if (-not $s) { return 'OpenApiModule' }
	$r = ($s -replace '[^A-Za-z0-9]', '_')
	if ($r -match '^[0-9]') { $r = '_' + $r }
	return $r.Trim('_')
}

function Build-UriLiteral {
	param(
		[string]$PathTemplate
	)
	# Replace {param} with string interpolation expression like $id -> $($id)
	$result = $PathTemplate -replace '\{([^}]+)\}', '$($$matches[1])'
	if ($result -notmatch '^/') { $result = '/' + $result }
	return $result
}

function Get-PowerShellVerbForHttpMethod {
	param([string]$Method, [string]$Path, [string]$OperationId)
	
	$resource = ($Path -split '/' | Where-Object { $_ -and $_ -notmatch '^\{.*\}$' } | Select-Object -Last 1)
	if ($resource) {
		$resource = $resource -replace '_', '-'
		$resource = (Get-Culture).TextInfo.ToTitleCase($resource)
	} else { 
		$resource = 'Resource' 
	}
	
	switch ($Method.ToUpper()) {
		'GET' { 
			if ($Path -match '\{[^}]+\}$') { "Get-$resource" }
			else { "Get-${resource}List" }
		}
		'POST' { "New-$resource" }
		'PUT' { "Set-$resource" }
		'PATCH' { "Update-$resource" }
		'DELETE' { "Remove-$resource" }
		default { "Invoke-$resource$Method" }
	}
}

function Build-ParameterValidation {
	param($Parameter)
	
	$validation = @()
	if ($Parameter.required -eq $true) {
		$validation += '[Parameter(Mandatory=$true)]'
	}
	
	# Add type validation based on schema
	$type = 'string'
	if ($Parameter.schema) {
		switch ($Parameter.schema.type) {
			'integer' { $type = 'int' }
			'number' { $type = 'double' }
			'boolean' { $type = 'bool' }
			'array' { $type = 'string[]' }
		}
		
		# Add enum validation
		if ($Parameter.schema.enum) {
			$enumValues = ($Parameter.schema.enum | ForEach-Object { "'$_'" }) -join ', '
			$validation += "[ValidateSet($enumValues)]"
		}
	}
	
	return $validation, $type
}

function Build-CommentBasedHelp {
	param($Operation, $Path, $Method)
	
	$synopsis = if ($Operation.summary) { $Operation.summary } else { "$Method $Path" }
	$description = if ($Operation.description) { $Operation.description } else { $synopsis }
	
	$help = @"
<#
.SYNOPSIS
$synopsis

.DESCRIPTION
$description

.PARAMETER BaseUrl
The base URL for the API (defaults to server URL from spec)

.PARAMETER X_TOKEN
Authentication token for X-TOKEN header

.PARAMETER NoThrow
Don't throw exceptions on HTTP errors, return `$null instead

#>
"@
	
	return $help
}

function Generate-Module {
	param(
		$Spec,
		[string]$OutRoot
	)

	$title = if ($Spec.info -and $Spec.info.title) { $Spec.info.title } else { 'OpenApiModule' }
	$moduleName = Safe-Name -s $title
	# Ensure OutRoot exists and is a resolved path
	$resolvedOut = Resolve-Path -Path $OutRoot -ErrorAction SilentlyContinue | Select-Object -First 1
	if (-not $resolvedOut) {
		New-Item -ItemType Directory -Path $OutRoot -Force | Out-Null
		$resolvedOut = Resolve-Path -Path $OutRoot -ErrorAction Stop
	}
	$moduleDir = Join-Path -Path $resolvedOut.Path $moduleName
	if (-not (Test-Path -Path $moduleDir)) { New-Item -ItemType Directory -Path $moduleDir -Force | Out-Null }

	# determine base url (first server)
	$baseUrl = $null
	if ($Spec.servers -and $Spec.servers.Count -gt 0) {
		$baseUrl = $Spec.servers[0].url
	}

	$psm1Path = Join-Path $moduleDir "$moduleName.psm1"
	$psd1Path = Join-Path $moduleDir "$moduleName.psd1"

	$functionsCode = New-Object System.Collections.Generic.List[string]
	$exportedFunctions = New-Object System.Collections.Generic.List[string]
	$functionMetadata = New-Object System.Collections.Generic.List[PSObject]

	# Iterate paths
	if (-not $Spec.paths) { throw "Spec has no paths" }
	
	# Handle both PSCustomObject (JSON) and Hashtable (YAML) paths
	$pathEntries = @()
	if ($Spec.paths -is [System.Collections.Hashtable]) {
		$pathEntries = $Spec.paths.GetEnumerator()
		Write-Log "Found $($Spec.paths.Count) path(s) in spec (Hashtable)"
	} else {
		# PSCustomObject from JSON
		$pathEntries = $Spec.paths.PSObject.Properties | ForEach-Object { @{Key = $_.Name; Value = $_.Value} }
		Write-Log "Found $($pathEntries.Count) path(s) in spec (PSCustomObject)"
	}
	
	foreach ($pathEntry in $pathEntries) {
		$path = $pathEntry.Key
		$pathObj = $pathEntry.Value
		Write-Log "Processing path: $path"
		
		# Get actual HTTP method properties, filtering out .NET dictionary properties
		$httpMethods = @('get', 'post', 'put', 'patch', 'delete', 'head', 'options')
		
		foreach ($methodName in $httpMethods) {
			if ($pathObj.$methodName) {
				$method = $methodName.ToUpper()
				$op = $pathObj.$methodName
				Write-Log "Found operation: $method $path (operationId: $($op.operationId))"

				# Generate PowerShell-friendly function name
				$fnName = Get-PowerShellVerbForHttpMethod -Method $method -Path $path -OperationId $op.operationId
				$exportedFunctions.Add($fnName)

				# collect parameters: path/query from both operation and path item
				$pathParams = New-Object System.Collections.Generic.List[PSObject]
				$queryParams = New-Object System.Collections.Generic.List[PSObject]

				$accParams = @()
				if ($pathObj.parameters) { 
					Write-Log "Found $($pathObj.parameters.Count) path-level parameters"
					$accParams += $pathObj.parameters 
				}
				if ($op.parameters) { 
					Write-Log "Found $($op.parameters.Count) operation-level parameters"
					$accParams += $op.parameters 
				}

				# Resolve parameter references and collect typed parameters
				$allParameters = New-Object System.Collections.Generic.List[PSObject]
				foreach ($p in $accParams) {
					$resolvedParam = $p
					# Handle parameter references like {"$ref": "#/components/parameters/..."}
					if ($p.'$ref') {
						$refPath = $p.'$ref' -replace '^#/', '' -split '/'
						$resolvedParam = $Spec
						foreach ($segment in $refPath) {
							# Handle both PSCustomObject and Hashtable navigation
							if ($resolvedParam -is [System.Collections.Hashtable] -and $resolvedParam.$segment) {
								$resolvedParam = $resolvedParam.$segment
							} elseif ($resolvedParam.PSObject.Properties[$segment]) {
								$resolvedParam = $resolvedParam.PSObject.Properties[$segment].Value
							} else {
								Write-Log "Warning: Could not resolve parameter reference: $($p.'$ref')"
								$resolvedParam = $null
								break
							}
						}
					}
					
					if ($resolvedParam -and $resolvedParam.in) {
						if ($resolvedParam.in -eq 'path') { $pathParams.Add($resolvedParam) }
						elseif ($resolvedParam.in -eq 'query') { $queryParams.Add($resolvedParam) }
						
						# Add to metadata collection
						$paramType = 'string'
						if ($resolvedParam.schema) {
							switch ($resolvedParam.schema.type) {
								'integer' { $paramType = 'int' }
								'number' { $paramType = 'double' }
								'boolean' { $paramType = 'bool' }
								'array' { $paramType = 'string[]' }
							}
						}
						
						$allParameters.Add([PSCustomObject]@{
							Name = (Safe-ParameterName -name $resolvedParam.name)
							OriginalName = $resolvedParam.name
							Type = $paramType
							Required = ($resolvedParam.required -eq $true)
							Description = $resolvedParam.description
							In = $resolvedParam.in
						})
					}
				}

				$hasBody = $false
				if ($op.requestBody) { 
					$hasBody = $true 
					$allParameters.Add([PSCustomObject]@{
						Name = 'Body'
						OriginalName = 'Body'
						Type = 'object'
						Required = $false
						Description = 'Request body data'
						In = 'body'
					})
				}

				# Add standard parameters to metadata
				$allParameters.Add([PSCustomObject]@{
					Name = 'BaseUrl'
					OriginalName = 'BaseUrl'
					Type = 'string'
					Required = $false
					Description = 'The base URL for the API'
					In = 'standard'
				})
				$allParameters.Add([PSCustomObject]@{
					Name = 'X_TOKEN'
					OriginalName = 'X_TOKEN'
					Type = 'string'
					Required = $false
					Description = 'Authentication token for X-TOKEN header'
					In = 'standard'
				})
				$allParameters.Add([PSCustomObject]@{
					Name = 'NoThrow'
					OriginalName = 'NoThrow'
					Type = 'switch'
					Required = $false
					Description = "Don't throw exceptions on HTTP errors, return `$null instead"
					In = 'standard'
				})

				# Store function metadata for README generation
				$functionMetadata.Add([PSCustomObject]@{
					FunctionName = $fnName
					Method = $method
					Path = $path
					OperationId = $op.operationId
					Summary = $op.summary
					Description = $op.description
					Parameters = $allParameters
				})

				# Build function parameter block lines with validation
				$paramLines = New-Object System.Collections.Generic.List[string]
				$paramLines.Add("    [string] `$BaseUrl = `"$baseUrl`"")
				$paramLines.Add("    [string] `$X_TOKEN = `$null")
				
				# Add path parameters (always mandatory)
				foreach ($pp in $pathParams | Sort-Object { $_.name } -Unique) {
					$validation, $type = Build-ParameterValidation -Parameter $pp
					$safeName = Safe-ParameterName -name $pp.name
					$paramLines.Add("    [Parameter(Mandatory=`$true)] [$type] `$$safeName")
				}
				
				# Add query parameters with proper validation (limit to first 20 to avoid too many params)
				$limitedQueryParams = $queryParams | Sort-Object { $_.name } -Unique | Select-Object -First 20
				foreach ($qp in $limitedQueryParams) {
					$validation, $type = Build-ParameterValidation -Parameter $qp
					$safeName = Safe-ParameterName -name $qp.name
					$validationStr = if ($validation) { $validation -join ' ' + ' ' } else { '' }
					$paramLines.Add("    ${validationStr}[$type] `$$safeName = `$null")
				}
				
				if ($hasBody) { $paramLines.Add("    [object] `$Body = `$null") }
				$paramLines.Add("    [switch] `$NoThrow")

				# Build comment-based help
				$helpComment = Build-CommentBasedHelp -Operation $op -Path $path -Method $method
				
				# Add parameter documentation to help
				foreach ($pp in $pathParams) {
					$safeName = Safe-ParameterName -name $pp.name
					if ($pp.description) {
						$helpComment += "`n.PARAMETER $safeName`n$($pp.description)"
					}
				}
				$limitedQueryParams = $queryParams | Sort-Object { $_.name } -Unique | Select-Object -First 20
				foreach ($qp in $limitedQueryParams) {
					$safeName = Safe-ParameterName -name $qp.name
					if ($qp.description) {
						$helpComment += "`n.PARAMETER $safeName`n$($qp.description)"
					}
				}
				$helpComment += "`n#>"

				$uriLiteral = Build-UriLiteral -PathTemplate $path

				# body arg
				if ($hasBody) {
					$bodyArg = "-Body (ConvertTo-Json `$Body -Depth 200) -ContentType 'application/vnd.api+json'"
				} else { $bodyArg = '' }

				# build query assembly - using safe parameter names and original query names
				$qsBuilder = New-Object System.Text.StringBuilder
				$qsBuilder.AppendLine("    `$query = @{}") | Out-Null
				$limitedQueryParams = $queryParams | Sort-Object { $_.name } -Unique | Select-Object -First 20
				foreach ($qp in $limitedQueryParams) {
					$safeName = Safe-ParameterName -name $qp.name
					$originalName = $qp.name
					$qsBuilder.AppendLine("    if (`$$safeName -ne `$null) { `$query['$originalName'] = `$$safeName }") | Out-Null
				}
				$qsBuilder.AppendLine("    if (`$query.Count -gt 0) {") | Out-Null
				$qsBuilder.AppendLine("        `$pairs = `$query.GetEnumerator() | ForEach-Object { [System.Uri]::EscapeDataString(`$_.Key) + '=' + [System.Uri]::EscapeDataString([string]`$_.Value) }") | Out-Null
				$qsBuilder.AppendLine("        `$q = `$pairs -join '&'") | Out-Null
				$qsBuilder.AppendLine("        `$uri = (`$BaseUrl.TrimEnd('/') ) + `"$uriLiteral`" + '?' + `$q") | Out-Null
				$qsBuilder.AppendLine("    } else {") | Out-Null
				$qsBuilder.AppendLine("        `$uri = (`$BaseUrl.TrimEnd('/') ) + `"$uriLiteral`"") | Out-Null
				$qsBuilder.AppendLine("    }") | Out-Null

				# headers
				$headersBlock = @"
    `$headers = @{}
    if (`$X_TOKEN) { `$headers['X-TOKEN'] = `$X_TOKEN }
"@

				$invokeBlock = @"
    try {
        `$resp = Invoke-RestMethod -Method $method -Uri `$uri -Headers `$headers $bodyArg -ErrorAction Stop
        return `$resp
    } catch {
        if (`$NoThrow) { return `$null } else { throw }
    }
"@

				$fn = @"
$helpComment
function $fnName {
    param(
$($paramLines -join ",`n")
    )
$($qsBuilder.ToString())
$headersBlock
$invokeBlock
}
"@

				$functionsCode.Add($fn)
			}
		}
	}

	# Write psm1
	$psm1Header = @(
		"# Module generated by parser.ps1 - PowerShell API wrapper",
		"# Module: $moduleName",
		"# Generated from: $($spec.info.title) v$($spec.info.version)",
		"# Base URL: $baseUrl",
		""
	)

	$psm1Content = $psm1Header + $functionsCode
	$exportList = ($exportedFunctions | Sort-Object -Unique) -join "', '"
	$psm1Content += "`n# Export all generated functions"
	$psm1Content += "`nExport-ModuleMember -Function '$exportList'"

	$psm1Content -join "`n" | Out-File -FilePath $psm1Path -Encoding UTF8

	# Write psd1
	$guid = (New-Guid).Guid
	$psd1 = @"
@{
	RootModule = '$moduleName.psm1'
	ModuleVersion = '0.1.0'
	GUID = '$guid'
	Author = 'Generated'
	CompanyName = 'Generated'
	Copyright = '(c) Generated'
	Description = 'PowerShell wrapper generated from OpenAPI spec'
	FunctionsToExport = @('*')
	CmdletsToExport = @()
	VariablesToExport = @()
	AliasesToExport = @()
}
"@
	$psd1 | Out-File -FilePath $psd1Path -Encoding UTF8

	Write-Log "Modul generiert: $moduleDir"
	return $moduleDir
}

# Main
try {
	Write-Log "Lade Spec: $SpecPath"
	$spec = Load-OpenApi -Path $SpecPath
	Write-Log "Spec geladen. Title: $($spec.info.title) Version: $($spec.info.version)"
	$out = Generate-Module -Spec $spec -OutRoot $OutDir
	Write-Log "Fertig. Modul-Ordner: $out"
} catch {
	Write-Error $_.Exception.Message
	exit 1
}
