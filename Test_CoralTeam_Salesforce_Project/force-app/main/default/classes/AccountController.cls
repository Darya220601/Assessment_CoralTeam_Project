public with sharing class AccountController {
     
    private static final String ADMIN_PERMISSION_SET_NAME = 'Admin_Contacts_Accounts';
    private static final String BUSINESS_PERMISSION_SET_NAME = 'Business_Contacts_Accounts';
    public static Boolean isAdminUser { get; private set; }
    public static Boolean isBusinessUser { get; private set; }


    @AuraEnabled(cacheable=true)
    public static List<AccountWrapper> getAccountContactTree() {
        List<AccountWrapper> accWrapper = new List<AccountWrapper>();

        getUserPermissionSetNames();

        String UserId = UserInfo.getUserId();
        List<Account> accounts = new List<Account>();
        String baseQuery = 'SELECT Id, Name, (SELECT Id, FirstName, LastName FROM Contacts) FROM Account';

        if (isBusinessUser) {
            baseQuery += ' WHERE OwnerId = :UserId';
        }
        accounts = Database.query(baseQuery);
            
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
}