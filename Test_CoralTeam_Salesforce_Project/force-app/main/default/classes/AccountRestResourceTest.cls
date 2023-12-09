@IsTest
public class AccountRestResourceTest {
    
    @isTest static void createNewAccountTest() {
        Test.startTest();
        
        Id accId = AccountRestResource.createNewAccount('Test Acc', '+4878345632', 'https://testacc.systems.com');
        
       	Assert.isTrue(accId != null, 'Account was not created');
        
        Account account = [SELECT Id,
                                  Phone
                           FROM Account 
                           WHERE Id = :accId];
        
        Assert.isTrue(account != null, 'Account was not created');
        Assert.areEqual(account.Phone, '+4878345632');
        
        Test.stopTest();
    }
    
     @isTest static void createNewAccountExceptionTest() {
        Test.startTest();
         
        String accId = AccountRestResource.createNewAccount(null, '+4878345632', 'https://testacc.systems.com');
        Assert.isTrue(accId != null, 'Exception message should be returned');
         
        Test.stopTest();
    }
}