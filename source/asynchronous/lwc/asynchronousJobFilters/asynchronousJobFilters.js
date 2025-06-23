/**
 * Created by Mark Brennand on 20/06/2025.
 */

import {LightningElement, api} from 'lwc';

export default class AsynchronousJobFilters extends LightningElement {
    @api refreshRate;

    statusOptions = [
        { value: 'RUNNING', label: 'Running', checked: true },
        { value: 'QUEUED', label: 'Queued', checked: true },
        { value: 'SUCCEEDED', label: 'Succeeded' },
        { value: 'FAILED', label: 'Failed' },
        { value: 'CANCELLED', label: 'Cancelled' }
    ];

    setRunnableSearchTerm(event) {
        this.dispatchEvent(new CustomEvent('change', { detail: { type: 'runnable', value: event.detail.value } }));
    }

    setReferenceSearchTerm(event) {
        this.dispatchEvent(new CustomEvent('change', { detail: { type: 'reference', value: event.detail.value } }));
    }

    filterStatusChange(event) {
        this.dispatchEvent(new CustomEvent('change', { detail: { type: 'status', value: event.detail.selected } }));
    }

    clearSelected(event) {
        this.dispatchEvent(new CustomEvent('clearselected'));
    }

    startSpinner(event) {
        this.dispatchEvent(new CustomEvent('startspinner'));
    }

    stopSpinner(event) {
        this.dispatchEvent(new CustomEvent('stopspinner'));
    }

    @api
    rowsSelected(selected) {
        this.template
            .querySelector('c-asynchronous-job-actions')
            .rowsSelected(selected);
    }
}