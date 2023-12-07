public with sharing class AccountController {
     
    //private static final String ADMIN_PERMISSION_SET_NAME = 'Admin';
    //private static final String BUSINESS_PERMISSION_SET_NAME = 'Business';
    //public static User_Permission_Set__mdt adminPermissionSet { get; private set; }
    //public static User_Permission_Set__mdt businessPermissionSet { get; private set; }
    private static final String ADMIN_PERMISSION_SET_NAME = 'Admin_Contacts_Accounts';
    private static final String BUSINESS_PERMISSION_SET_NAME = 'Business_Contacts_Accounts';
    public static Boolean isAdminUser { get; private set; }
    public static Boolean isBusinessUser { get; private set; }


    @AuraEnabled(cacheable=true)
    public static List<AccountWrapper> getAccountContactTree() {
        List<AccountWrapper> accWrapper = new List<AccountWrapper>();

        getUserPermissionSetNames();

        List<Account> accounts = new List<Account>();
        if (isAdminUser) {
            accounts = [SELECT Id, 
                               Name, 
                               (SELECT Id, 
                                       FirstName, 
                                       LastName 
                                FROM Contacts) 
                        FROM Account];
        } else if(isBusinessUser) {
            accounts = [SELECT Id, 
                               Name, 
                               (SELECT Id, 
                                       FirstName, 
                                       LastName 
                                FROM Contacts) 
                        FROM Account 
                        WHERE OwnerId = :UserInfo.getUserId()];
        }
        if (!accounts.isEmpty()) {
            for (Account acc : accounts) {
                AccountWrapper accountNode = new AccountWrapper(acc.Id, acc.Name, 'Account');
                List<AccountWrapper> contactNodes = new List<AccountWrapper>();

                for (Contact con : acc.Contacts) {
                    contactNodes.add(new AccountWrapper(con.Id, con.FirstName + ' ' + con.LastName, 'Contact'));
                }

                accountNode.items = contactNodes;
                accWrapper.add(accountNode);
            }
        }
        return accWrapper;
    }

    @AuraEnabled(cacheable=true)
    public static String getUserPermissionSetNames() {
        Set<String> permissionSetNames = new Set<String>();

        List<PermissionSetAssignment> assignments = [
            SELECT PermissionSet.Name
            FROM PermissionSetAssignment
            WHERE AssigneeId = :UserInfo.getUserId()
        ];

        for (PermissionSetAssignment assignment : assignments) {
            permissionSetNames.add(assignment.PermissionSet.Name);
        }

        //assignPermissionSets();

        //isAdminUser = adminPermissionSet != null && permissionSetNames.contains(adminPermissionSet.QualifiedApiName);
        //isBusinessUser = businessPermissionSet != null && permissionSetNames.contains(businessPermissionSet.QualifiedApiName);
        
        isAdminUser = permissionSetNames.contains(ADMIN_PERMISSION_SET_NAME);
        isBusinessUser = permissionSetNames.contains(BUSINESS_PERMISSION_SET_NAME);
        return isBusinessUser ? 'business' : (isAdminUser ? 'admin' : null);
    }

    public class AccountWrapper {
        @AuraEnabled
        public String name { get; set; }

        @AuraEnabled
        public String label { get; set; }

        @AuraEnabled
        public String type { get; set; }

        @AuraEnabled
        public List<AccountWrapper> items { get; set; }

        public AccountWrapper(String name, String label, String type) {
            this.name = name;
            this.label = label;
            this.type = type;
            this.items = new List<AccountWrapper>();
        }
    }

    /*public static void assignPermissionSets() {
        adminPermissionSet = getPermissionSetByName(ADMIN_PERMISSION_SET_NAME);
        businessPermissionSet = getPermissionSetByName(BUSINESS_PERMISSION_SET_NAME);
    }*/

   /*private static User_Permission_Set__mdt getPermissionSetByName(String name) {
        try {
            return [SELECT Id, 
                           QualifiedApiName
                    FROM User_Permission_Set__mdt
                    WHERE MasterLabel = :name
                    LIMIT 1];
        } catch (QueryException e) {
            return null;
        }
    }*/

    @AuraEnabled(cacheable=true)
    public static Object getRecordData(String recordId, String type) {
        Map<String, Object> result = new Map<String, Object>();

        if (type == 'Account') {
            result.put('accountData', getAccountInfo(recordId));
        } else if (type == 'Contact') {
            result.put('accountData', getAccountInfoFromContact(recordId));
            result.put('contactData', getContactInfo(recordId));
        }
        return result;
    }

    private static AccountInfoWrapper getAccountInfoFromContact(String contactId) {
        Contact con = [SELECT Id, 
                          AccountId 
                       FROM Contact 
                       WHERE Id = :contactId 
                       LIMIT 1];

        Account acc = [SELECT Id, 
                              Name, 
                              Type, 
                              Phone, 
                              Website 
                   FROM Account 
                   WHERE Id = :con.AccountId 
                   LIMIT 1];
    
        return new AccountInfoWrapper(acc.Name, acc.Type, acc.Phone, acc.Website);
    }

    private static AccountInfoWrapper getAccountInfo(String accountId) {
        Account acc = [SELECT Id, 
                              Name, 
                              Type, 
                              Phone, 
                              Website 
                       FROM Account 
                       WHERE Id = :accountId 
                       LIMIT 1];

        return new AccountInfoWrapper(acc.Name, acc.Type, acc.Phone, acc.Website);
    }

    private static ContactInfoWrapper getContactInfo(String contactId) {
        Contact con = [SELECT Id, 
                              Name, 
                              Phone, 
                              Email, 
                              AccountId 
                        FROM Contact 
                        WHERE Id = :contactId LIMIT 1];

        Account acc = [SELECT Id, 
                              Name, 
                              Type, 
                              Phone, 
                              Website 
                       FROM Account 
                       WHERE Id = :con.AccountId 
                       LIMIT 1];

        return new ContactInfoWrapper(con.Name, con.Phone, con.Email, acc.Name);
    }

    public class AccountInfoWrapper {
        @AuraEnabled
        public String accountName { get; set; }
        @AuraEnabled
        public String type { get; set; }
        @AuraEnabled
        public String phone { get; set; }
        @AuraEnabled
        public String website { get; set; }

        public AccountInfoWrapper(String accountName, String type, String phone, String website) {
            this.accountName = accountName;
            this.type = type;
            this.phone = phone;
            this.website = website;
        }
    }

    public class ContactInfoWrapper {
        @AuraEnabled
        public String contactName { get; set; }
        @AuraEnabled
        public String phone { get; set; }
        @AuraEnabled
        public String email { get; set; }

        public ContactInfoWrapper(String contactName, String phone, String email, String accountName) {
            this.contactName = contactName;
            this.phone = phone;
            this.email = email;
        }
    }
}

