using namespace System.Net

param($Request, $TriggerMetadata)

Write-Host "CF Whitelist function triggered."
$ruleName = "CF_Managed - Whitelist Cloudfirst Users"
$recipientAddresses = @("ask@cloudfirstinc.com", "dgentles@cloudfirstinc.com", "helpdesk@cloudfirstinc.com")
$sclValue = -1
$resultCode = 200
$message = ""
$ClientDomain = ($Request.Body.Ticket.Questions | Where-Object { $_.Id -eq "ClientDomain" }).Value
$Cleanup = ($Request.Body.Ticket.Questions | Where-Object { $_.Id -eq "Cleanup" }).Value

$TenantId = $Request.Body.Company.CompanyTenantId
#$TenantId = $env:Ms365_TenantId
$TicketId = $Request.Body.TicketId
$SecurityKey = $env:SecurityKey

if ($SecurityKey -And $SecurityKey -ne $Request.Headers.SecurityKey) {
    Write-Host "Invalid security key"
    break;
}

if (-Not $ClientDomain) {
    $message = "Domain cannot be blank."
    $resultCode = 500
} else {
    $ClientDomain = $ClientDomain.Trim()
}

if (-Not $TicketId) {
    $TicketId = ""
}

Write-Host "Client Domain: $ClientDomain"
Write-Host "Tenant Id: $TenantId"

if ($resultCode -Eq 200) {
    # Get the access token
    $bodytk = @{
        grant_type    = "client_credentials"
        client_id     = $env:Ms365_AuthAppId
        client_secret = $env:Ms365_AuthSecretId
        scope         = "https://outlook.office365.com/.default"
    }

    $response = Invoke-RestMethod -Uri "https://login.microsoftonline.com/$TenantId/oauth2/v2.0/token" -Method Post -ContentType "application/x-www-form-urlencoded" -Body $bodytk
    $accessToken = $response.access_token

    # Connect to Exchange Online using the access token
    Connect-ExchangeOnline -AccessToken $accessToken -DelegatedOrganization $ClientDomain
}

# Check if the transport rule exists
$rule = Get-TransportRule -Identity $ruleName -ErrorAction SilentlyContinue

if ($cleanup -eq "yes") {
    if ($null -ne $rule) {
        # Delete the transport rule
        Remove-TransportRule -Identity $ruleName -Confirm:$false
        Write-Output "Transport rule '$ruleName' deleted."
    } else {
        Write-Output "Transport rule '$ruleName' does not exist, nothing to delete."
    }
} else {
    # Output the result
    if ($null -ne $rule) {
        Write-Output "Transport rule '$ruleName' exists."
    } else {
        Write-Output "Transport rule '$ruleName' does not exist."
        # Create the mail flow rule
        New-TransportRule -Name $ruleName `
            -RecipientAddressContainsWords $recipientAddresses `
            -FromScope NotInOrganization `
            -SetSCL $sclValue
    }
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
