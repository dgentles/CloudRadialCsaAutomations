function Connect-ExchangeOnline {
	$username = if([string]::isnullorempty($env:username)) {
					"user"
				} else {
					$env:username
				}
				
	$thisModule = "ExchangeManagement"
	$actualModule = "ExchangeOnlineManagement"
	
    "Hello $username! You probably wanted to install the '$actualModule' module, but you installed the '$thisModule' module instead. This is kinda bad, but you're lucky today, since this '$thisModule' module is not malicious."
	"You can install the correct module using 'Install-Module $actualModule'"
	""
	"Have a nice day!"
	"- Andreas Dieckmann (https://diecknet.de)"
}
# Export function for module usage
Export-ModuleMember -Function Connect-ExchangeOnline