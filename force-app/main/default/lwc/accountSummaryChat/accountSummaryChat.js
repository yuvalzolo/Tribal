import { LightningElement, api } from 'lwc';

/**
 * Agentforce output renderer for Account Summary data.
 * Displays comprehensive account information with related opportunities, cases, contacts, and activities.
 */
export default class AccountSummaryChat extends LightningElement {
    @api value;

    get summary() {
        return this.value || {};
    }

    get hasSummary() {
        return this.value != null && !this.summary.hasError;
    }

    get hasError() {
        return this.summary.hasError === true;
    }

    get errorMessage() {
        return this.summary.errorMessage || 'An error occurred while retrieving the account summary.';
    }

    // Account header information
    get accountName() {
        return this.summary.accountName || 'Unknown Account';
    }

    get industry() {
        return this.summary.industry || 'Not specified';
    }

    get accountType() {
        return this.summary.accountType || 'Not specified';
    }

    get ownerName() {
        return this.summary.ownerName || 'Not assigned';
    }

    // Key metrics
    get totalOpportunities() {
        return this.summary.totalOpportunities || 0;
    }

    get totalOpportunityAmount() {
        const amount = this.summary.totalOpportunityAmount;
        if (amount == null || amount === 0) return '$0';
        return new Intl.NumberFormat('en-US', {
            style: 'currency',
            currency: 'USD'
        }).format(amount);
    }

    get openCases() {
        return this.summary.openCases || 0;
    }

    get contactCount() {
        return this.summary.contactCount || 0;
    }

    // Related records
    get opportunities() {
        return this.summary.opportunities || [];
    }

    get hasOpportunities() {
        return this.opportunities.length > 0;
    }

    get cases() {
        return this.summary.cases || [];
    }

    get hasCases() {
        return this.cases.length > 0;
    }

    get contacts() {
        return this.summary.contacts || [];
    }

    get hasContacts() {
        return this.contacts.length > 0;
    }

    get activities() {
        return this.summary.activities || [];
    }

    get hasActivities() {
        return this.activities.length > 0;
    }

    // Format helpers
    formatCurrency(amount) {
        if (amount == null) return 'N/A';
        return new Intl.NumberFormat('en-US', {
            style: 'currency',
            currency: 'USD'
        }).format(amount);
    }

    formatDate(dateString) {
        if (!dateString) return 'N/A';
        try {
            const date = new Date(dateString);
            return new Intl.DateTimeFormat('en-US', {
                year: 'numeric',
                month: 'short',
                day: 'numeric'
            }).format(date);
        } catch (e) {
            return dateString;
        }
    }
}
