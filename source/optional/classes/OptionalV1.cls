/**
 * @description
 * Copyright (c) 2025 Mark Brennand, released under <a href=../../LICENSE target="_blank">MIT License</a>.
 * <br><br>
 * Class providing an implementation of Optional which should be used in preference to using null to indicate a
 * value is un-assigned.
 * <br><br>
 * See <a href=../../source/optional/README.md target="_blank">README</a> for full details of Optional.
 *
 * @author Mark Brennand
 */
@SuppressWarnings('PMD.AvoidGlobalModifier')
global with sharing class OptionalV1 {

    /**
     * @description
     * Interface to allow Optional value to be processed.
     */
    global interface Function {

        /**
         * @description
         * Method called to process the value of an Optional.
         * <br><br>
         * The implementor must return an Optional representing the result of the processing.
         *
         * @param value The Optional to be processed.
         *
         * @return The result of the processing.
         */
        OptionalV1 apply(final OptionalV1 value);
    }

    /**
     * @description
     * Does the Optional have a value.
     */
    private final Boolean isPresent;

    /**
     * @description
     * The value of the Optional.
     */
    private final Object value;

    /**
     * @description
     * Exception thrown to indicate an attempt was made to use an un-assigned value.
     */
    global with sharing class NoSuchElementException extends Exception {}

    /**
     * @description
     * Constructs an Optional which has no value.
     */
    private OptionalV1() {
        this.isPresent = false;
    }

    /**
     * @description
     * Constructs an Optional with a value.
     *
     * @param value The value to assign to the Optional.
     */
    private OptionalV1(final Object value) {
        this.value = value;
        this.isPresent = true;
    }

    /**
     * @description
     * Returns an un-assigned Optional.
     *
     * @return An un-assigned Optional.
     */
    global static OptionalV1 empty() {
        return new OptionalV1();
    }

    /**
     * @description
     * Returns an Optional assigned to a value.
     *
     * @param value The value to assign the the Optional.
     *
     * @return The assigned Optional.
     */
    global static OptionalV1 of(final Object value) {
        return new OptionalV1(value);
    }

    /**
     * @description
     * Returns an Optional assigned to a value or an unassigned Optional if the argument is null.
     *
     * @param value The value to assign the the Optional.
     *
     * @return The assigned Optional.
     */
    global static OptionalV1 ofNullable(Object value) {
        return value == null ? empty() : of(value);
    }

    /**
     * @description
     * Returns true if the Optional has a value, false if not.
     *
     * @return True if the Optional has a value.
     */
    global Boolean isPresent() {
        return isPresent == true;
    }

    /**
     * @description
     * Returns the value assigned to the Optional.
     * <br><br>
     * If the Optional is un-assigned, a NoSuchElementException is thrown.
     *
     * @return The value assigned to the Optional.
     */
    global Object get() {
        if (!isPresent) {
            throw new NoSuchElementException();
        }

        return value;
    }

    /**
     * @description
     * Returns the Optional's value if assigned, the value of the other argument if not.
     *
     * @param other The value to return if the Optional is un-assigned.
     *
     * @return The Optional's value, or the other value.
     */
    global Object orElse(final Object other) {
        return isPresent ? value : other;
    }

    /**
     * @description
     * Uses the given Function to process an Optional.
     * <br><br>
     * The method may be used to build a chain of functions to process an Optional.
     *
     * @param function The transformer to create the value.
     *
     * @return The value returned by the transformer.
     */
    global OptionalV1 then(final Function function) {
        return function.apply(this);
    }
}