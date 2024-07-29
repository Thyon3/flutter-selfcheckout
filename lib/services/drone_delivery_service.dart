import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:selfcheckoutapp/services/logging_service.dart';
import 'package:selfcheckoutapp/services/cache_service.dart';
import 'package:selfcheckoutapp/services/geolocation_service.dart';
import 'package:selfcheckoutapp/services/security_service.dart';

class DroneDeliveryService {
  static const String _baseUrl = 'https://api.drone.scango.app';
  static const String _wsUrl = 'wss://drone.scango.app/ws';
  static const String _apiKey = 'drone_api_key_12345';
  static const String _cacheKey = 'drone_delivery_cache';
  
  static bool _isInitialized = false;
  static bool _isConnected = false;
  static WebSocketChannel? _droneChannel;
  static StreamSubscription? _droneSubscription;
  static final List<Drone> _availableDrones = [];
  static final List<DroneDelivery> _activeDeliveries = [];
  static final List<DroneDelivery> _deliveryHistory = [];
  static StreamController<DroneEvent>? _eventController;

  // Drone delivery service initialization
  static Future<bool> initialize() async {
    try {
      if (_isInitialized) return true;
      
      LoggingService.info('Initializing drone delivery service');
      
      // Initialize event controller
      _eventController = StreamController<DroneEvent>.broadcast();
      
      // Connect to drone service
      await _connectToDroneService();
      
      // Load available drones
      await _loadAvailableDrones();
      
      // Load delivery history
      await _loadDeliveryHistory();
      
      _isInitialized = true;
      
      LoggingService.info('Drone delivery service initialized successfully');
      return true;
    } catch (e) {
      LoggingService.error('Failed to initialize drone delivery service: $e');
      return false;
    }
  }

  // Drone service connection
  static Future<void> _connectToDroneService() async {
    try {
      _droneChannel = WebSocketChannel.connect(Uri.parse('$_wsUrl/service'));
      
      // Authenticate
      final authMessage = {
        'type': 'auth',
        'api_key': _apiKey,
        'timestamp': DateTime.now().toIso8601String(),
      };
      
      _droneChannel!.sink.add(json.encode(authMessage));
      
      // Listen for drone events
      _droneSubscription = _droneChannel!.stream.listen(
        _handleDroneEvent,
        onError: _handleDroneError,
        onDone: _handleDroneDisconnect,
      );
      
      _isConnected = true;
      
      LoggingService.info('Connected to drone delivery service');
    } catch (e) {
      LoggingService.error('Failed to connect to drone service: $e');
      _isConnected = false;
    }
  }

  // Drone management
  static Future<List<Drone>> getAvailableDrones({
    DroneStatus? status,
    DroneType? type,
    double? maxDistance,
  }) async {
    try {
      if (!_isInitialized) {
        await initialize();
      }
      
      var drones = List<Drone>.from(_availableDrones);
      
      if (status != null) {
        drones = drones.where((d) => d.status == status).toList();
      }
      
      if (type != null) {
        drones = drones.where((d) => d.type == type).toList();
      }
      
      if (maxDistance != null) {
        // Filter by distance from current location
        final currentLocation = await GeolocationService.getCurrentLocation();
        if (currentLocation != null) {
          drones = drones.where((d) {
            final distance = Geolocator.distanceBetween(
              currentLocation.latitude,
              currentLocation.longitude,
              d.currentPosition.latitude,
              d.currentPosition.longitude,
            );
            return distance <= maxDistance * 1000; // Convert km to meters
          }).toList();
        }
      }
      
      return drones;
    } catch (e) {
      LoggingService.error('Failed to get available drones: $e');
      return [];
    }
  }

  static Future<Drone?> getBestDroneForDelivery({
    required double pickupLat,
    required double pickupLng,
    required double deliveryLat,
    required double deliveryLng,
    double? packageWeight,
    DroneType? preferredType,
  }) async {
    try {
      final availableDrones = await getAvailableDrones(
        status: DroneStatus.available,
        type: preferredType,
      );
      
      if (availableDrones.isEmpty) {
        return null;
      }
      
      Drone? bestDrone;
      double bestScore = -1;
      
      for (final drone in availableDrones) {
        final score = _calculateDroneScore(
          drone,
          pickupLat,
          pickupLng,
          deliveryLat,
          deliveryLng,
          packageWeight ?? 1.0,
        );
        
        if (score > bestScore) {
          bestScore = score;
          bestDrone = drone;
        }
      }
      
      return bestDrone;
    } catch (e) {
      LoggingService.error('Failed to get best drone for delivery: $e');
      return null;
    }
  }

  static double _calculateDroneScore(
    Drone drone,
    double pickupLat,
    double pickupLng,
    double deliveryLat,
    double deliveryLng,
    double packageWeight,
  ) {
    try {
      double score = 0;
      
      // Distance to pickup
      final pickupDistance = Geolocator.distanceBetween(
        drone.currentPosition.latitude,
        drone.currentPosition.longitude,
        pickupLat,
        pickupLng,
      );
      
      // Distance to delivery
      final deliveryDistance = Geolocator.distanceBetween(
        pickupLat,
        pickupLng,
        deliveryLat,
        deliveryLng,
      );
      
      // Total distance
      final totalDistance = pickupDistance + deliveryDistance;
      
      // Score based on distance (closer is better)
      score += max(0, 100 - (totalDistance / 100)); // Max 100 points
      
      // Score based on battery level
      score += drone.batteryLevel * 0.5; // Max 50 points
      
      // Score based on capacity
      if (packageWeight <= drone.maxCapacity) {
        score += 30; // Full points if can carry
      } else {
        score -= 50; // Penalty if can't carry
      }
      
      // Score based on drone type
      switch (drone.type) {
        case DroneType.cargo:
          score += packageWeight > 2.0 ? 20 : 0; // Bonus for heavy packages
          break;
        case DroneType.speed:
          score += totalDistance > 5000 ? 20 : 0; // Bonus for long distances
          break;
        case DroneType.stealth:
          score += 10; // Small bonus
          break;
      }
      
      return score;
    } catch (e) {
      LoggingService.error('Failed to calculate drone score: $e');
      return 0;
    }
  }

  // Delivery operations
  static Future<DroneDeliveryResult> requestDelivery({
    required String orderId,
    required String customerId,
    required double pickupLat,
    required double pickupLng,
    required String pickupAddress,
    required double deliveryLat,
    required double deliveryLng,
    required String deliveryAddress,
    required double packageWeight,
    required double packageValue,
    DroneType? preferredType,
    DeliveryPriority priority = DeliveryPriority.standard,
    Map<String, dynamic>? packageDetails,
  }) async {
    try {
      if (!_isInitialized) {
        await initialize();
      }
      
      // Find best drone
      final drone = await getBestDroneForDelivery(
        pickupLat: pickupLat,
        pickupLng: pickupLng,
        deliveryLat: deliveryLat,
        deliveryLng: deliveryLng,
        packageWeight: packageWeight,
        preferredType: preferredType,
      );
      
      if (drone == null) {
        return DroneDeliveryResult(
          success: false,
          error: 'No available drones for this delivery',
        );
      }
      
      // Calculate delivery cost
      final cost = await _calculateDeliveryCost(
        drone,
        pickupLat,
        pickupLng,
        deliveryLat,
        deliveryLng,
        packageWeight,
        priority,
      );
      
      // Create delivery
      final delivery = DroneDelivery(
        id: _generateDeliveryId(),
        orderId: orderId,
        customerId: customerId,
        droneId: drone.id,
        pickupLocation: LocationData(
          latitude: pickupLat,
          longitude: pickupLng,
          address: pickupAddress,
          timestamp: DateTime.now(),
        ),
        deliveryLocation: LocationData(
          latitude: deliveryLat,
          longitude: deliveryLng,
          address: deliveryAddress,
          timestamp: DateTime.now(),
        ),
        packageWeight: packageWeight,
        packageValue: packageValue,
        cost: cost,
        priority: priority,
        status: DeliveryStatus.pending,
        packageDetails: packageDetails ?? {},
        createdAt: DateTime.now(),
        estimatedDeliveryTime: DateTime.now().add(Duration(minutes: 30)),
      );
      
      // Assign drone
      drone.status = DroneStatus.assigned;
      drone.currentDeliveryId = delivery.id;
      
      // Add to active deliveries
      _activeDeliveries.add(delivery);
      
      // Send delivery request to drone
      await _sendDeliveryRequest(drone, delivery);
      
      // Update drone status
      delivery.status = DeliveryStatus.assigned;
      delivery.assignedAt = DateTime.now();
      
      // Emit delivery requested event
      _emitEvent(DroneEvent(
        type: DroneEventType.deliveryRequested,
        data: delivery.toJson(),
      ));
      
      LoggingService.info('Drone delivery requested: ${delivery.id}');
      return DroneDeliveryResult(
        success: true,
        delivery: delivery,
        drone: drone,
      );
    } catch (e) {
      LoggingService.error('Failed to request delivery: $e');
      return DroneDeliveryResult(
        success: false,
        error: e.toString(),
      );
    }
  }

  static Future<double> _calculateDeliveryCost(
    Drone drone,
    double pickupLat,
    double pickupLng,
    double deliveryLat,
    double deliveryLng,
    double packageWeight,
    DeliveryPriority priority,
  ) async {
    try {
      // Calculate base cost
      final pickupDistance = Geolocator.distanceBetween(
        drone.currentPosition.latitude,
        drone.currentPosition.longitude,
        pickupLat,
        pickupLng,
      );
      
      final deliveryDistance = Geolocator.distanceBetween(
        pickupLat,
        pickupLng,
        deliveryLat,
        deliveryLng,
      );
      
      final totalDistance = (pickupDistance + deliveryDistance) / 1000; // Convert to km
      
      double baseCost = totalDistance * 50; // Rs 50 per km
      
      // Weight surcharge
      if (packageWeight > 2.0) {
        baseCost += (packageWeight - 2.0) * 20; // Rs 20 per kg over 2kg
      }
      
      // Priority surcharge
      switch (priority) {
        case DeliveryPriority.express:
          baseCost *= 2.0;
          break;
        case DeliveryPriority.priority:
          baseCost *= 1.5;
          break;
        case DeliveryPriority.standard:
          // No change
          break;
      }
      
      // Drone type surcharge
      switch (drone.type) {
        case DroneType.speed:
          baseCost *= 1.2;
          break;
        case DroneType.stealth:
          baseCost *= 1.5;
          break;
        case DroneType.cargo:
          // No change
          break;
      }
      
      return baseCost;
    } catch (e) {
      LoggingService.error('Failed to calculate delivery cost: $e');
      return 0.0;
    }
  }

  static Future<void> _sendDeliveryRequest(Drone drone, DroneDelivery delivery) async {
    try {
      final request = {
        'type': 'delivery_request',
        'drone_id': drone.id,
        'delivery_id': delivery.id,
        'pickup_location': {
          'latitude': delivery.pickupLocation.latitude,
          'longitude': delivery.pickupLocation.longitude,
          'address': delivery.pickupLocation.address,
        },
        'delivery_location': {
          'latitude': delivery.deliveryLocation.latitude,
          'longitude': delivery.deliveryLocation.longitude,
          'address': delivery.deliveryLocation.address,
        },
        'package_weight': delivery.packageWeight,
        'priority': delivery.priority.name,
        'timestamp': DateTime.now().toIso8601String(),
      };
      
      _droneChannel?.sink.add(json.encode(request));
      
      LoggingService.info('Delivery request sent to drone ${drone.id}');
    } catch (e) {
      LoggingService.error('Failed to send delivery request: $e');
    }
  }

  static Future<DroneDeliveryResult> trackDelivery(String deliveryId) async {
    try {
      final delivery = _activeDeliveries.firstWhere(
        (d) => d.id == deliveryId,
        orElse: () => throw Exception('Delivery not found: $deliveryId'),
      );
      
      // Get real-time drone position
      final drone = _availableDrones.firstWhere(
        (d) => d.id == delivery.droneId,
        orElse: () => throw Exception('Drone not found: ${delivery.droneId}'),
      );
      
      delivery.currentPosition = drone.currentPosition;
      delivery.batteryLevel = drone.batteryLevel;
      
      return DroneDeliveryResult(
        success: true,
        delivery: delivery,
        drone: drone,
      );
    } catch (e) {
      LoggingService.error('Failed to track delivery: $e');
      return DroneDeliveryResult(
        success: false,
        error: e.toString(),
      );
    }
  }

  static Future<void> cancelDelivery(String deliveryId) async {
    try {
      final delivery = _activeDeliveries.firstWhere(
        (d) => d.id == deliveryId,
        orElse: () => throw Exception('Delivery not found: $deliveryId'),
      );
      
      // Cancel delivery
      delivery.status = DeliveryStatus.cancelled;
      delivery.cancelledAt = DateTime.now();
      
      // Release drone
      final drone = _availableDrones.firstWhere(
        (d) => d.id == delivery.droneId,
        orElse: () => null,
      );
      
      if (drone != null) {
        drone.status = DroneStatus.available;
        drone.currentDeliveryId = null;
        
        // Send cancel message to drone
        final cancelMessage = {
          'type': 'cancel_delivery',
          'delivery_id': deliveryId,
          'timestamp': DateTime.now().toIso8601String(),
        };
        
        _droneChannel?.sink.add(json.encode(cancelMessage));
      }
      
      // Move to history
      _activeDeliveries.remove(delivery);
      _deliveryHistory.add(delivery);
      
      // Emit delivery cancelled event
      _emitEvent(DroneEvent(
        type: DroneEventType.deliveryCancelled,
        data: delivery.toJson(),
      ));
      
      LoggingService.info('Delivery cancelled: $deliveryId');
    } catch (e) {
      LoggingService.error('Failed to cancel delivery: $e');
    }
  }

  // Event handlers
  static void _handleDroneEvent(dynamic event) {
    try {
      final data = json.decode(event);
      final eventType = data['type'];
      
      switch (eventType) {
        case 'drone_status_update':
          _handleDroneStatusUpdate(data);
          break;
        case 'delivery_status_update':
          _handleDeliveryStatusUpdate(data);
          break;
        case 'drone_position_update':
          _handleDronePositionUpdate(data);
          break;
        case 'delivery_completed':
          _handleDeliveryCompleted(data);
          break;
        case 'emergency_landing':
          _handleEmergencyLanding(data);
          break;
      }
    } catch (e) {
      LoggingService.error('Failed to handle drone event: $e');
    }
  }

  static void _handleDroneStatusUpdate(Map<String, dynamic> data) {
    try {
      final droneId = data['drone_id'];
      final status = DroneStatus.values.firstWhere(
        (s) => s.name == data['status'],
        orElse: () => DroneStatus.available,
      );
      
      final drone = _availableDrones.firstWhere(
        (d) => d.id == droneId,
        orElse: () => null,
      );
      
      if (drone != null) {
        drone.status = status;
        drone.batteryLevel = data['battery_level']?.toDouble() ?? drone.batteryLevel;
        
        _emitEvent(DroneEvent(
          type: DroneEventType.droneStatusUpdated,
          data: data,
        ));
      }
    } catch (e) {
      LoggingService.error('Failed to handle drone status update: $e');
    }
  }

  static void _handleDeliveryStatusUpdate(Map<String, dynamic> data) {
    try {
      final deliveryId = data['delivery_id'];
      final status = DeliveryStatus.values.firstWhere(
        (s) => s.name == data['status'],
        orElse: () => DeliveryStatus.pending,
      );
      
      final delivery = _activeDeliveries.firstWhere(
        (d) => d.id == deliveryId,
        orElse: () => null,
      );
      
      if (delivery != null) {
        delivery.status = status;
        
        switch (status) {
          case DeliveryStatus.inTransit:
            delivery.pickupCompletedAt = DateTime.now();
            break;
          case DeliveryStatus.delivered:
            delivery.deliveredAt = DateTime.now();
            break;
          case DeliveryStatus.failed:
            delivery.failedAt = DateTime.now();
            break;
        }
        
        _emitEvent(DroneEvent(
          type: DroneEventType.deliveryStatusUpdated,
          data: delivery.toJson(),
        ));
      }
    } catch (e) {
      LoggingService.error('Failed to handle delivery status update: $e');
    }
  }

  static void _handleDronePositionUpdate(Map<String, dynamic> data) {
    try {
      final droneId = data['drone_id'];
      final position = LocationData(
        latitude: data['latitude'],
        longitude: data['longitude'],
        altitude: data['altitude']?.toDouble(),
        timestamp: DateTime.parse(data['timestamp']),
      );
      
      final drone = _availableDrones.firstWhere(
        (d) => d.id == droneId,
        orElse: () => null,
      );
      
      if (drone != null) {
        drone.currentPosition = position;
        
        _emitEvent(DroneEvent(
          type: DroneEventType.dronePositionUpdated,
          data: data,
        ));
      }
    } catch (e) {
      LoggingService.error('Failed to handle drone position update: $e');
    }
  }

  static void _handleDeliveryCompleted(Map<String, dynamic> data) {
    try {
      final deliveryId = data['delivery_id'];
      final delivery = _activeDeliveries.firstWhere(
        (d) => d.id == deliveryId,
        orElse: () => null,
      );
      
      if (delivery != null) {
        delivery.status = DeliveryStatus.delivered;
        delivery.deliveredAt = DateTime.now();
        
        // Release drone
        final drone = _availableDrones.firstWhere(
          (d) => d.id == delivery.droneId,
          orElse: () => null,
        );
        
        if (drone != null) {
          drone.status = DroneStatus.available;
          drone.currentDeliveryId = null;
        }
        
        // Move to history
        _activeDeliveries.remove(delivery);
        _deliveryHistory.add(delivery);
        
        _emitEvent(DroneEvent(
          type: DroneEventType.deliveryCompleted,
          data: delivery.toJson(),
        ));
      }
    } catch (e) {
      LoggingService.error('Failed to handle delivery completed: $e');
    }
  }

  static void _handleEmergencyLanding(Map<String, dynamic> data) {
    try {
      final droneId = data['drone_id'];
      final drone = _availableDrones.firstWhere(
        (d) => d.id == droneId,
        orElse: () => null,
      );
      
      if (drone != null) {
        drone.status = DroneStatus.emergency;
        
        // Handle emergency for active delivery
        final delivery = _activeDeliveries.firstWhere(
          (d) => d.droneId == droneId,
          orElse: () => null,
        );
        
        if (delivery != null) {
          delivery.status = DeliveryStatus.failed;
          delivery.failedAt = DateTime.now();
          delivery.failureReason = 'Emergency landing';
          
          // Move to history
          _activeDeliveries.remove(delivery);
          _deliveryHistory.add(delivery);
        }
        
        _emitEvent(DroneEvent(
          type: DroneEventType.emergencyLanding,
          data: data,
        ));
      }
    } catch (e) {
      LoggingService.error('Failed to handle emergency landing: $e');
    }
  }

  static void _handleDroneError(dynamic error) {
    LoggingService.error('Drone service error: $error');
    _emitEvent(DroneEvent(
      type: DroneEventType.error,
      data: {'error': error.toString()},
    ));
  }

  static void _handleDroneDisconnect() {
    LoggingService.info('Drone service disconnected');
    _isConnected = false;
    _emitEvent(DroneEvent(
      type: DroneEventType.serviceDisconnected,
      data: {},
    ));
  }

  static void _emitEvent(DroneEvent event) {
    _eventController?.add(event);
  }

  // Analytics and reporting
  static Future<DroneAnalytics> getAnalytics({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      var deliveries = List<DroneDelivery>.from(_deliveryHistory);
      
      if (startDate != null) {
        deliveries = deliveries.where((d) => d.createdAt.isAfter(startDate)).toList();
      }
      
      if (endDate != null) {
        deliveries = deliveries.where((d) => d.createdAt.isBefore(endDate)).toList();
      }
      
      final totalDeliveries = deliveries.length;
      final successfulDeliveries = deliveries.where((d) => d.status == DeliveryStatus.delivered).length;
      final failedDeliveries = deliveries.where((d) => d.status == DeliveryStatus.failed).length;
      final cancelledDeliveries = deliveries.where((d) => d.status == DeliveryStatus.cancelled).length;
      
      final totalRevenue = deliveries.map((d) => d.cost).fold(0.0, (a, b) => a + b);
      final averageDeliveryTime = _calculateAverageDeliveryTime(deliveries);
      
      final droneTypeStats = <DroneType, int>{};
      for (final delivery in deliveries) {
        final drone = _availableDrones.firstWhere(
          (d) => d.id == delivery.droneId,
          orElse: () => null,
        );
        if (drone != null) {
          droneTypeStats[drone.type] = (droneTypeStats[drone.type] ?? 0) + 1;
        }
      }
      
      return DroneAnalytics(
        totalDeliveries: totalDeliveries,
        successfulDeliveries: successfulDeliveries,
        failedDeliveries: failedDeliveries,
        cancelledDeliveries: cancelledDeliveries,
        totalRevenue: totalRevenue,
        successRate: totalDeliveries > 0 ? (successfulDeliveries / totalDeliveries) * 100 : 0,
        averageDeliveryTime: averageDeliveryTime,
        droneTypeStats: droneTypeStats,
        startDate: startDate ?? DateTime.now().subtract(Duration(days: 30)),
        endDate: endDate ?? DateTime.now(),
      );
    } catch (e) {
      LoggingService.error('Failed to get drone analytics: $e');
      return DroneAnalytics(
        totalDeliveries: 0,
        successfulDeliveries: 0,
        failedDeliveries: 0,
        cancelledDeliveries: 0,
        totalRevenue: 0.0,
        successRate: 0.0,
        averageDeliveryTime: Duration.zero,
        droneTypeStats: {},
        startDate: DateTime.now(),
        endDate: DateTime.now(),
      );
    }
  }

  static Duration _calculateAverageDeliveryTime(List<DroneDelivery> deliveries) {
    try {
      final completedDeliveries = deliveries.where(
        (d) => d.assignedAt != null && d.deliveredAt != null,
      );
      
      if (completedDeliveries.isEmpty) {
        return Duration.zero;
      }
      
      final totalDuration = completedDeliveries
          .map((d) => d.deliveredAt!.difference(d.assignedAt!))
          .fold(Duration.zero, (a, b) => a + b);
      
      return Duration(
        milliseconds: totalDuration.inMilliseconds ~/ completedDeliveries.length,
      );
    } catch (e) {
      LoggingService.error('Failed to calculate average delivery time: $e');
      return Duration.zero;
    }
  }

  // Utility methods
  static Future<void> _loadAvailableDrones() async {
    try {
      // Mock loading available drones
      _availableDrones.addAll([
        Drone(
          id: 'drone_001',
          type: DroneType.cargo,
          model: 'CargoX-2000',
          status: DroneStatus.available,
          currentPosition: LocationData(
            latitude: 6.9271,
            longitude: 79.8612,
            timestamp: DateTime.now(),
          ),
          batteryLevel: 85.0,
          maxCapacity: 5.0,
          maxRange: 50.0,
          currentDeliveryId: null,
          lastMaintenance: DateTime.now().subtract(Duration(days: 7)),
        ),
        Drone(
          id: 'drone_002',
          type: DroneType.speed,
          model: 'SpeedR-500',
          status: DroneStatus.available,
          currentPosition: LocationData(
            latitude: 6.9271,
            longitude: 79.8612,
            timestamp: DateTime.now(),
          ),
          batteryLevel: 92.0,
          maxCapacity: 2.0,
          maxRange: 30.0,
          currentDeliveryId: null,
          lastMaintenance: DateTime.now().subtract(Duration(days: 3)),
        ),
        Drone(
          id: 'drone_003',
          type: DroneType.stealth,
          model: 'Stealth-S100',
          status: DroneStatus.maintenance,
          currentPosition: LocationData(
            latitude: 6.9271,
            longitude: 79.8612,
            timestamp: DateTime.now(),
          ),
          batteryLevel: 45.0,
          maxCapacity: 1.0,
          maxRange: 20.0,
          currentDeliveryId: null,
          lastMaintenance: DateTime.now().subtract(Duration(days: 1)),
        ),
      ]);
    } catch (e) {
      LoggingService.error('Failed to load available drones: $e');
    }
  }

  static Future<void> _loadDeliveryHistory() async {
    try {
      // Load delivery history from cache
      final cachedData = await CacheService.getCachedData(_cacheKey);
      if (cachedData != null) {
        final historyData = json.decode(cachedData);
        _deliveryHistory.clear();
        _deliveryHistory.addAll(
          (historyData as List).map((item) => DroneDelivery.fromJson(item)),
        );
      }
    } catch (e) {
      LoggingService.error('Failed to load delivery history: $e');
    }
  }

  static Future<void> _saveDeliveryHistory() async {
    try {
      final data = json.encode(_deliveryHistory.map((d) => d.toJson()).toList());
      await CacheService.cacheData(_cacheKey, data, ttlHours: 24);
    } catch (e) {
      LoggingService.error('Failed to save delivery history: $e');
    }
  }

  static String _generateDeliveryId() {
    return 'drone_delivery_${DateTime.now().millisecondsSinceEpoch}';
  }

  // Getters
  static bool get isInitialized => _isInitialized;
  static bool get isConnected => _isConnected;
  static List<Drone> get availableDrones => List.from(_availableDrones);
  static List<DroneDelivery> get activeDeliveries => List.from(_activeDeliveries);
  static List<DroneDelivery> get deliveryHistory => List.from(_deliveryHistory);
  static Stream<DroneEvent> get events => _eventController?.stream ?? Stream.empty();
}

// Data models
class Drone {
  final String id;
  final DroneType type;
  final String model;
  DroneStatus status;
  LocationData currentPosition;
  double batteryLevel;
  final double maxCapacity;
  final double maxRange;
  String? currentDeliveryId;
  final DateTime lastMaintenance;

  Drone({
    required this.id,
    required this.type,
    required this.model,
    required this.status,
    required this.currentPosition,
    required this.batteryLevel,
    required this.maxCapacity,
    required this.maxRange,
    this.currentDeliveryId,
    required this.lastMaintenance,
  });
}

class DroneDelivery {
  final String id;
  final String orderId;
  final String customerId;
  final String droneId;
  final LocationData pickupLocation;
  final LocationData deliveryLocation;
  final double packageWeight;
  final double packageValue;
  final double cost;
  final DeliveryPriority priority;
  DeliveryStatus status;
  final Map<String, dynamic> packageDetails;
  final DateTime createdAt;
  final DateTime? assignedAt;
  final DateTime? pickupCompletedAt;
  final DateTime? deliveredAt;
  final DateTime? cancelledAt;
  final DateTime? failedAt;
  final String? failureReason;
  LocationData? currentPosition;
  double? batteryLevel;
  DateTime? estimatedDeliveryTime;

  DroneDelivery({
    required this.id,
    required this.orderId,
    required this.customerId,
    required this.droneId,
    required this.pickupLocation,
    required this.deliveryLocation,
    required this.packageWeight,
    required this.packageValue,
    required this.cost,
    required this.priority,
    required this.status,
    required this.packageDetails,
    required this.createdAt,
    this.assignedAt,
    this.pickupCompletedAt,
    this.deliveredAt,
    this.cancelledAt,
    this.failedAt,
    this.failureReason,
    this.currentPosition,
    this.batteryLevel,
    this.estimatedDeliveryTime,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'order_id': orderId,
      'customer_id': customerId,
      'drone_id': droneId,
      'pickup_location': {
        'latitude': pickupLocation.latitude,
        'longitude': pickupLocation.longitude,
        'address': pickupLocation.address,
      },
      'delivery_location': {
        'latitude': deliveryLocation.latitude,
        'longitude': deliveryLocation.longitude,
        'address': deliveryLocation.address,
      },
      'package_weight': packageWeight,
      'package_value': packageValue,
      'cost': cost,
      'priority': priority.name,
      'status': status.name,
      'package_details': packageDetails,
      'created_at': createdAt.toIso8601String(),
      'assigned_at': assignedAt?.toIso8601String(),
      'pickup_completed_at': pickupCompletedAt?.toIso8601String(),
      'delivered_at': deliveredAt?.toIso8601String(),
      'cancelled_at': cancelledAt?.toIso8601String(),
      'failed_at': failedAt?.toIso8601String(),
      'failure_reason': failureReason,
      'current_position': currentPosition != null ? {
        'latitude': currentPosition!.latitude,
        'longitude': currentPosition!.longitude,
      } : null,
      'battery_level': batteryLevel,
      'estimated_delivery_time': estimatedDeliveryTime?.toIso8601String(),
    };
  }

  factory DroneDelivery.fromJson(Map<String, dynamic> json) {
    return DroneDelivery(
      id: json['id'],
      orderId: json['order_id'],
      customerId: json['customer_id'],
      droneId: json['drone_id'],
      pickupLocation: LocationData(
        latitude: json['pickup_location']['latitude'],
        longitude: json['pickup_location']['longitude'],
        address: json['pickup_location']['address'],
        timestamp: DateTime.now(),
      ),
      deliveryLocation: LocationData(
        latitude: json['delivery_location']['latitude'],
        longitude: json['delivery_location']['longitude'],
        address: json['delivery_location']['address'],
        timestamp: DateTime.now(),
      ),
      packageWeight: json['package_weight'].toDouble(),
      packageValue: json['package_value'].toDouble(),
      cost: json['cost'].toDouble(),
      priority: DeliveryPriority.values.firstWhere(
        (p) => p.name == json['priority'],
        orElse: () => DeliveryPriority.standard,
      ),
      status: DeliveryStatus.values.firstWhere(
        (s) => s.name == json['status'],
        orElse: () => DeliveryStatus.pending,
      ),
      packageDetails: Map<String, dynamic>.from(json['package_details']),
      createdAt: DateTime.parse(json['created_at']),
      assignedAt: json['assigned_at'] != null ? DateTime.parse(json['assigned_at']) : null,
      pickupCompletedAt: json['pickup_completed_at'] != null ? DateTime.parse(json['pickup_completed_at']) : null,
      deliveredAt: json['delivered_at'] != null ? DateTime.parse(json['delivered_at']) : null,
      cancelledAt: json['cancelled_at'] != null ? DateTime.parse(json['cancelled_at']) : null,
      failedAt: json['failed_at'] != null ? DateTime.parse(json['failed_at']) : null,
      failureReason: json['failure_reason'],
      currentPosition: json['current_position'] != null ? LocationData(
        latitude: json['current_position']['latitude'],
        longitude: json['current_position']['longitude'],
        timestamp: DateTime.now(),
      ) : null,
      batteryLevel: json['battery_level']?.toDouble(),
      estimatedDeliveryTime: json['estimated_delivery_time'] != null ? DateTime.parse(json['estimated_delivery_time']) : null,
    );
  }
}

class DroneAnalytics {
  final int totalDeliveries;
  final int successfulDeliveries;
  final int failedDeliveries;
  final int cancelledDeliveries;
  final double totalRevenue;
  final double successRate;
  final Duration averageDeliveryTime;
  final Map<DroneType, int> droneTypeStats;
  final DateTime startDate;
  final DateTime endDate;

  DroneAnalytics({
    required this.totalDeliveries,
    required this.successfulDeliveries,
    required this.failedDeliveries,
    required this.cancelledDeliveries,
    required this.totalRevenue,
    required this.successRate,
    required this.averageDeliveryTime,
    required this.droneTypeStats,
    required this.startDate,
    required this.endDate,
  });
}

class DroneEvent {
  final DroneEventType type;
  final Map<String, dynamic> data;
  final DateTime timestamp;

  DroneEvent({
    required this.type,
    required this.data,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();
}

class DroneDeliveryResult {
  final bool success;
  final DroneDelivery? delivery;
  final Drone? drone;
  final String? error;

  DroneDeliveryResult({
    required this.success,
    this.delivery,
    this.drone,
    this.error,
  });
}

enum DroneType {
  cargo,
  speed,
  stealth,
}

enum DroneStatus {
  available,
  assigned,
  inTransit,
  maintenance,
  emergency,
  offline,
}

enum DeliveryStatus {
  pending,
  assigned,
  inTransit,
  delivered,
  failed,
  cancelled,
}

enum DeliveryPriority {
  standard,
  priority,
  express,
}

enum DroneEventType {
  droneStatusUpdated,
  dronePositionUpdated,
  deliveryRequested,
  deliveryStatusUpdated,
  deliveryCompleted,
  deliveryCancelled,
  emergencyLanding,
  serviceDisconnected,
  error,
}
