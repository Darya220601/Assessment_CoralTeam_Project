public with sharing class AccountController {
     
    private static final String ADMIN_PERMISSION_SET_NAME = 'Admin';
    private static final String BUSINESS_PERMISSION_SET_NAME = 'Business';

    public static User_Permission_Set__mdt adminPermissionSet { get; private set; }
    public static User_Permission_Set__mdt businessPermissionSet { get; private set; }

    @AuraEnabled(cacheable=true)
    public static List<AccountWrapper> getAccountContactTree() {
        List<AccountWrapper> accWrapper = new List<AccountWrapper>();

        Set<String> userPermissionSetNames = getUserPermissionSetNames(UserInfo.getUserId());
        assignPermissionSets();
        Boolean isAdminUser = adminPermissionSet != null && userPermissionSetNames.contains(adminPermissionSet.QualifiedApiName);
        Boolean isBusinessUser = businessPermissionSet != null && userPermissionSetNames.contains(businessPermissionSet.QualifiedApiName);

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

    private static Set<String> getUserPermissionSetNames(Id userId) {
        Set<String> permissionSetNames = new Set<String>();

        List<PermissionSetAssignment> assignments = [
            SELECT PermissionSet.Name
            FROM PermissionSetAssignment
            WHERE AssigneeId = :userId
        ];

        for (PermissionSetAssignment assignment : assignments) {
            permissionSetNames.add(assignment.PermissionSet.Name);
        }

        return permissionSetNames;
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

    public static void assignPermissionSets() {
        adminPermissionSet = getPermissionSetByName(ADMIN_PERMISSION_SET_NAME);
        businessPermissionSet = getPermissionSetByName(BUSINESS_PERMISSION_SET_NAME);
    }

    private static User_Permission_Set__mdt getPermissionSetByName(String name) {
        try {
            return [SELECT Id, 
                           QualifiedApiName
                    FROM User_Permission_Set__mdt
                    WHERE MasterLabel = :name
                    LIMIT 1];
        } catch (QueryException e) {
            return null;
        }
    }
}
