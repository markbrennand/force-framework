/**
 * Created by Mark Brennand on 23/06/2025.
 */

import { LightningElement, api } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getTotals from '@salesforce/apex/AsynchronousV1.getTotals';

export default class AsynchronousJobTotals extends LightningElement {
    @api refreshRate = 10000;
    queued = 0;
    running = 0;
    succeeded = 0;
    failed = 0;
    cancelled = 0;
    _timerId;

    async connectedCallback() {
        this.totals = await this.getTotals();
        this._timerId = window.setTimeout(() => {  this.refresh() }, this.refreshRate);
    }

    disconnectedCallback() {
        if (this._timerId) {
            window.clearTimeout(this._timerId);
        }
    }

    async refresh() {
        await this.getTotals();

        this._timerId = window.setTimeout(() => {  this.refresh() }, this.refreshRate);
    }

    async getTotals() {
        try {
            const totals = await getTotals();
            this.queued = totals.QUEUED;
            this.running = totals.RUNNING;
            this.succeeded = totals.SUCCEEDED;
            this.failed = totals.FAILED;
            this.cancelled = totals.CANCELLED;
        } catch (error) {
            this.dispatchEvent(
                new ShowToastEvent(
                    {
                        title: 'Error',
                        message: 'Get totals call failed, Status: {0}, Exception: {1}',
                        messageData: [ '' + error.status, error.body.message || error.body.pageErrors[0]?.message ]
                    }
                )
            );
        }
    }
}