/**
 * Controller for retrieving Account Summary information
 */
public with sharing class AccountSummaryController {

    /**
     * Request wrapper for account summary queries
     */
    public class AccountSummaryRequest {
        @InvocableVariable(required=true)
        public String accountIdentifier;
    }

    /**
     * Response wrapper for invocable methods
     */
    public class AccountSummaryResponse {
        @InvocableVariable
        public AccountSummaryDTO summary;
    }

    /**
     * Retrieves account summary information for multiple accounts
     * @param requests List of AccountSummaryRequest containing account identifiers (ID or Name)
     * @return List of AccountSummaryResponse containing account data and related records
     */
    @InvocableMethod(label='Get Account Summary' description='Retrieves comprehensive account information including opportunities, cases, contacts, and activities')
    public static List<AccountSummaryResponse> getAccountSummary(List<AccountSummaryRequest> requests) {
        List<AccountSummaryResponse> results = new List<AccountSummaryResponse>();

        for (AccountSummaryRequest request : requests) {
            AccountSummaryResponse response = new AccountSummaryResponse();
            response.summary = getAccountSummaryForIdentifier(request.accountIdentifier);
            results.add(response);
        }

        return results;
    }

    /**
     * Retrieves account summary for a single account identifier
     */
    private static AccountSummaryDTO getAccountSummaryForIdentifier(String accountIdentifier) {
        AccountSummaryDTO dto = new AccountSummaryDTO();

        try {
            // Determine if identifier is an ID or Name
            Boolean isId = accountIdentifier instanceof Id ||
                          (accountIdentifier.length() == 18 && accountIdentifier.startsWith('001'));

            // Query account
            String query = 'SELECT Id, Name, Industry, Type, Owner.Name FROM Account WHERE ';
            query += isId ? 'Id = :accountIdentifier' : 'Name = :accountIdentifier';
            query += ' LIMIT 1';

            List<Account> accounts = Database.query(query);

            if (accounts.isEmpty()) {
                dto.hasError = true;
                dto.errorMessage = 'Account not found for identifier: ' + accountIdentifier;
                return dto;
            }

            Account acc = accounts[0];

            // Populate account header fields
            dto.accountId = acc.Id;
            dto.accountName = acc.Name;
            dto.industry = acc.Industry;
            dto.accountType = acc.Type;
            dto.ownerName = acc.Owner.Name;

            // Query and populate opportunities
            List<Opportunity> opps = [
                SELECT Id, Name, StageName, Amount, CloseDate
                FROM Opportunity
                WHERE AccountId = :acc.Id
                ORDER BY CloseDate DESC
            ];

            dto.totalOpportunities = opps.size();
            dto.totalOpportunityAmount = 0;

            for (Opportunity opp : opps) {
                AccountSummaryDTO.OpportunityInfo oppInfo = new AccountSummaryDTO.OpportunityInfo();
                oppInfo.opportunityId = opp.Id;
                oppInfo.opportunityName = opp.Name;
                oppInfo.stageName = opp.StageName;
                oppInfo.amount = opp.Amount;
                oppInfo.closeDate = opp.CloseDate;
                dto.opportunities.add(oppInfo);

                if (opp.Amount != null) {
                    dto.totalOpportunityAmount += opp.Amount;
                }
            }

            // Query and populate cases
            List<Case> cases = [
                SELECT Id, CaseNumber, Status, Priority, Subject
                FROM Case
                WHERE AccountId = :acc.Id
                ORDER BY CreatedDate DESC
            ];

            dto.openCases = 0;
            for (Case c : cases) {
                AccountSummaryDTO.CaseInfo caseInfo = new AccountSummaryDTO.CaseInfo();
                caseInfo.caseId = c.Id;
                caseInfo.caseNumber = c.CaseNumber;
                caseInfo.status = c.Status;
                caseInfo.priority = c.Priority;
                caseInfo.subject = c.Subject;
                dto.cases.add(caseInfo);

                if (c.Status != 'Closed') {
                    dto.openCases++;
                }
            }

            // Query and populate contacts
            List<Contact> contacts = [
                SELECT Id, Name, Title, Email, Phone
                FROM Contact
                WHERE AccountId = :acc.Id
                ORDER BY Name
            ];

            dto.contactCount = contacts.size();
            for (Contact con : contacts) {
                AccountSummaryDTO.ContactInfo contactInfo = new AccountSummaryDTO.ContactInfo();
                contactInfo.contactId = con.Id;
                contactInfo.contactName = con.Name;
                contactInfo.title = con.Title;
                contactInfo.email = con.Email;
                contactInfo.phone = con.Phone;
                dto.contacts.add(contactInfo);
            }

            // Query and populate activities (Tasks and Events)
            List<Task> tasks = [
                SELECT Id, Subject, Status, ActivityDate
                FROM Task
                WHERE WhatId = :acc.Id
                ORDER BY ActivityDate DESC
            ];

            for (Task t : tasks) {
                AccountSummaryDTO.ActivityInfo activityInfo = new AccountSummaryDTO.ActivityInfo();
                activityInfo.activityId = t.Id;
                activityInfo.activityType = 'Task';
                activityInfo.subject = t.Subject;
                activityInfo.status = t.Status;
                activityInfo.activityDate = t.ActivityDate;
                dto.activities.add(activityInfo);
            }

            List<Event> events = [
                SELECT Id, Subject, StartDateTime, ActivityDate
                FROM Event
                WHERE WhatId = :acc.Id
                ORDER BY ActivityDate DESC
            ];

            for (Event e : events) {
                AccountSummaryDTO.ActivityInfo activityInfo = new AccountSummaryDTO.ActivityInfo();
                activityInfo.activityId = e.Id;
                activityInfo.activityType = 'Event';
                activityInfo.subject = e.Subject;
                activityInfo.status = 'Scheduled';
                activityInfo.activityDate = e.ActivityDate;
                dto.activities.add(activityInfo);
            }

        } catch (Exception e) {
            dto.hasError = true;
            dto.errorMessage = 'Error retrieving account summary: ' + e.getMessage();
        }

        return dto;
    }
}
