trigger ContactTotals on Contact (before insert, after insert, before update, after update, before delete, after delete) {
    forcefw.TriggerV1.publish();
}
