@RestResource(urlMapping='/Account/*')
global with sharing class AccountRestResource {
    
    @HttpPost
    global static String createNewAccount(String name, String phone, String website) {
        Account account = new Account();
        account.Name = name;
        account.phone = phone;
        account.website = website;
        insert account;
        
        return account.Id;
    }
}