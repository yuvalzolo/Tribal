/**
 * Unit tests for RefundEligibilityChecker.isEligible.
 */
@isTest
private with sharing class RefundEligibilityCheckerTest {

    @isTest
    static void purchaseInsideWindowIsEligible() {
        Boolean result = RefundEligibilityChecker.isEligible(Date.today(), 30);
        System.assertEquals(true, result, 'A purchase made today with a 30-day window should be eligible.');
    }

    @isTest
    static void lastDayOfWindowIsEligible() {
        Integer windowDays = 14;
        Boolean result = RefundEligibilityChecker.isEligible(Date.today().addDays(-windowDays), windowDays);
        System.assertEquals(true, result, 'The last day of the window should still be eligible.');
    }

    @isTest
    static void purchasePastWindowIsNotEligible() {
        Integer windowDays = 14;
        Boolean result = RefundEligibilityChecker.isEligible(Date.today().addDays(-(windowDays + 1)), windowDays);
        System.assertEquals(false, result, 'A purchase past the window should not be eligible.');
    }

    @isTest
    static void nullPurchaseDateIsNotEligible() {
        Boolean result = RefundEligibilityChecker.isEligible(null, 30);
        System.assertEquals(false, result, 'A null purchase date should not be eligible.');
    }

    @isTest
    static void nullWindowIsNotEligible() {
        Boolean result = RefundEligibilityChecker.isEligible(Date.today(), null);
        System.assertEquals(false, result, 'A null return window should not be eligible.');
    }

    @isTest
    static void negativeWindowIsNotEligible() {
        Boolean result = RefundEligibilityChecker.isEligible(Date.today(), -1);
        System.assertEquals(false, result, 'A negative return window should not be eligible.');
    }
}
