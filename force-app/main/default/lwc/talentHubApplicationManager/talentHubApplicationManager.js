import { LightningElement, api, wire } from 'lwc';

import getApplications
    from '@salesforce/apex/talentHubApplicationManager.getApplications';

import updateApplication
    from '@salesforce/apex/talentHubApplicationManager.updateApplication';

import { ShowToastEvent } from 'lightning/platformShowToastEvent';

import { refreshApex } from '@salesforce/apex';


const COLUMNS = [
    { label: 'Candidate', fieldName: 'candidateName' },
    { label: 'Email', fieldName: 'candidateEmail', type: 'email' },
    { label: 'Job', fieldName: 'jobName' },
    { label: 'Application Date', fieldName: 'Application_Date__c', type: 'date' },
    { label: 'Status', fieldName: 'Status__c' },
    { label: 'Interview Date', fieldName: 'Interview_Date__c', type: 'date' },
    {
        type: 'button',
        typeAttributes: {
            label: 'Edit',
            name: 'edit',
            variant: 'brand'
        }
    }
];

export default class TalentHubApplicationManager extends LightningElement {

    // Temporary loading test
    testLoadingDelay = true;

    @api recordId;

    applications = [];
    columns = COLUMNS;

    isLoading = true;
    errorMessage;

    selectedApplication;
    status;
    interviewDate;

    wiredApplicationsResult;

    statusOptions = [
        { label: 'Submitted', value: 'Submitted' },
        { label: 'Under Review', value: 'Under Review' },
        { label: 'Interview', value: 'Interview' },
        { label: 'Selected', value: 'Selected' },
        { label: 'Rejected', value: 'Rejected' }
    ];



    @wire(getApplications, { recordId: '$recordId' })
    wiredApplications(result) {

        this.wiredApplicationsResult = result;

        const { data, error } = result;

        if (data) {

            this.applications = data.map(app => ({
                ...app,
                candidateName: app.Candidate__r
                    ? app.Candidate__r.First_Name__c + ' ' +
                    app.Candidate__r.Last_Name__c
                    : '',
                candidateEmail: app.Candidate__r
                    ? app.Candidate__r.Email__c
                    : '',
                jobName: app.Job__r
                    ? app.Job__r.Name
                    : ''
            }));

            this.errorMessage = undefined;
            this.isLoading = false;

        } else if (error) {

            this.applications = [];
            this.errorMessage =
                error.body?.message || 'Unable to load applications.';

            this.isLoading = false;
        }
    }

    get hasApplications() {
        return this.applications.length > 0;
    }

    get showEmpty() {
        return !this.isLoading &&
            !this.errorMessage &&
            this.applications.length === 0;
    }

    handleStatusChange(event) {
        this.status = event.detail.value;
    }

    handleDateChange(event) {
        this.interviewDate = event.detail.value;
    }

    handleSave() {

        if (!this.selectedApplication) {
            return;
        }

        this.isLoading = true;

        updateApplication({
            applicationId: this.selectedApplication,
            status: this.status,
            interviewDate: this.interviewDate || null
        })
            .then(() => {

                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Success',
                        message: 'Application updated successfully.',
                        variant: 'success'
                    })
                );

                this.selectedApplication = undefined;

                return refreshApex(this.wiredApplicationsResult);
            })
            .catch(error => {

                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Error',
                        message:
                            error.body?.message ||
                            'Unable to update application.',
                        variant: 'error'
                    })
                );

            })
            .finally(() => {
                this.isLoading = false;
            });
    }
}