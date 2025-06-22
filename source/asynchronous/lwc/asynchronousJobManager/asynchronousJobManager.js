/**
 * Created by Mark Brennand on 18/06/2025.
 */

import {LightningElement} from 'lwc';

export default class AsynchronousJobManager extends LightningElement {

    refresh() {
        this.dispatchEvent(new CustomEvent('refreshlist'));
    }
}