trigger ContactTotals on Contact (after insert, after update, after delete) {
    AccountContactTotals.startCalculationJob((List<Contact>) Trigger.new, (Map<Id, Contact>) Trigger.oldMap);
}