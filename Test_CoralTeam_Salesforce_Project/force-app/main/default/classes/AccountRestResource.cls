@RestResource(urlMapping='/Account/*')
global with sharing class AccountRestResource {
    
    @HttpPost
    global static String createNewAccount(String name, String phone, String website) {
        Savepoint sPoint = Database.setSavepoint();
        Account account = new Account();
        account.Name = name;
        account.phone = phone;
        account.website = website;
        try {
            insert account;
        } catch(Exception ex) {
            Database.rollback(sPoint);
            return ex.getMessage();
        }
        
        return account.Id;
    }
}