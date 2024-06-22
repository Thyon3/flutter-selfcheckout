import 'dart:core';
import 'package:flutter/material.dart';

class ValidationService {
  // Email validation
  static String? validateEmail(String? email) {
    if (email == null || email.isEmpty) {
      return 'Email is required';
    }
    
    // Basic email regex
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$'
    );
    
    if (!emailRegex.hasMatch(email)) {
      return 'Please enter a valid email address';
    }
    
    // Length check
    if (email.length > 254) {
      return 'Email address is too long';
    }
    
    return null;
  }

  // Password validation
  static String? validatePassword(String? password) {
    if (password == null || password.isEmpty) {
      return 'Password is required';
    }
    
    if (password.length < 6) {
      return 'Password must be at least 6 characters long';
    }
    
    if (password.length > 128) {
      return 'Password is too long';
    }
    
    // Check for common weak passwords
    final weakPasswords = [
      'password', '123456', '123456789', 'qwerty', 'abc123',
      'password123', 'admin', 'letmein', 'welcome'
    ];
    
    if (weakPasswords.contains(password.toLowerCase())) {
      return 'Please choose a stronger password';
    }
    
    return null;
  }

  // Name validation
  static String? validateName(String? name) {
    if (name == null || name.isEmpty) {
      return 'Name is required';
    }
    
    if (name.length < 2) {
      return 'Name must be at least 2 characters long';
    }
    
    if (name.length > 50) {
      return 'Name is too long';
    }
    
    // Allow only letters, spaces, hyphens, and apostrophes
    final nameRegex = RegExp(r'^[a-zA-Z\s\'-]+$');
    if (!nameRegex.hasMatch(name)) {
      return 'Name can only contain letters, spaces, hyphens, and apostrophes';
    }
    
    return null;
  }

  // Barcode validation
  static String? validateBarcode(String? barcode) {
    if (barcode == null || barcode.isEmpty) {
      return 'Barcode is required';
    }
    
    // Remove whitespace and convert to uppercase
    barcode = barcode.trim().toUpperCase();
    
    // Check for valid barcode formats (EAN-13, UPC-A, etc.)
    final ean13Regex = RegExp(r'^\d{13}$');
    final upcaRegex = RegExp(r'^\d{12}$');
    final ean8Regex = RegExp(r'^\d{8}$');
    
    if (!ean13Regex.hasMatch(barcode) && 
        !upcaRegex.hasMatch(barcode) && 
        !ean8Regex.hasMatch(barcode)) {
      return 'Please enter a valid barcode (8, 12, or 13 digits)';
    }
    
    return null;
  }

  // Price validation
  static String? validatePrice(String? price) {
    if (price == null || price.isEmpty) {
      return 'Price is required';
    }
    
    final priceValue = double.tryParse(price);
    if (priceValue == null) {
      return 'Please enter a valid price';
    }
    
    if (priceValue <= 0) {
      return 'Price must be greater than 0';
    }
    
    if (priceValue > 999999.99) {
      return 'Price is too high';
    }
    
    return null;
  }

  // Weight validation
  static String? validateWeight(String? weight) {
    if (weight == null || weight.isEmpty) {
      return 'Weight is required';
    }
    
    final weightValue = double.tryParse(weight);
    if (weightValue == null) {
      return 'Please enter a valid weight';
    }
    
    if (weightValue <= 0) {
      return 'Weight must be greater than 0';
    }
    
    if (weightValue > 1000) {
      return 'Weight seems too high (max 1000 kg)';
    }
    
    return null;
  }

  // Quantity validation
  static String? validateQuantity(String? quantity) {
    if (quantity == null || quantity.isEmpty) {
      return 'Quantity is required';
    }
    
    final quantityValue = int.tryParse(quantity);
    if (quantityValue == null) {
      return 'Please enter a valid quantity';
    }
    
    if (quantityValue <= 0) {
      return 'Quantity must be greater than 0';
    }
    
    if (quantityValue > 999) {
      return 'Quantity seems too high (max 999)';
    }
    
    return null;
  }

  // General text validation
  static String? validateText(String? text, {
    required String fieldName,
    int minLength = 1,
    int maxLength = 100,
    bool allowEmpty = false,
  }) {
    if (text == null || text.isEmpty) {
      return allowEmpty ? null : '$fieldName is required';
    }
    
    if (text.length < minLength) {
      return '$fieldName must be at least $minLength characters long';
    }
    
    if (text.length > maxLength) {
      return '$fieldName is too long (max $maxLength characters)';
    }
    
    return null;
  }

  // Input sanitization
  static String sanitizeInput(String input) {
    // Remove potentially dangerous characters
    return input
        .replaceAll(RegExp(r'[<>"\']'), '')
        .trim();
  }

  // Sanitize for display (prevent XSS)
  static String sanitizeForDisplay(String input) {
    return input
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;')
        .replaceAll("'", '&#39;');
  }

  // Validate search query
  static String? validateSearchQuery(String? query) {
    if (query == null || query.isEmpty) {
      return null; // Empty search is allowed
    }
    
    if (query.length < 2) {
      return 'Search query must be at least 2 characters long';
    }
    
    if (query.length > 100) {
      return 'Search query is too long';
    }
    
    // Prevent SQL injection patterns
    final dangerousPatterns = [
      r'\b(SELECT|INSERT|UPDATE|DELETE|DROP|CREATE|ALTER)\b',
      r'[\'";]',
      r'\b(OR|AND)\s+\w+\s*=\s*\w+',
    ];
    
    for (final pattern in dangerousPatterns) {
      if (RegExp(pattern, caseSensitive: false).hasMatch(query)) {
        return 'Invalid search query';
      }
    }
    
    return null;
  }

  // Validate phone number
  static String? validatePhoneNumber(String? phone) {
    if (phone == null || phone.isEmpty) {
      return null; // Phone is optional
    }
    
    // Remove common formatting characters
    final cleanPhone = phone.replaceAll(RegExp(r'[\s\-\(\)]'), '');
    
    // Check if it's all digits
    if (!RegExp(r'^\d+$').hasMatch(cleanPhone)) {
      return 'Phone number can only contain digits';
    }
    
    // Check length (typical phone numbers are 10-15 digits)
    if (cleanPhone.length < 10 || cleanPhone.length > 15) {
      return 'Phone number must be between 10 and 15 digits';
    }
    
    return null;
  }

  // Validate URL
  static String? validateUrl(String? url) {
    if (url == null || url.isEmpty) {
      return null; // URL is optional
    }
    
    try {
      final uri = Uri.parse(url);
      if (!uri.hasScheme || (!uri.hasAuthority && !uri.isAbsolute)) {
        return 'Please enter a valid URL';
      }
      
      if (!['http', 'https'].contains(uri.scheme)) {
        return 'URL must start with http:// or https://';
      }
    } catch (e) {
      return 'Please enter a valid URL';
    }
    
    return null;
  }
}
