@IsTest
public class AccountRestResourceTest {
    
    @isTest static void testCreateCase() {
        Id accId = AccountRestResource.createNewAccount(
            'Test Acc', '+4878345632', 'https://testacc.systems.com');
        
       	Assert.isTrue(accId != null);
        
        Account account = [SELECT Id,
                                  Phone,
                                  Website
                           FROM Account 
                           WHERE Id = :accId];
        
        Assert.isTrue(account != null);
        Assert.areEqual(account.Phone, '+4878345632');
    }
}