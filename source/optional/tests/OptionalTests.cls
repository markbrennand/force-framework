/**
 * @description
 * Copyright (c) 2025 Mark Brennand, released under <a href=../../../LICENSE target="_blank">MIT License</a>.
 * <br><br>
 * Unit tests for Optional class.
 *
 * @author Mark Brennand
 */
@IsTest
public with sharing class OptionalTests {

    @IsTest
    private static void testEmpty() {
        Optional opt = Optional.empty();
        Assert.isFalse(opt.isPresent());
        try {
            opt.get();
            Assert.fail();
        } catch(Optional.NoSuchElementException nsee) {}
    }

    @IsTest
    private static void testOf() {
        String value = 'TEST';
        Optional opt = Optional.of(value);
        Assert.isTrue(opt.isPresent());
        Assert.areEqual('TEST', opt.get());

        opt = Optional.of(null);
        Assert.isTrue(opt.isPresent());
        Assert.isNull(opt.get());
    }

    @IsTest
    private static void testOfNullable() {
        Optional opt = Optional.ofNullable('TEST');
        Assert.isTrue(opt.isPresent());
        Assert.areEqual('TEST', opt.get());

        opt = Optional.ofNullable(null);
        Assert.isFalse(opt.isPresent());
    }

    @IsTest
    private static void testOrElse() {
        Optional opt = Optional.of('TEST');
        Assert.areEqual('TEST', opt.orElse('OTHER'));

        opt = Optional.empty();
        Assert.areEqual('OTHER', opt.orElse('OTHER'));
    }
}