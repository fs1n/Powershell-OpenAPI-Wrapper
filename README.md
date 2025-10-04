# PowerShell OpenAPI Wrapper Generator

> **Automatically generate PowerShell modules from OpenAPI/Swagger specifications with universal enhancement levels**

Transform any OpenAPI specification into a fully-featured Powershell API Wrapper module!

| Implemented Features:

| Feature | Status | Description |
|---------|--------|-------------|
| **Universal Generator** | ✅ Complete | Single generator with configurable enhancement levels |
| **Parameter Extraction** | ✅ Complete | Full OpenAPI parameter extraction for Advanced/Expert levels |
| **YAML Auto-Install** | ✅ Complete | Automatic PowerShell-Yaml module installation |
| **Modular Structure** | ✅ Complete | Automatic modular structure for large APIs (>50 functions) |
| **Interactive Wizard** | ✅ Complete | Guided setup with enhancement level selection |
| **Enhancement Levels** | ✅ Complete | Basic → Standard → Advanced → Expert progression |
| **Query Parameter Handling** | ✅ Complete | Automatic URL encoding and parameter building |
| **Enterprise Error Handling** | ✅ Complete | Retry logic and advanced error handling in Expert level |tus | 
| **Universal Generator** | ✅ Complete | Single generator with configurable enhancement levels |
| **Parameter Extraction** | ✅ Complete | Full OpenAPI parameter extraction for Advanced/Expert levels |
| **YAML Auto-Install** | ✅ Complete | Automatic PowerShell-Yaml module installation |
| **Modular Structure** | ✅ Complete | Automatic modular structure for large APIs (>50 functions) |
| **Interactive Wizard** | ✅ Complete | Guided setup with enhancement level selection |
| **Enhancement Levels** | ✅ Complete | Basic → Standard → Advanced → Expert progression |
| **Query Parameter Handling** | ✅ Complete | Automatic URL encoding and parameter building |
| **Enterprise Error Handling** | ✅ Complete | Retry logic and advanced error handling in Expert level |

## 📊 Tested APIs

Successfully tested with real-world APIs:

| API | Functions | Parameters | Enhancement Level | Structure |
|-----|-----------|------------|-------------------|-----------|
| **Hitobito MiData** | 19 functions | **170+ parameters** | Advanced/Expert | Single file |
| **Swagger Petstore** | 20 functions | Basic parameters | All levels | Single file |
| **SEPPmail Hera** | 309 functions | Complex | All levels | Modular structure |
| **Custom Enterprise APIs** | Various | Various | All levels | Auto-detected |

### Parameter Extraction Success

The **MiData API** demonstrates the power of Advanced/Expert level parameter extraction:

- ✅ **Basic parameters**: `include`, `sort`, `fields[people]`
- ✅ **Filter parameters**: 50+ filter combinations (`eq`, `not_eq`, `prefix`, `suffix`, `match`, etc.)
- ✅ **Field selectors**: `fields[groups]`, `fields[roles]`, `fields[phone_numbers]`, etc.
- ✅ **Type conversion**: Automatic string, array, boolean, integer parameter types
- ✅ **Safe naming**: Complex API parameters converted to PowerShell-safe namese with idiomatic function names, comprehensive parameter extraction, and built-in help documentation. Now with universal architecture supporting Basic to Expert enhancement levels!

## 🚀 Quick Start

### Option 1: Interactive Wizard (Recommended)
```powershell
# Start the interactive setup wizard
.\PowerShell-OpenAPI-Generator.ps1 -Interactive

# Follow the guided setup:
# 1. Select OpenAPI file (or choose from examples)
# 2. Enter module name
# 3. Choose output directory
# 4. Select enhancement level (Basic/Standard/Advanced/Expert)
# 5. Generate!
```

### Option 2: Command Line Generation
```powershell
# Basic Level - Simple HTTP requests
.\PowerShell-OpenAPI-Generator.ps1 -OpenAPIPath ".\examples\midata.yaml" -ModuleName "MiDataAPI" -OutputPath ".\MiDataAPI" -EnhancementLevel "Basic"

# Advanced Level - Full parameter extraction
.\PowerShell-OpenAPI-Generator.ps1 -OpenAPIPath ".\examples\midata.yaml" -ModuleName "MiDataAPI" -OutputPath ".\MiDataAPI" -EnhancementLevel "Advanced" -GenerateReadme

# Expert Level - Enterprise features with retry logic
.\PowerShell-OpenAPI-Generator.ps1 -OpenAPIPath ".\examples\midata.yaml" -ModuleName "MiDataAPI" -OutputPath ".\MiDataAPI" -EnhancementLevel "Expert" -GenerateReadme
```

### Option 3: Quick Mode (Legacy)
```powershell
# Generate with Quick Mode (equivalent to Basic level)
.\PowerShell-OpenAPI-Generator.ps1 -OpenAPIPath ".\examples\midata.yaml" -ModuleName "MiDataAPI" -OutputPath ".\MiDataAPI" -QuickMode
```

## ✨ Key Features

| Feature | Description |
|---------|-------------|
| 🎯 **PowerShell-Idiomatic** | `Get-Pet`, `New-Pet`, `Set-Pet` instead of generic `Invoke-*` |
| 📚 **Rich Documentation** | Complete comment-based help from OpenAPI descriptions |
| 🔒 **Parameter Extraction** | **Full OpenAPI parameter extraction** with 170+ parameters for complex APIs |
| 🌐 **Universal Format** | Supports both YAML and JSON OpenAPI specifications |
| 🛡️ **Safe Parameter Names** | Converts complex API parameters to PowerShell-safe names |
| 🧙‍♂️ **Interactive Wizard** | Guided setup process with enhancement level selection |
| ⚡ **Universal Architecture** | Single codebase with configurable enhancement levels |
| 🗂️ **Modular Structure** | Automatically creates modular structure for large APIs (>50 functions) |
| 🎛️ **Enhancement Levels** | Basic → Standard → Advanced → Expert progression |
| 🔄 **Auto-Installation** | Automatic PowerShell-Yaml module installation for YAML support |

## 🎛️ Enhancement Levels

| Level | Features | Use Case |
|-------|----------|----------|
| **Basic** | Simple HTTP requests, BaseUri, Headers | Quick prototyping, simple APIs |
| **Standard** | + Timeout management, enhanced headers | Production use, reliability |
| **Advanced** | + **Full parameter extraction**, Body handling | **Complex APIs with many parameters** |
| **Expert** | + Retry logic, enterprise error handling | Mission-critical applications |

### Real Parameter Extraction Example

**Advanced/Expert Level** extracts all OpenAPI parameters:

```powershell
# Generated function with 170+ parameters from Hitobito MiData API
Get-listPeople -BaseUri "https://<Hitobito>/api" `
               -filter_first_name__eq_ "Max" `
               -filter_last_name__prefix_ "Muster" `
               -filter_email__suffix_ "@pfadi.ch" `
               -sort "first_name" `
               -fields_people_ @("first_name", "last_name", "email") `
               -include "groups,roles"
```

## 🏗️ Project Structure

```
PowerShell-OpenAPI-Wrapper/
├── 🚀 PowerShell-OpenAPI-Generator.ps1  # Universal generator with enhancement levels
├── 📄 README.md                         # This documentation
├── 📂 src/                              # Legacy source code modules (deprecated)
│   ├── 📂 Core/                         # Core functionality (not used in universal generator)
│   └── 📂 Enhancements/                 # Enhancement modules (replaced by universal system)
├── 📂 examples/                         # Example OpenAPI specifications
│   ├── swagger.json                     # Petstore API example  
│   └── swagger.yaml                     # YAML format example
└── 📂 docs/                            # Documentation and guides
```

## 📁 Generated Module Structure

### Small APIs (≤50 functions):
```
MyModule/
├── MyModule.psd1          # PowerShell module manifest
├── MyModule.psm1          # All functions in one file
└── README.md              # Generated documentation (if requested)
```

### Large APIs (>50 functions):
```
MyModule/
├── MyModule.psd1          # PowerShell module manifest
├── MyModule.psm1          # Main module file (imports functions)
├── README.md              # Generated documentation
└── Functions/             # Individual function files
    ├── Get-listPeople.ps1
    ├── Get-Event.ps1
    └── ... (300+ more functions)
```

## 🛠️ Generated Function Examples

The universal generator creates PowerShell functions following standard verb conventions with different enhancement levels:

| OpenAPI Endpoint | Generated PowerShell Function | Enhancement Level |
|------------------|------------------------------|-------------------|
| `GET /api/people` | `Get-listPeople` | All levels |
| `GET /api/people/{id}` | `Get-Person` | All levels |
| `POST /api/roles` | `New-createRole` | All levels |
| `PUT /api/people/{id}` | `Set-updatePerson` | All levels |
| `DELETE /api/roles/{id}` | `Remove-Role` | All levels |

### Enhancement Level Comparison

#### Basic Level
```powershell
function Get-listPeople {
    param(
        [Parameter(Mandatory = $true)]
        [string]$BaseUri,
        [hashtable]$Headers = @{}
    )
    # Simple HTTP request implementation
}
```

#### Advanced Level (Full Parameter Extraction)
```powershell
function Get-listPeople {
    param(
        [Parameter(Mandatory = $true)]
        [string]$BaseUri,
        [hashtable]$Headers = @{},
        [int]$TimeoutSec = 30,
        [hashtable]$Body = @{},
        # 170+ extracted OpenAPI parameters:
        [string]$include,
        [string]$sort,
        [string[]]$filter_first_name__eq_,
        [string[]]$filter_last_name__prefix_,
        [string[]]$filter_email__match_,
        # ... and 165+ more parameters
    )
    # Advanced implementation with query parameter handling
}
```

#### Expert Level
```powershell
function Get-listPeople {
    param(
        # All Advanced parameters plus:
        [switch]$PassThru,
        [ValidateSet('Default', 'Ignore', 'Retry')]
        [string]$ErrorHandling = 'Default'
    )
    # Expert implementation with retry logic and Professional error handling
}
```

### Real-World Usage Example

```powershell
# Import your generated module
Import-Module ".\MiDataAPI\MiDataAPI.psd1"

# List available functions
Get-Command -Module MiDataAPI

# Get help for any function (shows all 170+ parameters for Advanced/Expert level)
Get-Help Get-listPeople -Full

# Basic Level usage
Get-listPeople -BaseUri "https://api.midata.cevi.ch"

# Advanced Level usage with extracted parameters
Get-listPeople -BaseUri "https://<Hitobito>/api" `
               -filter_first_name__eq_ "Max" `
               -filter_last_name__prefix_ "Muster" `
               -filter_email__suffix_ "@pfadi.ch" `
               -sort "first_name" `
               -fields_people_ @("first_name", "last_name", "email") `
               -include "groups,roles"

# Expert Level usage with retry logic
Get-listPeople -BaseUri "https://<Hitobito>/api" `
               -filter_first_name__eq_ "Max" `
               -ErrorHandling "Retry" `
               -TimeoutSec 60

# For large APIs, use selective imports for better performance
Import-Module ".\LargeModule\LargeAPI.psd1" -Function 'Get-*'
```

## 📋 Requirements

- **PowerShell 5.1+** (Windows PowerShell or PowerShell Core)
- **YAML Support** (automatically installed):
  - The generator automatically installs `PowerShell-Yaml` module if needed
  - PowerShell 7.0+ has enhanced YAML support

### Automatic YAML Installation

The universal generator automatically handles YAML dependencies:

```powershell
# The generator will automatically:
# 1. Detect YAML files (.yaml/.yml)
# 2. Check for ConvertFrom-Yaml availability
# 3. Install PowerShell-Yaml module if needed
# 4. Import and use the module

# No manual installation required!
```

## 📊 Tested APIs

Successfully tested with:

| API | Functions | Complexity | Structure |
|-----|-----------|------------|-----------|
| **Swagger Petstore** | 20 functions | Simple | Single file |
| **SEPPmail Cloud API (Hera)** | 309 functions | Complex | Modular structure |
| **Custom APIs** | Various | Various | Auto-detected |

## 🚀 Advanced Usage

### Enhancement Level Selection

```powershell
# Basic: Quick prototyping
.\PowerShell-OpenAPI-Generator.ps1 -OpenAPIPath "api.yaml" -ModuleName "API" -EnhancementLevel "Basic"

# Standard: Production reliability  
.\PowerShell-OpenAPI-Generator.ps1 -OpenAPIPath "api.yaml" -ModuleName "API" -EnhancementLevel "Standard"

# Advanced: Full parameter extraction (recommended for complex APIs)
.\PowerShell-OpenAPI-Generator.ps1 -OpenAPIPath "api.yaml" -ModuleName "API" -EnhancementLevel "Advanced"

# Expert: Enterprise features with retry logic
.\PowerShell-OpenAPI-Generator.ps1 -OpenAPIPath "api.yaml" -ModuleName "API" -EnhancementLevel "Expert"
```

### Large API Performance Tips

```powershell
# For APIs with 100+ functions, use selective imports
Import-Module ".\MyLargeAPI\API.psd1" -Function 'Get-*'

# Check function count and structure
Get-Command -Module MyAPI | Measure-Object
Test-Path ".\MyAPI\Functions\"  # True if modular structure used

# Get statistics about your generated module
Get-Command -Module MyAPI | Group-Object { ($_.Name -split '-')[0] }
```

### Batch Generation

```powershell
# Generate multiple modules from different specs
$specs = Get-ChildItem ".\specs\" -Filter "*.yaml"
foreach ($spec in $specs) {
    $moduleName = $spec.BaseName + "API"
    .\PowerShell-OpenAPI-Generator.ps1 -OpenAPIPath $spec.FullName -ModuleName $moduleName -OutputPath ".\modules\$moduleName" -EnhancementLevel "Advanced"
}
```

## 🛠️ Development & Customization

### Universal Architecture

The current architecture uses a single universal generator (`PowerShell-OpenAPI-Generator.ps1`) with:

- **Universal Helper Functions**: `ConvertTo-SafeProperty`, `Get-SafeObjectKeys`
- **Parameter Extraction Engine**: `Get-OpenAPIParameters` for Advanced/Expert levels
- **Universal Function Generator**: `New-UniversalFunction` with configurable enhancement levels
- **Universal Module Generator**: `New-UniversalModule` with smart structure detection

### Legacy Components (Deprecated)

- `src\Core\*` - Legacy core modules (replaced by universal architecture)
- `src\Enhancements\*` - Legacy enhancement system (replaced by enhancement levels)

### Extending Enhancement Levels

```powershell
# The enhancement levels are defined in New-UniversalFunction
# To add new levels, modify the switch statement:

switch ($Level) {
    'Basic' { # Simple implementation }
    'Standard' { # + Timeout management }
    'Advanced' { # + Parameter extraction }
    'Expert' { # + Retry logic }
    'Enterprise' { # Your new level here }
}
```

## 🛠️ Troubleshooting

### Common Issues

**YAML parsing (no longer needed - auto-installed):**
```powershell
# The generator now automatically installs PowerShell-Yaml
# No manual intervention required!
```

**Large API performance:**
```powershell
# Use modular imports for large APIs
Import-Module ".\MyAPI\API.psd1" -Function 'Get-Users*'

# Check if modular structure was used (>50 functions)
Test-Path ".\MyAPI\Functions\"
```

**Parameter conflicts:**
```powershell
# Advanced/Expert level converts complex parameter names safely
# Original: filter[first_name][eq] 
# PowerShell: filter_first_name__eq_

# Use Get-Help to see parameter documentation
Get-Help Get-listPeople -Parameter filter_first_name__eq_
```

**Enhancement level selection:**
```powershell
# If unsure which level to use:
# Basic: Testing/prototyping
# Standard: Production use
# Advanced: APIs with many parameters (recommended)  
# Expert: Mission-critical with retry needs
```

## 🎯 Roadmap

- ✅ **Universal Architecture** - Completed
- ✅ **Interactive Wizard** - Completed
- ✅ **Enhancement Levels** - Completed (Basic/Standard/Advanced/Expert)
- ✅ **Parameter Extraction** - Completed (170+ parameters from complex APIs)
- ✅ **Large API Support** - Completed  
- ✅ **Modular Architecture** - Completed
- ✅ **YAML Auto-Install** - Completed
- 🚧 **Path Parameter Support** - In Progress (currently static paths)
- � **Authentication Schemes** - Planned (OAuth2, JWT, API Key detection)
- 📋 **Request Body Schemas** - Planned (complex object validation)
- 📋 **Response Validation** - Planned (schema-based response validation)
- 📋 **Testing Framework** - Planned (automated Pester tests)

### Recent Achievements (v3.0.0)

- **Universal Generator**: Single codebase replacing separate Quick/Enhanced modes
- **Full Parameter Extraction**: Advanced/Expert levels extract all OpenAPI parameters
- **Safe Parameter Names**: Complex API parameters converted to PowerShell-safe names
- **Enhancement Progression**: Clear upgrade path from Basic to Expert functionality
- **Enterprise Features**: Retry logic, error handling, timeout management

## 🤝 Contributing

We welcome contributions! Areas of interest:

- **Path Parameter Support**: Dynamic path parameter replacement (`/api/people/{id}`)
- **Authentication Schemes**: OAuth2, JWT, API Key detection and implementation
- **Request Body Schemas**: Complex object validation for POST/PUT operations  
- **Response Validation**: Schema-based response validation and type conversion
- **Testing Framework**: Automated Pester tests for generated functions
- **Performance Optimization**: Further improvements for very large APIs (1000+ functions)

### Development Setup

```powershell
# Clone and test the universal generator
git clone <repository>
cd PowerShell-OpenAPI-Wrapper

# Test with provided examples
.\PowerShell-OpenAPI-Generator.ps1 -OpenAPIPath "examples\midata.yaml" -ModuleName "TestAPI" -EnhancementLevel "Advanced" -OutputPath "TestAPI"

# Verify parameter extraction
Import-Module ".\TestAPI\TestAPI.psd1"
Get-Help Get-listPeople -Parameter filter_first_name__eq_
```

## 📜 License

MIT License - see [LICENSE](LICENSE) file for details.

---

⭐ **Star this repository if you find it useful!** ⭐
