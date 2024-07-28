import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:http/http.dart' as http;
import 'package:selfcheckoutapp/services/logging_service.dart';
import 'package:selfcheckoutapp/services/cache_service.dart';
import 'package:selfcheckoutapp/services/security_service.dart';

class QRCodeService {
  static const String _baseUrl = 'https://api.qr.scango.app';
  static const String _apiKey = 'qr_api_key_12345';
  static const String _cacheKey = 'qr_code_cache';
  
  static bool _isInitialized = false;
  static StreamSubscription? _scannerSubscription;
  static final List<QRCodeData> _scannedHistory = [];
  static final Map<String, QRCodeTemplate> _templates = {};

  // QR code service initialization
  static Future<bool> initialize() async {
    try {
      if (_isInitialized) return true;
      
      LoggingService.info('Initializing QR code service');
      
      // Load scanned history
      await _loadScannedHistory();
      
      // Load templates
      await _loadTemplates();
      
      // Initialize default templates if none exist
      if (_templates.isEmpty) {
        await _initializeDefaultTemplates();
      }
      
      _isInitialized = true;
      
      LoggingService.info('QR code service initialized successfully');
      return true;
    } catch (e) {
      LoggingService.error('Failed to initialize QR code service: $e');
      return false;
    }
  }

  // QR code generation
  static Future<QRCodeResult> generateQRCode({
    required String data,
    QRCodeType type = QRCodeType.text,
    Map<String, dynamic>? options,
    int? size,
    String? logoPath,
    QRCodeColor? foregroundColor,
    QRCodeColor? backgroundColor,
  }) async {
    try {
      if (!_isInitialized) {
        await initialize();
      }

      final qrData = QRCodeData(
        id: _generateQRId(),
        type: type,
        data: data,
        options: options ?? {},
        size: size ?? 200,
        logoPath: logoPath,
        foregroundColor: foregroundColor ?? QRCodeColor.black,
        backgroundColor: backgroundColor ?? QRCodeColor.white,
        createdAt: DateTime.now(),
      );

      // Generate QR code image
      final imageData = await _generateQRImage(qrData);
      
      if (imageData != null) {
        qrData.imageData = imageData;
        
        // Add to history
        await _addToScannedHistory(qrData);
        
        // Cache the QR code
        await _cacheQRCode(qrData);
        
        LoggingService.info('QR code generated: ${qrData.id}');
        return QRCodeResult(
          success: true,
          qrCode: qrData,
        );
      }

      return QRCodeResult(
        success: false,
        error: 'Failed to generate QR code image',
      );
    } catch (e) {
      LoggingService.error('Failed to generate QR code: $e');
      return QRCodeResult(
        success: false,
        error: e.toString(),
      );
    }
  }

  static Future<Uint8List?> _generateQRImage(QRCodeData qrData) async {
    try {
      // Mock QR code generation
      await Future.delayed(Duration(milliseconds: 500));
      
      // Generate mock image data
      final imageData = Uint8List.fromList(List.generate(
        qrData.size * qrData.size,
        (index) => Random().nextInt(256),
      ));
      
      return imageData;
    } catch (e) {
      LoggingService.error('Failed to generate QR image: $e');
      return null;
    }
  }

  // QR code scanning
  static Future<QRScanResult> startScanning({
    Function(QRCodeData)? onScan,
    Function(String)? onError,
    bool continuous = false,
    Duration? timeout,
  }) async {
    try {
      if (!_isInitialized) {
        await initialize();
      }

      // Mock scanner initialization
      await Future.delayed(Duration(milliseconds: 1000));
      
      if (continuous) {
        // Start continuous scanning
        _scannerSubscription = _mockScanStream().listen(
          (qrData) {
            onScan?.call(qrData);
            _addToScannedHistory(qrData);
          },
          onError: (error) {
            onError?.call(error.toString());
          },
        );
      } else {
        // Single scan with timeout
        final qrData = await _mockScan(timeout ?? Duration(seconds: 10));
        if (qrData != null) {
          await _addToScannedHistory(qrData);
          onScan?.call(qrData);
        }
      }
      
      LoggingService.info('QR code scanning started');
      return QRScanResult(
        success: true,
        isContinuous: continuous,
      );
    } catch (e) {
      LoggingService.error('Failed to start QR scanning: $e');
      return QRScanResult(
        success: false,
        error: e.toString(),
      );
    }
  }

  static Future<void> stopScanning() async {
    try {
      await _scannerSubscription?.cancel();
      _scannerSubscription = null;
      
      LoggingService.info('QR code scanning stopped');
    } catch (e) {
      LoggingService.error('Failed to stop QR scanning: $e');
    }
  }

  static Stream<QRCodeData> _mockScanStream() async* {
    // Mock continuous scanning stream
    while (true) {
      await Future.delayed(Duration(seconds: 2));
      final mockData = _generateMockQRData();
      yield mockData;
    }
  }

  static Future<QRCodeData?> _mockScan(Duration timeout) async {
    try {
      // Mock single scan
      await Future.delayed(Duration(milliseconds: 1500));
      
      // Simulate successful scan 90% of the time
      if (Random().nextDouble() > 0.1) {
        return _generateMockQRData();
      }
      
      return null;
    } catch (e) {
      LoggingService.error('Mock scan failed: $e');
      return null;
    }
  }

  static QRCodeData _generateMockQRData() {
    final mockTypes = [
      QRCodeType.url,
      QRCodeType.text,
      QRCodeType.product,
      QRCodeType.payment,
      QRCodeType.contact,
    ];
    
    final type = mockTypes[Random().nextInt(mockTypes.length)];
    String data;
    Map<String, dynamic> options = {};
    
    switch (type) {
      case QRCodeType.url:
        data = 'https://scango.app/product/${Random().nextInt(1000)}';
        break;
      case QRCodeType.text:
        data = 'Sample QR code text ${Random().nextInt(1000)}';
        break;
      case QRCodeType.product:
        data = 'product:${Random().nextInt(1000)}:${Random().nextInt(100)}';
        options = {
          'product_id': Random().nextInt(1000).toString(),
          'price': Random().nextInt(1000).toDouble(),
        };
        break;
      case QRCodeType.payment:
        data = 'payment:${Random().nextInt(1000)}:${Random().nextInt(1000)}';
        options = {
          'amount': Random().nextInt(1000).toDouble(),
          'merchant': 'Test Merchant',
        };
        break;
      case QRCodeType.contact:
        data = 'contact:test@example.com:+1234567890';
        options = {
          'name': 'Test Contact',
          'email': 'test@example.com',
          'phone': '+1234567890',
        };
        break;
      default:
        data = 'Unknown QR data';
    }
    
    return QRCodeData(
      id: _generateQRId(),
      type: type,
      data: data,
      options: options,
      size: 200,
      createdAt: DateTime.now(),
    );
  }

  // Shopping-specific QR codes
  static Future<QRCodeResult> generateProductQR({
    required String productId,
    required String productName,
    required double price,
    String? imageUrl,
    Map<String, dynamic>? productDetails,
  }) async {
    try {
      final qrData = {
        'type': 'product',
        'product_id': productId,
        'name': productName,
        'price': price,
        'image_url': imageUrl,
        'details': productDetails ?? {},
        'timestamp': DateTime.now().toIso8601String(),
      };
      
      return await generateQRCode(
        data: json.encode(qrData),
        type: QRCodeType.product,
        options: {
          'product_name': productName,
          'price': price,
        },
      );
    } catch (e) {
      LoggingService.error('Failed to generate product QR: $e');
      return QRCodeResult(success: false, error: e.toString());
    }
  }

  static Future<QRCodeResult> generateShoppingListQR({
    required List<Map<String, dynamic>> items,
    String? listName,
  }) async {
    try {
      final qrData = {
        'type': 'shopping_list',
        'list_name': listName ?? 'My Shopping List',
        'items': items,
        'timestamp': DateTime.now().toIso8601String(),
      };
      
      return await generateQRCode(
        data: json.encode(qrData),
        type: QRCodeType.shoppingList,
        options: {
          'item_count': items.length,
          'list_name': listName,
        },
      );
    } catch (e) {
      LoggingService.error('Failed to generate shopping list QR: $e');
      return QRCodeResult(success: false, error: e.toString());
    }
  }

  static Future<QRCodeResult> generatePaymentQR({
    required double amount,
    required String merchantId,
    String? merchantName,
    String? orderId,
  }) async {
    try {
      final qrData = {
        'type': 'payment',
        'amount': amount,
        'merchant_id': merchantId,
        'merchant_name': merchantName,
        'order_id': orderId,
        'timestamp': DateTime.now().toIso8601String(),
      };
      
      return await generateQRCode(
        data: json.encode(qrData),
        type: QRCodeType.payment,
        options: {
          'amount': amount,
          'merchant': merchantName,
        },
      );
    } catch (e) {
      LoggingService.error('Failed to generate payment QR: $e');
      return QRCodeResult(success: false, error: e.toString());
    }
  }

  static Future<QRCodeResult> generateCouponQR({
    required String couponCode,
    required String discountType,
    required double discountValue,
    DateTime? expiryDate,
    Map<String, dynamic>? conditions,
  }) async {
    try {
      final qrData = {
        'type': 'coupon',
        'coupon_code': couponCode,
        'discount_type': discountType,
        'discount_value': discountValue,
        'expiry_date': expiryDate?.toIso8601String(),
        'conditions': conditions ?? {},
        'timestamp': DateTime.now().toIso8601String(),
      };
      
      return await generateQRCode(
        data: json.encode(qrData),
        type: QRCodeType.coupon,
        options: {
          'coupon_code': couponCode,
          'discount': discountValue,
        },
      );
    } catch (e) {
      LoggingService.error('Failed to generate coupon QR: $e');
      return QRCodeResult(success: false, error: e.toString());
    }
  }

  // QR code validation and processing
  static Future<QRProcessResult> processScannedQR(QRCodeData qrData) async {
    try {
      switch (qrData.type) {
        case QRCodeType.product:
          return await _processProductQR(qrData);
        case QRCodeType.payment:
          return await _processPaymentQR(qrData);
        case QRCodeType.shoppingList:
          return await _processShoppingListQR(qrData);
        case QRCodeType.coupon:
          return await _processCouponQR(qrData);
        case QRCodeType.contact:
          return await _processContactQR(qrData);
        case QRCodeType.url:
          return await _processUrlQR(qrData);
        case QRCodeType.text:
          return QRProcessResult(
            success: true,
            type: 'text',
            data: qrData.data,
          );
        default:
          return QRProcessResult(
            success: false,
            error: 'Unsupported QR code type',
          );
      }
    } catch (e) {
      LoggingService.error('Failed to process scanned QR: $e');
      return QRProcessResult(
        success: false,
        error: e.toString(),
      );
    }
  }

  static Future<QRProcessResult> _processProductQR(QRCodeData qrData) async {
    try {
      final data = json.decode(qrData.data);
      
      // Validate product data
      if (data['product_id'] == null) {
        return QRProcessResult(
          success: false,
          error: 'Invalid product QR code: missing product_id',
        );
      }
      
      // Get product details from API
      final product = await _getProductDetails(data['product_id']);
      
      return QRProcessResult(
        success: true,
        type: 'product',
        data: {
          'qr_data': data,
          'product_details': product,
        },
      );
    } catch (e) {
      LoggingService.error('Failed to process product QR: $e');
      return QRProcessResult(
        success: false,
        error: 'Invalid product QR code format',
      );
    }
  }

  static Future<QRProcessResult> _processPaymentQR(QRCodeData qrData) async {
    try {
      final data = json.decode(qrData.data);
      
      // Validate payment data
      if (data['amount'] == null || data['merchant_id'] == null) {
        return QRProcessResult(
          success: false,
          error: 'Invalid payment QR code: missing required fields',
        );
      }
      
      return QRProcessResult(
        success: true,
        type: 'payment',
        data: {
          'amount': data['amount'],
          'merchant_id': data['merchant_id'],
          'merchant_name': data['merchant_name'],
          'order_id': data['order_id'],
        },
      );
    } catch (e) {
      LoggingService.error('Failed to process payment QR: $e');
      return QRProcessResult(
        success: false,
        error: 'Invalid payment QR code format',
      );
    }
  }

  static Future<QRProcessResult> _processShoppingListQR(QRCodeData qrData) async {
    try {
      final data = json.decode(qrData.data);
      
      // Validate shopping list data
      if (data['items'] == null || !data['items'].is List) {
        return QRProcessResult(
          success: false,
          error: 'Invalid shopping list QR code: missing items',
        );
      }
      
      return QRProcessResult(
        success: true,
        type: 'shopping_list',
        data: {
          'list_name': data['list_name'],
          'items': data['items'],
        },
      );
    } catch (e) {
      LoggingService.error('Failed to process shopping list QR: $e');
      return QRProcessResult(
        success: false,
        error: 'Invalid shopping list QR code format',
      );
    }
  }

  static Future<QRProcessResult> _processCouponQR(QRCodeData qrData) async {
    try {
      final data = json.decode(qrData.data);
      
      // Validate coupon data
      if (data['coupon_code'] == null || data['discount_value'] == null) {
        return QRProcessResult(
          success: false,
          error: 'Invalid coupon QR code: missing required fields',
        );
      }
      
      // Check if coupon is still valid
      if (data['expiry_date'] != null) {
        final expiryDate = DateTime.parse(data['expiry_date']);
        if (DateTime.now().isAfter(expiryDate)) {
          return QRProcessResult(
            success: false,
            error: 'Coupon has expired',
          );
        }
      }
      
      return QRProcessResult(
        success: true,
        type: 'coupon',
        data: {
          'coupon_code': data['coupon_code'],
          'discount_type': data['discount_type'],
          'discount_value': data['discount_value'],
          'expiry_date': data['expiry_date'],
          'conditions': data['conditions'],
        },
      );
    } catch (e) {
      LoggingService.error('Failed to process coupon QR: $e');
      return QRProcessResult(
        success: false,
        error: 'Invalid coupon QR code format',
      );
    }
  }

  static Future<QRProcessResult> _processContactQR(QRCodeData qrData) async {
    try {
      final data = json.decode(qrData.data);
      
      return QRProcessResult(
        success: true,
        type: 'contact',
        data: {
          'name': data['name'],
          'email': data['email'],
          'phone': data['phone'],
        },
      );
    } catch (e) {
      LoggingService.error('Failed to process contact QR: $e');
      return QRProcessResult(
        success: false,
        error: 'Invalid contact QR code format',
      );
    }
  }

  static Future<QRProcessResult> _processUrlQR(QRCodeData qrData) async {
    try {
      final url = qrData.data;
      
      // Validate URL
      if (!Uri.tryParse(url)?.hasAbsolutePath ?? true) {
        return QRProcessResult(
          success: false,
          error: 'Invalid URL in QR code',
        );
      }
      
      return QRProcessResult(
        success: true,
        type: 'url',
        data: {
          'url': url,
        },
      );
    } catch (e) {
      LoggingService.error('Failed to process URL QR: $e');
      return QRProcessResult(
        success: false,
        error: 'Invalid URL QR code format',
      );
    }
  }

  // Templates
  static Future<List<QRCodeTemplate>> getTemplates() async {
    if (!_isInitialized) {
      await initialize();
    }
    return List.from(_templates.values);
  }

  static Future<QRCodeTemplate?> getTemplate(String templateId) async {
    if (!_isInitialized) {
      await initialize();
    }
    return _templates[templateId];
  }

  static Future<QRCodeResult> generateFromTemplate({
    required String templateId,
    required Map<String, dynamic> data,
  }) async {
    try {
      final template = await getTemplate(templateId);
      if (template == null) {
        return QRCodeResult(
          success: false,
          error: 'Template not found: $templateId',
        );
      }
      
      // Merge template data with provided data
      final mergedData = Map<String, dynamic>.from(template.defaultData);
      mergedData.addAll(data);
      
      // Generate QR code using template settings
      return await generateQRCode(
        data: json.encode(mergedData),
        type: template.type,
        options: template.options,
        size: template.size,
        foregroundColor: template.foregroundColor,
        backgroundColor: template.backgroundColor,
      );
    } catch (e) {
      LoggingService.error('Failed to generate from template: $e');
      return QRCodeResult(
        success: false,
        error: e.toString(),
      );
    }
  }

  // History and analytics
  static Future<List<QRCodeData>> getScannedHistory({
    QRCodeType? type,
    DateTime? startDate,
    DateTime? endDate,
    int? limit,
  }) async {
    try {
      var history = List<QRCodeData>.from(_scannedHistory);
      
      if (type != null) {
        history = history.where((qr) => qr.type == type).toList();
      }
      
      if (startDate != null) {
        history = history.where((qr) => qr.createdAt.isAfter(startDate)).toList();
      }
      
      if (endDate != null) {
        history = history.where((qr) => qr.createdAt.isBefore(endDate)).toList();
      }
      
      history.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      
      if (limit != null && history.length > limit) {
        history = history.take(limit).toList();
      }
      
      return history;
    } catch (e) {
      LoggingService.error('Failed to get scanned history: $e');
      return [];
    }
  }

  static Future<QRAnalytics> getAnalytics({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final history = await getScannedHistory(startDate: startDate, endDate: endDate);
      
      final typeStats = <QRCodeType, int>{};
      int totalGenerated = 0;
      int totalScanned = 0;
      
      for (final qr in history) {
        typeStats[qr.type] = (typeStats[qr.type] ?? 0) + 1;
        
        if (qr.imageData != null) {
          totalGenerated++;
        } else {
          totalScanned++;
        }
      }
      
      return QRAnalytics(
        totalGenerated: totalGenerated,
        totalScanned: totalScanned,
        typeStats: typeStats,
        startDate: startDate ?? DateTime.now().subtract(Duration(days: 30)),
        endDate: endDate ?? DateTime.now(),
      );
    } catch (e) {
      LoggingService.error('Failed to get QR analytics: $e');
      return QRAnalytics(
        totalGenerated: 0,
        totalScanned: 0,
        typeStats: {},
        startDate: DateTime.now(),
        endDate: DateTime.now(),
      );
    }
  }

  // Utility methods
  static Future<Map<String, dynamic>?> _getProductDetails(String productId) async {
    try {
      // Mock API call to get product details
      await Future.delayed(Duration(milliseconds: 500));
      
      return {
        'id': productId,
        'name': 'Product $productId',
        'price': Random().nextInt(1000).toDouble(),
        'description': 'Description for product $productId',
        'image_url': 'https://example.com/product$productId.jpg',
      };
    } catch (e) {
      LoggingService.error('Failed to get product details: $e');
      return null;
    }
  }

  static Future<void> _addToScannedHistory(QRCodeData qrData) async {
    try {
      _scannedHistory.add(qrData);
      
      // Keep only last 1000 QR codes
      if (_scannedHistory.length > 1000) {
        _scannedHistory.removeAt(0);
      }
      
      // Save to cache
      final data = json.encode(_scannedHistory.map((qr) => qr.toJson()).toList());
      await CacheService.cacheData(_cacheKey, data, ttlHours: 24);
    } catch (e) {
      LoggingService.error('Failed to add to scanned history: $e');
    }
  }

  static Future<void> _loadScannedHistory() async {
    try {
      final cachedData = await CacheService.getCachedData(_cacheKey);
      if (cachedData != null) {
        final historyData = json.decode(cachedData);
        _scannedHistory.clear();
        _scannedHistory.addAll(
          (historyData as List).map((item) => QRCodeData.fromJson(item)),
        );
      }
    } catch (e) {
      LoggingService.error('Failed to load scanned history: $e');
    }
  }

  static Future<void> _cacheQRCode(QRCodeData qrData) async {
    try {
      final key = 'qr_${qrData.id}';
      final data = json.encode(qrData.toJson());
      await CacheService.cacheData(key, data, ttlHours: 24);
    } catch (e) {
      LoggingService.error('Failed to cache QR code: $e');
    }
  }

  static Future<void> _loadTemplates() async {
    try {
      // Load templates from cache or create default ones
      final templatesData = await CacheService.getCachedData('qr_templates');
      if (templatesData != null) {
        final data = json.decode(templatesData);
        _templates.clear();
        for (final entry in data.entries) {
          _templates[entry.key] = QRCodeTemplate.fromJson(entry.value);
        }
      }
    } catch (e) {
      LoggingService.error('Failed to load templates: $e');
    }
  }

  static Future<void> _saveTemplates() async {
    try {
      final data = <String, dynamic>{};
      for (final entry in _templates.entries) {
        data[entry.key] = entry.value.toJson();
      }
      await CacheService.cacheData('qr_templates', json.encode(data), ttlHours: 24);
    } catch (e) {
      LoggingService.error('Failed to save templates: $e');
    }
  }

  static Future<void> _initializeDefaultTemplates() async {
    _templates.addAll({
      'product_template': QRCodeTemplate(
        id: 'product_template',
        name: 'Product QR Code',
        description: 'Template for product information QR codes',
        type: QRCodeType.product,
        defaultData: {
          'type': 'product',
          'product_id': '',
          'name': '',
          'price': 0.0,
        },
        options: {'include_image': true},
        size: 200,
        foregroundColor: QRCodeColor.black,
        backgroundColor: QRCodeColor.white,
      ),
      'payment_template': QRCodeTemplate(
        id: 'payment_template',
        name: 'Payment QR Code',
        description: 'Template for payment QR codes',
        type: QRCodeType.payment,
        defaultData: {
          'type': 'payment',
          'amount': 0.0,
          'merchant_id': '',
        },
        options: {'include_logo': true},
        size: 250,
        foregroundColor: QRCodeColor.blue,
        backgroundColor: QRCodeColor.white,
      ),
      'coupon_template': QRCodeTemplate(
        id: 'coupon_template',
        name: 'Coupon QR Code',
        description: 'Template for coupon QR codes',
        type: QRCodeType.coupon,
        defaultData: {
          'type': 'coupon',
          'coupon_code': '',
          'discount_value': 0.0,
        },
        options: {'include_expiry': true},
        size: 200,
        foregroundColor: QRCodeColor.green,
        backgroundColor: QRCodeColor.white,
      ),
    });
    
    await _saveTemplates();
  }

  static String _generateQRId() {
    return 'qr_${DateTime.now().millisecondsSinceEpoch}';
  }

  // Getters
  static bool get isInitialized => _isInitialized;
  static List<QRCodeData> get scannedHistory => List.from(_scannedHistory);
  static bool get isScanning => _scannerSubscription != null;
}

// Data models
class QRCodeData {
  final String id;
  final QRCodeType type;
  final String data;
  final Map<String, dynamic> options;
  final int size;
  final String? logoPath;
  final QRCodeColor foregroundColor;
  final QRCodeColor backgroundColor;
  final Uint8List? imageData;
  final DateTime createdAt;

  QRCodeData({
    required this.id,
    required this.type,
    required this.data,
    required this.options,
    required this.size,
    this.logoPath,
    required this.foregroundColor,
    required this.backgroundColor,
    this.imageData,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.name,
      'data': data,
      'options': options,
      'size': size,
      'logo_path': logoPath,
      'foreground_color': foregroundColor.name,
      'background_color': backgroundColor.name,
      'image_data': imageData?.toList(),
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory QRCodeData.fromJson(Map<String, dynamic> json) {
    return QRCodeData(
      id: json['id'],
      type: QRCodeType.values.firstWhere(
        (t) => t.name == json['type'],
        orElse: () => QRCodeType.text,
      ),
      data: json['data'],
      options: Map<String, dynamic>.from(json['options']),
      size: json['size'],
      logoPath: json['logo_path'],
      foregroundColor: QRCodeColor.values.firstWhere(
        (c) => c.name == json['foreground_color'],
        orElse: () => QRCodeColor.black,
      ),
      backgroundColor: QRCodeColor.values.firstWhere(
        (c) => c.name == json['background_color'],
        orElse: () => QRCodeColor.white,
      ),
      imageData: json['image_data'] != null 
          ? Uint8List.fromList(json['image_data'])
          : null,
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}

class QRCodeTemplate {
  final String id;
  final String name;
  final String description;
  final QRCodeType type;
  final Map<String, dynamic> defaultData;
  final Map<String, dynamic> options;
  final int size;
  final QRCodeColor foregroundColor;
  final QRCodeColor backgroundColor;

  QRCodeTemplate({
    required this.id,
    required this.name,
    required this.description,
    required this.type,
    required this.defaultData,
    required this.options,
    required this.size,
    required this.foregroundColor,
    required this.backgroundColor,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'type': type.name,
      'default_data': defaultData,
      'options': options,
      'size': size,
      'foreground_color': foregroundColor.name,
      'background_color': backgroundColor.name,
    };
  }

  factory QRCodeTemplate.fromJson(Map<String, dynamic> json) {
    return QRCodeTemplate(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      type: QRCodeType.values.firstWhere(
        (t) => t.name == json['type'],
        orElse: () => QRCodeType.text,
      ),
      defaultData: Map<String, dynamic>.from(json['default_data']),
      options: Map<String, dynamic>.from(json['options']),
      size: json['size'],
      foregroundColor: QRCodeColor.values.firstWhere(
        (c) => c.name == json['foreground_color'],
        orElse: () => QRCodeColor.black,
      ),
      backgroundColor: QRCodeColor.values.firstWhere(
        (c) => c.name == json['background_color'],
        orElse: () => QRCodeColor.white,
      ),
    );
  }
}

class QRCodeResult {
  final bool success;
  final QRCodeData? qrCode;
  final String? error;

  QRCodeResult({
    required this.success,
    this.qrCode,
    this.error,
  });
}

class QRScanResult {
  final bool success;
  final bool isContinuous;
  final String? error;

  QRScanResult({
    required this.success,
    required this.isContinuous,
    this.error,
  });
}

class QRProcessResult {
  final bool success;
  final String type;
  final dynamic data;
  final String? error;

  QRProcessResult({
    required this.success,
    required this.type,
    this.data,
    this.error,
  });
}

class QRAnalytics {
  final int totalGenerated;
  final int totalScanned;
  final Map<QRCodeType, int> typeStats;
  final DateTime startDate;
  final DateTime endDate;

  QRAnalytics({
    required this.totalGenerated,
    required this.totalScanned,
    required this.typeStats,
    required this.startDate,
    required this.endDate,
  });
}

enum QRCodeType {
  text,
  url,
  product,
  payment,
  shoppingList,
  coupon,
  contact,
  wifi,
  email,
  phone,
}

enum QRCodeColor {
  black,
  white,
  blue,
  red,
  green,
  purple,
  orange,
}
