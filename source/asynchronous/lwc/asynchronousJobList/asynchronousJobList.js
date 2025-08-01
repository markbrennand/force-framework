/**
 * Created by Mark Brennand on 18/06/2025.
 */

import { LightningElement } from 'lwc';
import getJobs from '@salesforce/apex/AsynchronousV1.getJobs';
import {ShowToastEvent} from "lightning/platformShowToastEvent";

const MAX_TO_FETCH = 200;
const REFRESH_RATE = 2500;

export default class AsynchronousJobList extends LightningElement {
    data = [];
    sortedBy = 'ScheduledRunTime__c';
    sortedDirection = 'asc';
    minColumnWidth = 120;
    maxColumnWidth = 275;
    showSpinner = false;
    refreshRate = REFRESH_RATE;

    _selectedRows= [];
    _statusFilter = [ 'RUNNING', 'QUEUED' ];
    _runnableSearchTerm = '';
    _referenceSearchTerm = '';
    _timerId;

    columns = [
        { label: 'Name', fieldName: 'Name' },
        { label: 'Apex Job', fieldName: 'ApexJobId__c' },
        { label: 'Owner', fieldName: 'Owner' },
        { label: 'Reference', fieldName: 'Reference__c' },
        { label: 'Status', fieldName: 'Status__c', sortable: true },
        { label: 'Active (ms)', fieldName: 'RunTime__c' },
        { label: 'Retries Remaining', fieldName: 'RetriesRemaining__c' },
        { label: 'Runnable', fieldName: 'Runnable__c' },
        { label: 'Scheduled Run Time', fieldName: 'ScheduledRunTime__c', type: 'datetime', sortable: true }
    ];

    async connectedCallback() {
        this.data = await this.getData(true);
        this._timerId = window.setTimeout(() => {  this.refresh() }, this.refreshRate);
    }

    disconnectedCallback() {
        if (this._timerId) {
            window.clearTimeout(this._timerId);
        }
    }

    sortData(event){
        this.sortedBy = event.detail.fieldName;
        this.sortedDirection = event.detail.sortDirection;
    }

    rowsSelected(event) {
        const selected = event.detail.selectedRows;
        this.template
            .querySelector('c-asynchronous-job-filters')
            .rowsSelected(selected);
        this._selectedRows = selected;
    }

    filterChanged(event) {
        if (event.detail.type === 'status') {
            this._statusFilter = event.detail.value;
        } else if (event.detail.type === 'reference') {
            this._referenceSearchTerm = event.detail.value;
        } else if (event.detail.type === 'runnable') {
            this._runnableSearchTerm = event.detail.value;
        }
    }

    async refresh(withSpinner) {
        if (this._selectedRows.length === 0) {
            this.data = await this.getData(withSpinner);
        }

        this._timerId = window.setTimeout(() => {  this.refresh(false) }, this.refreshRate);
    }

    async getData(withSpinner) {
        this.showSpinner = true & withSpinner;

        try {
            const filters = this._referenceSearchTerm ? {
                Status__c: this._statusFilter,
                Runnable__c: '%' + this._runnableSearchTerm + '%',
                Reference__c: '%' + this._referenceSearchTerm + '%'
            } : {
                Status__c: this._statusFilter,
                Runnable__c: '%' + this._runnableSearchTerm + '%'
            };

            try {
                return await getJobs({
                    filters: filters,
                    ordering: this.sortedBy + ' ' + this.sortedDirection,
                    offset: 0,
                    max: MAX_TO_FETCH
                });
            } catch(error) {
                this.dispatchEvent(
                    new ShowToastEvent(
                        {
                            title: 'Error',
                            message: 'Get jobs failed, Status: {0}, Exception: {1}',
                            messageData: [ '' + error.status, error.body.message || error.body.pageErrors[0]?.message ]
                        }
                    )
                );
            }

        } finally {
            this.showSpinner = false;
        }
    }

    clearSelectedRows() {
        this._selectedRows = [];
        this.template.querySelector('lightning-datatable').selectedRows = [];

        if (this._timerId) {
            window.clearTimeout(this._timerId);
        }

        this.refresh(true);
    }

    startSpinner() {
        this.showSpinner = true;
    }

    stopSpinner() {
        this.showSpinner = false;
    }
}