<#
This Azure Function PowerShell script performs the following tasks:

Initialization:

Imports the System.Net namespace.
Defines parameters $Request and $TriggerMetadata.
Sets up variables for the transport rule name, recipient addresses, SCL value, and result code.
Security Check:

Validates the security key from the request headers against an environment variable.
Input Validation:

Checks if the ClientDomain is provided and trims it.
Sets a default value for TicketId if not provided.
Logging:

Logs the client domain and ticket ID.
Exchange Online Connection:

If the result code is 200, it attempts to connect to Exchange Online using an access token obtained via client credentials.
The connection can be made using managed identity, user principal name, or delegated organization (commented out options).
Transport Rule Check and Creation:

Checks if the transport rule "CF_Managed - Whitelist Cloudfirst Users" exists.
If the rule does not exist, it creates the rule with specified recipient addresses, sender condition, and SCL value.
Response Construction:

Constructs a response body with a message, ticket ID, result code, and status.
Sends the response with a status code of 200 and content type of JSON.
Cleanup:

Disconnects from Exchange Online.
This script ensures that a specific mail flow rule is present in Exchange Online, creating it if necessary, and provides a structured response based on the operation's success. If you have any questions or need further details, feel free to ask!

#>

using namespace System.Net

param($Request, $TriggerMetadata)

Write-Host "CF Whitelist function triggered."
$ruleName = "CF_Managed - Whitelist Cloudfirst Users"
$recipientAddresses = @("ask@cloudfirstinc.com", "dgentles@cloudfirstinc.com", "helpdesk@cloudfirstinc.com")
$sclValue = -1
$resultCode = 200
$message = ""
$ClientDomain = $Request.Body.ClientDomain
$TenantId = $Request.Body.TenantId
$TicketId = $Request.Body.TicketId
$SecurityKey = $env:SecurityKey

if ($SecurityKey -And $SecurityKey -ne $Request.Headers.SecurityKey) {
    Write-Host "Invalid security key"
    break;
}

if (-Not $ClientDomain) {
    $message = "Domain cannot be blank."
    $resultCode = 500
}
else {
    $ClientDomain = $GroupName.Trim()
}

if (-Not $TicketId) {
    $TicketId = ""
}

Write-Host "Client Domain: $ClientDomain"
Write-Host "Ticket Id: $TicketId"

if ($resultCode -Eq 200) {
# Connect to Exchange Online using managed identity
#Connect-ExchangeOnline -ManagedIdentity -Organization "yourdomain.onmicrosoft.com"
#Connect-ExchangeOnline -UserPrincipalName "user@domain.com"
#Connect-ExchangeOnline -DelegatedOrganization "clientdomain.onmicrosoft.com"
#Connect-ExchangeOnline 


# Get the access token
$bodytk = @{
    grant_type    = "client_credentials"
    client_id     = $env:Ms365_AuthAppId
    client_secret = $env:Ms365_AuthSecretId
    scope         = "https://outlook.office365.com/.default"
}

$response = Invoke-RestMethod -Uri "https://login.microsoftonline.com/$tenantId/oauth2/v2.0/token" -Method Post -ContentType "application/x-www-form-urlencoded" -Body $bodytk
$accessToken = $response.access_token

# Connect to Exchange Online using the access token
Connect-ExchangeOnline -AccessToken $accessToken -DelegatedOrganization $ClientDomain
}


# Check if the transport rule exists
$rule = Get-TransportRule -Identity $ruleName -ErrorAction SilentlyContinue

# Output the result
if ($null -ne $rule) {
    Write-Output "Transport rule '$ruleName' exists."
} else {
    Write-Output "Transport rule '$ruleName' does not exist."
    # Create the mail flow rule
New-TransportRule -Name $ruleName `
    -RecipientAddressContainsWords $recipientAddresses `
    -SenderIsExternal `
    -SetSCL $sclValue
}

$body = @{
    Message      = $message
    TicketId     = $TicketId
    ResultCode   = $resultCode
    ResultStatus = if ($resultCode -eq 200) { "Success" } else { "Failure" }
} 

# Associate values to output bindings by calling 'Push-OutputBinding'.
Push-OutputBinding -Name Response -Value ([HttpResponseContext]@{
        StatusCode  = [HttpStatusCode]::OK
        Body        = $body
        ContentType = "application/json"
    })
# Disconnect from Exchange Online
Disconnect-ExchangeOnline -Confirm:$false
