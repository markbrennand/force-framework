/**
 * Created by Mark Brennand on 19/06/2025.
 */

import { LightningElement, api } from 'lwc';

export default class InlineCheckboxGroup extends LightningElement {
    _selectedValues = [];
    _options = [];
    @api name;
    @api label;
    @api set options(value) {
        this._options = [...value];
    }
    get options() {
        return [...this._options];
    }

    updateSelected() {
        this._selectedValues = [...this.template.querySelectorAll('input')]
            .filter(element => element.checked)
            .map(element => element.value);

        this.dispatchEvent(
            new CustomEvent('change', { detail: {selected: [...this._selectedValues]}})
        );
    }
}