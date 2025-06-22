/**
 * Created by Mark Brennand on 18/06/2025.
 */

import {LightningElement} from 'lwc';

export default class AsynchronousJob extends LightningElement {

    refreshList(event) {
        this.dispatchEvent(new CustomEvent('refreshlist'));
    }
}