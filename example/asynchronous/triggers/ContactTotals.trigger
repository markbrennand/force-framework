trigger ContactTotals on Contact (after insert, after update, after delete) {
    TriggersV1.route();
}