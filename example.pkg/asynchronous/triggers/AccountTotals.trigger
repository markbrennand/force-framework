trigger AccountTotals on Account (after insert, after update) {
    AccountContactTotals.startCalculationJob((List<Account>) Trigger.new, new Set<Id>());
}