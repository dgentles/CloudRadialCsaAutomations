ll
# Update the subscription in Partner Center
Set-PartnerCustomerSubscription -CustomerId $customerId -SubscriptionId $subscriptionId -Subscription $subscription

Write-Output "Successfully added $additionalLicenses Microsoft 365 Business Premium license(s) to the subscription."
    
    #In the script above, we first import the necessary modules and authenticate to Partner Center. We then define the customer and subscription details, including the customer ID, subscription ID, and offer ID for Microsoft 365 Business Premium. We retrieve the customer's subscription and define the number of additional licenses to add. We then update the subscription quantity and update the subscription in Partner Center. Finally, we output a success message indicating that the licenses have been added. 
   # You can run this script in a PowerShell environment to add new licenses to a Microsoft 365 subscription. 
    #If you have any questions or need further assistance, please let me know. 
    
    #Best regards,
    #Dennis Gentles (dgentles@cloudfirstinc.com
    #CloudFirst Inc. Support Team
    
    #End of email
    
