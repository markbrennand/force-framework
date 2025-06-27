/**
 * @description
 * Trigger to validate bindings on insert/update.
 *
 * @author Mark Brennand
 */
trigger Binding on Binding__c (after insert, after update) {
    DependencyAPI.checkForDuplicates();
    DependencyAPI.validate((List<Binding__c>) Trigger.new);
}