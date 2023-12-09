@IsTest
public class AccountRestResourceTest {
    
    @isTest static void createNewAccountTest() {
        Id accId = AccountRestResource.createNewAccount('Test Acc', '+4878345632', 'https://testacc.systems.com');
        
       	Assert.isTrue(accId != null, 'Account was not created');
        
        Account account = [SELECT Id,
                                  Phone,
                                  Website
                           FROM Account 
                           WHERE Id = :accId];
        
        Assert.isTrue(account != null);
        Assert.areEqual(account.Phone, '+4878345632');
    }
}