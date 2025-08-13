/**
 * Created by markbrennand on 15/07/2025.
 */

trigger Account on Account (before insert, before update, before delete, after insert, after update, after delete) {
    forcefw.TriggerV1.publish();
}