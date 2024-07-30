import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:selfcheckoutapp/services/logging_service.dart';
import 'package:selfcheckoutapp/services/cache_service.dart';
import 'package:selfcheckoutapp/services/ar_service.dart';

class HolographicDisplayService {
  static const String _baseUrl = 'https://api.holographic.scango.app';
  static const String _apiKey = 'holographic_api_key_12345';
  static const String _cacheKey = 'holographic_cache';
  
  static bool _isInitialized = false;
  static bool _isDisplayActive = false;
  static final Map<String, Hologram> _availableHolograms = {};
  static final List<HologramSession> _activeSessions = [];
  static HologramSession? _currentSession;
  static StreamController<HolographicEvent>? _eventController;

  // Holographic display service initialization
  static Future<bool> initialize() async {
    try {
      if (_isInitialized) return true;
      
      LoggingService.info('Initializing holographic display service');
      
      // Initialize event controller
      _eventController = StreamController<HolographicEvent>.broadcast();
      
      // Initialize holographic hardware
      await _initializeHolographicHardware();
      
      // Load available holograms
      await _loadAvailableHolograms();
      
      _isInitialized = true;
      
      LoggingService.info('Holographic display service initialized successfully');
      return true;
    } catch (e) {
      LoggingService.error('Failed to initialize holographic display service: $e');
      return false;
    }
  }

  // Holographic hardware initialization
  static Future<void> _initializeHolographicHardware() async {
    try {
      // Mock holographic hardware initialization
      await Future.delayed(Duration(seconds: 2));
      
      _isDisplayActive = true;
      
      LoggingService.info('Holographic hardware initialized');
    } catch (e) {
      LoggingService.error('Failed to initialize holographic hardware: $e');
      _isDisplayActive = false;
    }
  }

  // Hologram management
  static Future<HologramResult> createHologram({
    required String hologramId,
    required String name,
    required String description,
    required HologramType type,
    required String modelUrl,
    required String textureUrl,
    HologramQuality quality = HologramQuality.high,
    double scale = 1.0,
    Map<String, dynamic>? properties,
  }) async {
    try {
      if (!_isInitialized) {
        await initialize();
      }
      
      // Create hologram
      final hologram = Hologram(
        id: hologramId,
        name: name,
        description: description,
        type: type,
        modelUrl: modelUrl,
        textureUrl: textureUrl,
        quality: quality,
        scale: scale,
        position: Vector3(0, 0, 0),
        rotation: Vector3(0, 0, 0),
        properties: properties ?? {},
        createdAt: DateTime.now(),
        lastUpdated: DateTime.now(),
        isActive: false,
        isLoaded: false,
      );
      
      // Load hologram data
      await _loadHologramData(hologram);
      
      _availableHolograms[hologramId] = hologram;
      
      // Emit hologram created event
      _emitEvent(HolographicEvent(
        type: HolographicEventType.hologramCreated,
        data: hologram.toJson(),
      ));
      
      LoggingService.info('Hologram created: $hologramId');
      return HologramResult(
        success: true,
        hologram: hologram,
      );
    } catch (e) {
      LoggingService.error('Failed to create hologram: $e');
      return HologramResult(
        success: false,
        error: e.toString(),
      );
    }
  }

  static Future<void> _loadHologramData(Hologram hologram) async {
    try {
      // Mock hologram data loading
      await Future.delayed(Duration(milliseconds: 1500));
      
      hologram.isLoaded = true;
      hologram.lastUpdated = DateTime.now();
      
      LoggingService.info('Hologram data loaded: ${hologram.id}');
    } catch (e) {
      LoggingService.error('Failed to load hologram data: $e');
      hologram.isLoaded = false;
    }
  }

  // Hologram session management
  static Future<HologramSessionResult> startHologramSession({
    required String hologramId,
    HologramMode mode = HologramMode.interactive,
    Map<String, dynamic>? sessionConfig,
  }) async {
    try {
      if (!_isInitialized) {
        await initialize();
      }
      
      if (!_isDisplayActive) {
        return HologramSessionResult(
          success: false,
          error: 'Holographic display not active',
        );
      }
      
      final hologram = _availableHolograms[hologramId];
      if (hologram == null) {
        return HologramSessionResult(
          success: false,
          error: 'Hologram not found: $hologramId',
        );
      }
      
      if (!hologram.isLoaded) {
        return HologramSessionResult(
          success: false,
          error: 'Hologram not loaded: $hologramId',
        );
      }
      
      // Create session
      final session = HologramSession(
        id: _generateSessionId(),
        hologramId: hologramId,
        mode: mode,
        status: SessionStatus.initializing,
        startTime: DateTime.now(),
        endTime: null,
        interactions: [],
        properties: sessionConfig ?? {},
      );
      
      _currentSession = session;
      _activeSessions.add(session);
      
      // Initialize hologram display
      await _initializeHologramDisplay(session);
      
      // Emit session started event
      _emitEvent(HolographicEvent(
        type: HolographicEventType.sessionStarted,
        data: session.toJson(),
      ));
      
      LoggingService.info('Hologram session started: ${session.id}');
      return HologramSessionResult(
        success: true,
        session: session,
      );
    } catch (e) {
      LoggingService.error('Failed to start hologram session: $e');
      return HologramSessionResult(
        success: false,
        error: e.toString(),
      );
    }
  }

  static Future<void> _initializeHologramDisplay(HologramSession session) async {
    try {
      final hologram = _availableHolograms[session.hologramId]!;
      
      // Initialize display based on mode
      switch (session.mode) {
        case HologramMode.interactive:
          await _initializeInteractiveDisplay(hologram, session);
          break;
        case HologramMode.presentation:
          await _initializePresentationDisplay(hologram, session);
          break;
        case HologramMode.demonstration:
          await _initializeDemonstrationDisplay(hologram, session);
          break;
      }
      
      hologram.isActive = true;
      session.status = SessionStatus.active;
      
      LoggingService.info('Hologram display initialized: ${hologram.id}');
    } catch (e) {
      LoggingService.error('Failed to initialize hologram display: $e');
      session.status = SessionStatus.error;
    }
  }

  static Future<void> _initializeInteractiveDisplay(Hologram hologram, HologramSession session) async {
    try {
      // Mock interactive display initialization
      await Future.delayed(Duration(milliseconds: 1000));
      
      // Enable user interactions
      session.properties['interactive'] = true;
      session.properties['touch_enabled'] = true;
      session.properties['gesture_enabled'] = true;
      
      LoggingService.info('Interactive display initialized for: ${hologram.id}');
    } catch (e) {
      LoggingService.error('Failed to initialize interactive display: $e');
    }
  }

  static Future<void> _initializePresentationDisplay(Hologram hologram, HologramSession session) async {
    try {
      // Mock presentation display initialization
      await Future.delayed(Duration(milliseconds: 800));
      
      // Set up presentation mode
      session.properties['auto_rotate'] = true;
      session.properties['show_info'] = true;
      session.properties['timeline_enabled'] = true;
      
      LoggingService.info('Presentation display initialized for: ${hologram.id}');
    } catch (e) {
      LoggingService.error('Failed to initialize presentation display: $e');
    }
  }

  static Future<void> _initializeDemonstrationDisplay(Hologram hologram, HologramSession session) async {
    try {
      // Mock demonstration display initialization
      await Future.delayed(Duration(milliseconds: 1200));
      
      // Set up demonstration mode
      session.properties['auto_play'] = true;
      session.properties['annotations'] = true;
      session.properties['step_by_step'] = true;
      
      LoggingService.info('Demonstration display initialized for: ${hologram.id}');
    } catch (e) {
      LoggingService.error('Failed to initialize demonstration display: $e');
    }
  }

  static Future<void> stopHologramSession() async {
    try {
      if (_currentSession == null) return;
      
      final session = _currentSession!;
      final hologram = _availableHolograms[session.hologramId];
      
      // Stop hologram display
      await _stopHologramDisplay(session);
      
      // Update session status
      session.status = SessionStatus.ended;
      session.endTime = DateTime.now();
      
      if (hologram != null) {
        hologram.isActive = false;
      }
      
      // Remove from active sessions
      _activeSessions.remove(session);
      _currentSession = null;
      
      // Emit session ended event
      _emitEvent(HolographicEvent(
        type: HolographicEventType.sessionEnded,
        data: session.toJson(),
      ));
      
      LoggingService.info('Hologram session stopped: ${session.id}');
    } catch (e) {
      LoggingService.error('Failed to stop hologram session: $e');
    }
  }

  static Future<void> _stopHologramDisplay(HologramSession session) async {
    try {
      // Mock hologram display stop
      await Future.delayed(Duration(milliseconds: 500));
      
      LoggingService.info('Hologram display stopped: ${session.hologramId}');
    } catch (e) {
      LoggingService.error('Failed to stop hologram display: $e');
    }
  }

  // Hologram manipulation
  static Future<bool> updateHologramPosition({
    required Vector3 position,
    Vector3? rotation,
    double? scale,
  }) async {
    try {
      if (_currentSession == null) return false;
      
      final hologram = _availableHolograms[_currentSession!.hologramId];
      if (hologram == null) return false;
      
      // Update hologram position
      hologram.position = position;
      if (rotation != null) {
        hologram.rotation = rotation;
      }
      if (scale != null) {
        hologram.scale = scale;
      }
      
      hologram.lastUpdated = DateTime.now();
      
      // Record interaction
      final interaction = HologramInteraction(
        id: _generateInteractionId(),
        type: InteractionType.position,
        timestamp: DateTime.now(),
        data: {
          'position': position.toJson(),
          'rotation': rotation?.toJson(),
          'scale': scale,
        },
      );
      
      _currentSession!.interactions.add(interaction);
      
      // Emit position updated event
      _emitEvent(HolographicEvent(
        type: HolographicEventType.positionUpdated,
        data: {
          'hologram_id': hologram.id,
          'position': position.toJson(),
          'rotation': rotation?.toJson(),
          'scale': scale,
        },
      ));
      
      LoggingService.info('Hologram position updated: ${hologram.id}');
      return true;
    } catch (e) {
      LoggingService.error('Failed to update hologram position: $e');
      return false;
    }
  }

  static Future<bool> updateHologramProperties({
    required Map<String, dynamic> properties,
  }) async {
    try {
      if (_currentSession == null) return false;
      
      final hologram = _availableHolograms[_currentSession!.hologramId];
      if (hologram == null) return false;
      
      // Update hologram properties
      hologram.properties.addAll(properties);
      hologram.lastUpdated = DateTime.now();
      
      // Record interaction
      final interaction = HologramInteraction(
        id: _generateInteractionId(),
        type: InteractionType.properties,
        timestamp: DateTime.now(),
        data: properties,
      );
      
      _currentSession!.interactions.add(interaction);
      
      // Emit properties updated event
      _emitEvent(HolographicEvent(
        type: HolographicEventType.propertiesUpdated,
        data: {
          'hologram_id': hologram.id,
          'properties': properties,
        },
      ));
      
      LoggingService.info('Hologram properties updated: ${hologram.id}');
      return true;
    } catch (e) {
      LoggingService.error('Failed to update hologram properties: $e');
      return false;
    }
  }

  // Product holograms
  static Future<HologramResult> createProductHologram({
    required String productId,
    required String productName,
    required String modelUrl,
    required String textureUrl,
    List<String>? features,
    Map<String, dynamic>? productDetails,
  }) async {
    try {
      final hologramId = 'product_$productId';
      
      return await createHologram(
        hologramId: hologramId,
        name: productName,
        description: 'Interactive 3D hologram of $productName',
        type: HologramType.product,
        modelUrl: modelUrl,
        textureUrl: textureUrl,
        quality: HologramQuality.ultra,
        scale: 1.0,
        properties: {
          'product_id': productId,
          'product_name': productName,
          'features': features ?? [],
          'product_details': productDetails ?? {},
          'interactive': true,
          'rotatable': true,
          'scalable': true,
          'annotations': true,
        },
      );
    } catch (e) {
      LoggingService.error('Failed to create product hologram: $e');
      return HologramResult(
        success: false,
        error: e.toString(),
      );
    }
  }

  static Future<HologramSessionResult> startProductShowcase({
    required String productId,
    required String productName,
    HologramMode mode = HologramMode.interactive,
    Map<String, dynamic>? showcaseConfig,
  }) async {
    try {
      final hologramId = 'product_$productId';
      
      // Create product hologram if it doesn't exist
      if (!_availableHolograms.containsKey(hologramId)) {
        final result = await createProductHologram(
          productId: productId,
          productName: productName,
          modelUrl: 'https://api.holographic.scango.app/models/$productId.glb',
          textureUrl: 'https://api.holographic.scango.app/textures/$productId.jpg',
        );
        
        if (!result.success) {
          return HologramSessionResult(
            success: false,
            error: 'Failed to create product hologram',
          );
        }
      }
      
      // Start showcase session
      final sessionConfig = {
        'showcase_mode': true,
        'auto_rotate': true,
        'show_features': true,
        'enable_zoom': true,
        'product_info': true,
        ...?showcaseConfig,
      };
      
      return await startHologramSession(
        hologramId: hologramId,
        mode: mode,
        sessionConfig: sessionConfig,
      );
    } catch (e) {
      LoggingService.error('Failed to start product showcase: $e');
      return HologramSessionResult(
        success: false,
        error: e.toString(),
      );
    }
  }

  // Shopping cart hologram
  static Future<HologramResult> createShoppingCartHologram({
    required List<Map<String, dynamic>> cartItems,
    Map<String, dynamic>? cartConfig,
  }) async {
    try {
      final hologramId = 'shopping_cart_${DateTime.now().millisecondsSinceEpoch}';
      
      return await createHologram(
        hologramId: hologramId,
        name: 'Shopping Cart',
        description: 'Interactive 3D shopping cart hologram',
        type: HologramType.shoppingCart,
        modelUrl: 'https://api.holographic.scango.app/models/shopping_cart.glb',
        textureUrl: 'https://api.holographic.scango.app/textures/shopping_cart.jpg',
        quality: HologramQuality.high,
        scale: 0.8,
        properties: {
          'cart_items': cartItems,
          'total_items': cartItems.length,
          'interactive': true,
          'item_selection': true,
          'quantity_adjustment': true,
          'cart_config': cartConfig ?? {},
        },
      );
    } catch (e) {
      LoggingService.error('Failed to create shopping cart hologram: $e');
      return HologramResult(
        success: false,
        error: e.toString(),
      );
    }
  }

  // User interactions
  static Future<bool> handleUserInteraction({
    required InteractionType type,
    required Map<String, dynamic> interactionData,
  }) async {
    try {
      if (_currentSession == null) return false;
      
      // Record interaction
      final interaction = HologramInteraction(
        id: _generateInteractionId(),
        type: type,
        timestamp: DateTime.now(),
        data: interactionData,
      );
      
      _currentSession!.interactions.add(interaction);
      
      // Handle different interaction types
      switch (type) {
        case InteractionType.touch:
          await _handleTouchInteraction(interaction);
          break;
        case InteractionType.gesture:
          await _handleGestureInteraction(interaction);
          break;
        case InteractionType.voice:
          await _handleVoiceInteraction(interaction);
          break;
        case InteractionType.selection:
          await _handleSelectionInteraction(interaction);
          break;
      }
      
      // Emit interaction event
      _emitEvent(HolographicEvent(
        type: HolographicEventType.userInteraction,
        data: interaction.toJson(),
      ));
      
      LoggingService.info('User interaction handled: ${type.name}');
      return true;
    } catch (e) {
      LoggingService.error('Failed to handle user interaction: $e');
      return false;
    }
  }

  static Future<void> _handleTouchInteraction(HologramInteraction interaction) async {
    try {
      // Mock touch interaction handling
      await Future.delayed(Duration(milliseconds: 100));
      
      final touchData = interaction.data;
      final hologram = _availableHolograms[_currentSession!.hologramId];
      
      if (hologram != null) {
        // Update hologram based on touch
        if (touchData['action'] == 'rotate') {
          hologram.rotation = Vector3(
            hologram.rotation.x + (touchData['delta_x'] ?? 0.0),
            hologram.rotation.y + (touchData['delta_y'] ?? 0.0),
            hologram.rotation.z + (touchData['delta_z'] ?? 0.0),
          );
        } else if (touchData['action'] == 'scale') {
          hologram.scale *= (touchData['scale_factor'] ?? 1.0);
        }
        
        hologram.lastUpdated = DateTime.now();
      }
    } catch (e) {
      LoggingService.error('Failed to handle touch interaction: $e');
    }
  }

  static Future<void> _handleGestureInteraction(HologramInteraction interaction) async {
    try {
      // Mock gesture interaction handling
      await Future.delayed(Duration(milliseconds: 150));
      
      final gestureData = interaction.data;
      final hologram = _availableHolograms[_currentSession!.hologramId];
      
      if (hologram != null) {
        // Update hologram based on gesture
        if (gestureData['gesture'] == 'swipe') {
          hologram.position = Vector3(
            hologram.position.x + (gestureData['delta_x'] ?? 0.0),
            hologram.position.y + (gestureData['delta_y'] ?? 0.0),
            hologram.position.z + (gestureData['delta_z'] ?? 0.0),
          );
        } else if (gestureData['gesture'] == 'pinch') {
          hologram.scale *= (gestureData['scale_factor'] ?? 1.0);
        }
        
        hologram.lastUpdated = DateTime.now();
      }
    } catch (e) {
      LoggingService.error('Failed to handle gesture interaction: $e');
    }
  }

  static Future<void> _handleVoiceInteraction(HologramInteraction interaction) async {
    try {
      // Mock voice interaction handling
      await Future.delayed(Duration(milliseconds: 200));
      
      final voiceData = interaction.data;
      final hologram = _availableHolograms[_currentSession!.hologramId];
      
      if (hologram != null) {
        // Update hologram based on voice command
        if (voiceData['command'] == 'rotate') {
          hologram.rotation = Vector3(
            hologram.rotation.x + (voiceData['angle_x'] ?? 0.0),
            hologram.rotation.y + (voiceData['angle_y'] ?? 0.0),
            hologram.rotation.z + (voiceData['angle_z'] ?? 0.0),
          );
        } else if (voiceData['command'] == 'scale') {
          hologram.scale *= (voiceData['scale_factor'] ?? 1.0);
        }
        
        hologram.lastUpdated = DateTime.now();
      }
    } catch (e) {
      LoggingService.error('Failed to handle voice interaction: $e');
    }
  }

  static Future<void> _handleSelectionInteraction(HologramInteraction interaction) async {
    try {
      // Mock selection interaction handling
      await Future.delayed(Duration(milliseconds: 100));
      
      final selectionData = interaction.data;
      final hologram = _availableHolograms[_currentSession!.hologramId];
      
      if (hologram != null && hologram.type == HologramType.product) {
        // Handle product selection
        final productId = selectionData['product_id'];
        if (productId != null) {
          hologram.properties['selected_product'] = productId;
          hologram.lastUpdated = DateTime.now();
        }
      }
    } catch (e) {
      LoggingService.error('Failed to handle selection interaction: $e');
    }
  }

  // Analytics and insights
  static Future<HolographicAnalytics> getAnalytics({
    DateTime? startDate,
    DateTime? endDate,
    String? hologramId,
  }) async {
    try {
      var sessions = List<HologramSession>.from(_activeSessions);
      
      if (startDate != null) {
        sessions = sessions.where((s) => s.startTime.isAfter(startDate)).toList();
      }
      
      if (endDate != null) {
        sessions = sessions.where((s) => s.startTime.isBefore(endDate)).toList();
      }
      
      if (hologramId != null) {
        sessions = sessions.where((s) => s.hologramId == hologramId).toList();
      }
      
      final modeStats = <HologramMode, int>{};
      final interactionTypeStats = <InteractionType, int>{};
      final hologramTypeStats = <HologramType, int>{};
      
      int totalInteractions = 0;
      Duration totalSessionTime = Duration.zero;
      
      for (final session in sessions) {
        modeStats[session.mode] = (modeStats[session.mode] ?? 0) + 1;
        
        final hologram = _availableHolograms[session.hologramId];
        if (hologram != null) {
          hologramTypeStats[hologram.type] = (hologramTypeStats[hologram.type] ?? 0) + 1;
        }
        
        totalInteractions += session.interactions.length;
        for (final interaction in session.interactions) {
          interactionTypeStats[interaction.type] = (interactionTypeStats[interaction.type] ?? 0) + 1;
        }
        
        if (session.endTime != null) {
          totalSessionTime += session.endTime!.difference(session.startTime);
        }
      }
      
      return HolographicAnalytics(
        totalSessions: sessions.length,
        totalInteractions: totalInteractions,
        averageSessionTime: sessions.isNotEmpty 
            ? Duration(milliseconds: totalSessionTime.inMilliseconds ~/ sessions.length)
            : Duration.zero,
        modeStats: modeStats,
        interactionTypeStats: interactionTypeStats,
        hologramTypeStats: hologramTypeStats,
        startDate: startDate ?? DateTime.now().subtract(Duration(days: 30)),
        endDate: endDate ?? DateTime.now(),
      );
    } catch (e) {
      LoggingService.error('Failed to get holographic analytics: $e');
      return HolographicAnalytics(
        totalSessions: 0,
        totalInteractions: 0,
        averageSessionTime: Duration.zero,
        modeStats: {},
        interactionTypeStats: {},
        hologramTypeStats: {},
        startDate: DateTime.now(),
        endDate: DateTime.now(),
      );
    }
  }

  // Event handling
  static void _emitEvent(HolographicEvent event) {
    _eventController?.add(event);
  }

  // Data loading
  static Future<void> _loadAvailableHolograms() async {
    try {
      // Mock loading available holograms
      _availableHolograms.addAll([
        Hologram(
          id: 'demo_product_1',
          name: 'iPhone 15 Pro',
          description: 'Interactive iPhone 15 Pro hologram',
          type: HologramType.product,
          modelUrl: 'https://api.holographic.scango.app/models/iphone_15_pro.glb',
          textureUrl: 'https://api.holographic.scango.app/textures/iphone_15_pro.jpg',
          quality: HologramQuality.ultra,
          scale: 1.0,
          position: Vector3(0, 0, 0),
          rotation: Vector3(0, 0, 0),
          properties: {
            'product_id': 'iphone_15_pro',
            'brand': 'Apple',
            'features': ['5G', 'Pro Camera', 'A17 Chip'],
            'price': 999.99,
          },
          createdAt: DateTime.now().subtract(Duration(days: 7)),
          lastUpdated: DateTime.now().subtract(Duration(days: 7)),
          isActive: false,
          isLoaded: true,
        ),
        Hologram(
          id: 'demo_product_2',
          name: 'Nike Air Max',
          description: 'Interactive Nike Air Max hologram',
          type: HologramType.product,
          modelUrl: 'https://api.holographic.scango.app/models/nike_air_max.glb',
          textureUrl: 'https://api.holographic.scango.app/textures/nike_air_max.jpg',
          quality: HologramQuality.high,
          scale: 1.2,
          position: Vector3(0, 0, 0),
          rotation: Vector3(0, 0, 0),
          properties: {
            'product_id': 'nike_air_max',
            'brand': 'Nike',
            'features': ['Air Cushioning', 'Lightweight', 'Breathable'],
            'price': 150.00,
          },
          createdAt: DateTime.now().subtract(Duration(days: 5)),
          lastUpdated: DateTime.now().subtract(Duration(days: 5)),
          isActive: false,
          isLoaded: true,
        ),
      ]);
    } catch (e) {
      LoggingService.error('Failed to load available holograms: $e');
    }
  }

  // Utility methods
  static String _generateSessionId() {
    return 'hologram_session_${DateTime.now().millisecondsSinceEpoch}';
  }

  static String _generateInteractionId() {
    return 'interaction_${DateTime.now().millisecondsSinceEpoch}';
  }

  // Getters
  static bool get isInitialized => _isInitialized;
  static bool get isDisplayActive => _isDisplayActive;
  static Map<String, Hologram> get availableHolograms => Map.from(_availableHolograms);
  static List<HologramSession> get activeSessions => List.from(_activeSessions);
  static HologramSession? get currentSession => _currentSession;
  static Stream<HolographicEvent> get events => _eventController?.stream ?? Stream.empty();
}

// Data models
class Hologram {
  final String id;
  final String name;
  final String description;
  final HologramType type;
  final String modelUrl;
  final String textureUrl;
  final HologramQuality quality;
  double scale;
  Vector3 position;
  Vector3 rotation;
  final Map<String, dynamic> properties;
  final DateTime createdAt;
  DateTime lastUpdated;
  bool isActive;
  bool isLoaded;

  Hologram({
    required this.id,
    required this.name,
    required this.description,
    required this.type,
    required this.modelUrl,
    required this.textureUrl,
    required this.quality,
    required this.scale,
    required this.position,
    required this.rotation,
    required this.properties,
    required this.createdAt,
    required this.lastUpdated,
    required this.isActive,
    required this.isLoaded,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'type': type.name,
      'model_url': modelUrl,
      'texture_url': textureUrl,
      'quality': quality.name,
      'scale': scale,
      'position': position.toJson(),
      'rotation': rotation.toJson(),
      'properties': properties,
      'created_at': createdAt.toIso8601String(),
      'last_updated': lastUpdated.toIso8601String(),
      'is_active': isActive,
      'is_loaded': isLoaded,
    };
  }
}

class HologramSession {
  final String id;
  final String hologramId;
  final HologramMode mode;
  SessionStatus status;
  final DateTime startTime;
  final DateTime? endTime;
  final List<HologramInteraction> interactions;
  final Map<String, dynamic> properties;

  HologramSession({
    required this.id,
    required this.hologramId,
    required this.mode,
    required this.status,
    required this.startTime,
    this.endTime,
    required this.interactions,
    required this.properties,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'hologram_id': hologramId,
      'mode': mode.name,
      'status': status.name,
      'start_time': startTime.toIso8601String(),
      'end_time': endTime?.toIso8601String(),
      'interactions': interactions.map((i) => i.toJson()).toList(),
      'properties': properties,
    };
  }
}

class HologramInteraction {
  final String id;
  final InteractionType type;
  final DateTime timestamp;
  final Map<String, dynamic> data;

  HologramInteraction({
    required this.id,
    required this.type,
    required this.timestamp,
    required this.data,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.name,
      'timestamp': timestamp.toIso8601String(),
      'data': data,
    };
  }
}

class HolographicAnalytics {
  final int totalSessions;
  final int totalInteractions;
  final Duration averageSessionTime;
  final Map<HologramMode, int> modeStats;
  final Map<InteractionType, int> interactionTypeStats;
  final Map<HologramType, int> hologramTypeStats;
  final DateTime startDate;
  final DateTime endDate;

  HolographicAnalytics({
    required this.totalSessions,
    required this.totalInteractions,
    required this.averageSessionTime,
    required this.modeStats,
    required this.interactionTypeStats,
    required this.hologramTypeStats,
    required this.startDate,
    required this.endDate,
  });
}

class HolographicEvent {
  final HolographicEventType type;
  final Map<String, dynamic> data;
  final DateTime timestamp;

  HolographicEvent({
    required this.type,
    required this.data,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();
}

class HologramResult {
  final bool success;
  final Hologram? hologram;
  final String? error;

  HologramResult({
    required this.success,
    this.hologram,
    this.error,
  });
}

class HologramSessionResult {
  final bool success;
  final HologramSession? session;
  final String? error;

  HologramSessionResult({
    required this.success,
    this.session,
    this.error,
  });
}

class Vector3 {
  final double x;
  final double y;
  final double z;

  Vector3(this.x, this.y, this.z);

  Map<String, dynamic> toJson() {
    return {
      'x': x,
      'y': y,
      'z': z,
    };
  }

  factory Vector3.fromJson(Map<String, dynamic> json) {
    return Vector3(
      json['x'].toDouble(),
      json['y'].toDouble(),
      json['z'].toDouble(),
    );
  }
}

enum HologramType {
  product,
  shoppingCart,
  environment,
  character,
  text,
  data,
}

enum HologramQuality {
  low,
  medium,
  high,
  ultra,
}

enum HologramMode {
  interactive,
  presentation,
  demonstration,
}

enum SessionStatus {
  initializing,
  active,
  paused,
  error,
  ended,
}

enum InteractionType {
  touch,
  gesture,
  voice,
  selection,
  position,
  properties,
}

enum HolographicEventType {
  hologramCreated,
  sessionStarted,
  sessionEnded,
  positionUpdated,
  propertiesUpdated,
  userInteraction,
  error,
}
