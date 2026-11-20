import { LightningElement } from 'lwc';

import checkEligibility from '@salesforce/apex/TalentHubEligibilityService.checkEligibility';

export default class TalentHubEligibilityChecker extends LightningElement {

    candidateId = null;
    jobId = null;

    // Candidate search configuration
    candidateDisplayInfo = {
        primaryField: 'Candidate_Display_Name__c'
    };

    candidateMatchingInfo = {
        primaryField: {
            fieldPath: 'Candidate_Display_Name__c'
        }
    };

    // Job search configuration
    jobDisplayInfo = {
        primaryField: 'Name'
    };

    jobMatchingInfo = {
        primaryField: {
            fieldPath: 'Name'
        }
    };

    isEligible = false;
    isNotEligible = false;
    isLoading = false;
    errorMessage = '';

    handleCandidateChange(event) {
        this.candidateId = event.detail.recordId;
        this.clearResult();
    }

    handleJobChange(event) {
        this.jobId = event.detail.recordId;
        this.clearResult();
    }

    clearResult() {
        this.isEligible = false;
        this.isNotEligible = false;
        this.errorMessage = '';
    }

    get isCheckDisabled() {
        return !this.candidateId || !this.jobId || this.isLoading;
    }

    async checkEligibility() {
        this.clearResult();

        if (!this.candidateId || !this.jobId) {
            this.errorMessage = 'Please select both Candidate and Job.';
            return;
        }

        this.isLoading = true;

        try {
            const result = await checkEligibility({
                candidateId: this.candidateId,
                jobId: this.jobId
            });

            this.isEligible = result === true;
            this.isNotEligible = result === false;

        } catch (error) {
            this.errorMessage =
                error?.body?.message ||
                'Something went wrong while checking eligibility.';
        } finally {
            this.isLoading = false;
        }
    }
}