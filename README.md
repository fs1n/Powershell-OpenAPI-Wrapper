# PowerShell OpenAPI Wrapper Generator

> **Automatically generate professional PowerShell modules from OpenAPI 3.0.1+ specifications**

Transform any OpenAPI specification into a fully-featured PowerShell module with idiomatic function names, comprehensive parameter validation, and built-in help documentation.

## 🚀 Quick Start

```powershell
# Generate a module from your OpenAPI spec
.\Module-GEN-Parser-CLEAN.ps1 -SpecPath .\your-api-spec.yaml -OutDir .\modules

# Generate comprehensive documentation
.\Generate-README.ps1 -ModulePath .\modules\YourAPI\YourAPI.psm1 -SpecPath .\your-api-spec.yaml

# Use your generated module
Import-Module .\modules\YourAPI\YourAPI.psd1
Get-Help Get-Users -Full
$users = Get-UsersList -X_TOKEN "your-api-token"
```

## ✨ Key Features

| Feature | Description |
|---------|-------------|
| 🎯 **PowerShell-Idiomatic** | `Get-Users`, `New-Order`, `Set-Profile` instead of generic `Invoke-*` |
| 📚 **Rich Documentation** | Complete comment-based help from OpenAPI descriptions |
| 🔒 **Type Safety** | Parameter validation, enums, and type checking from schemas |
| 🌐 **Universal Format** | Supports both YAML and JSON OpenAPI specifications |
| 🛡️ **Secure Parameters** | Converts OpenAPI parameters to PowerShell-safe names |
| 🔑 **Built-in Auth** | X-TOKEN header authentication with configurable base URLs |
| 📖 **Auto Documentation** | Generates professional README.md with examples |

## 📁 What You Get

Every generated module includes:

```
YourAPI/
├── YourAPI.psd1          # PowerShell module manifest
├── YourAPI.psm1          # Generated wrapper functions
└── README.md             # Complete documentation with examples
```

## 🛠️ Generated Function Examples

The generator creates PowerShell functions following standard verb conventions:

| OpenAPI Endpoint | Generated PowerShell Function |
|------------------|------------------------------|
| `GET /api/users` | `Get-UsersList` |
| `GET /api/users/{id}` | `Get-Users` |
| `POST /api/users` | `New-Users` |
| `PUT /api/users/{id}` | `Set-Users` |
| `DELETE /api/users/{id}` | `Remove-Users` |

### Real-World Usage Example

```powershell
# Import your generated module
Import-Module .\modules\CompanyAPI\CompanyAPI.psd1

# List all users with filtering
$users = Get-UsersList -BaseUrl "https://api.company.com" `
    -X_TOKEN $apiToken `
    -department "Engineering" `
    -active $true `
    -limit 50

# Get specific user details
$user = Get-Users -id 123 -X_TOKEN $apiToken -fields @("name", "email", "department")

# Create a new user
$newUser = New-Users -X_TOKEN $apiToken -Body @{
    name = "John Doe"
    email = "john.doe@company.com"
    department = "Engineering"
    role = "Developer"
}

# Update user information
Set-Users -id 123 -X_TOKEN $apiToken -Body @{
    department = "Senior Engineering"
    role = "Lead Developer"
}
```

## 📋 Requirements

- **PowerShell 7.0+** *(recommended - includes built-in YAML support)*
- **PowerShell 5.1+** with `powershell-yaml` module *(alternative)*

### YAML Support Installation

```powershell
# For PowerShell 5.1 users
Install-Module -Name powershell-yaml -Scope CurrentUser

# Or use auto-installation flag
.\Module-GEN-Parser-CLEAN.ps1 -SpecPath .\spec.yaml -AutoInstallYamlModule
```

## 🔧 Core Scripts

| Script | Purpose | Usage |
|--------|---------|-------|
| `Module-GEN-Parser-CLEAN.ps1` | **Main generator** | Creates PowerShell modules from OpenAPI specs |
| `Generate-README.ps1` | **Documentation generator** | Creates comprehensive README for modules |

## 📚 Complete Workflow

### 1. Generate Your Module

```powershell
# From YAML specification
.\Module-GEN-Parser-CLEAN.ps1 -SpecPath .\petstore.yaml -OutDir .\generated

# From JSON specification  
.\Module-GEN-Parser-CLEAN.ps1 -SpecPath .\swagger.json -OutDir .\generated
```

### 2. Generate Documentation

```powershell
.\Generate-README.ps1 -ModulePath .\generated\Petstore\Petstore.psm1 -SpecPath .\petstore.yaml
```

### 3. Use Your Module

```powershell
Import-Module .\generated\Petstore\Petstore.psd1

# Get comprehensive help
Get-Help Get-Pets -Full

# Use the API
$pets = Get-PetsList -X_TOKEN "your-token" -status "available"
```

## 🎯 Advanced Features

### Built-in Error Handling
```powershell
# Throw exceptions on errors (default)
$result = Get-Users -id 999 -X_TOKEN $token

# Return $null on errors instead of throwing
$result = Get-Users -id 999 -X_TOKEN $token -NoThrow
```

### Flexible Base URL Configuration
```powershell
# Use default base URL from spec
Get-Users -id 123 -X_TOKEN $token

# Override base URL per call
Get-Users -id 123 -X_TOKEN $token -BaseUrl "https://staging-api.company.com"
```

### Comprehensive Parameter Validation
```powershell
# Automatic validation from OpenAPI schema
Get-UsersList -status "active"        # ✅ Valid enum value
Get-UsersList -status "invalid"       # ❌ Validation error
Get-UsersList -limit 50               # ✅ Valid integer
Get-UsersList -limit "not-a-number"   # ❌ Type error
```

## 📊 Proven Track Record

Successfully tested with:
- **swagger example spec** (YAML & JSON)

## 🛠️ Troubleshooting

### Common Issues

**YAML parsing errors:**
```powershell
# Ensure you have YAML support
Get-Command ConvertFrom-Yaml -ErrorAction SilentlyContinue

# Install if missing
Install-Module powershell-yaml -Scope CurrentUser
```

**Too many parameters:**
The generator limits query parameters to 20 per function to maintain usability. For complex APIs, you can modify the limit in the source code.

**Module import issues:**
```powershell
# Ensure paths are correct
Test-Path .\generated\YourAPI\YourAPI.psd1

# Import with full path
Import-Module (Resolve-Path .\generated\YourAPI\YourAPI.psd1)
```

## 🤝 Contributing

We welcome contributions! Areas of interest:

- **Authentication Schemes**: OAuth2, JWT, API Key detection
- **Response Validation**: Schema-based response validation
- **Testing Framework**: Automated Pester tests for generated functions
- **Advanced Features**: Pipeline support, bulk operations

## 📜 License

MIT License - see [LICENSE](LICENSE) file for details.
