trigger ContactTotals on Contact (after insert, after update, after delete) {
    forcefw.TriggersV1.route();
}
