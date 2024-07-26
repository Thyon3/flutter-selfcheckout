import 'dart:math';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:vector_math/vector_math.dart';
import 'package:selfcheckoutapp/services/logging_service.dart';
import 'package:selfcheckoutapp/models/item.dart';
import 'package:selfcheckoutapp/utils/app_utils.dart';

class ARService {
  static final Map<String, ARObject> _arObjects = {};
  static final Map<String, ARSession> _activeSessions = {};
  static final Map<String, ARMarker> _markers = {};
  
  static bool _isInitialized = false;
  static ARSession? _currentSession;
  static ARCamera? _camera;

  // AR initialization
  static Future<bool> initialize() async {
    try {
      if (_isInitialized) return true;
      
      LoggingService.info('Initializing AR service');
      
      // Check AR availability
      final isAvailable = await _checkARAvailability();
      if (!isAvailable) {
        LoggingService.warning('AR not available on this device');
        return false;
      }
      
      // Initialize camera
      _camera = ARCamera(
        position: Vector3(0, 0, 0),
        rotation: Quaternion.identity(),
        fov: 60.0,
        aspectRatio: 16.0 / 9.0,
        nearPlane: 0.1,
        farPlane: 100.0,
      );
      
      _isInitialized = true;
      
      LoggingService.info('AR service initialized successfully');
      return true;
    } catch (e) {
      LoggingService.error('Failed to initialize AR service: $e');
      return false;
    }
  }

  // Session management
  static Future<String> startSession({
    required ARSessionType type,
    String? sessionId,
    Map<String, dynamic>? configuration,
  }) async {
    try {
      if (!_isInitialized) {
        await initialize();
      }
      
      final id = sessionId ?? _generateSessionId();
      
      final session = ARSession(
        id: id,
        type: type,
        startedAt: DateTime.now(),
        isActive: true,
        configuration: configuration ?? {},
        trackingState: ARTrackingState.initializing,
        objects: [],
        markers: [],
      );
      
      _activeSessions[id] = session;
      _currentSession = session;
      
      // Start AR tracking based on session type
      await _startTracking(session);
      
      LoggingService.info('Started AR session: $id');
      return id;
    } catch (e) {
      LoggingService.error('Failed to start AR session: $e');
      rethrow;
    }
  }

  static Future<void> stopSession(String sessionId) async {
    try {
      final session = _activeSessions[sessionId];
      if (session == null) {
        throw Exception('Session not found: $sessionId');
      }
      
      session.isActive = false;
      session.endedAt = DateTime.now();
      
      if (_currentSession?.id == sessionId) {
        _currentSession = null;
      }
      
      await _stopTracking(session);
      
      LoggingService.info('Stopped AR session: $sessionId');
    } catch (e) {
      LoggingService.error('Failed to stop AR session: $e');
    }
  }

  // Object management
  static Future<String> addObject({
    required String modelPath,
    required Vector3 position,
    required Vector3 rotation,
    required Vector3 scale,
    String? objectId,
    Map<String, dynamic>? properties,
  }) async {
    try {
      final id = objectId ?? _generateObjectId();
      
      final arObject = ARObject(
        id: id,
        modelPath: modelPath,
        position: position,
        rotation: rotation,
        scale: scale,
        isVisible: true,
        properties: properties ?? {},
        createdAt: DateTime.now(),
      );
      
      _arObjects[id] = arObject;
      
      if (_currentSession != null) {
        _currentSession!.objects.add(arObject);
      }
      
      LoggingService.info('Added AR object: $id');
      return id;
    } catch (e) {
      LoggingService.error('Failed to add AR object: $e');
      rethrow;
    }
  }

  static Future<void> updateObject(
    String objectId,
    {
      Vector3? position,
      Vector3? rotation,
      Vector3? scale,
      bool? isVisible,
      Map<String, dynamic>? properties,
    }
  ) async {
    try {
      final arObject = _arObjects[objectId];
      if (arObject == null) {
        throw Exception('AR object not found: $objectId');
      }
      
      arObject.position = position ?? arObject.position;
      arObject.rotation = rotation ?? arObject.rotation;
      arObject.scale = scale ?? arObject.scale;
      arObject.isVisible = isVisible ?? arObject.isVisible;
      
      if (properties != null) {
        arObject.properties.addAll(properties);
      }
      
      arObject.updatedAt = DateTime.now();
      
      LoggingService.info('Updated AR object: $objectId');
    } catch (e) {
      LoggingService.error('Failed to update AR object: $e');
    }
  }

  static Future<void> removeObject(String objectId) async {
    try {
      _arObjects.remove(objectId);
      
      if (_currentSession != null) {
        _currentSession!.objects.removeWhere((obj) => obj.id == objectId);
      }
      
      LoggingService.info('Removed AR object: $objectId');
    } catch (e) {
      LoggingService.error('Failed to remove AR object: $e');
    }
  }

  // Marker management
  static Future<String> addMarker({
    required String barcode,
    required Vector3 position,
    required Vector3 size,
    String? markerId,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final id = markerId ?? _generateMarkerId();
      
      final marker = ARMarker(
        id: id,
        barcode: barcode,
        position: position,
        size: size,
        isDetected: false,
        metadata: metadata ?? {},
        createdAt: DateTime.now(),
      );
      
      _markers[id] = marker;
      
      if (_currentSession != null) {
        _currentSession!.markers.add(marker);
      }
      
      LoggingService.info('Added AR marker: $id');
      return id;
    } catch (e) {
      LoggingService.error('Failed to add AR marker: $e');
      rethrow;
    }
  }

  static Future<void> detectMarkers() async {
    try {
      if (_currentSession == null) {
        throw Exception('No active AR session');
      }
      
      // Simulate marker detection
      await Future.delayed(Duration(milliseconds: 500));
      
      for (final marker in _currentSession!.markers) {
        // Simulate detection probability
        final detectionProbability = Random().nextDouble();
        marker.isDetected = detectionProbability > 0.3;
        marker.lastDetected = marker.isDetected ? DateTime.now() : null;
      }
      
      LoggingService.info('Detected ${_currentSession!.markers.where((m) => m.isDetected).length} markers');
    } catch (e) {
      LoggingService.error('Failed to detect markers: $e');
    }
  }

  // Product visualization
  static Future<String> visualizeProduct({
    required Item product,
    Vector3? position,
    Vector3? rotation,
    Vector3? scale,
    bool showInfo = true,
    bool showPrice = true,
  }) async {
    try {
      final defaultPosition = position ?? Vector3(0, 0, -2.0);
      final defaultRotation = rotation ?? Quaternion.identity();
      final defaultScale = scale ?? Vector3(1.0, 1.0, 1.0);
      
      // Create 3D product object
      final objectId = await addObject(
        modelPath: _getProductModelPath(product),
        position: defaultPosition,
        rotation: defaultRotation.toEuler(),
        scale: defaultScale,
        properties: {
          'product_id': product.barcode,
          'name': product.name,
          'price': product.price,
          'category': product.category,
          'show_info': showInfo,
          'show_price': showPrice,
        },
      );
      
      // Add info panel if requested
      if (showInfo) {
        await _addInfoPanel(objectId, product);
      }
      
      LoggingService.info('Visualized product: ${product.name}');
      return objectId;
    } catch (e) {
      LoggingService.error('Failed to visualize product: $e');
      rethrow;
    }
  }

  static Future<void> _addInfoPanel(String objectId, Item product) async {
    try {
      final infoPosition = Vector3(0, 0.5, 0);
      
      await addObject(
        modelPath: 'assets/ar/models/info_panel.glb',
        position: infoPosition,
        rotation: Vector3(0, 0, 0),
        scale: Vector3(0.3, 0.2, 0.01),
        properties: {
          'type': 'info_panel',
          'product_id': product.barcode,
          'title': product.name,
          'price': AppUtils.formatPrice(product.price),
          'description': product.description ?? '',
        },
      );
    } catch (e) {
      LoggingService.error('Failed to add info panel: $e');
    }
  }

  // Shopping cart visualization
  static Future<List<String>> visualizeShoppingCart({
    required List<Item> items,
    bool animate = true,
    Vector3? centerPosition,
  }) async {
    try {
      final objectIds = <String>[];
      final center = centerPosition ?? Vector3(0, 0, -3.0);
      
      // Arrange items in a grid
      final gridSize = math.ceil(math.sqrt(items.length));
      final spacing = 0.8;
      
      for (int i = 0; i < items.length; i++) {
        final row = i ~/ gridSize;
        final col = i % gridSize;
        
        final position = Vector3(
          center.x + (col - gridSize / 2) * spacing,
          center.y,
          center.z + (row - gridSize / 2) * spacing,
        );
        
        final objectId = await visualizeProduct(
          product: items[i],
          position: position,
          scale: Vector3(0.5, 0.5, 0.5),
        );
        
        objectIds.add(objectId);
        
        // Animate appearance
        if (animate) {
          await _animateObjectAppearance(objectId);
        }
      }
      
      LoggingService.info('Visualized shopping cart with ${items.length} items');
      return objectIds;
    } catch (e) {
      LoggingService.error('Failed to visualize shopping cart: $e');
      rethrow;
    }
  }

  static Future<void> _animateObjectAppearance(String objectId) async {
    try {
      final arObject = _arObjects[objectId];
      if (arObject == null) return;
      
      // Scale animation
      final originalScale = arObject.scale;
      arObject.scale = Vector3(0, 0, 0);
      
      for (double t = 0.0; t <= 1.0; t += 0.1) {
        final easedT = _easeOutElastic(t);
        arObject.scale = originalScale * easedT;
        await Future.delayed(Duration(milliseconds: 50));
      }
      
      arObject.scale = originalScale;
    } catch (e) {
      LoggingService.error('Failed to animate object appearance: $e');
    }
  }

  // Navigation and guidance
  static Future<String> createNavigationPath({
    required List<Vector3> waypoints,
    String? pathId,
    Color color = Colors.blue,
    double width = 0.1,
  }) async {
    try {
      final id = pathId ?? _generatePathId();
      
      // Create path visualization
      for (int i = 0; i < waypoints.length - 1; i++) {
        final start = waypoints[i];
        final end = waypoints[i + 1];
        
        await _createPathSegment(start, end, color, width, '${id}_segment_$i');
      }
      
      LoggingService.info('Created navigation path: $id');
      return id;
    } catch (e) {
      LoggingService.error('Failed to create navigation path: $e');
      rethrow;
    }
  }

  static Future<void> _createPathSegment(
    Vector3 start,
    Vector3 end,
    Color color,
    double width,
    String segmentId,
  ) async {
    try {
      final direction = (end - start).normalized();
      final length = (end - start).length;
      
      final position = start + direction * (length / 2);
      final rotation = Quaternion.fromAxisAngle(Vector3(0, 1, 0), math.atan2(direction.x, direction.z));
      
      await addObject(
        modelPath: 'assets/ar/models/path_segment.glb',
        position: position,
        rotation: rotation.toEuler(),
        scale: Vector3(width, 0.01, length),
        properties: {
          'type': 'path_segment',
          'color': color.value,
          'start': start.storage,
          'end': end.storage,
        },
      );
    } catch (e) {
      LoggingService.error('Failed to create path segment: $e');
    }
  }

  // Interaction handling
  static Future<ARInteraction?> handleTouch({
    required Offset screenPosition,
    required Size screenSize,
  }) async {
    try {
      if (_currentSession == null || _camera == null) {
        return null;
      }
      
      // Convert screen position to world coordinates
      final worldPosition = _screenToWorld(screenPosition, screenSize);
      
      // Check for object intersections
      for (final arObject in _currentSession!.objects) {
        if (_isPointInObject(worldPosition, arObject)) {
          final interaction = ARInteraction(
            type: ARInteractionType.touch,
            objectId: arObject.id,
            position: worldPosition,
            timestamp: DateTime.now(),
          );
          
          LoggingService.info('AR touch interaction: ${arObject.id}');
          return interaction;
        }
      }
      
      return null;
    } catch (e) {
      LoggingService.error('Failed to handle AR touch: $e');
      return null;
    }
  }

  static Future<ARInteraction?> handleGesture({
    required ARGestureType type,
    required Offset startPosition,
    required Offset endPosition,
    required Size screenSize,
  }) async {
    try {
      if (_currentSession == null || _camera == null) {
        return null;
      }
      
      final worldStart = _screenToWorld(startPosition, screenSize);
      final worldEnd = _screenToWorld(endPosition, screenSize);
      
      // Check for object interactions
      for (final arObject in _currentSession!.objects) {
        if (_isPointInObject(worldStart, arObject) || _isPointInObject(worldEnd, arObject)) {
          final interaction = ARInteraction(
            type: _mapGestureType(type),
            objectId: arObject.id,
            position: worldStart,
            endPosition: worldEnd,
            timestamp: DateTime.now(),
          );
          
          LoggingService.info('AR gesture interaction: ${arObject.id}');
          return interaction;
        }
      }
      
      return null;
    } catch (e) {
      LoggingService.error('Failed to handle AR gesture: $e');
      return null;
    }
  }

  // Utility methods
  static Future<bool> _checkARAvailability() async {
    // Mock AR availability check
    return true;
  }

  static Future<void> _startTracking(ARSession session) async {
    // Simulate tracking initialization
    await Future.delayed(Duration(milliseconds: 1000));
    session.trackingState = ARTrackingState.tracking;
  }

  static Future<void> _stopTracking(ARSession session) async {
    session.trackingState = ARTrackingState.stopped;
  }

  static String _getProductModelPath(Item product) {
    // Return appropriate 3D model based on product category
    final category = product.category?.toLowerCase() ?? 'default';
    
    switch (category) {
      case 'vegetables':
        return 'assets/ar/models/vegetable.glb';
      case 'fruits':
        return 'assets/ar/models/fruit.glb';
      case 'dairy':
        return 'assets/ar/models/dairy.glb';
      case 'bakery':
        return 'assets/ar/models/bread.glb';
      default:
        return 'assets/ar/models/default_product.glb';
    }
  }

  static Vector3 _screenToWorld(Offset screenPosition, Size screenSize) {
    // Mock screen to world conversion
    final x = (screenPosition.dx / screenSize.width - 0.5) * 2.0;
    final y = (screenPosition.dy / screenSize.height - 0.5) * -2.0;
    
    return Vector3(x, y, -2.0);
  }

  static bool _isPointInObject(Vector3 point, ARObject object) {
    // Simple bounding box check
    final halfSize = object.scale / 2;
    final min = object.position - halfSize;
    final max = object.position + halfSize;
    
    return point.x >= min.x && point.x <= max.x &&
           point.y >= min.y && point.y <= max.y &&
           point.z >= min.z && point.z <= max.z;
  }

  static ARInteractionType _mapGestureType(ARGestureType gestureType) {
    switch (gestureType) {
      case ARGestureType.tap:
        return ARInteractionType.tap;
      case ARGestureType.doubleTap:
        return ARInteractionType.doubleTap;
      case ARGestureType.longPress:
        return ARInteractionType.longPress;
      case ARGestureType.pan:
        return ARInteractionType.pan;
      case ARGestureType.pinch:
        return ARInteractionType.pinch;
      case ARGestureType.rotate:
        return ARInteractionType.rotate;
    }
  }

  static double _easeOutElastic(double t) {
    final p = 0.3;
    return pow(2, -10 * t) * sin((t - p / 4) * (2 * pi) / p) + 1;
  }

  static String _generateSessionId() {
    return 'ar_session_${DateTime.now().millisecondsSinceEpoch}';
  }

  static String _generateObjectId() {
    return 'ar_object_${DateTime.now().millisecondsSinceEpoch}';
  }

  static String _generateMarkerId() {
    return 'ar_marker_${DateTime.now().millisecondsSinceEpoch}';
  }

  static String _generatePathId() {
    return 'ar_path_${DateTime.now().millisecondsSinceEpoch}';
  }

  // Getters
  static bool get isInitialized => _isInitialized;
  static ARSession? get currentSession => _currentSession;
  static ARCamera? get camera => _camera;
  static List<ARObject> get objects => _arObjects.values.toList();
  static List<ARMarker> get markers => _markers.values.toList();
  static List<ARSession> get sessions => _activeSessions.values.toList();
}

// Data models
class ARSession {
  final String id;
  final ARSessionType type;
  final DateTime startedAt;
  DateTime? endedAt;
  bool isActive;
  ARTrackingState trackingState;
  final Map<String, dynamic> configuration;
  final List<ARObject> objects;
  final List<ARMarker> markers;

  ARSession({
    required this.id,
    required this.type,
    required this.startedAt,
    this.endedAt,
    required this.isActive,
    required this.trackingState,
    required this.configuration,
    required this.objects,
    required this.markers,
  });
}

class ARCamera {
  Vector3 position;
  Quaternion rotation;
  final double fov;
  final double aspectRatio;
  final double nearPlane;
  final double farPlane;

  ARCamera({
    required this.position,
    required this.rotation,
    required this.fov,
    required this.aspectRatio,
    required this.nearPlane,
    required this.farPlane,
  });
}

class ARObject {
  final String id;
  final String modelPath;
  Vector3 position;
  Vector3 rotation;
  Vector3 scale;
  bool isVisible;
  final Map<String, dynamic> properties;
  final DateTime createdAt;
  DateTime? updatedAt;

  ARObject({
    required this.id,
    required this.modelPath,
    required this.position,
    required this.rotation,
    required this.scale,
    required this.isVisible,
    required this.properties,
    required this.createdAt,
    this.updatedAt,
  });
}

class ARMarker {
  final String id;
  final String barcode;
  Vector3 position;
  Vector3 size;
  bool isDetected;
  DateTime? lastDetected;
  final Map<String, dynamic> metadata;
  final DateTime createdAt;

  ARMarker({
    required this.id,
    required this.barcode,
    required this.position,
    required this.size,
    required this.isDetected,
    this.lastDetected,
    required this.metadata,
    required this.createdAt,
  });
}

class ARInteraction {
  final ARInteractionType type;
  final String objectId;
  final Vector3 position;
  final Vector3? endPosition;
  final DateTime timestamp;

  ARInteraction({
    required this.type,
    required this.objectId,
    required this.position,
    this.endPosition,
    required this.timestamp,
  });
}

enum ARSessionType {
  worldTracking,
  faceTracking,
  imageTracking,
  objectTracking,
}

enum ARTrackingState {
  initializing,
  tracking,
  stopped,
  limited,
}

enum ARInteractionType {
  touch,
  tap,
  doubleTap,
  longPress,
  pan,
  pinch,
  rotate,
}

enum ARGestureType {
  tap,
  doubleTap,
  longPress,
  pan,
  pinch,
  rotate,
}
