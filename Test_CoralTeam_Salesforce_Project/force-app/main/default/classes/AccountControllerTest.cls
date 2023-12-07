@isTest
private class AccountControllerTest {
    
    @testSetup
    static void testSetup() {
        Profile standardProfile = [SELECT Id 
                                   FROM Profile 
                                   WHERE Name = 'Standard User'];
        User adminUser = new User(
            ProfileId = standardProfile.Id,
            Username = 'adminuser@systems.com',
            Email = 'adminuser@systems.com',
            LastName = 'Admin',
            FirstName = 'User',
            Alias = 'Adm',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            TimeZoneSidKey = 'America/Los_Angeles'
        );
        insert adminUser;
        
        PermissionSet adminPermissionSet = [SELECT Id 
                                            FROM PermissionSet 
                                            WHERE Name = 'Admin_Contacts_Accounts' 
                                            LIMIT 1];
        PermissionSetAssignment adminPsAssignment = new PermissionSetAssignment(
            AssigneeId = adminUser.Id,
            PermissionSetId = adminPermissionSet.Id
        );
        
        // Separate DML operations for setup objects in a separate transaction
        System.runAs(new User(Id = UserInfo.getUserId())) {
            insert adminPsAssignment;
        }
        
        User businessUser = new User(
            ProfileId = standardProfile.Id,
            Username = 'businessuser@sunsystems.com',
            Email = 'businessuser@sunsystems.com',
            LastName = 'Business',
            FirstName = 'User',
            Alias = 'BS',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            TimeZoneSidKey = 'America/Los_Angeles'
        );
        insert businessUser;
        
        PermissionSet businessPermissionSet = [SELECT Id 
                                               FROM PermissionSet 
                                               WHERE Name = 'Business_Contacts_Accounts' 
                                               LIMIT 1];
        PermissionSetAssignment businessPsAssignment = new PermissionSetAssignment(
            AssigneeId = businessUser.Id,
            PermissionSetId = businessPermissionSet.Id
        );
        
        // Separate DML operations for setup objects in a separate transaction
        System.runAs(new User(Id = UserInfo.getUserId())) {
            insert businessPsAssignment;
        }
        
        List<Account> testAccounts = new List<Account>();
        List<Contact> testContacts = new List<Contact>();
        
        Account adminAccount = new Account(Name = 'AdminAccount');
        testAccounts.add(adminAccount);
        Account businessAccount = new Account(Name = 'BusinessAccount', OwnerId = businessUser.Id);
        testAccounts.add(businessAccount);
        
        insert testAccounts;
        
        for (Integer i = 0; i < 2; i++) {
            Contact adminContact = new Contact(
                FirstName = 'AdminContact' + i,
                LastName = 'AdminUser',
                AccountId = adminAccount.Id
            );
            testContacts.add(adminContact);
        }
        insert testContacts;
    }
    
    
    @isTest
    static void testGetAccountContactTree_AdminUser() {
        User adminUser = [SELECT Id 
                          FROM User 
                          WHERE Username = 'adminuser@systems.com' 
                          LIMIT 1];
        
        Test.startTest();
        System.runAs(adminUser) {
            List<AccountController.AccountWrapper> result = AccountController.getAccountContactTree();
            Assert.areEqual(2, result.size(), 'Two accounts should be retrieved for Admin user');
            Assert.areEqual(2, result[0].items.size(), 'Each account should have two contacts for Admin user');
        }
        Test.stopTest();
    }
    
    @isTest
    static void testGetAccountContactTree_BusinessUser() {
        User businessUser = [SELECT Id FROM User WHERE Username = 'businessuser@sunsystems.com' LIMIT 1];
        
        Test.startTest();
        System.runAs(businessUser) {
            AccountController accController = new AccountController();
            List<AccountController.AccountWrapper> result = AccountController.getAccountContactTree();
            Assert.areEqual(1, result.size(), 'Only accounts owned by the user should be retrieved for Business user');
            Assert.areEqual(0, result[0].items.size(), 'Contacts should not be retrieved for Business user');
        }
        Test.stopTest();
    }
    
    @isTest
    static void testGetRecordData_Account() {
        String accType = 'Account';
        Account testAccount = [SELECT Id,
                                      Name, 
                                      Type, 
                                      Phone, 
                                      Website 
                               FROM Account 
                               LIMIT 1];
        
        Test.startTest();
        Object accDetails = AccountController.getRecordData(testAccount.Id, accType);
        
        Map<String, Object> result = (Map<String, Object>)accDetails;
        AccountController.AccountInfoWrapper accountData = (AccountController.AccountInfoWrapper)result.get('accountData');
        
        Assert.areNotEqual(null, accountData, 'Account data should not be null');
        Assert.areEqual(testAccount.Name, accountData.accountName, 'Account name should match');
        
        Test.stopTest();
    }
    
    @isTest
    static void testGetRecordData_Contact() {
        String contactType = 'Contact';
        Contact testContact = [SELECT Id,
                                      Name, 
                                      Phone, 
                                      Email, 
                                      AccountId
                               FROM Contact 
                               LIMIT 1];
        
        Test.startTest();
        Object accDetails = AccountController.getRecordData(testContact.Id, contactType);
        
        Map<String, Object> result = (Map<String, Object>)accDetails;
        AccountController.AccountInfoWrapper accountData = (AccountController.AccountInfoWrapper)result.get('accountData');
        AccountController.ContactInfoWrapper contactData = (AccountController.ContactInfoWrapper)result.get('contactData');
        
        Assert.areNotEqual(null, accountData, 'Account data should not be null');
        Assert.areNotEqual(null, contactData, 'Contact data should not be null');
        
        
        Test.stopTest();
    }
    
}