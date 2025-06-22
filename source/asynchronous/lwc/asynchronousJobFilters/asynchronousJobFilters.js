/**
 * Created by Mark Brennand on 20/06/2025.
 */

import {LightningElement, api} from 'lwc';

export default class AsynchronousJobFilters extends LightningElement {

    statusOptions = [
        { value: 'RUNNING', label: 'RUNNING', checked: true },
        { value: 'QUEUED', label: 'QUEUED', checked: true },
        { value: 'SUCCEEDED', label: 'SUCCEEDED' },
        { value: 'FAILED', label: 'FAILED' },
        { value: 'CANCELLED', label: 'CANCELLED' }
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