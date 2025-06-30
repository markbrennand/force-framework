/**
 * @description
 * Copyright (c) 2025 Mark Brennand, released under <a href=../../../LICENSE target="_blank">MIT License</a>.
 * <br><br>
 * Unit tests for DependencyHelper class.
 *
 * @author Mark Brennand
 */
@IsTest
public with sharing class DependencyHelperTests {

    @IsTest
    private static void testAll() {
        Type t1 = Integer.class;
        Object o1 = 12;

        Type t2 = Double.class;
        Object o2 = (Double) 1.23;

        Type t3 = Dependency.Prototype.class;

        Dependency.ValidationResult r1 = DependencyHelper.buildValidationResult(
                o1 instanceof Integer,
                false,
                t1,
                t1
        );

        Assert.isTrue(r1.isValid);
        Assert.isNull(r1.errorMessage);

        Dependency.ValidationResult r2 = DependencyHelper.buildValidationResult(
                o2 instanceof Integer,
                false,
                t1,
                t2
        );

        Assert.isFalse(r2.isValid);
        Assert.areEqual('Class Double does not extend Integer', r2.errorMessage);

        Dependency.ValidationResult r3 = DependencyHelper.buildValidationResult(
                o2 instanceof Dependency.Prototype,
                true,
                t3,
                t2
        );

        Assert.isFalse(r3.isValid);
        Assert.isTrue(TestHelper.textContains('Class Double does not implement Dependency.Prototype', r3.errorMessage));
    }
}