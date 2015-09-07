/*
 * To change this license header, choose License Headers in Project Properties.
 * To change this template file, choose Tools | Templates
 * and open the template in the editor.
 */
package pingfederate.passwordcredentialvalidators;

import com.pingidentity.sdk.GuiConfigDescriptor;
import com.pingidentity.sdk.PluginDescriptor;
import com.pingidentity.sdk.password.PasswordCredentialValidator;
import com.pingidentity.sdk.password.PasswordCredentialValidatorAuthnException;
import com.pingidentity.sdk.password.PasswordValidationException;
import java.util.Collections;
import org.sourceid.saml20.adapter.attribute.AttributeValue;
import org.sourceid.saml20.adapter.conf.Configuration;
import org.sourceid.saml20.adapter.gui.TextFieldDescriptor;
import org.sourceid.util.log.AttributeMap;

/**
 *
 * @author asgupta
 */
public class Authenticator implements PasswordCredentialValidator{
    
    private static final String authServiceURLLabel = "Authentication service URL";
    private static final String authServiceURLDescription = "The URL of the service which validates user's credentials";
    private static final String USERNAME = "username";
    private String authenticationURL = "";

    /*    Creates a textfield for the authentication service URL in the Admin UI */
    @Override
    public PluginDescriptor getPluginDescriptor() {
       GuiConfigDescriptor guiDescriptor = new GuiConfigDescriptor();
       TextFieldDescriptor authServiceURLTextField = new TextFieldDescriptor(authServiceURLLabel, authServiceURLDescription);
       guiDescriptor.addField(authServiceURLTextField);
       PluginDescriptor pluginDescriptor = new PluginDescriptor(buildName(), this, guiDescriptor);
       // Below will make the attributes available in the input Userid mapping in the composite adapter If this is used inside the composite adapter.
       pluginDescriptor.setAttributeContractSet(Collections.singleton(USERNAME));
       return pluginDescriptor;
    }
   
    /* Get all the configured values in the PingFed admin e.g. Service URL */
    @Override
    public void configure(Configuration configuration) {
       this.authenticationURL = configuration.getFieldValue(authServiceURLLabel);
    }
    
    @Override
    public AttributeMap processPasswordCredential(String userName, String password) throws PasswordValidationException {
       AttributeMap attributeMap = new AttributeMap();
       if(!AuthHelper.IsUserAuthenticated(this.authenticationURL, userName, password))
       {
           throw new PasswordCredentialValidatorAuthnException(false, "authn.srvr.msg.invalid.credentials");
       }
       else
       {
          // The username value put here will be avilable to the next adapter in teh composite adapter chain
          attributeMap.put(USERNAME, new AttributeValue(userName));
       }
       
       return attributeMap;
    }
      
    private String buildName() {
        
        return "Custom password credential validator";
        /*
        Package plugin = Authenticator.class.getPackage();
        return plugin.getImplementationTitle();//+ " " + plugin.getImplementationVersion();         
        */
    }
    
}



