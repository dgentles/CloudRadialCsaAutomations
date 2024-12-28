# Define the parameters for the mail flow rule
$ruleName = "CF_Managed - Whitelist Cloudfirst Users"
$recipientAddresses = @("ask@cloudfirstinc.com", "dgentles@cloudfirstinc.com", "helpdesk@cloudfirstinc.com")
$sclValue = -1

# Connect to Exchange Online using managed identity
#Connect-ExchangeOnline -ManagedIdentity -Organization "yourdomain.onmicrosoft.com"
#Connect-ExchangeOnline -UserPrincipalName "user@domain.com"
#Connect-ExchangeOnline -DelegatedOrganization "clientdomain.onmicrosoft.com"
Connect-ExchangeOnline 

# Create the mail flow rule
New-TransportRule -Name $ruleName `
    -RecipientAddressContainsWords $recipientAddresses `
    -SenderIsExternal `
    -SetSCL $sclValue

# Disconnect from Exchange Online
Disconnect-ExchangeOnline -Confirm:$false
