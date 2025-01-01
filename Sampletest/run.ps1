using namespace System.Net
using namespace OpenQA.Selenium
using namespace OpenQA.Selenium.Chrome
using namespace OpenQA.Selenium.Support.UI

param($Request, $TriggerMetadata)

# Set up Selenium WebDriver
$options = New-Object OpenQA.Selenium.Chrome.ChromeOptions
$options.AddArgument('--headless')
$options.AddArgument('--no-sandbox')
$options.AddArgument('--disable-dev-shm-usage')
$driver = New-Object OpenQA.Selenium.Chrome.ChromeDriver($options)

try {
    # Navigate to the webpage
    $driver.Navigate().GoToUrl('URL_OF_THE_PAGE')

    # Log in to the page
    $username = $driver.FindElementById('username')
    $password = $driver.FindElementById('password')
    $username.SendKeys('YOUR_USERNAME')
    $password.SendKeys('YOUR_PASSWORD')
    $password.SendKeys([OpenQA.Selenium.Keys]::Return)

    # Wait for login to complete
    Start-Sleep -Seconds 5

    # Click 'Load More' to fetch content
    do {
        $loadMoreButton = $driver.FindElementById('loadMore')
        $loadMoreButton.Click()
        Start-Sleep -Seconds 2  # Adjust sleep time as needed
    } while ($loadMoreButton.Displayed)

    # Extract content for the last 30 days
    $content = $driver.FindElementById('content').Text

    # Save content to a text file
    $filePath = Join-Path $env:TEMP 'content.txt'
    Set-Content -Path $filePath -Value $content

    # Return success response
    $response = @{
        statusCode = [HttpStatusCode]::OK
        body       = "Content saved successfully."
    }
} catch {
    # Log error and return failure response
    Write-Error $_
    $response = @{
        statusCode = [HttpStatusCode]::InternalServerError
        body       = "An error occurred: $_"
    }
} finally {
    $driver.Quit()
}

return $response
