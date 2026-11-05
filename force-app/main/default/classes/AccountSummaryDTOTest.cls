/**
 * Test class for AccountSummaryDTO
 */
@IsTest
private class AccountSummaryDTOTest {

    @IsTest
    static void testDTOConstruction() {
        // Test default constructor initializes all collections
        AccountSummaryDTO dto = new AccountSummaryDTO();

        System.assertNotEquals(null, dto.opportunities, 'Opportunities list should be initialized');
        System.assertNotEquals(null, dto.cases, 'Cases list should be initialized');
        System.assertNotEquals(null, dto.contacts, 'Contacts list should be initialized');
        System.assertNotEquals(null, dto.activities, 'Activities list should be initialized');
        System.assertEquals(false, dto.hasError, 'hasError should default to false');
        System.assertEquals(0, dto.totalOpportunities, 'totalOpportunities should default to 0');
        System.assertEquals(0, dto.totalOpportunityAmount, 'totalOpportunityAmount should default to 0');
        System.assertEquals(0, dto.openCases, 'openCases should default to 0');
        System.assertEquals(0, dto.contactCount, 'contactCount should default to 0');
    }

    @IsTest
    static void testDTOSetters() {
        // Test all setters work correctly
        AccountSummaryDTO dto = new AccountSummaryDTO();

        // Set account header fields
        dto.accountId = '001000000000001';
        dto.accountName = 'Test Account';
        dto.industry = 'Technology';
        dto.accountType = 'Customer';
        dto.ownerName = 'Test Owner';

        // Set metrics
        dto.totalOpportunities = 5;
        dto.totalOpportunityAmount = 1000000.00;
        dto.openCases = 3;
        dto.contactCount = 10;

        // Verify all fields are set
        System.assertEquals('001000000000001', dto.accountId);
        System.assertEquals('Test Account', dto.accountName);
        System.assertEquals('Technology', dto.industry);
        System.assertEquals('Customer', dto.accountType);
        System.assertEquals('Test Owner', dto.ownerName);
        System.assertEquals(5, dto.totalOpportunities);
        System.assertEquals(1000000.00, dto.totalOpportunityAmount);
        System.assertEquals(3, dto.openCases);
        System.assertEquals(10, dto.contactCount);
    }

    @IsTest
    static void testNestedOpportunityInfo() {
        // Test OpportunityInfo nested class
        AccountSummaryDTO.OpportunityInfo oppInfo = new AccountSummaryDTO.OpportunityInfo();
        oppInfo.opportunityId = '006000000000001';
        oppInfo.opportunityName = 'Test Opportunity';
        oppInfo.stageName = 'Prospecting';
        oppInfo.amount = 50000.00;
        oppInfo.closeDate = Date.today().addDays(30);

        System.assertEquals('006000000000001', oppInfo.opportunityId);
        System.assertEquals('Test Opportunity', oppInfo.opportunityName);
        System.assertEquals('Prospecting', oppInfo.stageName);
        System.assertEquals(50000.00, oppInfo.amount);
        System.assertNotEquals(null, oppInfo.closeDate);
    }

    @IsTest
    static void testNestedCaseInfo() {
        // Test CaseInfo nested class
        AccountSummaryDTO.CaseInfo caseInfo = new AccountSummaryDTO.CaseInfo();
        caseInfo.caseId = '500000000000001';
        caseInfo.caseNumber = '00001001';
        caseInfo.status = 'New';
        caseInfo.priority = 'High';
        caseInfo.subject = 'Test Case';

        System.assertEquals('500000000000001', caseInfo.caseId);
        System.assertEquals('00001001', caseInfo.caseNumber);
        System.assertEquals('New', caseInfo.status);
        System.assertEquals('High', caseInfo.priority);
        System.assertEquals('Test Case', caseInfo.subject);
    }

    @IsTest
    static void testNestedContactInfo() {
        // Test ContactInfo nested class
        AccountSummaryDTO.ContactInfo contactInfo = new AccountSummaryDTO.ContactInfo();
        contactInfo.contactId = '003000000000001';
        contactInfo.contactName = 'John Doe';
        contactInfo.title = 'VP Sales';
        contactInfo.email = 'john.doe@example.com';
        contactInfo.phone = '555-1234';

        System.assertEquals('003000000000001', contactInfo.contactId);
        System.assertEquals('John Doe', contactInfo.contactName);
        System.assertEquals('VP Sales', contactInfo.title);
        System.assertEquals('john.doe@example.com', contactInfo.email);
        System.assertEquals('555-1234', contactInfo.phone);
    }

    @IsTest
    static void testNestedActivityInfo() {
        // Test ActivityInfo nested class
        AccountSummaryDTO.ActivityInfo activityInfo = new AccountSummaryDTO.ActivityInfo();
        activityInfo.activityId = '00T000000000001';
        activityInfo.activityType = 'Task';
        activityInfo.subject = 'Follow up call';
        activityInfo.status = 'In Progress';
        activityInfo.activityDate = Date.today();

        System.assertEquals('00T000000000001', activityInfo.activityId);
        System.assertEquals('Task', activityInfo.activityType);
        System.assertEquals('Follow up call', activityInfo.subject);
        System.assertEquals('In Progress', activityInfo.status);
        System.assertNotEquals(null, activityInfo.activityDate);
    }

    @IsTest
    static void testErrorHandling() {
        // Test error state
        AccountSummaryDTO dto = new AccountSummaryDTO();
        dto.hasError = true;
        dto.errorMessage = 'Account not found';

        System.assertEquals(true, dto.hasError);
        System.assertEquals('Account not found', dto.errorMessage);
    }
}
