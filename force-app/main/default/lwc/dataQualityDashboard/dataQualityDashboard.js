import { LightningElement, track } from 'lwc';
import getIssues from '@salesforce/apex/DQIssueController.getIssues';
import getIssueStatistics from '@salesforce/apex/DQIssueController.getIssueStatistics';
import getPriorityPicklistValues from '@salesforce/apex/DQIssueController.getPriorityPicklistValues';
import getStatusPicklistValues from '@salesforce/apex/DQIssueController.getStatusPicklistValues';

export default class DataQualityDashboard extends LightningElement {
    @track issues = [];
    @track statistics = {};
    @track loading = false;
    @track showToast = false;
    @track toastMessage = '';
    @track toastVariant = 'success';

    @track selectedObjectType = '';
    @track selectedPriority = '';
    @track selectedStatus = '';

    @track priorityOptions = [];
    @track statusOptions = [];

    objectTypeOptions = [
        { label: 'All Objects', value: '' },
        { label: 'Lead', value: 'Lead' },
        { label: 'Account', value: 'Account' },
        { label: 'Opportunity', value: 'Opportunity' }
    ];

    connectedCallback() {
        this.loadData();
        this.loadPicklistValues();
    }

    loadPicklistValues() {
        getPriorityPicklistValues()
            .then(result => {
                this.priorityOptions = [
                    { label: 'All Priorities', value: '' },
                    ...result.map(item => ({ label: item.label, value: item.value }))
                ];
            })
            .catch(error => {
                this.showToastMessage('Error loading priority values: ' + error.body.message, 'error');
            });

        getStatusPicklistValues()
            .then(result => {
                this.statusOptions = [
                    { label: 'All Statuses', value: '' },
                    ...result.map(item => ({ label: item.label, value: item.value }))
                ];
            })
            .catch(error => {
                this.showToastMessage('Error loading status values: ' + error.body.message, 'error');
            });
    }

    loadData() {
        this.loading = true;

        Promise.all([
            getIssues({
                objectType: this.selectedObjectType || null,
                priority: this.selectedPriority || null,
                status: this.selectedStatus || null
            }),
            getIssueStatistics()
        ])
        .then(([issuesResult, statsResult]) => {
            this.issues = issuesResult;
            this.statistics = statsResult;
            this.loading = false;
        })
        .catch(error => {
            this.loading = false;
            this.showToastMessage('Error loading data: ' + error.body.message, 'error');
        });
    }

    handleObjectTypeChange(event) {
        this.selectedObjectType = event.detail.value;
    }

    handlePriorityChange(event) {
        this.selectedPriority = event.detail.value;
    }

    handleStatusChange(event) {
        this.selectedStatus = event.detail.value;
    }

    handleApplyFilters() {
        this.loadData();
    }

    handleClearFilters() {
        this.selectedObjectType = '';
        this.selectedPriority = '';
        this.selectedStatus = '';
        this.loadData();
    }

    showToastMessage(message, variant) {
        this.toastMessage = message;
        this.toastVariant = variant;
        this.showToast = true;

        setTimeout(() => {
            this.showToast = false;
        }, 3000);
    }

    get hasIssues() {
        return this.issues && this.issues.length > 0;
    }

    get totalIssuesCount() {
        return this.issues ? this.issues.length : 0;
    }

    get criticalCount() {
        return this.statistics['Priority_Critical'] || 0;
    }

    get fixedCount() {
        return this.statistics['Status_Fixed'] || 0;
    }

    get toastClass() {
        const baseClass = 'slds-notify slds-notify_toast';
        if (this.toastVariant === 'success') {
            return baseClass + ' slds-theme_success';
        } else if (this.toastVariant === 'error') {
            return baseClass + ' slds-theme_error';
        }
        return baseClass;
    }
}
