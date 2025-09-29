/**
 * @description
 * <p>
 * Base exception for all Exceptions thrown by Force Framework APIs.
 * <p>
 * Any catchable exception thrown by the package can be caught with this exception.
 */
@SuppressWarnings('PMD.AvoidGlobalModifier')
global with sharing virtual class ForceFwException extends Exception {}