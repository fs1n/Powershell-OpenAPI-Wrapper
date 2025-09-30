# PowerShell OpenAPI Wrapper Generator

> **Automatically generate professional PowerShell modules from OpenAPI/Swagger specifications**

Transform any OpenAPI specification into a fully-featured PowerShell module with idiomatic function names, comprehensive parameter validation, and built-in help documentation. Now with support for large enterprise APIs!

## 🚀 Quick Start

### Option 1: Interactive Wizard (Recommended)
```powershell
# Start the interactive setup wizard
.\New-PowerShellAPIWrapper.ps1

# Follow the guided setup:
# 1. Select OpenAPI file (or choose from examples)
# 2. Enter module name
# 3. Choose output directory
# 4. Select enhancements
# 5. Generate!
```

### Option 2: Quick Generator (Immediate Results)
```powershell
# Generate a module instantly from any OpenAPI spec
.\Quick-Generator.ps1 -OpenAPIPath ".\examples\swagger.json" -OutputPath ".\MyModule" -ModuleName "PetStoreAPI"

# Import and use immediately
Import-Module ".\MyModule\PetStoreAPI.psd1"
Get-Command -Module PetStoreAPI
```

### Option 3: Advanced Generation
```powershell
# Generate with specific enhancements
.\New-PowerShellAPIWrapper.ps1 -OpenAPIPath ".\examples\swagger.json" -OutputPath ".\MyModule" -ModuleName "PetStoreAPI" -IncludeEnhancements @("VerbMapping", "ErrorHandling") -GenerateReadme
```

## ✨ Key Features

| Feature | Description |
|---------|-------------|
| 🎯 **PowerShell-Idiomatic** | `Get-Pet`, `New-Pet`, `Set-Pet` instead of generic `Invoke-*` |
| 📚 **Rich Documentation** | Complete comment-based help from OpenAPI descriptions |
| 🔒 **Type Safety** | Parameter validation and type checking from schemas |
| 🌐 **Universal Format** | Supports both YAML and JSON OpenAPI specifications |
| 🛡️ **Secure Parameters** | Converts OpenAPI parameters to PowerShell-safe names |
| 🧙‍♂️ **Interactive Wizard** | Guided setup process for easy configuration |
| ⚡ **Enterprise Scale** | Handles large APIs with 300+ functions efficiently |
| 🗂️ **Modular Structure** | Automatically creates modular structure for large APIs |
| 🎛️ **Enhancement System** | Optional advanced features (verb mapping, error handling, etc.) |

## 🏗️ Project Structure

```
PowerShell-OpenAPI-Wrapper/
├── 🚀 New-PowerShellAPIWrapper.ps1     # Main entry point with interactive wizard
├── ⚡ Quick-Generator.ps1              # Fast, simple generator (works immediately)
├── 📄 README.md                        # This documentation
├── 📂 src/                             # Source code modules
│   ├── 📂 Core/                        # Core functionality
│   │   ├── OpenAPIParser.ps1           # OpenAPI specification parser
│   │   ├── ModuleGenerator.ps1         # Module generation logic
│   │   ├── ReadmeGenerator.ps1         # README generator
│   │   └── UtilityFunctions.ps1        # Common utilities
│   └── � Enhancements/                # Optional advanced features
│       ├── VerbMappingEnhancement.ps1  # Enhanced PowerShell verb mapping
│       ├── ParameterEnhancement.ps1    # Advanced parameter handling
│       ├── ErrorHandlingEnhancement.ps1 # Enterprise error handling
│       └── TypeSystemEnhancement.ps1   # Strong typing system
├── 📂 examples/                        # Example OpenAPI specifications
│   ├── swagger.json                    # Petstore API example
│   └── swagger.yaml                    # YAML format example
└── 📂 docs/                           # Documentation and guides
```

## 📁 What You Get

### Small APIs (≤50 functions):
```
MyModule/
├── MyModule.psd1          # PowerShell module manifest
└── MyModule.psm1          # All functions in one file
```

### Large APIs (>50 functions):
```
MyModule/
├── MyModule.psd1          # PowerShell module manifest
├── MyModule.psm1          # Main module file (imports functions)
└── Functions/             # Individual function files
    ├── Get-Users.ps1
    ├── New-Users.ps1
    └── ... (300+ more functions)
```

## 🛠️ Generated Function Examples

The generator creates PowerShell functions following standard verb conventions:

| OpenAPI Endpoint | Generated PowerShell Function |
|------------------|------------------------------|
| `GET /pets` | `Get-findPetsByStatus` |
| `GET /pets/{id}` | `Get-PetById` |
| `POST /pets` | `New-addPet` |
| `PUT /pets/{id}` | `Set-updatePet` |
| `DELETE /pets/{id}` | `Remove-Pet` |

### Real-World Usage Example

```powershell
# Import your generated module
Import-Module ".\MyModule\PetStoreAPI.psd1"

# List available functions
Get-Command -Module PetStoreAPI

# Get help for any function
Get-Help Get-findPetsByStatus -Full

# Use the API functions
$pets = Get-findPetsByStatus -BaseUri "https://petstore.swagger.io/v2"
$inventory = Get-Inventory -BaseUri "https://petstore.swagger.io/v2"

# For large APIs, use selective imports for better performance
Import-Module ".\LargeModule\HeraAPI.psd1" -Function 'Get-*'
```

## 📋 Requirements

- **PowerShell 5.1+** (Windows PowerShell or PowerShell Core)
- **YAML Support** (optional, for YAML specifications):
  - PowerShell 7.0+ has built-in YAML support
  - PowerShell 5.1 requires `powershell-yaml` module

### YAML Support Installation

```powershell
# For PowerShell 5.1 users
Install-Module -Name powershell-yaml -Scope CurrentUser
```

## 🎯 Available Enhancements

| Enhancement | Description | Status |
|-------------|-------------|--------|
| **VerbMapping** | Enhanced PowerShell verb mapping based on Microsoft PSSwagger | ✅ Available |
| **ParameterFlattening** | Advanced parameter handling and flattening | � In Development |
| **ErrorHandling** | Enterprise-grade error handling with retry logic | 🚧 In Development |
| **TypeSystem** | Strong typing with custom PowerShell classes | 🚧 In Development |

## 📊 Tested APIs

Successfully tested with:

| API | Functions | Complexity | Structure |
|-----|-----------|------------|-----------|
| **Swagger Petstore** | 20 functions | Simple | Single file |
| **SEPPmail Cloud API (Hera)** | 309 functions | Complex | Modular structure |
| **Custom APIs** | Various | Various | Auto-detected |

## 🚀 Advanced Usage

### Large API Performance Tips

```powershell
# For APIs with 100+ functions, use selective imports
Import-Module ".\MyLargeAPI\API.psd1" -Function 'Get-*'

# Check function count
Get-Command -Module MyAPI | Measure-Object

# Get statistics about your generated module
Get-Command -Module MyAPI | Group-Object { ($_.Name -split '-')[0] }
```

### Batch Generation

```powershell
# Generate multiple modules from different specs
$specs = Get-ChildItem ".\specs\" -Filter "*.json"
foreach ($spec in $specs) {
    $moduleName = $spec.BaseName + "API"
    .\Quick-Generator.ps1 -OpenAPIPath $spec.FullName -OutputPath ".\modules\$moduleName" -ModuleName $moduleName
}
```

## 🛠️ Development & Customization

### Adding New Enhancements

1. Create your enhancement in `src\Enhancements\`
2. Follow the existing pattern from `VerbMappingEnhancement.ps1`
3. Add it to the enhancement map in `New-PowerShellAPIWrapper.ps1`

### Extending the Core

- **Core modules** in `src\Core\` provide basic functionality
- **Enhancements** in `src\Enhancements\` add optional features
- **Examples** in `examples\` for testing and demonstration

## 🛠️ Troubleshooting

### Common Issues

**YAML parsing errors:**
```powershell
# Check YAML support
Get-Command ConvertFrom-Yaml -ErrorAction SilentlyContinue

# Install if missing (PowerShell 5.1)
Install-Module powershell-yaml -Scope CurrentUser
```

**Large API performance:**
```powershell
# Use modular imports for large APIs
Import-Module ".\MyAPI\API.psd1" -Function 'Get-Users*'

# Check if modular structure was used
Test-Path ".\MyAPI\Functions\"
```

**Interactive wizard issues:**
```powershell
# Run Quick-Generator directly if wizard fails
.\Quick-Generator.ps1 -OpenAPIPath ".\examples\swagger.json" -OutputPath ".\test" -ModuleName "TestAPI"
```

## 🎯 Roadmap

- ✅ **Interactive Wizard** - Completed
- ✅ **Large API Support** - Completed  
- ✅ **Modular Architecture** - Completed
- 🚧 **Enhanced Error Handling** - In Progress
- 🚧 **Parameter Validation** - In Progress
- 🚧 **Type System Enhancement** - In Progress
- 📋 **Authentication Schemes** - Planned
- 📋 **Response Validation** - Planned
- 📋 **Testing Framework** - Planned

## 🤝 Contributing

We welcome contributions! Areas of interest:

- **Authentication Schemes**: OAuth2, JWT, API Key detection
- **Response Validation**: Schema-based response validation  
- **Testing Framework**: Automated Pester tests for generated functions
- **Enhanced Parameter Handling**: Complex parameter flattening

## 📜 License

MIT License - see [LICENSE](LICENSE) file for details.

---

⭐ **Star this repository if you find it useful!** ⭐
