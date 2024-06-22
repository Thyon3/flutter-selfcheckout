import 'package:selfcheckoutapp/services/validation_service.dart';

class ValidationUtils {
  static bool isValidEmail(String email) {
    return ValidationService.validateEmail(email) == null;
  }

  static bool isValidPassword(String password) {
    return ValidationService.validatePassword(password) == null;
  }

  static bool isValidBarcode(String barcode) {
    return ValidationService.validateBarcode(barcode) == null;
  }

  static bool isValidPrice(String price) {
    return ValidationService.validatePrice(price) == null;
  }

  static bool isValidQuantity(String quantity) {
    return ValidationService.validateQuantity(quantity) == null;
  }

  static bool isValidName(String name) {
    return ValidationService.validateName(name) == null;
  }

  static bool isValidWeight(String weight) {
    return ValidationService.validateWeight(weight) == null;
  }

  static bool isValidSearchQuery(String query) {
    return ValidationService.validateSearchQuery(query) == null;
  }

  static bool isValidPhoneNumber(String phone) {
    return ValidationService.validatePhoneNumber(phone) == null;
  }

  static bool isValidUrl(String url) {
    return ValidationService.validateUrl(url) == null;
  }

  static String sanitizeInput(String input) {
    return ValidationService.sanitizeInput(input);
  }

  static String sanitizeForDisplay(String input) {
    return ValidationService.sanitizeForDisplay(input);
  }
}
