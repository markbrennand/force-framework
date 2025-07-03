trigger ContactTotals on Contact (before insert, after insert, before update, after update, before delete, after delete) {
    TriggerV1.publish();
}