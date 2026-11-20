import { LightningElement } from 'lwc';
import createApplication from '@salesforce/apex/TalentHubApplicationService.createApplication';

export default class TalentHubApplicationDemo extends LightningElement {

    candidateId = '';
    jobId = '';
    message = '';
    isError = false;
    isLoading = false;

    // Capture Candidate ID
    handleCandidateChange(event) {
        this.candidateId = event.target.value;
    }

    // Capture Job ID
    handleJobChange(event) {
        this.jobId = event.target.value;
    }

    // Submit Application
    handleSubmit() {
        this.message = '';
        this.isError = false;
        this.isLoading = true;

        createApplication({
            candidateId: this.candidateId || null,
            jobId: this.jobId || null
        })
            .then(result => {
                this.message =
                    'Application created successfully! Record ID: ' + result;
                this.isError = false;
            })
            .catch(error => {
                console.error('Apex Error:', error);

                this.message =
                    error?.body?.message ||
                    error?.message ||
                    'An unexpected error occurred.';

                this.isError = true;
            })
            .finally(() => {
                this.isLoading = false;
            });
    }

    // Display success or error message
    get messageClass() {
        return this.isError
            ? 'slds-text-color_error slds-text-heading_small'
            : 'slds-text-color_success slds-text-heading_small';
    }
}