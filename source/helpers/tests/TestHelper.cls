/**
 * @description
 * Copyright (c) 2025 Mark Brennand, released under <a href=../../../LICENSE target="_blank">MIT License</a>.
 * <br><br>
 * Common test data and methods for all unit tests.
 *
 * @author Mark Brennand
 */
@IsTest
public with sharing class TestHelper {

    @TestVisible
    private with sharing class ExceptionComparator implements Comparator<Object> {
        public Integer compare(final Object param1, final Object param2) {
            return param1 instanceof Exception
                    && param2 instanceof Exception
                    && ((Exception) param1).getMessage() == ((Exception) param2).getMessage()
                    && ((Exception) param1).getCause()?.getTypeName() == ((Exception) param2).getCause()?.getTypeName()
                    && ((Exception) param1).getCause()?.getMessage() == ((Exception) param2).getCause()?.getMessage()
                    ? 0 : -1;
        }
    }

    @TestVisible
    private static void setNOW() {
        CommonHelper.NOW = Datetime.newInstance(2025, 1, 1, 1, 0 ,0);
    }


    @TestVisible
    private static Boolean textContains(final String expected, final String text) {
        return text.replace(CommonHelper.getApexNamespace(), '').contains(expected);

    }

    @TestVisible
    private static Boolean exceptionContains(final String expectedMessage, final Exception exc) {
        return textContains(expectedMessage, exc.getMessage());
    }
}