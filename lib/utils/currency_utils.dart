class CurrencyUtils {
  static String formatPrice(double price, {String currency = 'LKR'}) {
    return '$currency ${price.toStringAsFixed(2)}';
  }

  static String formatPriceWithoutCurrency(double price) {
    return price.toStringAsFixed(2);
  }

  static double parsePrice(String price) {
    return double.tryParse(price.replaceAll(RegExp(r'[^\d.]'), '')) ?? 0.0;
  }

  static double calculateTotal(double price, int quantity) {
    return price * quantity;
  }

  static double calculateDiscount(double price, double percentage) {
    return price * (1 - percentage / 100);
  }

  static double calculateTax(double price, double taxRate) {
    return price * (taxRate / 100);
  }
}
