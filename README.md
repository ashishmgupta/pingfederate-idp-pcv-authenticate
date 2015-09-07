# pingfederate-idp-pcv-authenticate
This is an example of creating a custom password credential validator [PCV] for PingFederate. </br>
If you are using PingFederate in your enterprise, you would probably use an authentication service from PingFederate to authenticate your 
users. This sample example of custom PCV, demonstrates how to create the UI element in your PingFederate to configure your custom service URL
and how the can you use the same URL to authenticate the users.

Focus on the below methods in the /Authenticator.java:-

1. getPluginDescriptor() </br>
This can be used to configure any set of UI elements which needs to be configured by the PingFed administrator.
In this example, It creates a textfield for the authentication service URL in the Admin UI. This is where the PingFederate administrator would
configure the service URL.


2. configure(Configuration configuration)</br>
This can be used to get the configured values from the UI elements (set thie getPluginDescriptor) to the class level variables which then can be used
in the processPasswordCredential(String userName, String password) method.

3. processPasswordCredential(String userName, String password) </br>
Takes the username and password from the input fields in the HTML form and will authenticate the user with your service.
Ignore the implementation details of the service. If the authentication service does not allow the service, this method should throw
the PasswordCredentialValidatorAuthnException with "false" and a string which shows up to the user in the HTML login form.

