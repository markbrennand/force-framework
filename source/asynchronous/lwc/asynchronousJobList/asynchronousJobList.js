/**
 * Created by Mark Brennand on 18/06/2025.
 */

import { LightningElement } from 'lwc';
import getJobs from '@salesforce/apex/AsynchronousImpl.getJobs';

const MAX_TO_FETCH = 200;
const REFRESH_RATE = 2500;

export default class AsynchronousJobList extends LightningElement {
    data = [];
    sortedBy = 'ScheduledRunTime__c';
    sortedDirection = 'asc';
    minColumnWidth = 120;
    maxColumnWidth = 275;
    showSpinner = false;

    _selectedRows= [];
    _statusFilter = [ 'RUNNING', 'QUEUED' ];
    _runnableSearchTerm = '';
    _referenceSearchTerm = '';
    _timerId;

    columns = [
        { label: 'Apex Job', fieldName: 'ApexJobId__c' },
        { label: 'Reference', fieldName: 'Reference__c' },
        { label: 'Status', fieldName: 'Status__c', sortable: true },
        { label: 'Active (ms)', fieldName: 'RunTime__c' },
        { label: 'Retry', fieldName: 'Retry__c' },
        { label: 'Runnable', fieldName: 'Runnable__c' },
        { label: 'Scheduled Run Time', fieldName: 'ScheduledRunTime__c', type: 'datetime', sortable: true }
    ];

    async connectedCallback() {
        this.data = await this.getData(true);
        this.sort();
        this._timerId = window.setTimeout(() => {  this.refresh() }, REFRESH_RATE);
    }

    disconnectedCallback() {
        if (this._timerId) {
            window.clearTimeout(this._timerId);
        }
    }

    sortData(event){
        this.sortedBy = event.detail.fieldName;
        this.sortedDirection = event.detail.sortDirection;
        this.sort();
    }

    sort() {
        let sortedData = [...this.data];
        sortedData.sort((a,b)=>{
            let valueA = a[this.sortedBy];
            let valueB = b[this.sortedBy];

            if(typeof valueA === 'string' && typeof valueB === 'string'){
                valueA = valueA.toLowerCase();
                valueB = valueB.toLowerCase();
            }
            if(valueA > valueB){
                return this.sortedDirection === 'asc' ? 1 : -1;
            } else if(valueA < valueB){
                return this.sortedDirection === 'asc' ? -1 : 1;
            } else{
                return 0;
            }
        });

        this.data = sortedData;
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

    async refresh() {
        if (this._selectedRows.length === 0) {
            this.data = await this.getData(false);
            this.sort();
        }

        this._timerId = window.setTimeout(() => {  this.refresh() }, REFRESH_RATE);
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

            return await getJobs({ filters: filters , offset: 0, max: MAX_TO_FETCH });
        } finally {
            this.showSpinner = false;
        }
    }

    clearSelectedRows() {
        this._selectedRows = [];
        this.template.querySelector('lightning-datatable').selectedRows = [];
    }

    startSpinner(event) {
        this.showSpinner = true;
    }

    stopSpinner(event) {
        this.showSpinner = false;
    }
}