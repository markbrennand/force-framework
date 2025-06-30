trigger AccountTotals on Account (after insert, after update) {
    TriggersV1.route();
    // AccountContactTotals.startCalculationJob((List<Account>) Trigger.new, new Set<Id>());
}