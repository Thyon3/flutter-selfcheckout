import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:selfcheckoutapp/services/logging_service.dart';
import 'package:selfcheckoutapp/services/security_service.dart';

class CollaborationService {
  static WebSocketChannel? _channel;
  static final Map<String, List<CollaborationEvent>> _eventHistory = {};
  static final Map<String, List<CollaborationUser>> _activeUsers = {};
  static final Map<String, CollaborationSession> _sessions = {};
  static final Map<String, Function(CollaborationEvent)> _eventHandlers = {};
  
  static bool _isConnected = false;
  static String? _currentUserId;
  static String? _currentSessionId;

  // Connection management
  static Future<bool> connect(String userId, {String? serverUrl}) async {
    try {
      if (_isConnected) {
        await disconnect();
      }

      _currentUserId = userId;
      final url = serverUrl ?? 'wss://collab.scango.app/ws';
      
      LoggingService.info('Connecting to collaboration server: $url');
      
      _channel = WebSocketChannel.connect(Uri.parse(url));
      _isConnected = true;
      
      // Send authentication
      await _authenticate(userId);
      
      // Start listening for messages
      _channel!.stream.listen(
        _handleMessage,
        onError: _handleError,
        onDone: _handleDisconnect,
      );
      
      LoggingService.info('Connected to collaboration server');
      return true;
    } catch (e) {
      LoggingService.error('Failed to connect to collaboration server: $e');
      _isConnected = false;
      return false;
    }
  }

  static Future<void> disconnect() async {
    try {
      if (_channel != null) {
        await _channel!.sink.close();
        _channel = null;
      }
      _isConnected = false;
      _currentUserId = null;
      _currentSessionId = null;
      LoggingService.info('Disconnected from collaboration server');
    } catch (e) {
      LoggingService.error('Error during disconnect: $e');
    }
  }

  static Future<void> _authenticate(String userId) async {
    final authToken = await SecurityService.generateToken(userId);
    final message = {
      'type': 'auth',
      'user_id': userId,
      'token': authToken,
      'timestamp': DateTime.now().toIso8601String(),
    };
    
    _sendMessage(message);
  }

  static void _handleMessage(dynamic message) {
    try {
      final data = json.decode(message);
      final event = CollaborationEvent.fromJson(data);
      
      LoggingService.info('Received collaboration event: ${event.type}');
      
      // Store event in history
      _storeEvent(event);
      
      // Process event based on type
      _processEvent(event);
      
      // Notify handlers
      _notifyHandlers(event);
    } catch (e) {
      LoggingService.error('Error handling collaboration message: $e');
    }
  }

  static void _handleError(dynamic error) {
    LoggingService.error('Collaboration WebSocket error: $error');
    _isConnected = false;
  }

  static void _handleDisconnect() {
    LoggingService.info('Collaboration WebSocket disconnected');
    _isConnected = false;
  }

  // Session management
  static Future<String> createSession({
    required String name,
    required String type,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final sessionId = _generateSessionId();
      
      final session = CollaborationSession(
        id: sessionId,
        name: name,
        type: type,
        createdBy: _currentUserId!,
        createdAt: DateTime.now(),
        metadata: metadata ?? {},
        activeUsers: [_currentUserId!],
      );
      
      _sessions[sessionId] = session;
      
      final message = {
        'type': 'create_session',
        'session_id': sessionId,
        'name': name,
        'session_type': type,
        'metadata': metadata,
        'created_by': _currentUserId,
        'timestamp': DateTime.now().toIso8601String(),
      };
      
      _sendMessage(message);
      
      LoggingService.info('Created collaboration session: $sessionId');
      return sessionId;
    } catch (e) {
      LoggingService.error('Failed to create session: $e');
      rethrow;
    }
  }

  static Future<void> joinSession(String sessionId) async {
    try {
      _currentSessionId = sessionId;
      
      final message = {
        'type': 'join_session',
        'session_id': sessionId,
        'user_id': _currentUserId,
        'timestamp': DateTime.now().toIso8601String(),
      };
      
      _sendMessage(message);
      
      LoggingService.info('Joined session: $sessionId');
    } catch (e) {
      LoggingService.error('Failed to join session: $e');
      rethrow;
    }
  }

  static Future<void> leaveSession(String sessionId) async {
    try {
      final message = {
        'type': 'leave_session',
        'session_id': sessionId,
        'user_id': _currentUserId,
        'timestamp': DateTime.now().toIso8601String(),
      };
      
      _sendMessage(message);
      
      if (_currentSessionId == sessionId) {
        _currentSessionId = null;
      }
      
      LoggingService.info('Left session: $sessionId');
    } catch (e) {
      LoggingService.error('Failed to leave session: $e');
    }
  }

  static Future<List<CollaborationSession>> getActiveSessions() async {
    try {
      final message = {
        'type': 'get_sessions',
        'user_id': _currentUserId,
        'timestamp': DateTime.now().toIso8601String(),
      };
      
      _sendMessage(message);
      
      // Return cached sessions for now
      return _sessions.values.toList();
    } catch (e) {
      LoggingService.error('Failed to get active sessions: $e');
      return [];
    }
  }

  // Real-time collaboration features
  static Future<void> broadcastCursor({
    required String sessionId,
    required double x,
    required double y,
    String? elementId,
  }) async {
    final message = {
      'type': 'cursor_move',
      'session_id': sessionId,
      'user_id': _currentUserId,
      'x': x,
      'y': y,
      'element_id': elementId,
      'timestamp': DateTime.now().toIso8601String(),
    };
    
    _sendMessage(message);
  }

  static Future<void> broadcastSelection({
    required String sessionId,
    required String elementId,
    String? text,
  }) async {
    final message = {
      'type': 'selection_change',
      'session_id': sessionId,
      'user_id': _currentUserId,
      'element_id': elementId,
      'text': text,
      'timestamp': DateTime.now().toIso8601String(),
    };
    
    _sendMessage(message);
  }

  static Future<void> broadcastEdit({
    required String sessionId,
    required String elementId,
    required String operation,
    required dynamic data,
  }) async {
    final message = {
      'type': 'edit_operation',
      'session_id': sessionId,
      'user_id': _currentUserId,
      'element_id': elementId,
      'operation': operation,
      'data': data,
      'timestamp': DateTime.now().toIso8601String(),
    };
    
    _sendMessage(message);
  }

  static Future<void> broadcastMessage({
    required String sessionId,
    required String message,
    MessageType messageType = MessageType.text,
    Map<String, dynamic>? metadata,
  }) async {
    final msg = {
      'type': 'chat_message',
      'session_id': sessionId,
      'user_id': _currentUserId,
      'message': message,
      'message_type': messageType.name,
      'metadata': metadata ?? {},
      'timestamp': DateTime.now().toIso8601String(),
    };
    
    _sendMessage(msg);
  }

  static Future<void> broadcastPresence({
    required String sessionId,
    required PresenceStatus status,
    String? statusMessage,
  }) async {
    final message = {
      'type': 'presence_update',
      'session_id': sessionId,
      'user_id': _currentUserId,
      'status': status.name,
      'status_message': statusMessage,
      'timestamp': DateTime.now().toIso8601String(),
    };
    
    _sendMessage(message);
  }

  static Future<void> broadcastTyping({
    required String sessionId,
    required bool isTyping,
  }) async {
    final message = {
      'type': 'typing_indicator',
      'session_id': sessionId,
      'user_id': _currentUserId,
      'is_typing': isTyping,
      'timestamp': DateTime.now().toIso8601String(),
    };
    
    _sendMessage(message);
  }

  // Shopping list collaboration
  static Future<void> shareShoppingList({
    required String sessionId,
    required List<Map<String, dynamic>> items,
  }) async {
    final message = {
      'type': 'share_shopping_list',
      'session_id': sessionId,
      'user_id': _currentUserId,
      'items': items,
      'timestamp': DateTime.now().toIso8601String(),
    };
    
    _sendMessage(message);
  }

  static Future<void> updateShoppingListItem({
    required String sessionId,
    required String itemId,
    required Map<String, dynamic> updates,
  }) async {
    final message = {
      'type': 'update_shopping_list_item',
      'session_id': sessionId,
      'user_id': _currentUserId,
      'item_id': itemId,
      'updates': updates,
      'timestamp': DateTime.now().toIso8601String(),
    };
    
    _sendMessage(message);
  }

  static Future<void> addShoppingListItem({
    required String sessionId,
    required Map<String, dynamic> item,
  }) async {
    final message = {
      'type': 'add_shopping_list_item',
      'session_id': sessionId,
      'user_id': _currentUserId,
      'item': item,
      'timestamp': DateTime.now().toIso8601String(),
    };
    
    _sendMessage(message);
  }

  static Future<void> removeShoppingListItem({
    required String sessionId,
    required String itemId,
  }) async {
    final message = {
      'type': 'remove_shopping_list_item',
      'session_id': sessionId,
      'user_id': _currentUserId,
      'item_id': itemId,
      'timestamp': DateTime.now().toIso8601String(),
    };
    
    _sendMessage(message);
  }

  // Cart collaboration
  static Future<void> shareCart({
    required String sessionId,
    required List<Map<String, dynamic>> cartItems,
  }) async {
    final message = {
      'type': 'share_cart',
      'session_id': sessionId,
      'user_id': _currentUserId,
      'cart_items': cartItems,
      'timestamp': DateTime.now().toIso8601String(),
    };
    
    _sendMessage(message);
  }

  static Future<void> updateCartItem({
    required String sessionId,
    required String itemId,
    required int quantity,
  }) async {
    final message = {
      'type': 'update_cart_item',
      'session_id': sessionId,
      'user_id': _currentUserId,
      'item_id': itemId,
      'quantity': quantity,
      'timestamp': DateTime.now().toIso8601String(),
    };
    
    _sendMessage(message);
  }

  // Event handling
  static void addEventHandler(String eventType, Function(CollaborationEvent) handler) {
    _eventHandlers[eventType] = handler;
  }

  static void removeEventHandler(String eventType) {
    _eventHandlers.remove(eventType);
  }

  static void _notifyHandlers(CollaborationEvent event) {
    final handler = _eventHandlers[event.type];
    if (handler != null) {
      handler(event);
    }
  }

  static void _processEvent(CollaborationEvent event) {
    switch (event.type) {
      case 'user_joined':
        _handleUserJoined(event);
        break;
      case 'user_left':
        _handleUserLeft(event);
        break;
      case 'cursor_move':
        _handleCursorMove(event);
        break;
      case 'selection_change':
        _handleSelectionChange(event);
        break;
      case 'edit_operation':
        _handleEditOperation(event);
        break;
      case 'chat_message':
        _handleChatMessage(event);
        break;
      case 'presence_update':
        _handlePresenceUpdate(event);
        break;
      case 'typing_indicator':
        _handleTypingIndicator(event);
        break;
      case 'share_shopping_list':
        _handleShareShoppingList(event);
        break;
      case 'update_shopping_list_item':
        _handleUpdateShoppingListItem(event);
        break;
      case 'add_shopping_list_item':
        _handleAddShoppingListItem(event);
        break;
      case 'remove_shopping_list_item':
        _handleRemoveShoppingListItem(event);
        break;
      case 'share_cart':
        _handleShareCart(event);
        break;
      case 'update_cart_item':
        _handleUpdateCartItem(event);
        break;
    }
  }

  static void _handleUserJoined(CollaborationEvent event) {
    final user = CollaborationUser(
      id: event.data['user_id'],
      name: event.data['user_name'],
      avatar: event.data['user_avatar'],
      status: PresenceStatus.online,
      joinedAt: DateTime.parse(event.timestamp),
    );
    
    final sessionId = event.data['session_id'];
    if (_activeUsers[sessionId] == null) {
      _activeUsers[sessionId] = [];
    }
    _activeUsers[sessionId]!.add(user);
  }

  static void _handleUserLeft(CollaborationEvent event) {
    final userId = event.data['user_id'];
    final sessionId = event.data['session_id'];
    
    if (_activeUsers[sessionId] != null) {
      _activeUsers[sessionId]!.removeWhere((user) => user.id == userId);
    }
  }

  static void _handleCursorMove(CollaborationEvent event) {
    // Handle cursor movement for real-time collaboration
    final cursorData = CursorData(
      userId: event.data['user_id'],
      x: event.data['x'].toDouble(),
      y: event.data['y'].toDouble(),
      elementId: event.data['element_id'],
      timestamp: DateTime.parse(event.timestamp),
    );
    
    // Store cursor data for UI updates
    _storeCursorData(event.data['session_id'], cursorData);
  }

  static void _handleSelectionChange(CollaborationEvent event) {
    // Handle text selection changes
    final selectionData = SelectionData(
      userId: event.data['user_id'],
      elementId: event.data['element_id'],
      text: event.data['text'],
      timestamp: DateTime.parse(event.timestamp),
    );
    
    _storeSelectionData(event.data['session_id'], selectionData);
  }

  static void _handleEditOperation(CollaborationEvent event) {
    // Handle collaborative editing operations
    final editData = EditData(
      userId: event.data['user_id'],
      elementId: event.data['element_id'],
      operation: event.data['operation'],
      data: event.data['data'],
      timestamp: DateTime.parse(event.timestamp),
    );
    
    _storeEditData(event.data['session_id'], editData);
  }

  static void _handleChatMessage(CollaborationEvent event) {
    // Handle chat messages
    final chatData = ChatData(
      userId: event.data['user_id'],
      message: event.data['message'],
      messageType: MessageType.values.firstWhere(
        (type) => type.name == event.data['message_type'],
        orElse: () => MessageType.text,
      ),
      metadata: event.data['metadata'] ?? {},
      timestamp: DateTime.parse(event.timestamp),
    );
    
    _storeChatData(event.data['session_id'], chatData);
  }

  static void _handlePresenceUpdate(CollaborationEvent event) {
    // Handle presence updates
    final userId = event.data['user_id'];
    final status = PresenceStatus.values.firstWhere(
      (status) => status.name == event.data['status'],
      orElse: () => PresenceStatus.offline,
    );
    final statusMessage = event.data['status_message'];
    
    _updateUserPresence(userId, status, statusMessage);
  }

  static void _handleTypingIndicator(CollaborationEvent event) {
    // Handle typing indicators
    final userId = event.data['user_id'];
    final isTyping = event.data['is_typing'];
    
    _updateTypingStatus(event.data['session_id'], userId, isTyping);
  }

  static void _handleShareShoppingList(CollaborationEvent event) {
    // Handle shopping list sharing
    final items = List<Map<String, dynamic>>.from(event.data['items']);
    _storeShoppingList(event.data['session_id'], items);
  }

  static void _handleUpdateShoppingListItem(CollaborationEvent event) {
    // Handle shopping list item updates
    final itemId = event.data['item_id'];
    final updates = Map<String, dynamic>.from(event.data['updates']);
    _updateShoppingListItem(event.data['session_id'], itemId, updates);
  }

  static void _handleAddShoppingListItem(CollaborationEvent event) {
    // Handle adding shopping list items
    final item = Map<String, dynamic>.from(event.data['item']);
    _addShoppingListItem(event.data['session_id'], item);
  }

  static void _handleRemoveShoppingListItem(CollaborationEvent event) {
    // Handle removing shopping list items
    final itemId = event.data['item_id'];
    _removeShoppingListItem(event.data['session_id'], itemId);
  }

  static void _handleShareCart(CollaborationEvent event) {
    // Handle cart sharing
    final cartItems = List<Map<String, dynamic>>.from(event.data['cart_items']);
    _storeCart(event.data['session_id'], cartItems);
  }

  static void _handleUpdateCartItem(CollaborationEvent event) {
    // Handle cart item updates
    final itemId = event.data['item_id'];
    final quantity = event.data['quantity'];
    _updateCartItem(event.data['session_id'], itemId, quantity);
  }

  // Utility methods
  static void _sendMessage(Map<String, dynamic> message) {
    if (_channel != null && _isConnected) {
      _channel!.sink.add(json.encode(message));
    }
  }

  static void _storeEvent(CollaborationEvent event) {
    final sessionId = event.data['session_id'] ?? 'global';
    if (_eventHistory[sessionId] == null) {
      _eventHistory[sessionId] = [];
    }
    _eventHistory[sessionId]!.add(event);
    
    // Keep only last 100 events per session
    if (_eventHistory[sessionId]!.length > 100) {
      _eventHistory[sessionId]!.removeAt(0);
    }
  }

  static String _generateSessionId() {
    return 'session_${DateTime.now().millisecondsSinceEpoch}_${_currentUserId}';
  }

  static void _storeCursorData(String sessionId, CursorData cursorData) {
    // Store cursor data for UI rendering
  }

  static void _storeSelectionData(String sessionId, SelectionData selectionData) {
    // Store selection data for UI rendering
  }

  static void _storeEditData(String sessionId, EditData editData) {
    // Store edit data for collaborative editing
  }

  static void _storeChatData(String sessionId, ChatData chatData) {
    // Store chat data for UI rendering
  }

  static void _updateUserPresence(String userId, PresenceStatus status, String? message) {
    // Update user presence in active users list
    for (final sessionUsers in _activeUsers.values) {
      final user = sessionUsers.firstWhere((u) => u.id == userId, orElse: () => null);
      if (user != null) {
        user.status = status;
        user.statusMessage = message;
        break;
      }
    }
  }

  static void _updateTypingStatus(String sessionId, String userId, bool isTyping) {
    // Update typing status for UI indicators
  }

  static void _storeShoppingList(String sessionId, List<Map<String, dynamic>> items) {
    // Store shared shopping list
  }

  static void _updateShoppingListItem(String sessionId, String itemId, Map<String, dynamic> updates) {
    // Update shopping list item
  }

  static void _addShoppingListItem(String sessionId, Map<String, dynamic> item) {
    // Add item to shopping list
  }

  static void _removeShoppingListItem(String sessionId, String itemId) {
    // Remove item from shopping list
  }

  static void _storeCart(String sessionId, List<Map<String, dynamic>> cartItems) {
    // Store shared cart
  }

  static void _updateCartItem(String sessionId, String itemId, int quantity) {
    // Update cart item quantity
  }

  // Getters
  static bool get isConnected => _isConnected;
  static String? get currentUserId => _currentUserId;
  static String? get currentSessionId => _currentSessionId;
  static List<CollaborationEvent> getEventHistory(String sessionId) {
    return _eventHistory[sessionId] ?? [];
  }
  static List<CollaborationUser> getActiveUsers(String sessionId) {
    return _activeUsers[sessionId] ?? [];
  }
}

// Data models
class CollaborationEvent {
  final String type;
  final Map<String, dynamic> data;
  final String timestamp;
  final String? userId;

  CollaborationEvent({
    required this.type,
    required this.data,
    required this.timestamp,
    this.userId,
  });

  factory CollaborationEvent.fromJson(Map<String, dynamic> json) {
    return CollaborationEvent(
      type: json['type'],
      data: json['data'] ?? {},
      timestamp: json['timestamp'],
      userId: json['user_id'],
    );
  }
}

class CollaborationSession {
  final String id;
  final String name;
  final String type;
  final String createdBy;
  final DateTime createdAt;
  final Map<String, dynamic> metadata;
  final List<String> activeUsers;

  CollaborationSession({
    required this.id,
    required this.name,
    required this.type,
    required this.createdBy,
    required this.createdAt,
    required this.metadata,
    required this.activeUsers,
  });
}

class CollaborationUser {
  final String id;
  final String name;
  final String? avatar;
  PresenceStatus status;
  final String? statusMessage;
  final DateTime joinedAt;
  bool isTyping;

  CollaborationUser({
    required this.id,
    required this.name,
    this.avatar,
    required this.status,
    this.statusMessage,
    required this.joinedAt,
    this.isTyping = false,
  });
}

class CursorData {
  final String userId;
  final double x;
  final double y;
  final String? elementId;
  final DateTime timestamp;

  CursorData({
    required this.userId,
    required this.x,
    required this.y,
    this.elementId,
    required this.timestamp,
  });
}

class SelectionData {
  final String userId;
  final String elementId;
  final String? text;
  final DateTime timestamp;

  SelectionData({
    required this.userId,
    required this.elementId,
    this.text,
    required this.timestamp,
  });
}

class EditData {
  final String userId;
  final String elementId;
  final String operation;
  final dynamic data;
  final DateTime timestamp;

  EditData({
    required this.userId,
    required this.elementId,
    required this.operation,
    required this.data,
    required this.timestamp,
  });
}

class ChatData {
  final String userId;
  final String message;
  final MessageType messageType;
  final Map<String, dynamic> metadata;
  final DateTime timestamp;

  ChatData({
    required this.userId,
    required this.message,
    required this.messageType,
    required this.metadata,
    required this.timestamp,
  });
}

enum PresenceStatus {
  online,
  away,
  busy,
  offline,
}

enum MessageType {
  text,
  image,
  file,
  system,
}
