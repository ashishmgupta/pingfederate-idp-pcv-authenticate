/*
 * To change this license header, choose License Headers in Project Properties.
 * To change this template file, choose Tools | Templates
 * and open the template in the editor.
 */
package pingfederate.passwordcredentialvalidators;

/**
 *
 * @author asgupta
 */
public class AuthHelper {
    
    /* 
    A very simple (or ridiculous) implementation of authenticate method .
    The point here is to show you could call a service which can do the necessary validation.
    */
    public static boolean IsUserAuthenticated(String serviceUrl, String userName, String password)
    {
        return "ashish".equals(userName) && "ashish123".equals(password);
    }
}
