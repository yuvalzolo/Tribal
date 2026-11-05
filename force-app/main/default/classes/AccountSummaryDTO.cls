/**
 * Data Transfer Object for Account Summary information
 */
@JsonAccess(serializable='always' deserializable='always')
global class AccountSummaryDTO {

    // Account header fields
    @AuraEnabled public String accountId { get; set; }
    @AuraEnabled public String accountName { get; set; }
    @AuraEnabled public String industry { get; set; }
    @AuraEnabled public String accountType { get; set; }
    @AuraEnabled public String ownerName { get; set; }

    // Metrics
    @AuraEnabled public Integer totalOpportunities { get; set; }
    @AuraEnabled public Decimal totalOpportunityAmount { get; set; }
    @AuraEnabled public Integer openCases { get; set; }
    @AuraEnabled public Integer contactCount { get; set; }

    // Related records
    @AuraEnabled public List<OpportunityInfo> opportunities { get; set; }
    @AuraEnabled public List<CaseInfo> cases { get; set; }
    @AuraEnabled public List<ContactInfo> contacts { get; set; }
    @AuraEnabled public List<ActivityInfo> activities { get; set; }

    // Error handling
    @AuraEnabled public Boolean hasError { get; set; }
    @AuraEnabled public String errorMessage { get; set; }

    // Constructor
    public AccountSummaryDTO() {
        this.opportunities = new List<OpportunityInfo>();
        this.cases = new List<CaseInfo>();
        this.contacts = new List<ContactInfo>();
        this.activities = new List<ActivityInfo>();
        this.hasError = false;
        this.totalOpportunities = 0;
        this.totalOpportunityAmount = 0;
        this.openCases = 0;
        this.contactCount = 0;
    }

    // Nested class for Opportunity information
    public class OpportunityInfo {
        @AuraEnabled public String opportunityId { get; set; }
        @AuraEnabled public String opportunityName { get; set; }
        @AuraEnabled public String stageName { get; set; }
        @AuraEnabled public Decimal amount { get; set; }
        @AuraEnabled public Date closeDate { get; set; }
    }

    // Nested class for Case information
    public class CaseInfo {
        @AuraEnabled public String caseId { get; set; }
        @AuraEnabled public String caseNumber { get; set; }
        @AuraEnabled public String status { get; set; }
        @AuraEnabled public String priority { get; set; }
        @AuraEnabled public String subject { get; set; }
    }

    // Nested class for Contact information
    public class ContactInfo {
        @AuraEnabled public String contactId { get; set; }
        @AuraEnabled public String contactName { get; set; }
        @AuraEnabled public String title { get; set; }
        @AuraEnabled public String email { get; set; }
        @AuraEnabled public String phone { get; set; }
    }

    // Nested class for Activity information
    public class ActivityInfo {
        @AuraEnabled public String activityId { get; set; }
        @AuraEnabled public String activityType { get; set; }
        @AuraEnabled public String subject { get; set; }
        @AuraEnabled public String status { get; set; }
        @AuraEnabled public Date activityDate { get; set; }
    }
}
