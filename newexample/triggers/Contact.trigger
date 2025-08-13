/**
 * Created by markbrennand on 15/07/2025.
 */

trigger Contact on Contact (before insert, before update, before delete, after insert, after update, after delete) {
    forcefw.TriggerV1.publish();
}