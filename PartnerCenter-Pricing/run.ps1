# Import necessary modules
Import-Module Az.Accounts
Import-Module Az.Functions

# Authenticate to Partner Center API
$tenantId = $env:Ms365_TenantId
$clientId = $env:Ms365_AuthAppId     
$clientSecret = $env:Ms365_AuthSecretId
$resource = "https://api.partnercenter.microsoft.com"
$authContext = [Microsoft.IdentityModel.Clients.ActiveDirectory.AuthenticationContext]::new("https://login.microsoftonline.com/$tenantId")
$authResult = $authContext.AcquireTokenAsync($resource, [Microsoft.IdentityModel.Clients.ActiveDirectory.ClientCredential]::new($clientId, $clientSecret)).Result
$accessToken = $authResult.AccessToken

# Define pricing URLs
$pricingUrls = @(
    "https://api.partnercenter.microsoft.com/v1/pricing/azure",
    "https://api.partnercenter.microsoft.com/v1/pricing/usage-based",
    "https://api.partnercenter.microsoft.com/v1/pricing/software"
)

# Save the CSVs to a SharePoint folder
$sharepointSiteUrl = "https://palaisparc.sharepoint.com/sites/SalesMarketingTeam-Marketing"
$sharepointFolderPath = "/Shared Documents/Marketing/MicrosoftPriceLists"

# Authenticate to SharePoint
$sharepointContext = [Microsoft.SharePoint.Client.ClientContext]::new($sharepointSiteUrl)
$sharepointContext.Credentials = [Microsoft.SharePoint.Client.SharePointOnlineCredentials]::new("microsoft@cloudfirstinc.com", (ConvertTo-SecureString "Pr1c1ing1!" -AsPlainText -Force))

foreach ($pricingUrl in $pricingUrls) {
    # Download the pricing CSV
    $headers = @{
        Authorization = "Bearer $accessToken"
    }
    $response = Invoke-RestMethod -Uri $pricingUrl -Headers $headers -Method Get
    $csvContent = $response.Content

    # Determine the file name based on the URL
    $csvFileName = ($pricingUrl -split "/")[-1] + ".csv"
    $csvFilePath = "$sharepointFolderPath/$csvFileName"

    # Upload the CSV file to SharePoint
    $fileCreationInfo = [Microsoft.SharePoint.Client.FileCreationInformation]::new()
    $fileCreationInfo.Content = [System.Text.Encoding]::UTF8.GetBytes($csvContent)
    $fileCreationInfo.Url = $csvFilePath
    $sharepointContext.Web.GetFolderByServerRelativeUrl($sharepointFolderPath).Files.Add($fileCreationInfo)
    $sharepointContext.ExecuteQuery()
}
