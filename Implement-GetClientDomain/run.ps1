<# 

.SYNOPSIS
    
    This function is used get the client domain for the tenant and place it into a cloud radial token

.DESCRIPTION

    This function gets the primary client domain 

    The function requires the following environment variables to be set:

    Ms365_AuthAppId - Application Id of the service principal
    Ms365_AuthSecretId - Secret Id of the service principal
    Ms365_TenantId - Tenant Id of the Microsoft 365 tenant
    SecurityKey - Optional, use this as an additional step to secure the function

    The function requires the following modules to be installed:
    
    Microsoft.Graph

.INPUTS

    UserEmail - user email address that exists in the tenant
    GroupName - group name that exists in the tenant
    TenantId - string value of the tenant id, if blank uses the environment variable Ms365_TenantId
    TicketId - optional - string value of the ticket id used for transaction tracking
    SecurityKey - Optional, use this as an additional step to secure the function

    JSON Structure

    {
        "UserEmail": "email@address.com",
        "GroupName": "Group Name",
        "TenantId": "12345678-1234-1234-123456789012",
        "TicketId": "123456,
        "SecurityKey", "optional"
    }

.OUTPUTS

    JSON response with the following fields:

    Message - Descriptive string of result
    TicketId - TicketId passed in Parameters
    ResultCode - 200 for success, 500 for failure
    ResultStatus - "Success" or "Failure"

#>


using namespace System.Net

param($Request, $TriggerMetadata)

# Log the function trigger
Write-Host "Function triggered to get default domain for tenant."

# Extract the tenant ID from the request body
$tenantId = $Request.Body.TenantId
$SecurityKey = $env:SecurityKey

if ($SecurityKey -And $SecurityKey -ne $Request.Headers.SecurityKey) {
    Write-Host "Invalid security key"
    break;
}

# Validate the tenant ID
if (-not $tenantId) {
    $response = @{
        status = 400
        body = "Tenant ID is required."
    }
    Push-OutputBinding -Name Response -Value ([HttpResponseContext]@{
        StatusCode  = [HttpStatusCode]::BadRequest
        Body        = $response
        ContentType = "application/json"
    })
    return
}

# Define the client ID and client secret (stored in environment variables for security)
$clientId = $env:Ms365_AuthAppId
$clientSecret = $env:Ms365_AuthSecretId


# Get the access token
$body = @{
    grant_type    = "client_credentials"
    client_id     = $clientId
    client_secret = $clientSecret
    scope         = "https://graph.microsoft.com/.default"
}

$response = Invoke-RestMethod -Uri "https://login.microsoftonline.com/$tenantId/oauth2/v2.0/token" -Method Post -ContentType "application/x-www-form-urlencoded" -Body $body
$accessToken = $response.access_token

# Set the authorization header
$headers = @{
    "Authorization" = "Bearer $accessToken"
}

# Define the Graph API endpoint to get the verified domains
$endpoint = "https://graph.microsoft.com/v1.0/domains"

# Make the API request
$response = Invoke-RestMethod -Uri $endpoint -Headers $headers -Method Get

# Find the default domain
$defaultDomain = $response.value | Where-Object { $_.isDefault -eq $true }

# Prepare the response
if ($defaultDomain) {
    $response = @{
        status = 200
        body = @{
            DefaultDomain = $defaultDomain.id
        }
    }
} else {
    $response = @{
        status = 404
        body = "Default domain not found."
    }
}

# Return the response
Push-OutputBinding -Name Response -Value ([HttpResponseContext]@{
    StatusCode  = [HttpStatusCode]::OK
    Body        = $response
    ContentType = "application/json"
})