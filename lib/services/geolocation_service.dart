import 'dart:async';
import 'dart:convert';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:selfcheckoutapp/services/logging_service.dart';
import 'package:selfcheckoutapp/services/cache_service.dart';
import 'package:selfcheckoutapp/services/security_service.dart';

class GeolocationService {
  static const String _apiKey = 'geolocation_api_key_12345';
  static const String _baseUrl = 'https://api.geolocation.scango.app';
  static const String _cacheKey = 'geolocation_data';
  static const String _locationHistoryKey = 'location_history';
  
  static Position? _currentPosition;
  static LocationData? _currentLocationData;
  static final List<LocationData> _locationHistory = [];
  static StreamSubscription<Position>? _positionStream;
  static bool _isTracking = false;
  static bool _isInitialized = false;

  // Geolocation service initialization
  static Future<bool> initialize() async {
    try {
      if (_isInitialized) return true;
      
      LoggingService.info('Initializing geolocation service');
      
      // Check location permissions
      final hasPermission = await _checkLocationPermission();
      if (!hasPermission) {
        LoggingService.warning('Location permission not granted');
        return false;
      }
      
      // Load cached location data
      await _loadCachedLocationData();
      
      // Load location history
      await _loadLocationHistory();
      
      _isInitialized = true;
      
      LoggingService.info('Geolocation service initialized successfully');
      return true;
    } catch (e) {
      LoggingService.error('Failed to initialize geolocation service: $e');
      return false;
    }
  }

  // Location permission management
  static Future<bool> _checkLocationPermission() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        LoggingService.warning('Location services are disabled');
        return false;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          LoggingService.warning('Location permission denied');
          return false;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        LoggingService.warning('Location permission permanently denied');
        return false;
      }

      return true;
    } catch (e) {
      LoggingService.error('Failed to check location permission: $e');
      return false;
    }
  }

  // Current location
  static Future<LocationData?> getCurrentLocation({
    bool forceRefresh = false,
    LocationAccuracy accuracy = LocationAccuracy.high,
  }) async {
    try {
      if (!_isInitialized) {
        await initialize();
      }

      // Check cache first
      if (!forceRefresh && _currentLocationData != null) {
        final cacheAge = DateTime.now().difference(_currentLocationData!.timestamp);
        if (cacheAge.inMinutes < 5) {
          return _currentLocationData;
        }
      }

      // Get current position
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: accuracy,
        timeLimit: Duration(seconds: 10),
      );

      // Convert to location data
      final locationData = await _convertPositionToLocationData(position);
      
      if (locationData != null) {
        _currentPosition = position;
        _currentLocationData = locationData;
        
        // Cache the location
        await _cacheLocationData(locationData);
        
        // Add to history
        await _addToLocationHistory(locationData);
        
        LoggingService.info('Current location obtained: ${locationData.latitude}, ${locationData.longitude}');
        return locationData;
      }

      return null;
    } catch (e) {
      LoggingService.error('Failed to get current location: $e');
      return null;
    }
  }

  // Location tracking
  static Future<bool> startLocationTracking({
    LocationAccuracy accuracy = LocationAccuracy.high,
    double distanceFilter = 10.0,
  }) async {
    try {
      if (_isTracking) {
        LoggingService.warning('Location tracking already active');
        return true;
      }

      final locationSettings = LocationSettings(
        accuracy: accuracy,
        distanceFilter: distanceFilter,
      );

      _positionStream = Geolocator.getPositionStream(locationSettings: locationSettings)
          .listen(_onPositionChanged);

      _isTracking = true;
      
      LoggingService.info('Started location tracking');
      return true;
    } catch (e) {
      LoggingService.error('Failed to start location tracking: $e');
      return false;
    }
  }

  static Future<void> stopLocationTracking() async {
    try {
      if (!_isTracking) return;
      
      await _positionStream?.cancel();
      _positionStream = null;
      _isTracking = false;
      
      LoggingService.info('Stopped location tracking');
    } catch (e) {
      LoggingService.error('Failed to stop location tracking: $e');
    }
  }

  // Location services
  static Future<List<StoreLocation>> findNearbyStores({
    double radius = 10.0, // km
    String? category,
  }) async {
    try {
      final currentLocation = await getCurrentLocation();
      if (currentLocation == null) {
        return [];
      }

      final response = await http.post(
        Uri.parse('$_baseUrl/stores/nearby'),
        headers: {
          'Authorization': 'Bearer $_apiKey',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'latitude': currentLocation.latitude,
          'longitude': currentLocation.longitude,
          'radius': radius,
          'category': category,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final stores = (data['stores'] as List)
            .map((store) => StoreLocation.fromJson(store))
            .toList();
        
        LoggingService.info('Found ${stores.length} nearby stores');
        return stores;
      }

      return [];
    } catch (e) {
      LoggingService.error('Failed to find nearby stores: $e');
      return [];
    }
  }

  static Future<DirectionsResult?> getDirections({
    required double destinationLat,
    required double destinationLng,
    String? destinationAddress,
    TravelMode travelMode = TravelMode.driving,
  }) async {
    try {
      final currentLocation = await getCurrentLocation();
      if (currentLocation == null) {
        return null;
      }

      final response = await http.post(
        Uri.parse('$_baseUrl/directions'),
        headers: {
          'Authorization': 'Bearer $_apiKey',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'origin': {
            'latitude': currentLocation.latitude,
            'longitude': currentLocation.longitude,
          },
          'destination': {
            'latitude': destinationLat,
            'longitude': destinationLng,
            'address': destinationAddress,
          },
          'travel_mode': travelMode.name,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final directions = DirectionsResult.fromJson(data);
        
        LoggingService.info('Directions obtained: ${directions.distance} km, ${directions.duration}');
        return directions;
      }

      return null;
    } catch (e) {
      LoggingService.error('Failed to get directions: $e');
      return null;
    }
  }

  static Future<AddressData?> reverseGeocode({
    required double latitude,
    required double longitude,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/reverse-geocode'),
        headers: {
          'Authorization': 'Bearer $_apiKey',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'latitude': latitude,
          'longitude': longitude,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final address = AddressData.fromJson(data);
        
        LoggingService.info('Address obtained: ${address.formattedAddress}');
        return address;
      }

      return null;
    } catch (e) {
      LoggingService.error('Failed to reverse geocode: $e');
      return null;
    }
  }

  static Future<LocationData?> geocode({
    required String address,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/geocode'),
        headers: {
          'Authorization': 'Bearer $_apiKey',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'address': address,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final location = LocationData.fromJson(data);
        
        LoggingService.info('Location geocoded: ${location.latitude}, ${location.longitude}');
        return location;
      }

      return null;
    } catch (e) {
      LoggingService.error('Failed to geocode address: $e');
      return null;
    }
  }

  // Location-based features
  static Future<List<StoreLocation>> findStoresByProduct({
    required String productId,
    double radius = 20.0,
  }) async {
    try {
      final currentLocation = await getCurrentLocation();
      if (currentLocation == null) {
        return [];
      }

      final response = await http.post(
        Uri.parse('$_baseUrl/stores/by-product'),
        headers: {
          'Authorization': 'Bearer $_apiKey',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'latitude': currentLocation.latitude,
          'longitude': currentLocation.longitude,
          'product_id': productId,
          'radius': radius,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final stores = (data['stores'] as List)
            .map((store) => StoreLocation.fromJson(store))
            .toList();
        
        LoggingService.info('Found ${stores.length} stores with product $productId');
        return stores;
      }

      return [];
    } catch (e) {
      LoggingService.error('Failed to find stores by product: $e');
      return [];
    }
  }

  static Future<List<DeliveryZone>> getDeliveryZones({
    required double latitude,
    required double longitude,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/delivery-zones'),
        headers: {
          'Authorization': 'Bearer $_apiKey',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'latitude': latitude,
          'longitude': longitude,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final zones = (data['zones'] as List)
            .map((zone) => DeliveryZone.fromJson(zone))
            .toList();
        
        LoggingService.info('Found ${zones.length} delivery zones');
        return zones;
      }

      return [];
    } catch (e) {
      LoggingService.error('Failed to get delivery zones: $e');
      return [];
    }
  }

  static Future<LocationInsights> getLocationInsights() async {
    try {
      final currentLocation = await getCurrentLocation();
      if (currentLocation == null) {
        return LocationInsights(
          city: 'Unknown',
          country: 'Unknown',
          timezone: 'Unknown',
          localTime: DateTime.now(),
          isNearStore: false,
          nearestStoreDistance: 0.0,
          deliveryAvailable: false,
          popularCategories: [],
        );
      }

      final response = await http.post(
        Uri.parse('$_baseUrl/location-insights'),
        headers: {
          'Authorization': 'Bearer $_apiKey',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'latitude': currentLocation.latitude,
          'longitude': currentLocation.longitude,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final insights = LocationInsights.fromJson(data);
        
        LoggingService.info('Location insights obtained: ${insights.city}, ${insights.country}');
        return insights;
      }

      // Return default insights
      return LocationInsights(
        city: 'Unknown',
        country: 'Unknown',
        timezone: 'Unknown',
        localTime: DateTime.now(),
        isNearStore: false,
        nearestStoreDistance: 0.0,
        deliveryAvailable: false,
        popularCategories: [],
      );
    } catch (e) {
      LoggingService.error('Failed to get location insights: $e');
      return LocationInsights(
        city: 'Unknown',
        country: 'Unknown',
        timezone: 'Unknown',
        localTime: DateTime.now(),
        isNearStore: false,
        nearestStoreDistance: 0.0,
        deliveryAvailable: false,
        popularCategories: [],
      );
    }
  }

  // Location history and analytics
  static Future<List<LocationData>> getLocationHistory({
    DateTime? startDate,
    DateTime? endDate,
    int? limit,
  }) async {
    try {
      var history = List<LocationData>.from(_locationHistory);
      
      if (startDate != null) {
        history = history.where((location) => location.timestamp.isAfter(startDate)).toList();
      }
      
      if (endDate != null) {
        history = history.where((location) => location.timestamp.isBefore(endDate)).toList();
      }
      
      history.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      
      if (limit != null && history.length > limit) {
        history = history.take(limit).toList();
      }
      
      return history;
    } catch (e) {
      LoggingService.error('Failed to get location history: $e');
      return [];
    }
  }

  static Future<LocationAnalytics> getLocationAnalytics({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final history = await getLocationHistory(startDate: startDate, endDate: endDate);
      
      if (history.isEmpty) {
        return LocationAnalytics(
          totalLocations: 0,
          averageSpeed: 0.0,
          totalDistance: 0.0,
          mostVisitedAreas: [],
          timeSpentPerArea: {},
          movementPatterns: [],
        );
      }

      // Calculate analytics
      double totalDistance = 0.0;
      double totalSpeed = 0.0;
      final areaVisits = <String, int>{};
      
      for (int i = 1; i < history.length; i++) {
        final prev = history[i - 1];
        final curr = history[i];
        
        // Calculate distance
        final distance = Geolocator.distanceBetween(
          prev.latitude,
          prev.longitude,
          curr.latitude,
          curr.longitude,
        );
        totalDistance += distance;
        
        // Calculate speed
        final timeDiff = curr.timestamp.difference(prev.timestamp).inSeconds;
        if (timeDiff > 0) {
          totalSpeed += distance / timeDiff;
        }
        
        // Count area visits (mock implementation)
        final areaKey = '${curr.latitude.toStringAsFixed(2)},${curr.longitude.toStringAsFixed(2)}';
        areaVisits[areaKey] = (areaVisits[areaKey] ?? 0) + 1;
      }
      
      final mostVisitedAreas = areaVisits.entries
          .toList()
          ..sort((a, b) => b.value.compareTo(a.value))
          ..take(5)
          .map((e) => AreaVisit(
                area: e.key,
                visitCount: e.value,
              ))
          .toList();
      
      return LocationAnalytics(
        totalLocations: history.length,
        averageSpeed: history.length > 1 ? totalSpeed / (history.length - 1) : 0.0,
        totalDistance: totalDistance,
        mostVisitedAreas: mostVisitedAreas,
        timeSpentPerArea: {},
        movementPatterns: [],
      );
    } catch (e) {
      LoggingService.error('Failed to get location analytics: $e');
      return LocationAnalytics(
        totalLocations: 0,
        averageSpeed: 0.0,
        totalDistance: 0.0,
        mostVisitedAreas: [],
        timeSpentPerArea: {},
        movementPatterns: [],
      );
    }
  }

  // Utility methods
  static Future<void> _onPositionChanged(Position position) async {
    try {
      final locationData = await _convertPositionToLocationData(position);
      if (locationData != null) {
        _currentPosition = position;
        _currentLocationData = locationData;
        
        // Cache the location
        await _cacheLocationData(locationData);
        
        // Add to history
        await _addToLocationHistory(locationData);
        
        LoggingService.info('Location updated: ${locationData.latitude}, ${locationData.longitude}');
      }
    } catch (e) {
      LoggingService.error('Failed to handle position change: $e');
    }
  }

  static Future<LocationData> _convertPositionToLocationData(Position position) async {
    try {
      // Get address for the position
      final address = await reverseGeocode(
        latitude: position.latitude,
        longitude: position.longitude,
      );
      
      return LocationData(
        latitude: position.latitude,
        longitude: position.longitude,
        altitude: position.altitude,
        accuracy: position.accuracy,
        speed: position.speed,
        heading: position.heading,
        timestamp: DateTime.now(),
        address: address,
      );
    } catch (e) {
      LoggingService.error('Failed to convert position to location data: $e');
      rethrow;
    }
  }

  static Future<void> _cacheLocationData(LocationData locationData) async {
    try {
      final data = json.encode(locationData.toJson());
      await CacheService.cacheData(_cacheKey, data, ttlMinutes: 5);
    } catch (e) {
      LoggingService.error('Failed to cache location data: $e');
    }
  }

  static Future<void> _loadCachedLocationData() async {
    try {
      final cachedData = await CacheService.getCachedData(_cacheKey);
      if (cachedData != null) {
        final data = json.decode(cachedData);
        _currentLocationData = LocationData.fromJson(data);
      }
    } catch (e) {
      LoggingService.error('Failed to load cached location data: $e');
    }
  }

  static Future<void> _addToLocationHistory(LocationData locationData) async {
    try {
      _locationHistory.add(locationData);
      
      // Keep only last 1000 locations
      if (_locationHistory.length > 1000) {
        _locationHistory.removeAt(0);
      }
      
      // Save to secure storage
      final data = json.encode(_locationHistory.map((l) => l.toJson()).toList());
      await SecurityService.secureStore(_locationHistoryKey, data);
    } catch (e) {
      LoggingService.error('Failed to add location to history: $e');
    }
  }

  static Future<void> _loadLocationHistory() async {
    try {
      final data = await SecurityService.secureRetrieve(_locationHistoryKey);
      if (data != null) {
        final historyData = json.decode(data);
        _locationHistory.clear();
        _locationHistory.addAll(
          (historyData as List).map((item) => LocationData.fromJson(item)),
        );
      }
    } catch (e) {
      LoggingService.error('Failed to load location history: $e');
    }
  }

  static double calculateDistance({
    required double startLat,
    required double startLng,
    required double endLat,
    required double endLng,
  }) {
    return Geolocator.distanceBetween(startLat, startLng, endLat, endLng);
  }

  static bool isLocationWithinRadius({
    required double centerLat,
    required double centerLng,
    required double targetLat,
    required double targetLng,
    required double radius, // in meters
  }) {
    final distance = Geolocator.distanceBetween(
      centerLat,
      centerLng,
      targetLat,
      targetLng,
    );
    return distance <= radius;
  }

  // Getters
  static bool get isInitialized => _isInitialized;
  static bool get isTracking => _isTracking;
  static Position? get currentPosition => _currentPosition;
  static LocationData? get currentLocation => _currentLocationData;
  static List<LocationData> get locationHistory => List.from(_locationHistory);
}

// Data models
class LocationData {
  final double latitude;
  final double longitude;
  final double? altitude;
  final double accuracy;
  final double? speed;
  final double? heading;
  final DateTime timestamp;
  final AddressData? address;

  LocationData({
    required this.latitude,
    required this.longitude,
    this.altitude,
    required this.accuracy,
    this.speed,
    this.heading,
    required this.timestamp,
    this.address,
  });

  factory LocationData.fromJson(Map<String, dynamic> json) {
    return LocationData(
      latitude: json['latitude'].toDouble(),
      longitude: json['longitude'].toDouble(),
      altitude: json['altitude']?.toDouble(),
      accuracy: json['accuracy'].toDouble(),
      speed: json['speed']?.toDouble(),
      heading: json['heading']?.toDouble(),
      timestamp: DateTime.parse(json['timestamp']),
      address: json['address'] != null ? AddressData.fromJson(json['address']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'latitude': latitude,
      'longitude': longitude,
      'altitude': altitude,
      'accuracy': accuracy,
      'speed': speed,
      'heading': heading,
      'timestamp': timestamp.toIso8601String(),
      'address': address?.toJson(),
    };
  }
}

class AddressData {
  final String formattedAddress;
  final String street;
  final String city;
  final String state;
  final String country;
  final String postalCode;
  final String? sublocality;

  AddressData({
    required this.formattedAddress,
    required this.street,
    required this.city,
    required this.state,
    required this.country,
    required this.postalCode,
    this.sublocality,
  });

  factory AddressData.fromJson(Map<String, dynamic> json) {
    return AddressData(
      formattedAddress: json['formatted_address'],
      street: json['street'],
      city: json['city'],
      state: json['state'],
      country: json['country'],
      postalCode: json['postal_code'],
      sublocality: json['sublocality'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'formatted_address': formattedAddress,
      'street': street,
      'city': city,
      'state': state,
      'country': country,
      'postal_code': postalCode,
      'sublocality': sublocality,
    };
  }
}

class StoreLocation {
  final String id;
  final String name;
  final String address;
  final double latitude;
  final double longitude;
  final double distance;
  final String? category;
  final List<String> features;
  final StoreHours? hours;
  final double? rating;
  final String? phoneNumber;

  StoreLocation({
    required this.id,
    required this.name,
    required this.address,
    required this.latitude,
    required this.longitude,
    required this.distance,
    this.category,
    required this.features,
    this.hours,
    this.rating,
    this.phoneNumber,
  });

  factory StoreLocation.fromJson(Map<String, dynamic> json) {
    return StoreLocation(
      id: json['id'],
      name: json['name'],
      address: json['address'],
      latitude: json['latitude'].toDouble(),
      longitude: json['longitude'].toDouble(),
      distance: json['distance'].toDouble(),
      category: json['category'],
      features: List<String>.from(json['features'] ?? []),
      hours: json['hours'] != null ? StoreHours.fromJson(json['hours']) : null,
      rating: json['rating']?.toDouble(),
      phoneNumber: json['phone_number'],
    );
  }
}

class StoreHours {
  final Map<String, String> hours;
  final bool isOpenNow;

  StoreHours({
    required this.hours,
    required this.isOpenNow,
  });

  factory StoreHours.fromJson(Map<String, dynamic> json) {
    return StoreHours(
      hours: Map<String, String>.from(json['hours']),
      isOpenNow: json['is_open_now'],
    );
  }
}

class DirectionsResult {
  final double distance; // in km
  final Duration duration;
  final List<DirectionStep> steps;
  final String? polyline;

  DirectionsResult({
    required this.distance,
    required this.duration,
    required this.steps,
    this.polyline,
  });

  factory DirectionsResult.fromJson(Map<String, dynamic> json) {
    return DirectionsResult(
      distance: json['distance'].toDouble(),
      duration: Duration(seconds: json['duration']),
      steps: (json['steps'] as List)
          .map((step) => DirectionStep.fromJson(step))
          .toList(),
      polyline: json['polyline'],
    );
  }
}

class DirectionStep {
  final String instruction;
  final double distance;
  final Duration duration;
  final String? maneuver;

  DirectionStep({
    required this.instruction,
    required this.distance,
    required this.duration,
    this.maneuver,
  });

  factory DirectionStep.fromJson(Map<String, dynamic> json) {
    return DirectionStep(
      instruction: json['instruction'],
      distance: json['distance'].toDouble(),
      duration: Duration(seconds: json['duration']),
      maneuver: json['maneuver'],
    );
  }
}

class DeliveryZone {
  final String id;
  final String name;
  final double deliveryFee;
  final Duration estimatedDeliveryTime;
  final List<String> postalCodes;

  DeliveryZone({
    required this.id,
    required this.name,
    required this.deliveryFee,
    required this.estimatedDeliveryTime,
    required this.postalCodes,
  });

  factory DeliveryZone.fromJson(Map<String, dynamic> json) {
    return DeliveryZone(
      id: json['id'],
      name: json['name'],
      deliveryFee: json['delivery_fee'].toDouble(),
      estimatedDeliveryTime: Duration(minutes: json['estimated_delivery_time']),
      postalCodes: List<String>.from(json['postal_codes']),
    );
  }
}

class LocationInsights {
  final String city;
  final String country;
  final String timezone;
  final DateTime localTime;
  final bool isNearStore;
  final double nearestStoreDistance;
  final bool deliveryAvailable;
  final List<String> popularCategories;

  LocationInsights({
    required this.city,
    required this.country,
    required this.timezone,
    required this.localTime,
    required this.isNearStore,
    required this.nearestStoreDistance,
    required this.deliveryAvailable,
    required this.popularCategories,
  });

  factory LocationInsights.fromJson(Map<String, dynamic> json) {
    return LocationInsights(
      city: json['city'],
      country: json['country'],
      timezone: json['timezone'],
      localTime: DateTime.parse(json['local_time']),
      isNearStore: json['is_near_store'],
      nearestStoreDistance: json['nearest_store_distance'].toDouble(),
      deliveryAvailable: json['delivery_available'],
      popularCategories: List<String>.from(json['popular_categories']),
    );
  }
}

class LocationAnalytics {
  final int totalLocations;
  final double averageSpeed; // in m/s
  final double totalDistance; // in meters
  final List<AreaVisit> mostVisitedAreas;
  final Map<String, Duration> timeSpentPerArea;
  final List<MovementPattern> movementPatterns;

  LocationAnalytics({
    required this.totalLocations,
    required this.averageSpeed,
    required this.totalDistance,
    required this.mostVisitedAreas,
    required this.timeSpentPerArea,
    required this.movementPatterns,
  });
}

class AreaVisit {
  final String area;
  final int visitCount;

  AreaVisit({
    required this.area,
    required this.visitCount,
  });
}

class MovementPattern {
  final String pattern;
  final double frequency;
  final List<LocationData> samplePoints;

  MovementPattern({
    required this.pattern,
    required this.frequency,
    required this.samplePoints,
  });
}

enum TravelMode {
  driving,
  walking,
  cycling,
  transit,
}
