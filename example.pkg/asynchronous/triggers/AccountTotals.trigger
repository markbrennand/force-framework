trigger AccountTotals on Account (after insert, after update) {
    forcefw.TriggersV1.route();
}
