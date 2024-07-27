import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:selfcheckoutapp/services/logging_service.dart';
import 'package:selfcheckoutapp/services/security_service.dart';

class IoTService {
  static final Map<String, IoTDevice> _devices = {};
  static final Map<String, IoTGateway> _gateways = {};
  static final Map<String, StreamSubscription<IoTData>> _subscriptions = {};
  static final Map<String, List<IoTData>> _dataHistory = {};
  
  static WebSocketChannel? _mqttChannel;
  static bool _isConnected = false;
  static String? _currentGatewayId;

  // IoT service initialization
  static Future<bool> initialize({
    String? serverUrl,
    String? apiKey,
  }) async {
    try {
      if (_isConnected) return true;
      
      LoggingService.info('Initializing IoT service');
      
      final url = serverUrl ?? 'wss://iot.scango.app/mqtt';
      final key = apiKey ?? 'iot_api_key_12345';
      
      // Connect to MQTT broker
      _mqttChannel = WebSocketChannel.connect(Uri.parse(url));
      
      // Send authentication
      await _authenticate(key);
      
      // Start listening for messages
      _mqttChannel!.stream.listen(
        _handleMessage,
        onError: _handleError,
        onDone: _handleDisconnect,
      );
      
      _isConnected = true;
      
      // Discover existing devices
      await _discoverDevices();
      
      LoggingService.info('IoT service initialized successfully');
      return true;
    } catch (e) {
      LoggingService.error('Failed to initialize IoT service: $e');
      return false;
    }
  }

  // Device management
  static Future<String> registerDevice({
    required String deviceId,
    required String deviceType,
    required String name,
    required String gatewayId,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final device = IoTDevice(
        id: deviceId,
        type: deviceType,
        name: name,
        gatewayId: gatewayId,
        status: IoTDeviceStatus.offline,
        metadata: metadata ?? {},
        registeredAt: DateTime.now(),
        lastSeen: DateTime.now(),
      );
      
      _devices[deviceId] = device;
      
      // Register with gateway
      await _registerWithGateway(device);
      
      LoggingService.info('Registered IoT device: $deviceId');
      return deviceId;
    } catch (e) {
      LoggingService.error('Failed to register device: $e');
      rethrow;
    }
  }

  static Future<void> unregisterDevice(String deviceId) async {
    try {
      final device = _devices[deviceId];
      if (device == null) {
        throw Exception('Device not found: $deviceId');
      }
      
      // Unregister from gateway
      await _unregisterFromGateway(device);
      
      _devices.remove(deviceId);
      _dataHistory.remove(deviceId);
      
      LoggingService.info('Unregistered IoT device: $deviceId');
    } catch (e) {
      LoggingService.error('Failed to unregister device: $e');
    }
  }

  static Future<List<IoTDevice>> getDevices({String? gatewayId}) async {
    if (gatewayId != null) {
      return _devices.values.where((device) => device.gatewayId == gatewayId).toList();
    }
    return _devices.values.toList();
  }

  // Gateway management
  static Future<String> addGateway({
    required String gatewayId,
    required String name,
    required String location,
    required String ipAddress,
    int port = 1883,
    Map<String, dynamic>? configuration,
  }) async {
    try {
      final gateway = IoTGateway(
        id: gatewayId,
        name: name,
        location: location,
        ipAddress: ipAddress,
        port: port,
        status: IoTGatewayStatus.online,
        configuration: configuration ?? {},
        addedAt: DateTime.now(),
        connectedDevices: [],
      );
      
      _gateways[gatewayId] = gateway;
      _currentGatewayId = gatewayId;
      
      // Connect to gateway
      await _connectToGateway(gateway);
      
      LoggingService.info('Added IoT gateway: $gatewayId');
      return gatewayId;
    } catch (e) {
      LoggingService.error('Failed to add gateway: $e');
      rethrow;
    }
  }

  static Future<void> removeGateway(String gatewayId) async {
    try {
      final gateway = _gateways[gatewayId];
      if (gateway == null) {
        throw Exception('Gateway not found: $gatewayId');
      }
      
      // Disconnect from gateway
      await _disconnectFromGateway(gateway);
      
      _gateways.remove(gatewayId);
      
      if (_currentGatewayId == gatewayId) {
        _currentGatewayId = null;
      }
      
      LoggingService.info('Removed IoT gateway: $gatewayId');
    } catch (e) {
      LoggingService.error('Failed to remove gateway: $e');
    }
  }

  // Device control
  static Future<void> sendCommand({
    required String deviceId,
    required String command,
    Map<String, dynamic>? parameters,
  }) async {
    try {
      final device = _devices[deviceId];
      if (device == null) {
        throw Exception('Device not found: $deviceId');
      }
      
      final message = {
        'type': 'command',
        'device_id': deviceId,
        'command': command,
        'parameters': parameters ?? {},
        'timestamp': DateTime.now().toIso8601String(),
      };
      
      await _sendMessage(message);
      
      LoggingService.info('Sent command to device $deviceId: $command');
    } catch (e) {
      LoggingService.error('Failed to send command: $e');
      rethrow;
    }
  }

  // Smart shelf management
  static Future<String> addSmartShelf({
    required String shelfId,
    required String location,
    required List<String> productIds,
    int capacity = 100,
    Map<String, dynamic>? configuration,
  }) async {
    try {
      final deviceId = 'shelf_$shelfId';
      
      await registerDevice(
        deviceId: deviceId,
        deviceType: 'smart_shelf',
        name: 'Smart Shelf $shelfId',
        gatewayId: _currentGatewayId ?? 'default_gateway',
        metadata: {
          'location': location,
          'product_ids': productIds,
          'capacity': capacity,
          'configuration': configuration ?? {},
        },
      );
      
      // Configure shelf sensors
      await _configureSmartShelf(deviceId, productIds, configuration);
      
      LoggingService.info('Added smart shelf: $shelfId');
      return deviceId;
    } catch (e) {
      LoggingService.error('Failed to add smart shelf: $e');
      rethrow;
    }
  }

  static Future<void> updateSmartShelfInventory({
    required String shelfId,
    required String productId,
    required int quantity,
  }) async {
    try {
      final deviceId = 'shelf_$shelfId';
      
      await sendCommand(
        deviceId: deviceId,
        command: 'update_inventory',
        parameters: {
          'product_id': productId,
          'quantity': quantity,
        },
      );
      
      LoggingService.info('Updated smart shelf inventory: $shelfId, $productId, $quantity');
    } catch (e) {
      LoggingService.error('Failed to update smart shelf inventory: $e');
    }
  }

  // Smart cart management
  static Future<String> addSmartCart({
    required String cartId,
    required String location,
    Map<String, dynamic>? configuration,
  }) async {
    try {
      final deviceId = 'cart_$cartId';
      
      await registerDevice(
        deviceId: deviceId,
        deviceType: 'smart_cart',
        name: 'Smart Cart $cartId',
        gatewayId: _currentGatewayId ?? 'default_gateway',
        metadata: {
          'location': location,
          'configuration': configuration ?? {},
        },
      );
      
      // Configure cart sensors
      await _configureSmartCart(deviceId, configuration);
      
      LoggingService.info('Added smart cart: $cartId');
      return deviceId;
    } catch (e) {
      LoggingService.error('Failed to add smart cart: $e');
      rethrow;
    }
  }

  static Future<void> addItemToSmartCart({
    required String cartId,
    required String productId,
    required double weight,
    int quantity = 1,
  }) async {
    try {
      final deviceId = 'cart_$cartId';
      
      await sendCommand(
        deviceId: deviceId,
        command: 'add_item',
        parameters: {
          'product_id': productId,
          'weight': weight,
          'quantity': quantity,
        },
      );
      
      LoggingService.info('Added item to smart cart: $cartId, $productId');
    } catch (e) {
      LoggingService.error('Failed to add item to smart cart: $e');
    }
  }

  static Future<void> removeItemFromSmartCart({
    required String cartId,
    required String productId,
    int quantity = 1,
  }) async {
    try {
      final deviceId = 'cart_$cartId';
      
      await sendCommand(
        deviceId: deviceId,
        command: 'remove_item',
        parameters: {
          'product_id': productId,
          'quantity': quantity,
        },
      );
      
      LoggingService.info('Removed item from smart cart: $cartId, $productId');
    } catch (e) {
      LoggingService.error('Failed to remove item from smart cart: $e');
    }
  }

  // Environmental monitoring
  static Future<String> addEnvironmentalSensor({
    required String sensorId,
    required String location,
    required List<String> sensorTypes,
    Map<String, dynamic>? configuration,
  }) async {
    try {
      final deviceId = 'sensor_$sensorId';
      
      await registerDevice(
        deviceId: deviceId,
        deviceType: 'environmental_sensor',
        name: 'Environmental Sensor $sensorId',
        gatewayId: _currentGatewayId ?? 'default_gateway',
        metadata: {
          'location': location,
          'sensor_types': sensorTypes,
          'configuration': configuration ?? {},
        },
      );
      
      // Configure sensor
      await _configureEnvironmentalSensor(deviceId, sensorTypes, configuration);
      
      LoggingService.info('Added environmental sensor: $sensorId');
      return deviceId;
    } catch (e) {
      LoggingService.error('Failed to add environmental sensor: $e');
      rethrow;
    }
  }

  static Future<EnvironmentalData> getEnvironmentalData(String sensorId) async {
    try {
      final deviceId = 'sensor_$sensorId';
      final history = _dataHistory[deviceId] ?? [];
      
      if (history.isEmpty) {
        return EnvironmentalData(
          sensorId: sensorId,
          temperature: 0.0,
          humidity: 0.0,
          pressure: 0.0,
          lightLevel: 0.0,
          timestamp: DateTime.now(),
        );
      }
      
      final latestData = history.last;
      final data = latestData.data;
      
      return EnvironmentalData(
        sensorId: sensorId,
        temperature: data['temperature']?.toDouble() ?? 0.0,
        humidity: data['humidity']?.toDouble() ?? 0.0,
        pressure: data['pressure']?.toDouble() ?? 0.0,
        lightLevel: data['light_level']?.toDouble() ?? 0.0,
        timestamp: latestData.timestamp,
      );
    } catch (e) {
      LoggingService.error('Failed to get environmental data: $e');
      rethrow;
    }
  }

  // Data streaming
  static Stream<IoTData> streamDeviceData(String deviceId) {
    final controller = StreamController<IoTData>();
    
    // Subscribe to device data
    _subscriptions[deviceId] = controller.stream.listen(null);
    
    return controller.stream;
  }

  static Future<List<IoTData>> getDeviceHistory({
    required String deviceId,
    DateTime? startTime,
    DateTime? endTime,
    int? limit,
  }) async {
    final history = _dataHistory[deviceId] ?? [];
    
    var filteredHistory = history.where((data) {
      if (startTime != null && data.timestamp.isBefore(startTime)) return false;
      if (endTime != null && data.timestamp.isAfter(endTime)) return false;
      return true;
    }).toList();
    
    filteredHistory.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    
    if (limit != null && filteredHistory.length > limit) {
      filteredHistory = filteredHistory.take(limit).toList();
    }
    
    return filteredHistory;
  }

  // Automation and rules
  static Future<String> createAutomationRule({
    required String name,
    required String deviceId,
    required String condition,
    required String action,
    Map<String, dynamic>? parameters,
  }) async {
    try {
      final ruleId = _generateRuleId();
      
      final rule = AutomationRule(
        id: ruleId,
        name: name,
        deviceId: deviceId,
        condition: condition,
        action: action,
        parameters: parameters ?? {},
        isActive: true,
        createdAt: DateTime.now(),
      );
      
      // Register rule with gateway
      await _registerAutomationRule(rule);
      
      LoggingService.info('Created automation rule: $ruleId');
      return ruleId;
    } catch (e) {
      LoggingService.error('Failed to create automation rule: $e');
      rethrow;
    }
  }

  static Future<void> triggerAutomation({
    required String deviceId,
    required Map<String, dynamic> triggerData,
  }) async {
    try {
      final message = {
        'type': 'automation_trigger',
        'device_id': deviceId,
        'trigger_data': triggerData,
        'timestamp': DateTime.now().toIso8601String(),
      };
      
      await _sendMessage(message);
      
      LoggingService.info('Triggered automation for device: $deviceId');
    } catch (e) {
      LoggingService.error('Failed to trigger automation: $e');
    }
  }

  // Analytics and insights
  static Future<IoTAnalytics> getAnalytics({
    String? deviceId,
    DateTime? startTime,
    DateTime? endTime,
  }) async {
    try {
      final devices = deviceId != null ? [deviceId] : _devices.keys.toList();
      final allData = <IoTData>[];
      
      for (final id in devices) {
        final history = await getDeviceHistory(
          deviceId: id,
          startTime: startTime,
          endTime: endTime,
        );
        allData.addAll(history);
      }
      
      return IoTAnalytics(
        deviceId: deviceId,
        dataPoints: allData.length,
        startTime: startTime ?? DateTime.now().subtract(Duration(days: 7)),
        endTime: endTime ?? DateTime.now(),
        averageValue: _calculateAverageValue(allData),
        maxValue: _calculateMaxValue(allData),
        minValue: _calculateMinValue(allData),
        trends: _calculateTrends(allData),
      );
    } catch (e) {
      LoggingService.error('Failed to get analytics: $e');
      rethrow;
    }
  }

  // Utility methods
  static Future<void> _authenticate(String apiKey) async {
    final message = {
      'type': 'auth',
      'api_key': apiKey,
      'timestamp': DateTime.now().toIso8601String(),
    };
    
    await _sendMessage(message);
  }

  static Future<void> _sendMessage(Map<String, dynamic> message) async {
    if (_mqttChannel != null && _isConnected) {
      _mqttChannel!.sink.add(json.encode(message));
    }
  }

  static void _handleMessage(dynamic message) {
    try {
      final data = json.decode(message);
      final iotData = IoTData.fromJson(data);
      
      // Store in history
      if (_dataHistory[iotData.deviceId] == null) {
        _dataHistory[iotData.deviceId] = [];
      }
      _dataHistory[iotData.deviceId]!.add(iotData);
      
      // Keep only last 1000 data points per device
      if (_dataHistory[iotData.deviceId]!.length > 1000) {
        _dataHistory[iotData.deviceId]!.removeAt(0);
      }
      
      // Update device status
      _updateDeviceStatus(iotData.deviceId, iotData);
      
      LoggingService.info('Received IoT data: ${iotData.deviceId}');
    } catch (e) {
      LoggingService.error('Error handling IoT message: $e');
    }
  }

  static void _handleError(dynamic error) {
    LoggingService.error('IoT WebSocket error: $error');
    _isConnected = false;
  }

  static void _handleDisconnect() {
    LoggingService.info('IoT WebSocket disconnected');
    _isConnected = false;
  }

  static Future<void> _discoverDevices() async {
    try {
      final message = {
        'type': 'discover_devices',
        'timestamp': DateTime.now().toIso8601String(),
      };
      
      await _sendMessage(message);
    } catch (e) {
      LoggingService.error('Failed to discover devices: $e');
    }
  }

  static Future<void> _registerWithGateway(IoTDevice device) async {
    final message = {
      'type': 'register_device',
      'device_id': device.id,
      'device_type': device.type,
      'gateway_id': device.gatewayId,
      'timestamp': DateTime.now().toIso8601String(),
    };
    
    await _sendMessage(message);
  }

  static Future<void> _unregisterFromGateway(IoTDevice device) async {
    final message = {
      'type': 'unregister_device',
      'device_id': device.id,
      'gateway_id': device.gatewayId,
      'timestamp': DateTime.now().toIso8601String(),
    };
    
    await _sendMessage(message);
  }

  static Future<void> _connectToGateway(IoTGateway gateway) async {
    final message = {
      'type': 'connect_gateway',
      'gateway_id': gateway.id,
      'ip_address': gateway.ipAddress,
      'port': gateway.port,
      'timestamp': DateTime.now().toIso8601String(),
    };
    
    await _sendMessage(message);
  }

  static Future<void> _disconnectFromGateway(IoTGateway gateway) async {
    final message = {
      'type': 'disconnect_gateway',
      'gateway_id': gateway.id,
      'timestamp': DateTime.now().toIso8601String(),
    };
    
    await _sendMessage(message);
  }

  static Future<void> _configureSmartShelf(
    String deviceId,
    List<String> productIds,
    Map<String, dynamic>? configuration,
  ) async {
    await sendCommand(
      deviceId: deviceId,
      command: 'configure',
      parameters: {
        'product_ids': productIds,
        'configuration': configuration ?? {},
      },
    );
  }

  static Future<void> _configureSmartCart(
    String deviceId,
    Map<String, dynamic>? configuration,
  ) async {
    await sendCommand(
      deviceId: deviceId,
      command: 'configure',
      parameters: {
        'configuration': configuration ?? {},
      },
    );
  }

  static Future<void> _configureEnvironmentalSensor(
    String deviceId,
    List<String> sensorTypes,
    Map<String, dynamic>? configuration,
  ) async {
    await sendCommand(
      deviceId: deviceId,
      command: 'configure',
      parameters: {
        'sensor_types': sensorTypes,
        'configuration': configuration ?? {},
      },
    );
  }

  static Future<void> _registerAutomationRule(AutomationRule rule) async {
    final message = {
      'type': 'register_automation',
      'rule_id': rule.id,
      'device_id': rule.deviceId,
      'condition': rule.condition,
      'action': rule.action,
      'parameters': rule.parameters,
      'timestamp': DateTime.now().toIso8601String(),
    };
    
    await _sendMessage(message);
  }

  static void _updateDeviceStatus(String deviceId, IoTData data) {
    final device = _devices[deviceId];
    if (device != null) {
      device.lastSeen = data.timestamp;
      device.status = IoTDeviceStatus.online;
      
      // Update device metadata with latest data
      device.metadata['last_data'] = data.data;
    }
  }

  static double _calculateAverageValue(List<IoTData> data) {
    if (data.isEmpty) return 0.0;
    
    double sum = 0.0;
    int count = 0;
    
    for (final point in data) {
      if (point.data['value'] != null) {
        sum += point.data['value'].toDouble();
        count++;
      }
    }
    
    return count > 0 ? sum / count : 0.0;
  }

  static double _calculateMaxValue(List<IoTData> data) {
    if (data.isEmpty) return 0.0;
    
    double maxValue = 0.0;
    
    for (final point in data) {
      if (point.data['value'] != null) {
        final value = point.data['value'].toDouble();
        if (value > maxValue) maxValue = value;
      }
    }
    
    return maxValue;
  }

  static double _calculateMinValue(List<IoTData> data) {
    if (data.isEmpty) return 0.0;
    
    double minValue = double.infinity;
    
    for (final point in data) {
      if (point.data['value'] != null) {
        final value = point.data['value'].toDouble();
        if (value < minValue) minValue = value;
      }
    }
    
    return minValue == double.infinity ? 0.0 : minValue;
  }

  static List<TrendData> _calculateTrends(List<IoTData> data) {
    // Mock trend calculation
    return [
      TrendData(
        period: '1h',
        direction: 'up',
        change: 5.2,
      ),
      TrendData(
        period: '24h',
        direction: 'down',
        change: -2.1,
      ),
      TrendData(
        period: '7d',
        direction: 'up',
        change: 12.8,
      ),
    ];
  }

  static String _generateRuleId() {
    return 'rule_${DateTime.now().millisecondsSinceEpoch}';
  }

  // Getters
  static bool get isConnected => _isConnected;
  static List<IoTDevice> get devices => _devices.values.toList();
  static List<IoTGateway> get gateways => _gateways.values.toList();
  static String? get currentGatewayId => _currentGatewayId;
}

// Data models
class IoTDevice {
  final String id;
  final String type;
  final String name;
  final String gatewayId;
  IoTDeviceStatus status;
  final Map<String, dynamic> metadata;
  final DateTime registeredAt;
  DateTime lastSeen;

  IoTDevice({
    required this.id,
    required this.type,
    required this.name,
    required this.gatewayId,
    required this.status,
    required this.metadata,
    required this.registeredAt,
    required this.lastSeen,
  });
}

class IoTGateway {
  final String id;
  final String name;
  final String location;
  final String ipAddress;
  final int port;
  IoTGatewayStatus status;
  final Map<String, dynamic> configuration;
  final DateTime addedAt;
  final List<String> connectedDevices;

  IoTGateway({
    required this.id,
    required this.name,
    required this.location,
    required this.ipAddress,
    required this.port,
    required this.status,
    required this.configuration,
    required this.addedAt,
    required this.connectedDevices,
  });
}

class IoTData {
  final String deviceId;
  final Map<String, dynamic> data;
  final DateTime timestamp;

  IoTData({
    required this.deviceId,
    required this.data,
    required this.timestamp,
  });

  factory IoTData.fromJson(Map<String, dynamic> json) {
    return IoTData(
      deviceId: json['device_id'],
      data: json['data'] ?? {},
      timestamp: DateTime.parse(json['timestamp']),
    );
  }
}

class EnvironmentalData {
  final String sensorId;
  final double temperature;
  final double humidity;
  final double pressure;
  final double lightLevel;
  final DateTime timestamp;

  EnvironmentalData({
    required this.sensorId,
    required this.temperature,
    required this.humidity,
    required this.pressure,
    required this.lightLevel,
    required this.timestamp,
  });
}

class AutomationRule {
  final String id;
  final String name;
  final String deviceId;
  final String condition;
  final String action;
  final Map<String, dynamic> parameters;
  bool isActive;
  final DateTime createdAt;

  AutomationRule({
    required this.id,
    required this.name,
    required this.deviceId,
    required this.condition,
    required this.action,
    required this.parameters,
    required this.isActive,
    required this.createdAt,
  });
}

class IoTAnalytics {
  final String? deviceId;
  final int dataPoints;
  final DateTime startTime;
  final DateTime endTime;
  final double averageValue;
  final double maxValue;
  final double minValue;
  final List<TrendData> trends;

  IoTAnalytics({
    this.deviceId,
    required this.dataPoints,
    required this.startTime,
    required this.endTime,
    required this.averageValue,
    required this.maxValue,
    required this.minValue,
    required this.trends,
  });
}

class TrendData {
  final String period;
  final String direction;
  final double change;

  TrendData({
    required this.period,
    required this.direction,
    required this.change,
  });
}

enum IoTDeviceStatus {
  online,
  offline,
  error,
  maintenance,
}

enum IoTGatewayStatus {
  online,
  offline,
  error,
}
