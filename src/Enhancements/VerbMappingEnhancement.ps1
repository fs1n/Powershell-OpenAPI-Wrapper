# Add to Module-GEN-Parser-CLEAN.ps1

$script:EnhancedVerbMap = @{
    # CRUD Operations
    'Create'         = 'New'
    'Generate'       = 'New'
    'Allocate'       = 'New'
    'Provision'      = 'New'
    'Make'           = 'New'
    'Add'            = 'Add'
    'Append'         = 'Add'
    'Attach'         = 'Add'
    'Insert'         = 'Add'
    
    # Read Operations
    'Read'           = 'Get'
    'Retrieve'       = 'Get'
    'Fetch'          = 'Get'
    'List'           = 'Get'
    'Search'         = 'Find'
    'Query'          = 'Find'
    'Filter'         = 'Find'
    
    # Update Operations
    'Update'         = 'Set'
    'Modify'         = 'Set'
    'Change'         = 'Set'
    'Edit'           = 'Set'
    'Configure'      = 'Set'
    'Assign'         = 'Set'
    'Replace'        = 'Set'
    
    # Delete Operations
    'Delete'         = 'Remove'
    'Remove'         = 'Remove'
    'Clear'          = 'Clear'
    'Reset'          = 'Reset'
    'Purge'          = 'Clear'
    
    # Action Operations
    'Execute'        = 'Invoke'
    'Run'            = 'Start'
    'Start'          = 'Start'
    'Stop'           = 'Stop'
    'Restart'        = 'Restart'
    'Pause'          = 'Suspend'
    'Resume'         = 'Resume'
    'Enable'         = 'Enable'
    'Disable'        = 'Disable'
    'Activate'       = 'Enable'
    'Deactivate'     = 'Disable'
    'Test'           = 'Test'
    'Validate'       = 'Test'
    'Check'          = 'Test'
    'Verify'         = 'Test'
    
    # Import/Export Operations
    'Import'         = 'Import'
    'Export'         = 'Export'
    'Download'       = 'Get'
    'Upload'         = 'Send'
    'Sync'           = 'Sync'
    'Synchronize'    = 'Sync'
    
    # Conversion Operations
    'Convert'        = 'Convert'
    'Transform'      = 'Convert'
    'Parse'          = 'Convert'
    'Format'         = 'Format'
    
    # Copy Operations
    'Copy'           = 'Copy'
    'Clone'          = 'Copy'
    'Duplicate'      = 'Copy'
    'Backup'         = 'Backup'
    'Restore'        = 'Restore'
    
    # Move Operations
    'Move'           = 'Move'
    'Relocate'       = 'Move'
    'Transfer'       = 'Move'
    
    # Join Operations
    'Join'           = 'Join'
    'Merge'          = 'Merge'
    'Combine'        = 'Join'
    
    # Split Operations
    'Split'          = 'Split'
    'Separate'       = 'Split'
    'Divide'         = 'Split'
    
    # Measure Operations
    'Count'          = 'Measure'
    'Calculate'      = 'Measure'
    'Compute'        = 'Measure'
    'Analyze'        = 'Measure'
    
    # Compare Operations
    'Compare'        = 'Compare'
    'Diff'           = 'Compare'
    'Match'          = 'Compare'
    
    # Wait Operations
    'Wait'           = 'Wait'
    'Sleep'          = 'Wait'
    'Delay'          = 'Wait'
    
    # Watch Operations
    'Watch'          = 'Watch'
    'Monitor'        = 'Watch'
    'Observe'        = 'Watch'
    
    # Debug Operations
    'Debug'          = 'Debug'
    'Trace'          = 'Trace'
    'Log'            = 'Write'
    
    # Batch Operations
    'Batch'          = 'Invoke'
    'Bulk'           = 'Invoke'
    'Mass'           = 'Invoke'
}

function Get-EnhancedPowerShellVerbForHttpMethod {
    param(
        [string]$Method, 
        [string]$Path, 
        [string]$OperationId,
        [object]$Operation
    )
    
    # 1. Try OperationId analysis first (most reliable)
    if ($OperationId) {
        # Split operationId by common separators
        $parts = $OperationId -split '[_\-\.]|(?=[A-Z])'
        
        # Look for verb in first part
        $verbPart = $parts[0]
        if ($script:EnhancedVerbMap.ContainsKey($verbPart)) {
            $verb = $script:EnhancedVerbMap[$verbPart]
        }
    }
    
    # 2. Check operation summary/description for verbs
    if (-not $verb -and $Operation) {
        $searchText = "$($Operation.summary) $($Operation.description)".ToLower()
        
        foreach ($key in $script:EnhancedVerbMap.Keys) {
            if ($searchText -match "\b$($key.ToLower())\b") {
                $verb = $script:EnhancedVerbMap[$key]
                break
            }
        }
    }
    
    # 3. Fall back to HTTP method mapping
    if (-not $verb) {
        switch ($Method.ToUpper()) {
            'GET' { 
                $verb = if ($Path -match '\{[^}]+\}$' -or $Path -match '/\d+$') { 'Get' } else { 'Get' }
            }
            'POST' { $verb = 'New' }
            'PUT' { $verb = 'Set' }
            'PATCH' { $verb = 'Update' }
            'DELETE' { $verb = 'Remove' }
            default { $verb = 'Invoke' }
        }
    }
    
    # 4. Generate noun from path
    $pathSegments = ($Path -split '/' | Where-Object { $_ -and $_ -notmatch '^\{.*\}$' })
    $noun = if ($pathSegments.Count -gt 0) { 
        $lastSegment = $pathSegments[-1]
        # Convert to PascalCase and singularize
        (Get-Culture).TextInfo.ToTitleCase($lastSegment -replace '[_\-]', ' ') -replace ' ', ''
    } else { 
        'Resource' 
    }
    
    # 5. Handle collection vs single resource
    if ($verb -eq 'Get' -and $Path -notmatch '\{[^}]+\}$') {
        $noun += 'List'
    }
    
    return "$verb-$noun"
}