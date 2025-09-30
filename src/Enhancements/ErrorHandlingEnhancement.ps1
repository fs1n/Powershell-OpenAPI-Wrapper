# Enhanced Error Handling based on PSSwagger patterns
# Add to Module-GEN-Parser-CLEAN.ps1

function New-EnhancedErrorHandling {
    param(
        [string]$FunctionName,
        [object]$Operation
    )
    
    $errorHandling = @"
    try {
        # Pre-execution validation
        if (`$PSCmdlet.ShouldProcess(`$PSBoundParameters.ToString(), "$FunctionName")) {
            
            # Parameter validation
            foreach (`$param in `$PSBoundParameters.Keys) {
                if (`$null -eq `$PSBoundParameters[`$param] -and `$param -in @('RequiredParam1', 'RequiredParam2')) {
                    throw [System.ArgumentNullException]::new(`$param, "Required parameter '`$param' cannot be null or empty")
                }
            }
            
            # Build request URI with proper encoding
            `$requestUri = Build-RequestUri -BaseUri `$BaseUri -Path "$($Operation.path)" -Parameters `$PSBoundParameters
            
            # Execute REST call with retry logic
            `$response = Invoke-RestMethodWithRetry -Uri `$requestUri -Method '$($Operation.method.ToUpper())' -Headers `$Headers -Body `$Body
            
            # Process response based on content type
            if (`$response) {
                return ConvertTo-PowerShellObject -Response `$response -OperationId '$($Operation.operationId)'
            }
        }
    }
    catch [System.Net.WebException] {
        `$errorDetails = Get-WebExceptionDetails -Exception `$_
        
        switch (`$errorDetails.StatusCode) {
            400 { 
                Write-Error "Bad Request: `$(`$errorDetails.Message)" -Category InvalidArgument
            }
            401 { 
                Write-Error "Unauthorized: Check your authentication credentials" -Category AuthenticationError
            }
            403 { 
                Write-Error "Forbidden: Insufficient permissions for this operation" -Category PermissionDenied
            }
            404 { 
                Write-Error "Not Found: The requested resource does not exist" -Category ObjectNotFound
            }
            409 { 
                Write-Error "Conflict: `$(`$errorDetails.Message)" -Category ResourceExists
            }
            429 { 
                Write-Warning "Rate limit exceeded. Consider implementing exponential backoff."
                Start-Sleep -Seconds 5
                # Implement retry logic here
            }
            500 { 
                Write-Error "Internal Server Error: `$(`$errorDetails.Message)" -Category NotSpecified
            }
            503 { 
                Write-Error "Service Unavailable: The service is temporarily unavailable" -Category ResourceUnavailable
            }
            default { 
                Write-Error "HTTP Error `$(`$errorDetails.StatusCode): `$(`$errorDetails.Message)" -Category NotSpecified
            }
        }
        
        # Enhanced error record for debugging
        `$errorRecord = [System.Management.Automation.ErrorRecord]::new(
            `$_.Exception,
            "$FunctionName.WebException",
            [System.Management.Automation.ErrorCategory]::InvalidOperation,
            `$requestUri
        )
        
        # Add detailed information to error record
        `$errorRecord.ErrorDetails = [System.Management.Automation.ErrorDetails]::new(`$errorDetails.DetailedMessage)
        `$errorRecord.CategoryInfo = [System.Management.Automation.ErrorCategoryInfo]::new(
            [System.Management.Automation.ErrorCategory]::InvalidOperation,
            "$FunctionName",
            [System.String],
            `$requestUri
        )
        
        `$PSCmdlet.ThrowTerminatingError(`$errorRecord)
    }
    catch [System.ArgumentException] {
        Write-Error "Invalid argument: `$(`$_.Exception.Message)" -Category InvalidArgument -TargetObject `$PSBoundParameters
    }
    catch [System.UnauthorizedAccessException] {
        Write-Error "Access denied: `$(`$_.Exception.Message)" -Category PermissionDenied
    }
    catch {
        # Generic error handling with full details
        `$errorRecord = [System.Management.Automation.ErrorRecord]::new(
            `$_.Exception,
            "$FunctionName.UnhandledException",
            [System.Management.Automation.ErrorCategory]::NotSpecified,
            `$null
        )
        
        `$PSCmdlet.ThrowTerminatingError(`$errorRecord)
    }
"@
    
    return $errorHandling
}

function New-RetryLogic {
    return @"
function Invoke-RestMethodWithRetry {
    param(
        [string]`$Uri,
        [string]`$Method,
        [hashtable]`$Headers,
        [object]`$Body,
        [int]`$MaxRetries = 3,
        [int]`$InitialDelaySeconds = 1
    )
    
    `$attempt = 0
    `$delay = `$InitialDelaySeconds
    
    do {
        try {
            `$attempt++
            
            `$splat = @{
                Uri = `$Uri
                Method = `$Method
                Headers = `$Headers
                ContentType = 'application/json'
                ErrorAction = 'Stop'
            }
            
            if (`$Body) {
                `$splat.Body = `$Body | ConvertTo-Json -Depth 10
            }
            
            # Add progress information
            Write-Progress -Activity "API Call" -Status "Attempt `$attempt of `$(`$MaxRetries + 1)" -PercentComplete ((`$attempt / (`$MaxRetries + 1)) * 100)
            
            `$response = Invoke-RestMethod @splat
            
            Write-Progress -Activity "API Call" -Completed
            return `$response
        }
        catch [System.Net.WebException] {
            `$statusCode = `$_.Exception.Response.StatusCode
            
            # Only retry on specific status codes
            if (`$statusCode -in @(429, 500, 502, 503, 504) -and `$attempt -le `$MaxRetries) {
                Write-Warning "Request failed with status `$statusCode. Retrying in `$delay seconds... (Attempt `$attempt of `$(`$MaxRetries + 1))"
                Start-Sleep -Seconds `$delay
                `$delay *= 2  # Exponential backoff
            } else {
                Write-Progress -Activity "API Call" -Completed
                throw
            }
        }
    } while (`$attempt -le `$MaxRetries)
    
    Write-Progress -Activity "API Call" -Completed
    throw "Maximum retry attempts (`$MaxRetries) exceeded"
}
"@
}