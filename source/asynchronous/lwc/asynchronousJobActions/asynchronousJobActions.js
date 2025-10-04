/**
 * Created by Mark Brennand on 21/06/2025.
 */

import { LightningElement, api } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import deleteJobs from '@salesforce/apex/AsynchronousV1.deleteJobs';
import runJobs from '@salesforce/apex/AsynchronousV1.runJobs';

export default class AsynchronousJobActions extends LightningElement {
    viewNotAllowed = true;
    deleteNotAllowed = true;
    runNotAllowed = true;
    _selectedRows = [];

    @api
    rowsSelected(selected) {
        this._selectedRows = selected;

        if (selected.length === 0) {
            this.viewNotAllowed = true;
            this.deleteNotAllowed = true;
            this.runNotAllowed = true;
        } else if (selected.length === 1) {
            this.viewNotAllowed = false;
            this.deleteNotAllowed = false;
            this.runNotAllowed = !this._canRowBeRun(selected[0]);
        } else {
            this.viewNotAllowed = true;
            this.deleteNotAllowed = false;
            this.runNotAllowed = false;
            selected.forEach(row => {
                if (!this._canRowBeRun(row)) {
                    this.runNotAllowed = true;
                }
            });
        }
    }

    async deleteSelected() {
        this.dispatchEvent(new CustomEvent('startspinner'));
        const idsToDelete = this._selectedRows.map(row => row.Id);
        deleteJobs({ jobIds: idsToDelete }).then(
            () => {
                this._reset();
            },
            (error) => {
                this._reset();
                this.dispatchEvent(
                    new ShowToastEvent(
                        {
                            title: 'Error',
                            message: 'Deletion failed, Status: {0}, Exception: {1}',
                            messageData: [ '' + error.status, error.body.message || error.body.pageErrors[0]?.message ]
                        }
                    )
                );
            }
        );
    }

    async runSelected() {
        this.dispatchEvent(new CustomEvent('startspinner'));
        const idsToRun = this._selectedRows.map(row => row.Id);
        runJobs({ jobIds: idsToRun }).then(
            () => {
                this._reset();
            },
            (error) => {
                this._reset();

                this.dispatchEvent(
                    new ShowToastEvent(
                        {
                            title: 'Error',
                            message: 'Run jobs failed, Status: {0}, Exception: {1}',
                            messageData: [ '' + error.status, error.body.message || error.body.pageErrors[0]?.message ]
                        }
                    )
                );
            }
        );
    }

    _canRowBeRun(row) {
        return row.Status__c === 'SUCCEEDED'
            || row.Status__c === 'FAILED'
            || row.Status__c === 'CANCELLED'
            || row.Status__c === 'QUEUED';
    }

    _reset() {
        this._selectedRows = [];
        this.viewNotAllowed = true;
        this.deleteNotAllowed = true;
        this.runNotAllowed = true;
        this.dispatchEvent(new CustomEvent('action'));
        this.dispatchEvent(new CustomEvent('stopspinner'));
    }
}