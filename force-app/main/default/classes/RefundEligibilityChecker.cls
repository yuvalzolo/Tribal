/**
 * Utility that checks whether a purchase is still within its return window.
 */
public with sharing class RefundEligibilityChecker {

    /**
     * Determines whether today falls within the return window of a purchase.
     * The last day of the window still counts as eligible.
     *
     * @param purchaseDate      Date the purchase was made
     * @param returnWindowDays  Number of days after purchase that returns are allowed
     * @return true if today is on or before purchaseDate + returnWindowDays;
     *         false if either input is null or the window is negative
     */
    public static Boolean isEligible(Date purchaseDate, Integer returnWindowDays) {
        if (purchaseDate == null || returnWindowDays == null || returnWindowDays < 0) {
            return false;
        }
        return Date.today() <= purchaseDate.addDays(returnWindowDays);
    }
}
