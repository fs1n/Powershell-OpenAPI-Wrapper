# Parameter Enhancement based on PSSwagger patterns
# Add to Module-GEN-Parser-CLEAN.ps1

function Get-EnhancedParameterDefinition {
    param(
        [object]$Parameter,
        [hashtable]$Definitions = @{}
    )
    
    $paramDef = @{
        Name = $Parameter.name
        Type = Get-PowerShellType $Parameter.type $Parameter.format
        Mandatory = $Parameter.required -eq $true
        Position = -1
        ValueFromPipeline = $false
        ValueFromPipelineByPropertyName = $true
        HelpMessage = $Parameter.description
        ParameterSetName = '__AllParameterSets'
    }
    
    # Handle parameter grouping (x-ms-parameter-grouping)
    if ($Parameter.'x-ms-parameter-grouping') {
        $groupInfo = $Parameter.'x-ms-parameter-grouping'
        $paramDef.ParameterSetName = $groupInfo.name
        if ($groupInfo.postfix) {
            $paramDef.Name += $groupInfo.postfix
        }
    }
    
    # Handle client flattening (x-ms-client-flatten)
    if ($Parameter.'x-ms-client-flatten' -eq $true -and $Parameter.schema) {
        return Get-FlattenedParameters $Parameter.schema $Definitions
    }
    
    # Enhanced type handling
    switch ($Parameter.type) {
        'array' {
            $itemType = Get-PowerShellType $Parameter.items.type $Parameter.items.format
            $paramDef.Type = "$itemType[]"
            
            # Add validation for array constraints
            if ($Parameter.minItems) {
                $paramDef.ValidateCount = @($Parameter.minItems, $Parameter.maxItems ?? [int]::MaxValue)
            }
        }
        
        'string' {
            # Handle enums with ValidateSet
            if ($Parameter.enum) {
                $paramDef.ValidateSet = $Parameter.enum
                $paramDef.Type = 'string'
            }
            
            # Add string validation
            if ($Parameter.pattern) {
                $paramDef.ValidatePattern = $Parameter.pattern
            }
            
            if ($Parameter.minLength -or $Parameter.maxLength) {
                $paramDef.ValidateLength = @(
                    $Parameter.minLength ?? 0, 
                    $Parameter.maxLength ?? [int]::MaxValue
                )
            }
        }
        
        'integer' {
            # Add range validation
            if ($Parameter.minimum -or $Parameter.maximum) {
                $paramDef.ValidateRange = @(
                    $Parameter.minimum ?? [int]::MinValue,
                    $Parameter.maximum ?? [int]::MaxValue
                )
            }
        }
        
        'boolean' {
            # Convert boolean parameters to switch parameters
            $paramDef.Type = 'switch'
            $paramDef.Mandatory = $false
        }
    }
    
    # Handle references
    if ($Parameter.'$ref') {
        $refName = $Parameter.'$ref' -replace '#/definitions/', ''
        if ($Definitions[$refName]) {
            return Get-EnhancedParameterDefinition $Definitions[$refName] $Definitions
        }
    }
    
    return $paramDef
}

function Get-FlattenedParameters {
    param(
        [object]$Schema,
        [hashtable]$Definitions
    )
    
    $flattenedParams = @()
    
    if ($Schema.properties) {
        foreach ($propName in $Schema.properties.Keys) {
            $property = $Schema.properties[$propName]
            
            $flatParam = @{
                Name = $propName
                Type = Get-PowerShellType $property.type $property.format
                Mandatory = $Schema.required -contains $propName
                HelpMessage = $property.description
                ValueFromPipelineByPropertyName = $true
            }
            
            # Recursive flattening for nested objects
            if ($property.type -eq 'object' -and $property.'x-ms-client-flatten') {
                $flattenedParams += Get-FlattenedParameters $property $Definitions
            } else {
                $flattenedParams += $flatParam
            }
        }
    }
    
    return $flattenedParams
}

function Get-PowerShellType {
    param([string]$Type, [string]$Format)
    
    # Enhanced type mapping based on PSSwagger patterns
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
            'default' = 'array'
        }
        'object' = @{
            'default' = 'PSCustomObject'
        }
        'file' = @{
            'default' = 'FileInfo'
        }
    }
    
    if ($typeMap[$Type] -and $typeMap[$Type][$Format]) {
        return $typeMap[$Type][$Format]
    } elseif ($typeMap[$Type]) {
        return $typeMap[$Type]['default']
    }
    
    return 'object'
}