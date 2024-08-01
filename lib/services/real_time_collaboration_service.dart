import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:selfcheckoutapp/services/logging_service.dart';
import 'package:selfcheckoutapp/services/cache_service.dart';
import 'package:selfcheckoutapp/services/security_service.dart';

class RealTimeCollaborationService {
  static const String _baseUrl = 'https://api.collaboration.scango.app';
  static const String _wsUrl = 'wss://collaboration.scango.app/ws';
  static const String _apiKey = 'collaboration_api_key_12345';
  static const String _cacheKey = 'collaboration_cache';
  
  static bool _isInitialized = false;
  static bool _isConnected = false;
  static WebSocketChannel? _collaborationChannel;
  static StreamSubscription? _collaborationSubscription;
  static final Map<String, CollaborationSession> _activeSessions = {};
  static final Map<String, User> _connectedUsers = {};
  static final List<CollaborationEvent> _eventHistory = [];
  static StreamController<CollaborationEvent>? _eventController;

  // Real-time collaboration service initialization
  static Future<bool> initialize() async {
    try {
      if (_isInitialized) return true;
      
      LoggingService.info('Initializing real-time collaboration service');
      
      // Initialize event controller
      _eventController = StreamController<CollaborationEvent>.broadcast();
      
      // Connect to collaboration server
      await _connectToCollaborationServer();
      
      // Load active sessions
      await _loadActiveSessions();
      
      _isInitialized = true;
      
      LoggingService.info('Real-time collaboration service initialized successfully');
      return true;
    } catch (e) {
      LoggingService.error('Failed to initialize real-time collaboration service: $e');
      return false;
    }
  }

  // Collaboration server connection
  static Future<void> _connectToCollaborationServer() async {
    try {
      _collaborationChannel = WebSocketChannel.connect(Uri.parse('$_wsUrl/realtime'));
      
      // Authenticate
      final authMessage = {
        'type': 'auth',
        'api_key': _apiKey,
        'timestamp': DateTime.now().toIso8601String(),
      };
      
      _collaborationChannel!.sink.add(json.encode(authMessage));
      
      // Listen for collaboration events
      _collaborationSubscription = _collaborationChannel!.stream.listen(
        _handleCollaborationEvent,
        onError: _handleCollaborationError,
        onDone: _handleCollaborationDisconnect,
      );
      
      _isConnected = true;
      
      LoggingService.info('Connected to collaboration server');
    } catch (e) {
      LoggingService.error('Failed to connect to collaboration server: $e');
      _isConnected = false;
    }
  }

  // Collaboration session management
  static Future<SessionResult> createSession({
    required String sessionId,
    required String sessionName,
    required String creatorId,
    required String creatorName,
    CollaborationType type = CollaborationType.shopping,
    Map<String, dynamic>? sessionConfig,
  }) async {
    try {
      if (!_isInitialized) {
        await initialize();
      }
      
      // Create collaboration session
      final session = CollaborationSession(
        id: sessionId,
        name: sessionName,
        type: type,
        creatorId: creatorId,
        creatorName: creatorName,
        status: SessionStatus.active,
        createdAt: DateTime.now(),
        endTime: null,
        participants: [],
        sharedCart: SharedCart(
          items: [],
          lastUpdated: DateTime.now(),
          version: 1,
        ),
        sharedWishlist: SharedWishlist(
          items: [],
          lastUpdated: DateTime.now(),
          version: 1,
        ),
        sharedNotes: SharedNotes(
          notes: [],
          lastUpdated: DateTime.now(),
          version: 1,
        ),
        activityFeed: [],
        config: sessionConfig ?? {},
        metadata: {},
      );
      
      _activeSessions[sessionId] = session;
      
      // Add creator as first participant
      await _addParticipantToSession(sessionId, creatorId, creatorName);
      
      // Register session on server
      await _registerSessionOnServer(session);
      
      // Emit session created event
      _emitEvent(CollaborationEvent(
        type: CollaborationEventType.sessionCreated,
        data: session.toJson(),
      ));
      
      LoggingService.info('Collaboration session created: $sessionId');
      return SessionResult(
        success: true,
        session: session,
      );
    } catch (e) {
      LoggingService.error('Failed to create collaboration session: $e');
      return SessionResult(
        success: false,
        error: e.toString(),
      );
    }
  }

  static Future<void> _registerSessionOnServer(CollaborationSession session) async {
    try {
      final registration = {
        'type': 'register_session',
        'session_id': session.id,
        'session_name': session.name,
        'session_type': session.type.name,
        'creator_id': session.creatorId,
        'config': session.config,
        'timestamp': DateTime.now().toIso8601String(),
      };
      
      _collaborationChannel?.sink.add(json.encode(registration));
      
      LoggingService.info('Session registered on server: ${session.id}');
    } catch (e) {
      LoggingService.error('Failed to register session on server: $e');
    }
  }

  static Future<SessionResult> joinSession({
    required String sessionId,
    required String userId,
    required String userName,
    Map<String, dynamic>? joinConfig,
  }) async {
    try {
      if (!_activeSessions.containsKey(sessionId)) {
        return SessionResult(
          success: false,
          error: 'Session not found: $sessionId',
        );
      }
      
      final session = _activeSessions[sessionId]!;
      
      // Check if user is already a participant
      if (session.participants.any((p) => p.userId == userId)) {
        return SessionResult(
          success: false,
          error: 'User already in session: $userId',
        );
      }
      
      // Add participant to session
      await _addParticipantToSession(sessionId, userId, userName);
      
      // Notify other participants
      await _notifyParticipantsJoined(sessionId, userId, userName);
      
      // Emit session joined event
      _emitEvent(CollaborationEvent(
        type: CollaborationEventType.sessionJoined,
        data: {
          'session_id': sessionId,
          'user_id': userId,
          'user_name': userName,
        },
      ));
      
      LoggingService.info('User joined session: $userId -> $sessionId');
      return SessionResult(
        success: true,
        session: session,
      );
    } catch (e) {
      LoggingService.error('Failed to join session: $e');
      return SessionResult(
        success: false,
        error: e.toString(),
      );
    }
  }

  static Future<void> _addParticipantToSession(String sessionId, String userId, String userName) async {
    try {
      final session = _activeSessions[sessionId]!;
      
      final participant = Participant(
        userId: userId,
        userName: userName,
        role: ParticipantRole.collaborator,
        status: ParticipantStatus.active,
        joinedAt: DateTime.now(),
        lastActive: DateTime.now(),
        permissions: {
          'can_edit_cart': true,
          'can_edit_wishlist': true,
          'can_add_notes': true,
          'can_chat': true,
        },
        cursor: CursorPosition(
          x: 0,
          y: 0,
          visible: false,
        ),
        selection: [],
      );
      
      session.participants.add(participant);
      
      // Add to connected users
      _connectedUsers[userId] = User(
        id: userId,
        name: userName,
        status: UserStatus.online,
        currentSession: sessionId,
        lastSeen: DateTime.now(),
      );
      
      // Add activity to feed
      session.activityFeed.add(Activity(
        id: _generateActivityId(),
        type: ActivityType.userJoined,
        userId: userId,
        userName: userName,
        timestamp: DateTime.now(),
        data: {
          'session_id': sessionId,
        },
      ));
      
      LoggingService.info('Participant added to session: $userId -> $sessionId');
    } catch (e) {
      LoggingService.error('Failed to add participant to session: $e');
    }
  }

  static Future<void> _notifyParticipantsJoined(String sessionId, String userId, String userName) async {
    try {
      final notification = {
        'type': 'user_joined',
        'session_id': sessionId,
        'user_id': userId,
        'user_name': userName,
        'timestamp': DateTime.now().toIso8601String(),
      };
      
      _collaborationChannel?.sink.add(json.encode(notification));
      
      LoggingService.info('Notified participants of user join: $userId');
    } catch (e) {
      LoggingService.error('Failed to notify participants of user join: $e');
    }
  }

  static Future<bool> leaveSession({
    required String sessionId,
    required String userId,
  }) async {
    try {
      if (!_activeSessions.containsKey(sessionId)) {
        return false;
      }
      
      final session = _activeSessions[sessionId]!;
      
      // Remove participant from session
      session.participants.removeWhere((p) => p.userId == userId);
      
      // Remove from connected users
      _connectedUsers.remove(userId);
      
      // Add activity to feed
      session.activityFeed.add(Activity(
        id: _generateActivityId(),
        type: ActivityType.userLeft,
        userId: userId,
        userName: _getUserName(userId),
        timestamp: DateTime.now(),
        data: {
          'session_id': sessionId,
        },
      ));
      
      // Notify other participants
      await _notifyParticipantsLeft(sessionId, userId);
      
      // Emit session left event
      _emitEvent(CollaborationEvent(
        type: CollaborationEventType.sessionLeft,
        data: {
          'session_id': sessionId,
          'user_id': userId,
        },
      ));
      
      // Check if session should be ended
      if (session.participants.isEmpty) {
        await _endSession(sessionId);
      }
      
      LoggingService.info('User left session: $userId -> $sessionId');
      return true;
    } catch (e) {
      LoggingService.error('Failed to leave session: $e');
      return false;
    }
  }

  static Future<void> _notifyParticipantsLeft(String sessionId, String userId) async {
    try {
      final notification = {
        'type': 'user_left',
        'session_id': sessionId,
        'user_id': userId,
        'timestamp': DateTime.now().toIso8601String(),
      };
      
      _collaborationChannel?.sink.add(json.encode(notification));
      
      LoggingService.info('Notified participants of user leave: $userId');
    } catch (e) {
      LoggingService.error('Failed to notify participants of user leave: $e');
    }
  }

  static Future<void> _endSession(String sessionId) async {
    try {
      final session = _activeSessions[sessionId]!;
      
      session.status = SessionStatus.ended;
      session.endTime = DateTime.now();
      
      // Notify server
      final notification = {
        'type': 'session_ended',
        'session_id': sessionId,
        'timestamp': DateTime.now().toIso8601String(),
      };
      
      _collaborationChannel?.sink.add(json.encode(notification));
      
      // Remove from active sessions
      _activeSessions.remove(sessionId);
      
      // Emit session ended event
      _emitEvent(CollaborationEvent(
        type: CollaborationEventType.sessionEnded,
        data: session.toJson(),
      ));
      
      LoggingService.info('Session ended: $sessionId');
    } catch (e) {
      LoggingService.error('Failed to end session: $e');
    }
  }

  // Shared cart operations
  static Future<CartResult> addToSharedCart({
    required String sessionId,
    required String userId,
    required String productId,
    required String productName,
    required double price,
    int quantity = 1,
    Map<String, dynamic>? productDetails,
  }) async {
    try {
      if (!_activeSessions.containsKey(sessionId)) {
        return CartResult(
          success: false,
          error: 'Session not found: $sessionId',
        );
      }
      
      final session = _activeSessions[sessionId]!;
      
      // Check user permissions
      final participant = session.participants.firstWhere(
        (p) => p.userId == userId,
        orElse: () => throw Exception('User not in session: $userId'),
      );
      
      if (!participant.permissions['can_edit_cart'] ?? false) {
        return CartResult(
          success: false,
          error: 'User does not have permission to edit cart',
        );
      }
      
      // Add item to shared cart
      final cartItem = CartItem(
        id: _generateCartItemId(),
        productId: productId,
        productName: productName,
        price: price,
        quantity: quantity,
        addedBy: userId,
        addedByName: participant.userName,
        addedAt: DateTime.now(),
        productDetails: productDetails ?? {},
        sharedBy: [userId],
      );
      
      session.sharedCart.items.add(cartItem);
      session.sharedCart.lastUpdated = DateTime.now();
      session.sharedCart.version++;
      
      // Add activity to feed
      session.activityFeed.add(Activity(
        id: _generateActivityId(),
        type: ActivityType.cartUpdated,
        userId: userId,
        userName: participant.userName,
        timestamp: DateTime.now(),
        data: {
          'action': 'add',
          'product_id': productId,
          'product_name': productName,
          'quantity': quantity,
        },
      ));
      
      // Notify other participants
      await _notifyCartUpdated(sessionId, cartItem, 'add');
      
      // Emit cart updated event
      _emitEvent(CollaborationEvent(
        type: CollaborationEventType.cartUpdated,
        data: {
          'session_id': sessionId,
          'action': 'add',
          'item': cartItem.toJson(),
          'user_id': userId,
        },
      ));
      
      LoggingService.info('Item added to shared cart: $productId by $userId");
      return CartResult(
        success: true,
        cartItem: cartItem,
      );
    } catch (e) {
      LoggingService.error('Failed to add to shared cart: $e');
      return CartResult(
        success: false,
        error: e.toString(),
      );
    }
  }

  static Future<CartResult> removeFromSharedCart({
    required String sessionId,
    required String userId,
    required String cartItemId,
  }) async {
    try {
      if (!_activeSessions.containsKey(sessionId)) {
        return CartResult(
          success: false,
          error: 'Session not found: $sessionId',
        );
      }
      
      final session = _activeSessions[sessionId]!;
      
      // Check user permissions
      final participant = session.participants.firstWhere(
        (p) => p.userId == userId,
        orElse: () => throw Exception('User not in session: $userId'),
      );
      
      if (!participant.permissions['can_edit_cart'] ?? false) {
        return CartResult(
          success: false,
          error: 'User does not have permission to edit cart',
        );
      }
      
      // Find and remove item
      final cartItem = session.sharedCart.items.firstWhere(
        (item) => item.id == cartItemId,
        orElse: () => throw Exception('Cart item not found: $cartItemId'),
      );
      
      session.sharedCart.items.remove(cartItem);
      session.sharedCart.lastUpdated = DateTime.now();
      session.sharedCart.version++;
      
      // Add activity to feed
      session.activityFeed.add(Activity(
        id: _generateActivityId(),
        type: ActivityType.cartUpdated,
        userId: userId,
        userName: participant.userName,
        timestamp: DateTime.now(),
        data: {
          'action': 'remove',
          'product_id': cartItem.productId,
          'product_name': cartItem.productName,
        },
      ));
      
      // Notify other participants
      await _notifyCartUpdated(sessionId, cartItem, 'remove');
      
      // Emit cart updated event
      _emitEvent(CollaborationEvent(
        type: CollaborationEventType.cartUpdated,
        data: {
          'session_id': sessionId,
          'action': 'remove',
          'item': cartItem.toJson(),
          'user_id': userId,
        },
      ));
      
      LoggingService.info('Item removed from shared cart: $cartItemId by $userId');
      return CartResult(
        success: true,
        cartItem: cartItem,
      );
    } catch (e) {
      LoggingService.error('Failed to remove from shared cart: $e');
      return CartResult(
        success: false,
        error: e.toString(),
      );
    }
  }

  static Future<void> _notifyCartUpdated(String sessionId, CartItem cartItem, String action) async {
    try {
      final notification = {
        'type': 'cart_updated',
        'session_id': sessionId,
        'action': action,
        'item': cartItem.toJson(),
        'timestamp': DateTime.now().toIso8601String(),
      };
      
      _collaborationChannel?.sink.add(json.encode(notification));
      
      LoggingService.info('Notified participants of cart update: $action');
    } catch (e) {
      LoggingService.error('Failed to notify participants of cart update: $e');
    }
  }

  // Shared wishlist operations
  static Future<WishlistResult> addToSharedWishlist({
    required String sessionId,
    required String userId,
    required String productId,
    required String productName,
    double? price,
    Map<String, dynamic>? productDetails,
  }) async {
    try {
      if (!_activeSessions.containsKey(sessionId)) {
        return WishlistResult(
          success: false,
          error: 'Session not found: $sessionId',
        );
      }
      
      final session = _activeSessions[sessionId]!;
      
      // Check user permissions
      final participant = session.participants.firstWhere(
        (p) => p.userId == userId,
        orElse: () => throw Exception('User not in session: $userId'),
      );
      
      if (!participant.permissions['can_edit_wishlist'] ?? false) {
        return WishlistResult(
          success: false,
          error: 'User does not have permission to edit wishlist',
        );
      }
      
      // Add item to shared wishlist
      final wishlistItem = WishlistItem(
        id: _generateWishlistItemId(),
        productId: productId,
        productName: productName,
        price: price,
        addedBy: userId,
        addedByName: participant.userName,
        addedAt: DateTime.now(),
        productDetails: productDetails ?? {},
        votes: [],
        comments: [],
      );
      
      session.sharedWishlist.items.add(wishlistItem);
      session.sharedWishlist.lastUpdated = DateTime.now();
      session.sharedWishlist.version++;
      
      // Add activity to feed
      session.activityFeed.add(Activity(
        id: _generateActivityId(),
        type: ActivityType.wishlistUpdated,
        userId: userId,
        userName: participant.userName,
        timestamp: DateTime.now(),
        data: {
          'action': 'add',
          'product_id': productId,
          'product_name': productName,
        },
      ));
      
      // Notify other participants
      await _notifyWishlistUpdated(sessionId, wishlistItem, 'add');
      
      // Emit wishlist updated event
      _emitEvent(CollaborationEvent(
        type: CollaborationEventType.wishlistUpdated,
        data: {
          'session_id': sessionId,
          'action': 'add',
          'item': wishlistItem.toJson(),
          'user_id': userId,
        },
      ));
      
      LoggingService.info('Item added to shared wishlist: $productId by $userId');
      return WishlistResult(
        success: true,
        wishlistItem: wishlistItem,
      );
    } catch (e) {
      LoggingService.error('Failed to add to shared wishlist: $e');
      return WishlistResult(
        success: false,
        error: e.toString(),
      );
    }
  }

  static Future<void> _notifyWishlistUpdated(String sessionId, WishlistItem wishlistItem, String action) async {
    try {
      final notification = {
        'type': 'wishlist_updated',
        'session_id': sessionId,
        'action': action,
        'item': wishlistItem.toJson(),
        'timestamp': DateTime.now().toIso8601String(),
      };
      
      _collaborationChannel?.sink.add(json.encode(notification));
      
      LoggingService.info('Notified participants of wishlist update: $action');
    } catch (e) {
      LoggingService.error('Failed to notify participants of wishlist update: $e');
    }
  }

  // Real-time cursor and selection sharing
  static Future<bool> updateCursorPosition({
    required String sessionId,
    required String userId,
    required double x,
    required double y,
    bool visible = true,
  }) async {
    try {
      if (!_activeSessions.containsKey(sessionId)) {
        return false;
      }
      
      final session = _activeSessions[sessionId]!;
      
      // Find participant
      final participant = session.participants.firstWhere(
        (p) => p.userId == userId,
        orElse: () => throw Exception('User not in session: $userId'),
      );
      
      // Update cursor position
      participant.cursor = CursorPosition(
        x: x,
        y: y,
        visible: visible,
      );
      
      participant.lastActive = DateTime.now();
      
      // Notify other participants
      await _notifyCursorUpdated(sessionId, userId, x, y, visible);
      
      // Emit cursor updated event
      _emitEvent(CollaborationEvent(
        type: CollaborationEventType.cursorUpdated,
        data: {
          'session_id': sessionId,
          'user_id': userId,
          'x': x,
          'y': y,
          'visible': visible,
        },
      ));
      
      return true;
    } catch (e) {
      LoggingService.error('Failed to update cursor position: $e');
      return false;
    }
  }

  static Future<void> _notifyCursorUpdated(String sessionId, String userId, double x, double y, bool visible) async {
    try {
      final notification = {
        'type': 'cursor_updated',
        'session_id': sessionId,
        'user_id': userId,
        'x': x,
        'y': y,
        'visible': visible,
        'timestamp': DateTime.now().toIso8601String(),
      };
      
      _collaborationChannel?.sink.add(json.encode(notification));
      
      LoggingService.info('Notified participants of cursor update: $userId');
    } catch (e) {
      LoggingService.error('Failed to notify participants of cursor update: $e');
    }
  }

  static Future<bool> updateSelection({
    required String sessionId,
    required String userId,
    required List<String> selectedItems,
  }) async {
    try {
      if (!_activeSessions.containsKey(sessionId)) {
        return false;
      }
      
      final session = _activeSessions[sessionId]!;
      
      // Find participant
      final participant = session.participants.firstWhere(
        (p) => p.userId == userId,
        orElse: () => throw Exception('User not in session: $userId'),
      );
      
      // Update selection
      participant.selection = selectedItems;
      
      participant.lastActive = DateTime.now();
      
      // Notify other participants
      await _notifySelectionUpdated(sessionId, userId, selectedItems);
      
      // Emit selection updated event
      _emitEvent(CollaborationEvent(
        type: CollaborationEventType.selectionUpdated,
        data: {
          'session_id': sessionId,
          'user_id': userId,
          'selection': selectedItems,
        },
      ));
      
      return true;
    } catch (e) {
      LoggingService.error('Failed to update selection: $e');
      return false;
    }
  }

  static Future<void> _notifySelectionUpdated(String sessionId, String userId, List<String> selectedItems) async {
    try {
      final notification = {
        'type': 'selection_updated',
        'session_id': sessionId,
        'user_id': userId,
        'selection': selectedItems,
        'timestamp': DateTime.now().toIso8601String(),
      };
      
      _collaborationChannel?.sink.add(json.encode(notification));
      
      LoggingService.info('Notified participants of selection update: $userId');
    } catch (e) {
      LoggingService.error('Failed to notify participants of selection update: $e');
    }
  }

  // Chat and messaging
  static Future<ChatResult> sendChatMessage({
    required String sessionId,
    required String userId,
    required String message,
    MessageType messageType = MessageType.text,
    Map<String, dynamic>? attachments,
  }) async {
    try {
      if (!_activeSessions.containsKey(sessionId)) {
        return ChatResult(
          success: false,
          error: 'Session not found: $sessionId',
        );
      }
      
      final session = _activeSessions[sessionId]!;
      
      // Find participant
      final participant = session.participants.firstWhere(
        (p) => p.userId == userId,
        orElse: () => throw Exception('User not in session: $userId'),
      );
      
      if (!participant.permissions['can_chat'] ?? false) {
        return ChatResult(
          success: false,
          error: 'User does not have permission to chat',
        );
      }
      
      // Create chat message
      final chatMessage = ChatMessage(
        id: _generateChatMessageId(),
        userId: userId,
        userName: participant.userName,
        message: message,
        messageType: messageType,
        timestamp: DateTime.now(),
        attachments: attachments ?? {},
        reactions: {},
        isEdited: false,
        replyTo: null,
      );
      
      // Add to session chat
      if (session.chatMessages == null) {
        session.chatMessages = [];
      }
      session.chatMessages!.add(chatMessage);
      
      // Add activity to feed
      session.activityFeed.add(Activity(
        id: _generateActivityId(),
        type: ActivityType.chatMessage,
        userId: userId,
        userName: participant.userName,
        timestamp: DateTime.now(),
        data: {
          'message_id': chatMessage.id,
          'message': message,
          'message_type': messageType.name,
        },
      ));
      
      // Notify other participants
      await _notifyChatMessage(sessionId, chatMessage);
      
      // Emit chat message event
      _emitEvent(CollaborationEvent(
        type: CollaborationEventType.chatMessage,
        data: chatMessage.toJson(),
      ));
      
      LoggingService.info('Chat message sent: $userId -> $sessionId');
      return ChatResult(
        success: true,
        message: chatMessage,
      );
    } catch (e) {
      LoggingService.error('Failed to send chat message: $e');
      return ChatResult(
        success: false,
        error: e.toString(),
      );
    }
  }

  static Future<void> _notifyChatMessage(String sessionId, ChatMessage message) async {
    try {
      final notification = {
        'type': 'chat_message',
        'session_id': sessionId,
        'message': message.toJson(),
        'timestamp': DateTime.now().toIso8601String(),
      };
      
      _collaborationChannel?.sink.add(json.encode(notification));
      
      LoggingService.info('Notified participants of chat message: ${message.id}');
    } catch (e) {
      LoggingService.error('Failed to notify participants of chat message: $e');
    }
  }

  // Analytics and reporting
  static Future<CollaborationAnalytics> getAnalytics({
    String? sessionId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      var sessions = _activeSessions.values.toList();
      
      if (sessionId != null) {
        sessions = sessions.where((s) => s.id == sessionId).toList();
      }
      
      if (startDate != null) {
        sessions = sessions.where((s) => s.createdAt.isAfter(startDate)).toList();
      }
      
      if (endDate != null) {
        sessions = sessions.where((s) => s.createdAt.isBefore(endDate)).toList();
      }
      
      final sessionTypeStats = <CollaborationType, int>{};
      final participantStats = <String, int>{};
      final activityStats = <ActivityType, int>{};
      
      for (final session in sessions) {
        sessionTypeStats[session.type] = (sessionTypeStats[session.type] ?? 0) + 1;
        participantStats[session.id] = session.participants.length;
        
        for (final activity in session.activityFeed) {
          activityStats[activity.type] = (activityStats[activity.type] ?? 0) + 1;
        }
      }
      
      return CollaborationAnalytics(
        totalSessions: sessions.length,
        sessionTypeStats: sessionTypeStats,
        participantStats: participantStats,
        activityStats: activityStats,
        averageParticipants: sessions.isNotEmpty
            ? sessions.map((s) => s.participants.length).reduce((a, b) => a + b) / sessions.length
            : 0.0,
        startDate: startDate ?? DateTime.now().subtract(Duration(days: 30)),
        endDate: endDate ?? DateTime.now(),
      );
    } catch (e) {
      LoggingService.error('Failed to get collaboration analytics: $e');
      return CollaborationAnalytics(
        totalSessions: 0,
        sessionTypeStats: {},
        participantStats: {},
        activityStats: {},
        averageParticipants: 0.0,
        startDate: DateTime.now(),
        endDate: DateTime.now(),
      );
    }
  }

  // Event handling
  static void _handleCollaborationEvent(dynamic event) {
    try {
      final data = json.decode(event);
      final eventType = data['type'];
      
      switch (eventType) {
        case 'user_joined':
          _handleUserJoined(data);
          break;
        case 'user_left':
          _handleUserLeft(data);
          break;
        case 'cart_updated':
          _handleCartUpdated(data);
          break;
        case 'wishlist_updated':
          _handleWishlistUpdated(data);
          break;
        case 'cursor_updated':
          _handleCursorUpdated(data);
          break;
        case 'selection_updated':
          _handleSelectionUpdated(data);
          break;
        case 'chat_message':
          _handleChatMessage(data);
          break;
      }
    } catch (e) {
      LoggingService.error('Failed to handle collaboration event: $e');
    }
  }

  static void _handleUserJoined(Map<String, dynamic> data) {
    try {
      final sessionId = data['session_id'];
      final userId = data['user_id'];
      final userName = data['user_name'];
      
      _emitEvent(CollaborationEvent(
        type: CollaborationEventType.userJoined,
        data: data,
      ));
      
      LoggingService.info('User joined event handled: $userId -> $sessionId');
    } catch (e) {
      LoggingService.error('Failed to handle user joined event: $e');
    }
  }

  static void _handleUserLeft(Map<String, dynamic> data) {
    try {
      final sessionId = data['session_id'];
      final userId = data['user_id'];
      
      _emitEvent(CollaborationEvent(
        type: CollaborationEventType.userLeft,
        data: data,
      ));
      
      LoggingService.info('User left event handled: $userId -> $sessionId');
    } catch (e) {
      LoggingService.error('Failed to handle user left event: $e');
    }
  }

  static void _handleCartUpdated(Map<String, dynamic> data) {
    try {
      _emitEvent(CollaborationEvent(
        type: CollaborationEventType.cartUpdated,
        data: data,
      ));
      
      LoggingService.info('Cart updated event handled');
    } catch (e) {
      LoggingService.error('Failed to handle cart updated event: $e');
    }
  }

  static void _handleWishlistUpdated(Map<String, dynamic> data) {
    try {
      _emitEvent(CollaborationEvent(
        type: CollaborationEventType.wishlistUpdated,
        data: data,
      ));
      
      LoggingService.info('Wishlist updated event handled');
    } catch (e) {
      LoggingService.error('Failed to handle wishlist updated event: $e');
    }
  }

  static void _handleCursorUpdated(Map<String, dynamic> data) {
    try {
      _emitEvent(CollaborationEvent(
        type: CollaborationEventType.cursorUpdated,
        data: data,
      ));
      
      LoggingService.info('Cursor updated event handled');
    } catch (e) {
      LoggingService.error('Failed to handle cursor updated event: $e');
    }
  }

  static void _handleSelectionUpdated(Map<String, dynamic> data) {
    try {
      _emitEvent(CollaborationEvent(
        type: CollaborationEventType.selectionUpdated,
        data: data,
      ));
      
      LoggingService.info('Selection updated event handled');
    } catch (e) {
      LoggingService.error('Failed to handle selection updated event: $e');
    }
  }

  static void _handleChatMessage(Map<String, dynamic> data) {
    try {
      _emitEvent(CollaborationEvent(
        type: CollaborationEventType.chatMessage,
        data: data,
      ));
      
      LoggingService.info('Chat message event handled');
    } catch (e) {
      LoggingService.error('Failed to handle chat message event: $e');
    }
  }

  static void _handleCollaborationError(dynamic error) {
    LoggingService.error('Collaboration service error: $error');
    _emitEvent(CollaborationEvent(
      type: CollaborationEventType.error,
      data: {'error': error.toString()},
    ));
  }

  static void _handleCollaborationDisconnect() {
    LoggingService.info('Collaboration service disconnected');
    _isConnected = false;
    _emitEvent(CollaborationEvent(
      type: CollaborationEventType.serviceDisconnected,
      data: {},
    ));
  }

  static void _emitEvent(CollaborationEvent event) {
    _eventController?.add(event);
  }

  // Data loading
  static Future<void> _loadActiveSessions() async {
    try {
      // Mock loading active sessions
      _activeSessions.clear();
      
      // Add mock active sessions
      for (int i = 0; i < 3; i++) {
        final session = CollaborationSession(
          id: 'session_${DateTime.now().millisecondsSinceEpoch}_$i',
          name: 'Shopping Session ${i + 1}',
          type: CollaborationType.shopping,
          creatorId: 'user_${i}',
          creatorName: 'User ${i + 1}',
          status: SessionStatus.active,
          createdAt: DateTime.now().subtract(Duration(minutes: Random().nextInt(60))),
          endTime: null,
          participants: [],
          sharedCart: SharedCart(
            items: [],
            lastUpdated: DateTime.now(),
            version: 1,
          ),
          sharedWishlist: SharedWishlist(
            items: [],
            lastUpdated: DateTime.now(),
            version: 1,
          ),
          sharedNotes: SharedNotes(
            notes: [],
            lastUpdated: DateTime.now(),
            version: 1,
          ),
          activityFeed: [],
          config: {},
          metadata: {},
        );
        
        _activeSessions[session.id] = session;
      }
      
      LoggingService.info('Loaded ${_activeSessions.length} active sessions');
    } catch (e) {
      LoggingService.error('Failed to load active sessions: $e');
    }
  }

  // Utility methods
  static String _generateActivityId() {
    return 'activity_${DateTime.now().millisecondsSinceEpoch}';
  }

  static String _generateCartItemId() {
    return 'cart_item_${DateTime.now().millisecondsSinceEpoch}';
  }

  static String _generateWishlistItemId() {
    return 'wishlist_item_${DateTime.now().millisecondsSinceEpoch}';
  }

  static String _generateChatMessageId() {
    return 'chat_msg_${DateTime.now().millisecondsSinceEpoch}';
  }

  static String _getUserName(String userId) {
    return _connectedUsers[userId]?.name ?? 'Unknown User';
  }

  // Getters
  static bool get isInitialized => _isInitialized;
  static bool get isConnected => _isConnected;
  static Map<String, CollaborationSession> get activeSessions => Map.from(_activeSessions);
  static Map<String, User> get connectedUsers => Map.from(_connectedUsers);
  static List<CollaborationEvent> get eventHistory => List.from(_eventHistory);
  static Stream<CollaborationEvent> get events => _eventController?.stream ?? Stream.empty();
}

// Data models
class CollaborationSession {
  final String id;
  final String name;
  final CollaborationType type;
  final String creatorId;
  final String creatorName;
  SessionStatus status;
  final DateTime createdAt;
  final DateTime? endTime;
  final List<Participant> participants;
  final SharedCart sharedCart;
  final SharedWishlist sharedWishlist;
  final SharedNotes sharedNotes;
  final List<Activity> activityFeed;
  final List<ChatMessage>? chatMessages;
  final Map<String, dynamic> config;
  final Map<String, dynamic> metadata;

  CollaborationSession({
    required this.id,
    required this.name,
    required this.type,
    required this.creatorId,
    required this.creatorName,
    required this.status,
    required this.createdAt,
    this.endTime,
    required this.participants,
    required this.sharedCart,
    required this.sharedWishlist,
    required this.sharedNotes,
    required this.activityFeed,
    this.chatMessages,
    required this.config,
    required this.metadata,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'type': type.name,
      'creator_id': creatorId,
      'creator_name': creatorName,
      'status': status.name,
      'created_at': createdAt.toIso8601String(),
      'end_time': endTime?.toIso8601String(),
      'participants': participants.map((p) => p.toJson()).toList(),
      'shared_cart': sharedCart.toJson(),
      'shared_wishlist': sharedWishlist.toJson(),
      'shared_notes': sharedNotes.toJson(),
      'activity_feed': activityFeed.map((a) => a.toJson()).toList(),
      'chat_messages': chatMessages?.map((m) => m.toJson()).toList(),
      'config': config,
      'metadata': metadata,
    };
  }
}

class Participant {
  final String userId;
  final String userName;
  final ParticipantRole role;
  final ParticipantStatus status;
  final DateTime joinedAt;
  final DateTime lastActive;
  final Map<String, bool> permissions;
  CursorPosition cursor;
  final List<String> selection;

  Participant({
    required this.userId,
    required this.userName,
    required this.role,
    required this.status,
    required this.joinedAt,
    required this.lastActive,
    required this.permissions,
    required this.cursor,
    required this.selection,
  });

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'user_name': userName,
      'role': role.name,
      'status': status.name,
      'joined_at': joinedAt.toIso8601String(),
      'last_active': lastActive.toIso8601String(),
      'permissions': permissions,
      'cursor': cursor.toJson(),
      'selection': selection,
    };
  }
}

class CursorPosition {
  final double x;
  final double y;
  final bool visible;

  CursorPosition({
    required this.x,
    required this.y,
    required this.visible,
  });

  Map<String, dynamic> toJson() {
    return {
      'x': x,
      'y': y,
      'visible': visible,
    };
  }
}

class SharedCart {
  final List<CartItem> items;
  final DateTime lastUpdated;
  final int version;

  SharedCart({
    required this.items,
    required this.lastUpdated,
    required this.version,
  });

  Map<String, dynamic> toJson() {
    return {
      'items': items.map((item) => item.toJson()).toList(),
      'last_updated': lastUpdated.toIso8601String(),
      'version': version,
    };
  }
}

class CartItem {
  final String id;
  final String productId;
  final String productName;
  final double price;
  final int quantity;
  final String addedBy;
  final String addedByName;
  final DateTime addedAt;
  final Map<String, dynamic> productDetails;
  final List<String> sharedBy;

  CartItem({
    required this.id,
    required this.productId,
    required this.productName,
    required this.price,
    required this.quantity,
    required this.addedBy,
    required this.addedByName,
    required this.addedAt,
    required this.productDetails,
    required this.sharedBy,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'product_id': productId,
      'product_name': productName,
      'price': price,
      'quantity': quantity,
      'added_by': addedBy,
      'added_by_name': addedByName,
      'added_at': addedAt.toIso8601String(),
      'product_details': productDetails,
      'shared_by': sharedBy,
    };
  }
}

class SharedWishlist {
  final List<WishlistItem> items;
  final DateTime lastUpdated;
  final int version;

  SharedWishlist({
    required this.items,
    required this.lastUpdated,
    required this.version,
  });

  Map<String, dynamic> toJson() {
    return {
      'items': items.map((item) => item.toJson()).toList(),
      'last_updated': lastUpdated.toIso8601String(),
      'version': version,
    };
  }
}

class WishlistItem {
  final String id;
  final String productId;
  final String productName;
  final double? price;
  final String addedBy;
  final String addedByName;
  final DateTime addedAt;
  final Map<String, dynamic> productDetails;
  final List<Vote> votes;
  final List<Comment> comments;

  WishlistItem({
    required this.id,
    required this.productId,
    required this.productName,
    this.price,
    required this.addedBy,
    required this.addedByName,
    required this.addedAt,
    required this.productDetails,
    required this.votes,
    required this.comments,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'product_id': productId,
      'product_name': productName,
      'price': price,
      'added_by': addedBy,
      'added_by_name': addedByName,
      'added_at': addedAt.toIso8601String(),
      'product_details': productDetails,
      'votes': votes.map((v) => v.toJson()).toList(),
      'comments': comments.map((c) => c.toJson()).toList(),
    };
  }
}

class Vote {
  final String userId;
  final String userName;
  final bool value;
  final DateTime timestamp;

  Vote({
    required this.userId,
    required this.userName,
    required this.value,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'user_name': userName,
      'value': value,
      'timestamp': timestamp.toIso8601String(),
    };
  }
}

class Comment {
  final String id;
  final String userId;
  final String userName;
  final String text;
  final DateTime timestamp;
  final List<Reaction> reactions;

  Comment({
    required this.id,
    required this.userId,
    required this.userName,
    required this.text,
    required this.timestamp,
    required this.reactions,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'user_name': userName,
      'text': text,
      'timestamp': timestamp.toIso8601String(),
      'reactions': reactions.map((r) => r.toJson()).toList(),
    };
  }
}

class Reaction {
  final String userId;
  final String userName;
  final String emoji;
  final DateTime timestamp;

  Reaction({
    required this.userId,
    required this.userName,
    required this.emoji,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'user_name': userName,
      'emoji': emoji,
      'timestamp': timestamp.toIso8601String(),
    };
  }
}

class SharedNotes {
  final List<Note> notes;
  final DateTime lastUpdated;
  final int version;

  SharedNotes({
    required this.notes,
    required this.lastUpdated,
    required this.version,
  });

  Map<String, dynamic> toJson() {
    return {
      'notes': notes.map((note) => note.toJson()).toList(),
      'last_updated': lastUpdated.toIso8601String(),
      'version': version,
    };
  }
}

class Note {
  final String id;
  final String title;
  final String content;
  final String createdBy;
  final String createdByName;
  final DateTime createdAt;
  final DateTime lastModified;
  final List<String> tags;
  final bool isPinned;

  Note({
    required this.id,
    required this.title,
    required this.content,
    required this.createdBy,
    required this.createdByName,
    required this.createdAt,
    required this.lastModified,
    required this.tags,
    required this.isPinned,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'created_by': createdBy,
      'created_by_name': createdByName,
      'created_at': createdAt.toIso8601String(),
      'last_modified': lastModified.toIso8601String(),
      'tags': tags,
      'is_pinned': isPinned,
    };
  }
}

class Activity {
  final String id;
  final ActivityType type;
  final String userId;
  final String userName;
  final DateTime timestamp;
  final Map<String, dynamic> data;

  Activity({
    required this.id,
    required this.type,
    required this.userId,
    required this.userName,
    required this.timestamp,
    required this.data,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.name,
      'user_id': userId,
      'user_name': userName,
      'timestamp': timestamp.toIso8601String(),
      'data': data,
    };
  }
}

class ChatMessage {
  final String id;
  final String userId;
  final String userName;
  final String message;
  final MessageType messageType;
  final DateTime timestamp;
  final Map<String, dynamic> attachments;
  final Map<String, List<Reaction>> reactions;
  final bool isEdited;
  final String? replyTo;

  ChatMessage({
    required this.id,
    required this.userId,
    required this.userName,
    required this.message,
    required this.messageType,
    required this.timestamp,
    required this.attachments,
    required this.reactions,
    required this.isEdited,
    this.replyTo,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'user_name': userName,
      'message': message,
      'message_type': messageType.name,
      'timestamp': timestamp.toIso8601String(),
      'attachments': attachments,
      'reactions': reactions.map((k, v) => MapEntry(k, v.map((r) => r.toJson()).toList())),
      'is_edited': isEdited,
      'reply_to': replyTo,
    };
  }
}

class User {
  final String id;
  final String name;
  final UserStatus status;
  final String? currentSession;
  final DateTime lastSeen;

  User({
    required this.id,
    required this.name,
    required this.status,
    this.currentSession,
    required this.lastSeen,
  });
}

class CollaborationAnalytics {
  final int totalSessions;
  final Map<CollaborationType, int> sessionTypeStats;
  final Map<String, int> participantStats;
  final Map<ActivityType, int> activityStats;
  final double averageParticipants;
  final DateTime startDate;
  final DateTime endDate;

  CollaborationAnalytics({
    required this.totalSessions,
    required this.sessionTypeStats,
    required this.participantStats,
    required this.activityStats,
    required this.averageParticipants,
    required this.startDate,
    required this.endDate,
  });
}

class CollaborationEvent {
  final CollaborationEventType type;
  final Map<String, dynamic> data;
  final DateTime timestamp;

  CollaborationEvent({
    required this.type,
    required this.data,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();
}

class SessionResult {
  final bool success;
  final CollaborationSession? session;
  final String? error;

  SessionResult({
    required this.success,
    this.session,
    this.error,
  });
}

class CartResult {
  final bool success;
  final CartItem? cartItem;
  final String? error;

  CartResult({
    required this.success,
    this.cartItem,
    this.error,
  });
}

class WishlistResult {
  final bool success;
  final WishlistItem? wishlistItem;
  final String? error;

  WishlistResult({
    required this.success,
    this.wishlistItem,
    this.error,
  });
}

class ChatResult {
  final bool success;
  final ChatMessage? message;
  final String? error;

  ChatResult({
    required this.success,
    this.message,
    this.error,
  });
}

enum CollaborationType {
  shopping,
  planning,
  decision,
  review,
  brainstorm,
}

enum SessionStatus {
  active,
  paused,
  ended,
  error,
}

enum ParticipantRole {
  creator,
  admin,
  collaborator,
  viewer,
}

enum ParticipantStatus {
  active,
  away,
  busy,
  offline,
}

enum ActivityType {
  userJoined,
  userLeft,
  cartUpdated,
  wishlistUpdated,
  notesUpdated,
  chatMessage,
  cursorUpdated,
  selectionUpdated,
  fileShared,
}

enum MessageType {
  text,
  image,
  file,
  emoji,
  system,
}

enum UserStatus {
  online,
  away,
  busy,
  offline,
}

enum CollaborationEventType {
  sessionCreated,
  sessionJoined,
  sessionLeft,
  sessionEnded,
  userJoined,
  userLeft,
  cartUpdated,
  wishlistUpdated,
  notesUpdated,
  cursorUpdated,
  selectionUpdated,
  chatMessage,
  fileShared,
  error,
  serviceDisconnected,
}
