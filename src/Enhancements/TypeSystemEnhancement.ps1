# Type System Enhancement based on PSSwagger patterns
# Add to Module-GEN-Parser-CLEAN.ps1

function New-EnhancedTypeSystem {
    param([hashtable]$Definitions)
    
    $typeClasses = @()
    
    foreach ($defName in $Definitions.Keys) {
        $definition = $Definitions[$defName]
        
        if ($definition.type -eq 'object') {
            $typeClasses += New-PowerShellClass -Name $defName -Definition $definition -AllDefinitions $Definitions
        }
    }
    
    return $typeClasses -join "`n`n"
}

function New-PowerShellClass {
    param(
        [string]$Name,
        [object]$Definition,
        [hashtable]$AllDefinitions
    )
    
    $className = ConvertTo-PascalCase $Name
    $properties = @()
    $constructors = @()
    $methods = @()
    
    # Generate properties with proper typing and validation
    if ($Definition.properties) {
        foreach ($propName in $Definition.properties.Keys) {
            $property = $Definition.properties[$propName]
            $properties += New-ClassProperty -Name $propName -Definition $property -Required ($Definition.required -contains $propName)
        }
    }
    
    # Generate default constructor
    $constructors += @"
    $className() {
        # Default constructor
    }
"@
    
    # Generate parameterized constructor for required properties
    if ($Definition.required) {
        $requiredParams = @()
        $assignments = @()
        
        foreach ($reqProp in $Definition.required) {
            if ($Definition.properties[$reqProp]) {
                $propDef = $Definition.properties[$reqProp]
                $psType = Get-PowerShellType $propDef.type $propDef.format
                $requiredParams += "[$psType]`$$reqProp"
                $assignments += "        `$this.$reqProp = `$$reqProp"
            }
        }
        
        if ($requiredParams.Count -gt 0) {
            $constructors += @"
    $className($($requiredParams -join ', ')) {
$($assignments -join "`n")
    }
"@
        }
    }
    
    # Generate validation method
    $methods += @"
    [bool] IsValid() {
        `$errors = @()
        
$(if ($Definition.required) {
    $Definition.required | ForEach-Object {
        "        if (`$null -eq `$this.$_) { `$errors += 'Property $_ is required' }"
    }
} else { "        # No required properties" })
        
        if (`$errors.Count -gt 0) {
            Write-Warning "Validation errors: `$(`$errors -join ', ')"
            return `$false
        }
        
        return `$true
    }
"@
    
    # Generate ToHashtable method for API calls
    $methods += @"
    [hashtable] ToHashtable() {
        `$result = @{}
        
$(if ($Definition.properties) {
    $Definition.properties.Keys | ForEach-Object {
        "        if (`$null -ne `$this.$_) { `$result['$_'] = `$this.$_ }"
    }
} else { "        # No properties to convert" })
        
        return `$result
    }
"@
    
    # Generate FromHashtable static method
    $methods += @"
    static [$className] FromHashtable([hashtable]`$data) {
        `$instance = [${className}]::new()
        
$(if ($Definition.properties) {
    $Definition.properties.Keys | ForEach-Object {
        "        if (`$data.ContainsKey('$_')) { `$instance.$_ = `$data['$_'] }"
    }
} else { "        # No properties to set" })
        
        return `$instance
    }
"@
    
    return @"
class $className {
$(if ($properties.Count -gt 0) { $properties -join "`n" } else { "    # No properties defined" })

$(if ($constructors.Count -gt 0) { $constructors -join "`n`n" })

$(if ($methods.Count -gt 0) { $methods -join "`n`n" })
}
"@
}

function New-ClassProperty {
    param(
        [string]$Name,
        [object]$Definition,
        [bool]$Required
    )
    
    $psType = Get-PowerShellType $Definition.type $Definition.format
    $propName = ConvertTo-PascalCase $Name
    
    # Handle arrays
    if ($Definition.type -eq 'array') {
        $itemType = Get-PowerShellType $Definition.items.type $Definition.items.format
        $psType = "$itemType[]"
    }
    
    # Handle enums
    if ($Definition.enum) {
        $enumValues = $Definition.enum | ForEach-Object { "'$_'" }
        $validation = "`n    [ValidateSet($($enumValues -join ', '))]"
    } else {
        $validation = ""
    }
    
    # Handle string constraints
    if ($Definition.type -eq 'string') {
        $constraints = @()
        
        if ($Definition.minLength -or $Definition.maxLength) {
            $min = $Definition.minLength ?? 0
            $max = $Definition.maxLength ?? [int]::MaxValue
            $constraints += "[ValidateLength($min, $max)]"
        }
        
        if ($Definition.pattern) {
            $constraints += "[ValidatePattern('$($Definition.pattern)')]"
        }
        
        if ($constraints.Count -gt 0) {
            $validation = "`n    " + ($constraints -join "`n    ")
        }
    }
    
    # Handle numeric constraints
    if ($Definition.type -in @('integer', 'number')) {
        if ($Definition.minimum -or $Definition.maximum) {
            $min = $Definition.minimum ?? [int]::MinValue
            $max = $Definition.maximum ?? [int]::MaxValue
            $validation = "`n    [ValidateRange($min, $max)]"
        }
    }
    
    $comments = if ($Definition.description) {
        "`n    # $($Definition.description)"
    } else { "" }
    
    return @"
$comments$validation
    [$psType] `$$propName
"@
}

function ConvertTo-PascalCase {
    param([string]$Text)
    
    # Split on various separators and convert to PascalCase
    $words = $Text -split '[_\-\s]+'
    $result = ($words | ForEach-Object { 
        if ($_.Length -gt 0) {
            $_.Substring(0,1).ToUpper() + $_.Substring(1).ToLower()
        }
    }) -join ''
    
    return $result
}