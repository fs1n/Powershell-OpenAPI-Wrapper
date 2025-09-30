# 📁 PowerShell OpenAPI Wrapper Generator - Project Structure

This document describes the organized structure of the PowerShell OpenAPI Wrapper Generator repository.

## 🏗️ Repository Structure

```
PowerShell-OpenAPI-Wrapper/
├── 📄 New-PowerShellAPIWrapper.ps1     # Main entry point script
├── 📄 README.md                        # Repository documentation
├── 📄 LICENSE                          # License file
├── 📂 src/                             # Source code directory
│   ├── 📂 Core/                        # Core functionality modules
│   │   ├── 📄 OpenAPIParser.ps1        # OpenAPI specification parser
│   │   ├── 📄 ModuleGenerator.ps1      # Main module generation logic
│   │   ├── 📄 ReadmeGenerator.ps1      # Module README generator
│   │   └── 📄 UtilityFunctions.ps1     # Common utility functions
│   └── 📂 Enhancements/                # Optional enhancement modules
│       ├── 📄 VerbMappingEnhancement.ps1      # Enhanced PowerShell verb mapping
│       ├── 📄 ParameterEnhancement.ps1        # Advanced parameter handling
│       ├── 📄 ErrorHandlingEnhancement.ps1    # Enterprise error handling
│       └── 📄 TypeSystemEnhancement.ps1       # Strong typing system
├── 📂 examples/                        # Example OpenAPI specifications
│   ├── 📄 swagger.json                 # Sample Swagger/OpenAPI files
│   ├── 📄 swagger-hera-0.1.0.json     # Real-world API examples
│   ├── 📄 swagger.yaml                 # YAML format examples
│   └── 📄 midata.yaml                  # Additional examples
├── 📂 docs/                            # Documentation
│   ├── 📄 IntegrationGuide.ps1         # Integration instructions
│   ├── 📄 ProjectStructure.md          # This file
│   └── 📄 EnhancementGuide.md           # Enhancement development guide
└── 📂 reference/                       # Reference materials
    └── 📂 PSSwagger-developer/          # Microsoft PSSwagger reference
```

## 🎯 Design Principles

### **1. Single Entry Point**
- `New-PowerShellAPIWrapper.ps1` is the only script users need to run
- All complexity is abstracted away behind a clean interface
- Supports both simple and advanced usage scenarios

### **2. Modular Architecture**
- **Core modules**: Essential functionality that's always loaded
- **Enhancement modules**: Optional features that can be enabled/disabled
- **Clear separation of concerns**: Each module has a specific responsibility

### **3. Progressive Enhancement**
- Basic functionality works out of the box
- Advanced features can be enabled as needed
- Enhancements don't break core functionality

## 🚀 Usage Examples

### **Basic Usage**
```powershell
# Generate a simple PowerShell module
.\New-PowerShellAPIWrapper.ps1 -OpenAPIPath ".\examples\swagger.json" -OutputPath ".\MyModule" -ModuleName "MyAPI"
```

### **Advanced Usage**
```powershell
# Generate with specific enhancements
.\New-PowerShellAPIWrapper.ps1 `
    -OpenAPIPath ".\examples\midata.yaml" `
    -OutputPath ".\MidataModule" `
    -ModuleName "MidataAPI" `
    -IncludeEnhancements @("VerbMapping", "ErrorHandling", "TypeSystem") `
    -GenerateReadme `
    -BaseUri "https://api.midata.coop"
```

## 📦 Core Modules

### **OpenAPIParser.ps1**
- Parses JSON and YAML OpenAPI specifications
- Resolves $ref references
- Normalizes different OpenAPI versions
- Validates specification structure

### **ModuleGenerator.ps1**
- Main module generation logic (formerly Module-GEN-Parser.ps1)
- Creates PowerShell module structure
- Generates function scaffolding
- Handles module manifest creation

### **ReadmeGenerator.ps1**
- Generates documentation for created modules
- Creates usage examples
- Documents available functions
- Provides troubleshooting information

### **UtilityFunctions.ps1**
- Common string manipulation functions
- Type conversion utilities
- Validation helpers
- Logging and progress functions

## 🔧 Enhancement Modules

### **VerbMappingEnhancement.ps1**
- Intelligent PowerShell verb mapping
- Context-aware function naming
- Support for complex operation patterns
- Based on Microsoft PSSwagger patterns

### **ParameterEnhancement.ps1**
- Parameter flattening for nested objects
- Advanced validation attributes
- Type-safe parameter definitions
- Support for parameter grouping

### **ErrorHandlingEnhancement.ps1**
- Enterprise-grade error handling
- HTTP status code mapping
- Retry logic with exponential backoff
- Structured error reporting

### **TypeSystemEnhancement.ps1**
- Strong typing with PowerShell classes
- Custom type definitions
- Validation methods
- Serialization/deserialization support

## 📂 Directory Purposes

### **`/src/Core/`**
Contains the essential modules that provide the core functionality of the generator. These modules are always loaded and provide the basic features needed to generate a working PowerShell module.

### **`/src/Enhancements/`**
Contains optional enhancement modules that add advanced features. Users can selectively enable these based on their needs, allowing for both simple and sophisticated generated modules.

### **`/examples/`**
Contains sample OpenAPI specifications that users can use to test the generator or as starting points for their own APIs. Includes both simple examples and real-world specifications.

### **`/docs/`**
Contains comprehensive documentation including integration guides, development instructions, and architectural decisions.

### **`/reference/`**
Contains reference materials, particularly the Microsoft PSSwagger implementation that serves as inspiration for many of the enhancements.

## 🔄 Migration from Old Structure

The repository has been reorganized from a flat structure to this organized hierarchy:

- **Main script**: Single entry point replaces multiple scattered scripts
- **Modular core**: Core functionality split into logical modules
- **Optional enhancements**: Advanced features separated for optional inclusion
- **Clear examples**: Sample files organized for easy discovery
- **Comprehensive docs**: All documentation centralized and structured

This new structure makes the project more maintainable, easier to understand, and simpler to extend with new features.