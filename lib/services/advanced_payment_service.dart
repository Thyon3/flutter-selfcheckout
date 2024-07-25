import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:uuid/uuid.dart';
import 'package:selfcheckoutapp/services/security_service.dart';
import 'package:selfcheckoutapp/services/logging_service.dart';
import 'package:selfcheckoutapp/utils/app_utils.dart';

class AdvancedPaymentService {
  static const String _baseUrl = 'https://api.payment-provider.com/v1';
  static const Duration _timeout = Duration(seconds: 30);
  
  static final Uuid _uuid = Uuid();
  static final Map<String, PaymentMethod> _savedPaymentMethods = {};
  static final Map<String, Subscription> _activeSubscriptions = {};

  // Payment processing
  static Future<PaymentResult> processPayment(PaymentRequest request) async {
    try {
      LoggingService.info('Processing payment: ${request.amount} ${request.currency}');
      
      // Validate request
      _validatePaymentRequest(request);
      
      // Generate payment ID
      final paymentId = _uuid.v4();
      
      // Create payment intent
      final paymentIntent = await _createPaymentIntent(request, paymentId);
      
      // Process payment based on method
      final result = await _processPaymentByMethod(paymentIntent);
      
      // Log result
      LoggingService.info('Payment processed: ${result.status}');
      
      return result;
    } catch (e) {
      LoggingService.error('Payment processing failed: $e');
      return PaymentResult(
        success: false,
        status: PaymentStatus.failed,
        errorMessage: e.toString(),
        transactionId: null,
      );
    }
  }

  static Future<PaymentIntent> _createPaymentIntent(
    PaymentRequest request, 
    String paymentId
  ) async {
    final payload = {
      'id': paymentId,
      'amount': request.amount,
      'currency': request.currency,
      'payment_method': request.paymentMethod.type.name,
      'customer_id': request.customerId,
      'metadata': request.metadata,
      'created_at': DateTime.now().toIso8601String(),
    };

    // Encrypt sensitive data
    final encryptedPayload = await SecurityService.encryptData(json.encode(payload));
    
    final response = await http.post(
      Uri.parse('$_baseUrl/payment-intents'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${await _getApiKey()}',
      },
      body: json.encode({'encrypted_data': encryptedPayload}),
    ).timeout(_timeout);

    if (response.statusCode != 200) {
      throw Exception('Failed to create payment intent: ${response.body}');
    }

    final data = json.decode(response.body);
    return PaymentIntent.fromJson(data);
  }

  static Future<PaymentResult> _processPaymentByMethod(
    PaymentIntent paymentIntent
  ) async {
    switch (paymentIntent.paymentMethod) {
      case PaymentMethodType.creditCard:
        return await _processCreditCardPayment(paymentIntent);
      case PaymentMethodType.debitCard:
        return await _processDebitCardPayment(paymentIntent);
      case PaymentMethodType.paypal:
        return await _processPayPalPayment(paymentIntent);
      case PaymentMethodType.googlePay:
        return await _processGooglePayPayment(paymentIntent);
      case PaymentMethodType.applePay:
        return await _processApplePayPayment(paymentIntent);
      case PaymentMethodType.bankTransfer:
        return await _processBankTransferPayment(paymentIntent);
      case PaymentMethodType.cryptocurrency:
        return await _processCryptoPayment(paymentIntent);
      default:
        throw Exception('Unsupported payment method');
    }
  }

  static Future<PaymentResult> _processCreditCardPayment(
    PaymentIntent paymentIntent
  ) async {
    try {
      // Simulate credit card processing
      await Future.delayed(Duration(seconds: 2));
      
      // Validate card details
      final cardDetails = paymentIntent.cardDetails;
      if (cardDetails == null) {
        throw Exception('Card details required');
      }
      
      // Check card expiry
      final now = DateTime.now();
      final expiryDate = DateTime(cardDetails.expiryYear, cardDetails.expiryMonth);
      if (expiryDate.isBefore(now)) {
        throw Exception('Card has expired');
      }
      
      // Process with payment gateway
      final response = await http.post(
        Uri.parse('$_baseUrl/process-card'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${await _getApiKey()}',
        },
        body: json.encode({
          'intent_id': paymentIntent.id,
          'card_number': cardDetails.number,
          'expiry_month': cardDetails.expiryMonth,
          'expiry_year': cardDetails.expiryYear,
          'cvv': cardDetails.cvv,
          'holder_name': cardDetails.holderName,
        }),
      ).timeout(_timeout);

      final data = json.decode(response.body);
      
      return PaymentResult(
        success: data['success'] ?? false,
        status: _parsePaymentStatus(data['status']),
        transactionId: data['transaction_id'],
        errorMessage: data['error_message'],
        processingTime: Duration(milliseconds: data['processing_time_ms'] ?? 0),
        fees: double.parse(data['fees']?.toString() ?? '0'),
      );
    } catch (e) {
      return PaymentResult(
        success: false,
        status: PaymentStatus.failed,
        errorMessage: e.toString(),
      );
    }
  }

  static Future<PaymentResult> _processDebitCardPayment(
    PaymentIntent paymentIntent
  ) async {
    // Similar to credit card but with debit-specific validation
    return await _processCreditCardPayment(paymentIntent);
  }

  static Future<PaymentResult> _processPayPalPayment(
    PaymentIntent paymentIntent
  ) async {
    try {
      // Redirect to PayPal or use SDK
      final response = await http.post(
        Uri.parse('$_baseUrl/process-paypal'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${await _getApiKey()}',
        },
        body: json.encode({
          'intent_id': paymentIntent.id,
          'return_url': paymentIntent.returnUrl,
          'cancel_url': paymentIntent.cancelUrl,
        }),
      ).timeout(_timeout);

      final data = json.decode(response.body);
      
      return PaymentResult(
        success: data['success'] ?? false,
        status: _parsePaymentStatus(data['status']),
        transactionId: data['transaction_id'],
        redirectUrl: data['redirect_url'],
        errorMessage: data['error_message'],
      );
    } catch (e) {
      return PaymentResult(
        success: false,
        status: PaymentStatus.failed,
        errorMessage: e.toString(),
      );
    }
  }

  static Future<PaymentResult> _processGooglePayPayment(
    PaymentIntent paymentIntent
  ) async {
    try {
      // Use Google Pay SDK
      if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
        // Initialize Google Pay
        final paymentData = await _getGooglePayPaymentData(paymentIntent);
        
        // Process payment
        final response = await http.post(
          Uri.parse('$_baseUrl/process-google-pay'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer ${await _getApiKey()}',
          },
          body: json.encode({
            'intent_id': paymentIntent.id,
            'payment_data': paymentData,
          }),
        ).timeout(_timeout);

        final data = json.decode(response.body);
        
        return PaymentResult(
          success: data['success'] ?? false,
          status: _parsePaymentStatus(data['status']),
          transactionId: data['transaction_id'],
          errorMessage: data['error_message'],
        );
      } else {
        throw Exception('Google Pay not supported on this platform');
      }
    } catch (e) {
      return PaymentResult(
        success: false,
        status: PaymentStatus.failed,
        errorMessage: e.toString(),
      );
    }
  }

  static Future<PaymentResult> _processApplePayPayment(
    PaymentIntent paymentIntent
  ) async {
    try {
      // Use Apple Pay SDK (iOS only)
      if (!kIsWeb && Platform.isIOS) {
        final paymentData = await _getApplePayPaymentData(paymentIntent);
        
        final response = await http.post(
          Uri.parse('$_baseUrl/process-apple-pay'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer ${await _getApiKey()}',
          },
          body: json.encode({
            'intent_id': paymentIntent.id,
            'payment_data': paymentData,
          }),
        ).timeout(_timeout);

        final data = json.decode(response.body);
        
        return PaymentResult(
          success: data['success'] ?? false,
          status: _parsePaymentStatus(data['status']),
          transactionId: data['transaction_id'],
          errorMessage: data['error_message'],
        );
      } else {
        throw Exception('Apple Pay not supported on this platform');
      }
    } catch (e) {
      return PaymentResult(
        success: false,
        status: PaymentStatus.failed,
        errorMessage: e.toString(),
      );
    }
  }

  static Future<PaymentResult> _processBankTransferPayment(
    PaymentIntent paymentIntent
  ) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/process-bank-transfer'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${await _getApiKey()}',
        },
        body: json.encode({
          'intent_id': paymentIntent.id,
          'bank_details': paymentIntent.bankDetails,
        }),
      ).timeout(_timeout);

      final data = json.decode(response.body);
      
      return PaymentResult(
        success: true,
        status: PaymentStatus.pending,
        transactionId: data['transaction_id'],
        bankReference: data['bank_reference'],
        estimatedCompletion: DateTime.parse(data['estimated_completion']),
        errorMessage: data['error_message'],
      );
    } catch (e) {
      return PaymentResult(
        success: false,
        status: PaymentStatus.failed,
        errorMessage: e.toString(),
      );
    }
  }

  static Future<PaymentResult> _processCryptoPayment(
    PaymentIntent paymentIntent
  ) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/process-crypto'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${await _getApiKey()}',
        },
        body: json.encode({
          'intent_id': paymentIntent.id,
          'crypto_type': paymentIntent.cryptoType,
          'wallet_address': paymentIntent.walletAddress,
        }),
      ).timeout(_timeout);

      final data = json.decode(response.body);
      
      return PaymentResult(
        success: true,
        status: PaymentStatus.pending,
        transactionId: data['transaction_id'],
        cryptoTransactionId: data['crypto_transaction_id'],
        confirmationsRequired: data['confirmations_required'],
        errorMessage: data['error_message'],
      );
    } catch (e) {
      return PaymentResult(
        success: false,
        status: PaymentStatus.failed,
        errorMessage: e.toString(),
      );
    }
  }

  // Payment method management
  static Future<void> savePaymentMethod(
    String customerId, 
    PaymentMethod paymentMethod
  ) async {
    try {
      // Encrypt sensitive data
      final encryptedMethod = await SecurityService.encryptData(
        json.encode(paymentMethod.toJson())
      );
      
      _savedPaymentMethods[paymentMethod.id] = paymentMethod;
      
      // Save to backend
      await http.post(
        Uri.parse('$_baseUrl/customers/$customerId/payment-methods'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${await _getApiKey()}',
        },
        body: json.encode({
          'payment_method': encryptedMethod,
        }),
      ).timeout(_timeout);
      
      LoggingService.info('Payment method saved: ${paymentMethod.id}');
    } catch (e) {
      LoggingService.error('Failed to save payment method: $e');
      throw Exception('Failed to save payment method');
    }
  }

  static Future<List<PaymentMethod>> getSavedPaymentMethods(
    String customerId
  ) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/customers/$customerId/payment-methods'),
        headers: {
          'Authorization': 'Bearer ${await _getApiKey()}',
        },
      ).timeout(_timeout);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final methods = <PaymentMethod>[];
        
        for (final item in data['payment_methods']) {
          final decrypted = await SecurityService.decryptData(item['encrypted_data']);
          methods.add(PaymentMethod.fromJson(json.decode(decrypted)));
        }
        
        return methods;
      }
      
      return [];
    } catch (e) {
      LoggingService.error('Failed to get payment methods: $e');
      return [];
    }
  }

  static Future<void> deletePaymentMethod(
    String customerId, 
    String paymentMethodId
  ) async {
    try {
      _savedPaymentMethods.remove(paymentMethodId);
      
      await http.delete(
        Uri.parse('$_baseUrl/customers/$customerId/payment-methods/$paymentMethodId'),
        headers: {
          'Authorization': 'Bearer ${await _getApiKey()}',
        },
      ).timeout(_timeout);
      
      LoggingService.info('Payment method deleted: $paymentMethodId');
    } catch (e) {
      LoggingService.error('Failed to delete payment method: $e');
      throw Exception('Failed to delete payment method');
    }
  }

  // Subscription management
  static Future<Subscription> createSubscription(
    SubscriptionRequest request
  ) async {
    try {
      LoggingService.info('Creating subscription: ${request.planId}');
      
      final subscriptionId = _uuid.v4();
      
      final response = await http.post(
        Uri.parse('$_baseUrl/subscriptions'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${await _getApiKey()}',
        },
        body: json.encode({
          'id': subscriptionId,
          'customer_id': request.customerId,
          'plan_id': request.planId,
          'payment_method_id': request.paymentMethodId,
          'trial_period_days': request.trialPeriodDays,
          'metadata': request.metadata,
        }),
      ).timeout(_timeout);

      if (response.statusCode != 201) {
        throw Exception('Failed to create subscription: ${response.body}');
      }

      final data = json.decode(response.body);
      final subscription = Subscription.fromJson(data);
      _activeSubscriptions[subscription.id] = subscription;
      
      return subscription;
    } catch (e) {
      LoggingService.error('Failed to create subscription: $e');
      throw Exception('Failed to create subscription');
    }
  }

  static Future<Subscription> getSubscription(String subscriptionId) async {
    try {
      if (_activeSubscriptions.containsKey(subscriptionId)) {
        return _activeSubscriptions[subscriptionId]!;
      }
      
      final response = await http.get(
        Uri.parse('$_baseUrl/subscriptions/$subscriptionId'),
        headers: {
          'Authorization': 'Bearer ${await _getApiKey()}',
        },
      ).timeout(_timeout);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final subscription = Subscription.fromJson(data);
        _activeSubscriptions[subscriptionId] = subscription;
        return subscription;
      }
      
      throw Exception('Subscription not found');
    } catch (e) {
      LoggingService.error('Failed to get subscription: $e');
      throw Exception('Failed to get subscription');
    }
  }

  static Future<void> cancelSubscription(
    String subscriptionId, 
    String reason
  ) async {
    try {
      await http.post(
        Uri.parse('$_baseUrl/subscriptions/$subscriptionId/cancel'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${await _getApiKey()}',
        },
        body: json.encode({
          'reason': reason,
          'cancel_at_period_end': true,
        }),
      ).timeout(_timeout);
      
      if (_activeSubscriptions.containsKey(subscriptionId)) {
        final subscription = _activeSubscriptions[subscriptionId]!;
        _activeSubscriptions[subscriptionId] = subscription.copyWith(
          status: SubscriptionStatus.canceled,
          canceledAt: DateTime.now(),
        );
      }
      
      LoggingService.info('Subscription canceled: $subscriptionId');
    } catch (e) {
      LoggingService.error('Failed to cancel subscription: $e');
      throw Exception('Failed to cancel subscription');
    }
  }

  // Refund management
  static Future<RefundResult> processRefund(RefundRequest request) async {
    try {
      LoggingService.info('Processing refund: ${request.amount}');
      
      final response = await http.post(
        Uri.parse('$_baseUrl/refunds'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${await _getApiKey()}',
        },
        body: json.encode({
          'payment_id': request.paymentId,
          'amount': request.amount,
          'reason': request.reason,
          'metadata': request.metadata,
        }),
      ).timeout(_timeout);

      final data = json.decode(response.body);
      
      return RefundResult(
        success: data['success'] ?? false,
        refundId: data['refund_id'],
        status: _parseRefundStatus(data['status']),
        amount: double.parse(data['amount'].toString()),
        processedAt: DateTime.parse(data['processed_at']),
        errorMessage: data['error_message'],
      );
    } catch (e) {
      LoggingService.error('Refund processing failed: $e');
      return RefundResult(
        success: false,
        status: RefundStatus.failed,
        errorMessage: e.toString(),
      );
    }
  }

  // Utility methods
  static void _validatePaymentRequest(PaymentRequest request) {
    if (request.amount <= 0) {
      throw Exception('Amount must be greater than 0');
    }
    
    if (request.currency.isEmpty) {
      throw Exception('Currency is required');
    }
    
    if (request.customerId.isEmpty) {
      throw Exception('Customer ID is required');
    }
    
    if (request.paymentMethod.type == PaymentMethodType.creditCard ||
        request.paymentMethod.type == PaymentMethodType.debitCard) {
      final card = request.paymentMethod.cardDetails;
      if (card == null || !_isValidCard(card.number)) {
        throw Exception('Invalid card details');
      }
    }
  }

  static bool _isValidCard(String cardNumber) {
    // Luhn algorithm for card validation
    final digits = cardNumber.replaceAll(RegExp(r'[^\d]'), '');
    if (digits.length < 13 || digits.length > 19) return false;
    
    int sum = 0;
    bool isEven = false;
    
    for (int i = digits.length - 1; i >= 0; i--) {
      int digit = int.parse(digits[i]);
      
      if (isEven) {
        digit *= 2;
        if (digit > 9) {
          digit = (digit % 10) + 1;
        }
      }
      
      sum += digit;
      isEven = !isEven;
    }
    
    return sum % 10 == 0;
  }

  static PaymentStatus _parsePaymentStatus(String status) {
    switch (status.toLowerCase()) {
      case 'succeeded':
        return PaymentStatus.succeeded;
      case 'pending':
        return PaymentStatus.pending;
      case 'failed':
        return PaymentStatus.failed;
      case 'cancelled':
        return PaymentStatus.cancelled;
      case 'refunded':
        return PaymentStatus.refunded;
      default:
        return PaymentStatus.unknown;
    }
  }

  static RefundStatus _parseRefundStatus(String status) {
    switch (status.toLowerCase()) {
      case 'succeeded':
        return RefundStatus.succeeded;
      case 'pending':
        return RefundStatus.pending;
      case 'failed':
        return RefundStatus.failed;
      case 'cancelled':
        return RefundStatus.cancelled;
      default:
        return RefundStatus.unknown;
    }
  }

  static Future<String> _getApiKey() async {
    // In production, this should be securely stored
    return 'pk_test_1234567890abcdef';
  }

  static Future<Map<String, dynamic>> _getGooglePayPaymentData(
    PaymentIntent paymentIntent
  ) async {
    // Implement Google Pay SDK integration
    return {
      'apiVersion': '2.0',
      'apiVersionMinor': '0',
      'merchantInfo': {
        'merchantId': 'merchant_id',
        'merchantName': 'ScanGo',
      },
      'allowedPaymentMethods': [
        {
          'type': 'CARD',
          'parameters': {
            'allowedAuthMethods': ['PAN_ONLY', 'CRYPTOGRAM_3DS'],
            'allowedCardNetworks': ['AMEX', 'DISCOVER', 'JCB', 'MASTERCARD', 'VISA'],
          },
          'tokenizationSpecification': {
            'type': 'PAYMENT_GATEWAY',
            'parameters': {
              'gateway': 'example',
              'gatewayMerchantId': 'gateway_merchant_id',
            },
          },
        },
      ],
      'transactionInfo': {
        'totalPrice': paymentIntent.amount.toString(),
        'totalPriceStatus': 'FINAL',
        'currencyCode': paymentIntent.currency,
      },
    };
  }

  static Future<Map<String, dynamic>> _getApplePayPaymentData(
    PaymentIntent paymentIntent
  ) async {
    // Implement Apple Pay SDK integration
    return {
      'countryCode': 'US',
      'currencyCode': paymentIntent.currency,
      'merchantCapabilities': ['3DS', 'debit', 'credit'],
      'supportedNetworks': ['amex', 'discover', 'jcb', 'masterCard', 'visa'],
      'total': {
        'label': 'ScanGo',
        'amount': paymentIntent.amount.toString(),
      },
    };
  }
}

// Data models
class PaymentRequest {
  final double amount;
  final String currency;
  final String customerId;
  final PaymentMethod paymentMethod;
  final Map<String, dynamic>? metadata;
  final String? returnUrl;
  final String? cancelUrl;

  PaymentRequest({
    required this.amount,
    required this.currency,
    required this.customerId,
    required this.paymentMethod,
    this.metadata,
    this.returnUrl,
    this.cancelUrl,
  });
}

class PaymentMethod {
  final String id;
  final PaymentMethodType type;
  final CardDetails? cardDetails;
  final BankDetails? bankDetails;
  final String? cryptoType;
  final String? walletAddress;
  final bool isDefault;
  final DateTime createdAt;

  PaymentMethod({
    required this.id,
    required this.type,
    this.cardDetails,
    this.bankDetails,
    this.cryptoType,
    this.walletAddress,
    this.isDefault = false,
    required this.createdAt,
  });

  factory PaymentMethod.fromJson(Map<String, dynamic> json) {
    return PaymentMethod(
      id: json['id'],
      type: PaymentMethodType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => PaymentMethodType.creditCard,
      ),
      cardDetails: json['card_details'] != null 
          ? CardDetails.fromJson(json['card_details']) 
          : null,
      bankDetails: json['bank_details'] != null 
          ? BankDetails.fromJson(json['bank_details']) 
          : null,
      cryptoType: json['crypto_type'],
      walletAddress: json['wallet_address'],
      isDefault: json['is_default'] ?? false,
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.name,
      'card_details': cardDetails?.toJson(),
      'bank_details': bankDetails?.toJson(),
      'crypto_type': cryptoType,
      'wallet_address': walletAddress,
      'is_default': isDefault,
      'created_at': createdAt.toIso8601String(),
    };
  }
}

class CardDetails {
  final String number;
  final int expiryMonth;
  final int expiryYear;
  final String cvv;
  final String holderName;
  final String? brand;

  CardDetails({
    required this.number,
    required this.expiryMonth,
    required this.expiryYear,
    required this.cvv,
    required this.holderName,
    this.brand,
  });

  factory CardDetails.fromJson(Map<String, dynamic> json) {
    return CardDetails(
      number: json['number'],
      expiryMonth: json['expiry_month'],
      expiryYear: json['expiry_year'],
      cvv: json['cvv'],
      holderName: json['holder_name'],
      brand: json['brand'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'number': number,
      'expiry_month': expiryMonth,
      'expiry_year': expiryYear,
      'cvv': cvv,
      'holder_name': holderName,
      'brand': brand,
    };
  }
}

class BankDetails {
  final String accountNumber;
  final String routingNumber;
  final String accountHolderName;
  final String bankName;
  final String? swiftCode;

  BankDetails({
    required this.accountNumber,
    required this.routingNumber,
    required this.accountHolderName,
    required this.bankName,
    this.swiftCode,
  });

  factory BankDetails.fromJson(Map<String, dynamic> json) {
    return BankDetails(
      accountNumber: json['account_number'],
      routingNumber: json['routing_number'],
      accountHolderName: json['account_holder_name'],
      bankName: json['bank_name'],
      swiftCode: json['swift_code'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'account_number': accountNumber,
      'routing_number': routingNumber,
      'account_holder_name': accountHolderName,
      'bank_name': bankName,
      'swift_code': swiftCode,
    };
  }
}

class PaymentIntent {
  final String id;
  final double amount;
  final String currency;
  final PaymentMethodType paymentMethod;
  final CardDetails? cardDetails;
  final BankDetails? bankDetails;
  final String? cryptoType;
  final String? walletAddress;
  final String? returnUrl;
  final String? cancelUrl;
  final DateTime createdAt;

  PaymentIntent({
    required this.id,
    required this.amount,
    required this.currency,
    required this.paymentMethod,
    this.cardDetails,
    this.bankDetails,
    this.cryptoType,
    this.walletAddress,
    this.returnUrl,
    this.cancelUrl,
    required this.createdAt,
  });

  factory PaymentIntent.fromJson(Map<String, dynamic> json) {
    return PaymentIntent(
      id: json['id'],
      amount: double.parse(json['amount'].toString()),
      currency: json['currency'],
      paymentMethod: PaymentMethodType.values.firstWhere(
        (e) => e.name == json['payment_method'],
        orElse: () => PaymentMethodType.creditCard,
      ),
      cardDetails: json['card_details'] != null 
          ? CardDetails.fromJson(json['card_details']) 
          : null,
      bankDetails: json['bank_details'] != null 
          ? BankDetails.fromJson(json['bank_details']) 
          : null,
      cryptoType: json['crypto_type'],
      walletAddress: json['wallet_address'],
      returnUrl: json['return_url'],
      cancelUrl: json['cancel_url'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}

class PaymentResult {
  final bool success;
  final PaymentStatus status;
  final String? transactionId;
  final String? errorMessage;
  final String? redirectUrl;
  final String? bankReference;
  final String? cryptoTransactionId;
  final DateTime? estimatedCompletion;
  final int? confirmationsRequired;
  final Duration processingTime;
  final double fees;

  PaymentResult({
    required this.success,
    required this.status,
    this.transactionId,
    this.errorMessage,
    this.redirectUrl,
    this.bankReference,
    this.cryptoTransactionId,
    this.estimatedCompletion,
    this.confirmationsRequired,
    this.processingTime = Duration.zero,
    this.fees = 0.0,
  });
}

class SubscriptionRequest {
  final String customerId;
  final String planId;
  final String paymentMethodId;
  final int? trialPeriodDays;
  final Map<String, dynamic>? metadata;

  SubscriptionRequest({
    required this.customerId,
    required this.planId,
    required this.paymentMethodId,
    this.trialPeriodDays,
    this.metadata,
  });
}

class Subscription {
  final String id;
  final String customerId;
  final String planId;
  final SubscriptionStatus status;
  final DateTime currentPeriodStart;
  final DateTime currentPeriodEnd;
  final DateTime? trialStart;
  final DateTime? trialEnd;
  final DateTime? canceledAt;
  final DateTime? endedAt;
  final Map<String, dynamic>? metadata;

  Subscription({
    required this.id,
    required this.customerId,
    required this.planId,
    required this.status,
    required this.currentPeriodStart,
    required this.currentPeriodEnd,
    this.trialStart,
    this.trialEnd,
    this.canceledAt,
    this.endedAt,
    this.metadata,
  });

  factory Subscription.fromJson(Map<String, dynamic> json) {
    return Subscription(
      id: json['id'],
      customerId: json['customer_id'],
      planId: json['plan_id'],
      status: SubscriptionStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => SubscriptionStatus.incomplete,
      ),
      currentPeriodStart: DateTime.parse(json['current_period_start']),
      currentPeriodEnd: DateTime.parse(json['current_period_end']),
      trialStart: json['trial_start'] != null 
          ? DateTime.parse(json['trial_start']) 
          : null,
      trialEnd: json['trial_end'] != null 
          ? DateTime.parse(json['trial_end']) 
          : null,
      canceledAt: json['canceled_at'] != null 
          ? DateTime.parse(json['canceled_at']) 
          : null,
      endedAt: json['ended_at'] != null 
          ? DateTime.parse(json['ended_at']) 
          : null,
      metadata: json['metadata'],
    );
  }

  Subscription copyWith({
    String? id,
    String? customerId,
    String? planId,
    SubscriptionStatus? status,
    DateTime? currentPeriodStart,
    DateTime? currentPeriodEnd,
    DateTime? trialStart,
    DateTime? trialEnd,
    DateTime? canceledAt,
    DateTime? endedAt,
    Map<String, dynamic>? metadata,
  }) {
    return Subscription(
      id: id ?? this.id,
      customerId: customerId ?? this.customerId,
      planId: planId ?? this.planId,
      status: status ?? this.status,
      currentPeriodStart: currentPeriodStart ?? this.currentPeriodStart,
      currentPeriodEnd: currentPeriodEnd ?? this.currentPeriodEnd,
      trialStart: trialStart ?? this.trialStart,
      trialEnd: trialEnd ?? this.trialEnd,
      canceledAt: canceledAt ?? this.canceledAt,
      endedAt: endedAt ?? this.endedAt,
      metadata: metadata ?? this.metadata,
    );
  }
}

class RefundRequest {
  final String paymentId;
  final double amount;
  final String reason;
  final Map<String, dynamic>? metadata;

  RefundRequest({
    required this.paymentId,
    required this.amount,
    required this.reason,
    this.metadata,
  });
}

class RefundResult {
  final bool success;
  final String? refundId;
  final RefundStatus status;
  final double amount;
  final DateTime processedAt;
  final String? errorMessage;

  RefundResult({
    required this.success,
    this.refundId,
    required this.status,
    required this.amount,
    required this.processedAt,
    this.errorMessage,
  });
}

enum PaymentMethodType {
  creditCard,
  debitCard,
  paypal,
  googlePay,
  applePay,
  bankTransfer,
  cryptocurrency,
}

enum PaymentStatus {
  succeeded,
  pending,
  failed,
  cancelled,
  refunded,
  unknown,
}

enum SubscriptionStatus {
  incomplete,
  incompleteExpired,
  trialing,
  active,
  pastDue,
  canceled,
  unpaid,
  ended,
}

enum RefundStatus {
  succeeded,
  pending,
  failed,
  cancelled,
  unknown,
}
