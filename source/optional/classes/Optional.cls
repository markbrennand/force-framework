/**
 * @description
 * Copyright (c) 2025 Mark Brennand, released under <a href=../../../LICENSE target="_blank">MIT License</a>.
 * <br><br>
 * Class providing an implementation of Optional which should be used in preference to using null to indicate a
 * value is un-assigned.
 * <br><br>
 * See <a href=../README.md target="_blank">README</a> for full details of Optional.
 *
 * @author Mark Brennand
 */
global with sharing class Optional {


    /**
     * @description
     * Exception thrown to indicate an attempt was made to use an un-assigned value.
     */
    global with sharing class NoSuchElementException extends Exception {}

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
     * Constructs an Optional which has no value.
     */
    private Optional() {
        this.isPresent = false;
    }

    /**
     * @description
     * Constructs an Optional with a value.
     *
     * @param value The value to assign to the Optional.
     */
    private Optional(final Object value) {
        this.value = value;
        this.isPresent = true;
    }

    /**
     * @description
     * Returns an un-assigned Optional.
     *
     * @return An un-assigned Optional.
     */
    global static Optional empty() {
        return new Optional();
    }

    /**
     * @description
     * Returns an Optional assigned to a value.
     *
     * @param value The value to assign the the Optional.
     *
     * @return The assigned Optional.
     */
    global static Optional of(final Object value) {
        return new Optional(value);
    }

    /**
     * @description
     * Returns an Optional assigned to a value or an unassigned Optional if the argument is null.
     *
     * @param value The value to assign the the Optional.
     *
     * @return The assigned Optional.
     */
    global static Optional ofNullable(Object value) {
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
}