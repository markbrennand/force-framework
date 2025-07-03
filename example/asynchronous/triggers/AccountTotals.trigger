trigger AccountTotals on Account (before insert, after insert, before update, after update, before delete, after delete) {
    TriggerV1.publish();
}