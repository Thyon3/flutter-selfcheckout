import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:selfcheckoutapp/services/logging_service.dart';
import 'package:selfcheckoutapp/services/cache_service.dart';
import 'package:selfcheckoutapp/services/security_service.dart';
import 'package:selfcheckoutapp/services/holographic_display_service.dart';

class MetaverseShoppingService {
  static const String _baseUrl = 'https://api.metaverse.scango.app';
  static const String _wsUrl = 'wss://metaverse.scango.app/ws';
  static const String _apiKey = 'metaverse_api_key_12345';
  static const String _cacheKey = 'metaverse_cache';
  
  static bool _isInitialized = false;
  static bool _isConnected = false;
  static WebSocketChannel? _metaverseChannel;
  static StreamSubscription? _metaverseSubscription;
  static MetaverseUser? _currentUser;
  static final Map<String, MetaverseWorld> _availableWorlds = {};
  static final List<ShoppingSession> _activeSessions = [];
  static final List<VirtualStore> _virtualStores = [];
  static final List<Avatar> _availableAvatars = [];
  static StreamController<MetaverseEvent>? _eventController;

  // Metaverse shopping service initialization
  static Future<bool> initialize() async {
    try {
      if (_isInitialized) return true;
      
      LoggingService.info('Initializing metaverse shopping service');
      
      // Initialize event controller
      _eventController = StreamController<MetaverseEvent>.broadcast();
      
      // Connect to metaverse platform
      await _connectToMetaverse();
      
      // Load available worlds
      await _loadAvailableWorlds();
      
      // Load virtual stores
      await _loadVirtualStores();
      
      // Load available avatars
      await _loadAvailableAvatars();
      
      _isInitialized = true;
      
      LoggingService.info('Metaverse shopping service initialized successfully');
      return true;
    } catch (e) {
      LoggingService.error('Failed to initialize metaverse shopping service: $e');
      return false;
    }
  }

  // Metaverse platform connection
  static Future<void> _connectToMetaverse() async {
    try {
      _metaverseChannel = WebSocketChannel.connect(Uri.parse('$_wsUrl/platform'));
      
      // Authenticate
      final authMessage = {
        'type': 'auth',
        'api_key': _apiKey,
        'timestamp': DateTime.now().toIso8601String(),
      };
      
      _metaverseChannel!.sink.add(json.encode(authMessage));
      
      // Listen for metaverse events
      _metaverseSubscription = _metaverseChannel!.stream.listen(
        _handleMetaverseEvent,
        onError: _handleMetaverseError,
        onDone: _handleMetaverseDisconnect,
      );
      
      _isConnected = true;
      
      LoggingService.info('Connected to metaverse platform');
    } catch (e) {
      LoggingService.error('Failed to connect to metaverse: $e');
      _isConnected = false;
    }
  }

  // User management
  static Future<MetaverseUserResult> createUser({
    required String userId,
    required String username,
    required String email,
    String? avatarId,
    Map<String, dynamic>? userProfile,
  }) async {
    try {
      if (!_isInitialized) {
        await initialize();
      }
      
      // Create metaverse user
      final user = MetaverseUser(
        id: userId,
        username: username,
        email: email,
        avatarId: avatarId,
        profile: userProfile ?? {},
        inventory: [],
        currency: 1000.0,
        experience: 0,
        level: 1,
        achievements: [],
        friends: [],
        createdAt: DateTime.now(),
        lastActive: DateTime.now(),
        isOnline: false,
      );
      
      _currentUser = user;
      
      // Register user on metaverse platform
      await _registerUserOnMetaverse(user);
      
      // Emit user created event
      _emitEvent(MetaverseEvent(
        type: MetaverseEventType.userCreated,
        data: user.toJson(),
      ));
      
      LoggingService.info('Metaverse user created: $userId');
      return MetaverseUserResult(
        success: true,
        user: user,
      );
    } catch (e) {
      LoggingService.error('Failed to create metaverse user: $e');
      return MetaverseUserResult(
        success: false,
        error: e.toString(),
      );
    }
  }

  static Future<void> _registerUserOnMetaverse(MetaverseUser user) async {
    try {
      final registration = {
        'type': 'register_user',
        'user_id': user.id,
        'username': user.username,
        'email': user.email,
        'avatar_id': user.avatarId,
        'profile': user.profile,
        'timestamp': DateTime.now().toIso8601String(),
      };
      
      _metaverseChannel?.sink.add(json.encode(registration));
      
      LoggingService.info('User registered on metaverse: ${user.id}');
    } catch (e) {
      LoggingService.error('Failed to register user on metaverse: $e');
    }
  }

  // Avatar management
  static Future<AvatarResult> selectAvatar({
    required String avatarId,
    Map<String, dynamic>? customizations,
  }) async {
    try {
      if (_currentUser == null) {
        return AvatarResult(
          success: false,
          error: 'No active user',
        );
      }
      
      final avatar = _availableAvatars.firstWhere(
        (a) => a.id == avatarId,
        orElse: () => throw Exception('Avatar not found: $avatarId'),
      );
      
      // Apply customizations
      if (customizations != null) {
        avatar.customizations.addAll(customizations);
      }
      
      // Update user avatar
      _currentUser!.avatarId = avatarId;
      
      // Equip avatar on metaverse
      await _equipAvatarOnMetaverse(avatar);
      
      // Emit avatar selected event
      _emitEvent(MetaverseEvent(
        type: MetaverseEventType.avatarSelected,
        data: {
          'user_id': _currentUser!.id,
          'avatar_id': avatarId,
          'customizations': customizations,
        },
      ));
      
      LoggingService.info('Avatar selected: $avatarId');
      return AvatarResult(
        success: true,
        avatar: avatar,
      );
    } catch (e) {
      LoggingService.error('Failed to select avatar: $e');
      return AvatarResult(
        success: false,
        error: e.toString(),
      );
    }
  }

  static Future<void> _equipAvatarOnMetaverse(Avatar avatar) async {
    try {
      final equipMessage = {
        'type': 'equip_avatar',
        'user_id': _currentUser!.id,
        'avatar_id': avatar.id,
        'customizations': avatar.customizations,
        'timestamp': DateTime.now().toIso8601String(),
      };
      
      _metaverseChannel?.sink.add(json.encode(equipMessage));
      
      LoggingService.info('Avatar equipped on metaverse: ${avatar.id}');
    } catch (e) {
      LoggingService.error('Failed to equip avatar on metaverse: $e');
    }
  }

  // World management
  static Future<WorldResult> enterWorld({
    required String worldId,
    Map<String, dynamic>? entryOptions,
  }) async {
    try {
      if (_currentUser == null) {
        return WorldResult(
          success: false,
          error: 'No active user',
        );
      }
      
      final world = _availableWorlds[worldId];
      if (world == null) {
        return WorldResult(
          success: false,
          error: 'World not found: $worldId',
        );
      }
      
      // Create shopping session
      final session = ShoppingSession(
        id: _generateSessionId(),
        userId: _currentUser!.id,
        worldId: worldId,
        startTime: DateTime.now(),
        endTime: null,
        status: SessionStatus.active,
        visitedStores: [],
        purchasedItems: [],
        interactions: [],
        currency: _currentUser!.currency,
        experience: 0,
        properties: entryOptions ?? {},
      );
      
      _activeSessions.add(session);
      
      // Enter world on metaverse
      await _enterWorldOnMetaverse(world, session);
      
      // Update user status
      _currentUser!.isOnline = true;
      _currentUser!.lastActive = DateTime.now();
      
      // Emit world entered event
      _emitEvent(MetaverseEvent(
        type: MetaverseEventType.worldEntered,
        data: {
          'user_id': _currentUser!.id,
          'world_id': worldId,
          'session_id': session.id,
        },
      ));
      
      LoggingService.info('World entered: $worldId');
      return WorldResult(
        success: true,
        world: world,
        session: session,
      );
    } catch (e) {
      LoggingService.error('Failed to enter world: $e');
      return WorldResult(
        success: false,
        error: e.toString(),
      );
    }
  }

  static Future<void> _enterWorldOnMetaverse(MetaverseWorld world, ShoppingSession session) async {
    try {
      final entryMessage = {
        'type': 'enter_world',
        'user_id': _currentUser!.id,
        'world_id': world.id,
        'session_id': session.id,
        'avatar_id': _currentUser!.avatarId,
        'entry_options': session.properties,
        'timestamp': DateTime.now().toIso8601String(),
      };
      
      _metaverseChannel?.sink.add(json.encode(entryMessage));
      
      LoggingService.info('User entered world on metaverse: ${world.id}');
    } catch (e) {
      LoggingService.error('Failed to enter world on metaverse: $e');
    }
  }

  static Future<void> leaveWorld() async {
    try {
      if (_currentUser == null || _activeSessions.isEmpty) return;
      
      final session = _activeSessions.last;
      final world = _availableWorlds[session.worldId];
      
      // Leave world on metaverse
      await _leaveWorldOnMetaverse(world, session);
      
      // Update session status
      session.status = SessionStatus.ended;
      session.endTime = DateTime.now();
      
      // Update user status
      _currentUser!.isOnline = false;
      
      // Emit world left event
      _emitEvent(MetaverseEvent(
        type: MetaverseEventType.worldLeft,
        data: {
          'user_id': _currentUser!.id,
          'world_id': world?.id,
          'session_id': session.id,
        },
      ));
      
      LoggingService.info('World left: ${world?.id}');
    } catch (e) {
      LoggingService.error('Failed to leave world: $e');
    }
  }

  static Future<void> _leaveWorldOnMetaverse(MetaverseWorld? world, ShoppingSession session) async {
    try {
      final leaveMessage = {
        'type': 'leave_world',
        'user_id': _currentUser!.id,
        'world_id': world?.id,
        'session_id': session.id,
        'timestamp': DateTime.now().toIso8601String(),
      };
      
      _metaverseChannel?.sink.add(json.encode(leaveMessage));
      
      LoggingService.info('User left world on metaverse: ${world?.id}');
    } catch (e) {
      LoggingService.error('Failed to leave world on metaverse: $e');
    }
  }

  // Virtual store management
  static Future<StoreResult> visitVirtualStore({
    required String storeId,
    Map<String, dynamic>? visitOptions,
  }) async {
    try {
      if (_activeSessions.isEmpty) {
        return StoreResult(
          success: false,
          error: 'No active session',
        );
      }
      
      final session = _activeSessions.last;
      final store = _virtualStores.firstWhere(
        (s) => s.id == storeId,
        orElse: () => throw Exception('Store not found: $storeId'),
      );
      
      // Visit store on metaverse
      await _visitStoreOnMetaverse(store, session);
      
      // Update session
      session.visitedStores.add(storeId);
      
      // Record interaction
      final interaction = StoreInteraction(
        id: _generateInteractionId(),
        storeId: storeId,
        type: InteractionType.visit,
        timestamp: DateTime.now(),
        data: visitOptions ?? {},
      );
      
      session.interactions.add(interaction);
      
      // Emit store visited event
      _emitEvent(MetaverseEvent(
        type: MetaverseEventType.storeVisited,
        data: {
          'user_id': _currentUser!.id,
          'session_id': session.id,
          'store_id': storeId,
        },
      ));
      
      LoggingService.info('Virtual store visited: $storeId');
      return StoreResult(
        success: true,
        store: store,
      );
    } catch (e) {
      LoggingService.error('Failed to visit virtual store: $e');
      return StoreResult(
        success: false,
        error: e.toString(),
      );
    }
  }

  static Future<void> _visitStoreOnMetaverse(VirtualStore store, ShoppingSession session) async {
    try {
      final visitMessage = {
        'type': 'visit_store',
        'user_id': _currentUser!.id,
        'session_id': session.id,
        'store_id': store.id,
        'avatar_id': _currentUser!.avatarId,
        'visit_options': {},
        'timestamp': DateTime.now().toIso8601String(),
      };
      
      _metaverseChannel?.sink.add(json.encode(visitMessage));
      
      LoggingService.info('User visited virtual store on metaverse: ${store.id}');
    } catch (e) {
      LoggingService.error('Failed to visit virtual store on metaverse: $e');
    }
  }

  // Product browsing and purchasing
  static Future<ProductResult> browseProduct({
    required String productId,
    required String storeId,
    Map<String, dynamic>? browseOptions,
  }) async {
    try {
      if (_activeSessions.isEmpty) {
        return ProductResult(
          success: false,
          error: 'No active session',
        );
      }
      
      final session = _activeSessions.last;
      final store = _virtualStores.firstWhere(
        (s) => s.id == storeId,
        orElse: () => throw Exception('Store not found: $storeId'),
      );
      
      // Find product in store
      final product = store.products.firstWhere(
        (p) => p.id == productId,
        orElse: () => throw Exception('Product not found: $productId'),
      );
      
      // Browse product on metaverse
      await _browseProductOnMetaverse(product, session);
      
      // Record interaction
      final interaction = StoreInteraction(
        id: _generateInteractionId(),
        storeId: storeId,
        type: InteractionType.browse,
        timestamp: DateTime.now(),
        data: {
          'product_id': productId,
          'browse_options': browseOptions ?? {},
        },
      );
      
      session.interactions.add(interaction);
      
      // Emit product browsed event
      _emitEvent(MetaverseEvent(
        type: MetaverseEventType.productBrowsed,
        data: {
          'user_id': _currentUser!.id,
          'session_id': session.id,
          'store_id': storeId,
          'product_id': productId,
        },
      ));
      
      LoggingService.info('Product browsed in metaverse: $productId');
      return ProductResult(
        success: true,
        product: product,
      );
    } catch (e) {
      LoggingService.error('Failed to browse product: $e');
      return ProductResult(
        success: false,
        error: e.toString(),
      );
    }
  }

  static Future<void> _browseProductOnMetaverse(VirtualProduct product, ShoppingSession session) async {
    try {
      final browseMessage = {
        'type': 'browse_product',
        'user_id': _currentUser!.id,
        'session_id': session.id,
        'store_id': product.storeId,
        'product_id': product.id,
        'avatar_id': _currentUser!.avatarId,
        'product_data': product.toJson(),
        'timestamp': DateTime.now().toIso8601String(),
      };
      
      _metaverseChannel?.sink.add(json.encode(browseMessage));
      
      LoggingService.info('User browsed product on metaverse: ${product.id}');
    } catch (e) {
      LoggingService.error('Failed to browse product on metaverse: $e');
    }
  }

  static Future<PurchaseResult> purchaseProduct({
    required String productId,
    required String storeId,
    required int quantity,
    Map<String, dynamic>? purchaseOptions,
  }) async {
    try {
      if (_activeSessions.isEmpty) {
        return PurchaseResult(
          success: false,
          error: 'No active session',
        );
      }
      
      final session = _activeSessions.last;
      final store = _virtualStores.firstWhere(
        (s) => s.id == storeId,
        orElse: () => throw Exception('Store not found: $storeId'),
      );
      
      final product = store.products.firstWhere(
        (p) => p.id == productId,
        orElse: () => throw Exception('Product not found: $productId'),
      );
      
      // Check if user has enough currency
      final totalPrice = product.price * quantity;
      if (session.currency < totalPrice) {
        return PurchaseResult(
          success: false,
          error: 'Insufficient currency',
        );
      }
      
      // Purchase product on metaverse
      final purchaseResult = await _purchaseProductOnMetaverse(product, session, quantity);
      
      if (purchaseResult.success) {
        // Update session
        session.currency -= totalPrice;
        session.purchasedItems.add(PurchasedItem(
          productId: productId,
          storeId: storeId,
          quantity: quantity,
          price: product.price,
          purchaseTime: DateTime.now(),
        ));
        
        // Update user
        _currentUser!.currency = session.currency;
        _currentUser!.experience += 10;
        
        // Record interaction
        final interaction = StoreInteraction(
          id: _generateInteractionId(),
          storeId: storeId,
          type: InteractionType.purchase,
          timestamp: DateTime.now(),
          data: {
            'product_id': productId,
            'quantity': quantity,
            'price': product.price,
            'total_price': totalPrice,
          },
        );
        
        session.interactions.add(interaction);
        
        // Emit product purchased event
        _emitEvent(MetaverseEvent(
          type: MetaverseEventType.productPurchased,
          data: {
            'user_id': _currentUser!.id,
            'session_id': session.id,
            'store_id': storeId,
            'product_id': productId,
            'quantity': quantity,
            'price': product.price,
            'total_price': totalPrice,
          },
        ));
        
        LoggingService.info('Product purchased in metaverse: $productId ($quantity units for Rs $totalPrice)');
      }
      
      return purchaseResult;
    } catch (e) {
      LoggingService.error('Failed to purchase product: $e');
      return PurchaseResult(
        success: false,
        error: e.toString(),
      );
    }
  }

  static Future<PurchaseResult> _purchaseProductOnMetaverse(
    VirtualProduct product,
    ShoppingSession session,
    int quantity,
  ) async {
    try {
      final purchaseMessage = {
        'type': 'purchase_product',
        'user_id': _currentUser!.id,
        'session_id': session.id,
        'store_id': product.storeId,
        'product_id': product.id,
        'quantity': quantity,
        'price': product.price,
        'avatar_id': _currentUser!.avatarId,
        'timestamp': DateTime.now().toIso8601String(),
      };
      
      _metaverseChannel?.sink.add(json.encode(purchaseMessage));
      
      // Mock purchase processing
      await Future.delayed(Duration(seconds: 2));
      
      LoggingService.info('Product purchased on metaverse: ${product.id}');
      return PurchaseResult(
        success: true,
        transactionId: _generateTransactionId(),
      );
    } catch (e) {
      LoggingService.error('Failed to purchase product on metaverse: $e');
      return PurchaseResult(
        success: false,
        error: e.toString(),
      );
    }
  }

  // Social features
  static Future<FriendResult> addFriend({
    required String friendId,
    String? message,
  }) async {
    try {
      if (_currentUser == null) {
        return FriendResult(
          success: false,
          error: 'No active user',
        );
      }
      
      // Send friend request
      await _sendFriendRequest(friendId, message);
      
      // Add to user's friend list (pending)
      if (!_currentUser!.friends.contains(friendId)) {
        _currentUser!.friends.add(friendId);
      }
      
      // Emit friend request sent event
      _emitEvent(MetaverseEvent(
        type: MetaverseEventType.friendRequestSent,
        data: {
          'user_id': _currentUser!.id,
          'friend_id': friendId,
          'message': message,
        },
      ));
      
      LoggingService.info('Friend request sent: $friendId');
      return FriendResult(
        success: true,
      );
    } catch (e) {
      LoggingService.error('Failed to add friend: $e');
      return FriendResult(
        success: false,
        error: e.toString(),
      );
    }
  }

  static Future<void> _sendFriendRequest(String friendId, String? message) async {
    try {
      final requestMessage = {
        'type': 'send_friend_request',
        'user_id': _currentUser!.id,
        'friend_id': friendId,
        'message': message ?? 'Let\'s be friends in the metaverse!',
        'timestamp': DateTime.now().toIso8601String(),
      };
      
      _metaverseChannel?.sink.add(json.encode(requestMessage));
      
      LoggingService.info('Friend request sent to metaverse: $friendId');
    } catch (e) {
      LoggingService.error('Failed to send friend request: $e');
    }
  }

  static Future<ChatResult> startChat({
    required String userId,
    String? message,
  }) async {
    try {
      if (_currentUser == null) {
        return ChatResult(
          success: false,
          error: 'No active user',
        );
      }
      
      // Start chat session
      final chatId = _generateChatId();
      
      // Send chat message
      if (message != null) {
        await _sendChatMessage(chatId, userId, message);
      }
      
      // Emit chat started event
      _emitEvent(MetaverseEvent(
        type: MetaverseEventType.chatStarted,
        data: {
          'user_id': _currentUser!.id,
          'friend_id': userId,
          'chat_id': chatId,
        },
      ));
      
      LoggingService.info('Chat started with: $userId');
      return ChatResult(
        success: true,
        chatId: chatId,
      );
    } catch (e) {
      LoggingService.error('Failed to start chat: $e');
      return ChatResult(
        success: false,
        error: e.toString(),
      );
    }
  }

  static Future<void> _sendChatMessage(String chatId, String userId, String message) async {
    try {
      final chatMessage = {
        'type': 'send_chat_message',
        'chat_id': chatId,
        'sender_id': _currentUser!.id,
        'receiver_id': userId,
        'message': message,
        'timestamp': DateTime.now().toIso8601String(),
      };
      
      _metaverseChannel?.sink.add(json.encode(chatMessage));
      
      LoggingService.info('Chat message sent to metaverse: $userId');
    } catch (e) {
      LoggingService.error('Failed to send chat message: $e');
    }
  }

  // Event handling
  static void _handleMetaverseEvent(dynamic event) {
    try {
      final data = json.decode(event);
      final eventType = data['type'];
      
      switch (eventType) {
        case 'user_status_updated':
          _handleUserStatusUpdated(data);
          break;
        case 'friend_request_received':
          _handleFriendRequestReceived(data);
          break;
        case 'chat_message_received':
          _handleChatMessageReceived(data);
          break;
        case 'store_event':
          _handleStoreEvent(data);
          break;
        case 'world_event':
          _handleWorldEvent(data);
          break;
      }
    } catch (e) {
      LoggingService.error('Failed to handle metaverse event: $e');
    }
  }

  static void _handleUserStatusUpdated(Map<String, dynamic> data) {
    try {
      final userId = data['user_id'];
      final isOnline = data['is_online'];
      
      if (_currentUser != null && _currentUser!.id == userId) {
        _currentUser!.isOnline = isOnline;
        _currentUser!.lastActive = DateTime.now();
      }
      
      _emitEvent(MetaverseEvent(
        type: MetaverseEventType.userStatusUpdated,
        data: data,
      ));
    } catch (e) {
      LoggingService.error('Failed to handle user status updated: $e');
    }
  }

  static void _handleFriendRequestReceived(Map<String, dynamic> data) {
    try {
      _emitEvent(MetaverseEvent(
        type: MetaverseEventType.friendRequestReceived,
        data: data,
      ));
    } catch (e) {
      LoggingService.error('Failed to handle friend request received: $e');
    }
  }

  static void _handleChatMessageReceived(Map<String, dynamic> data) {
    try {
      _emitEvent(MetaverseEvent(
        type: MetaverseEventType.chatMessageReceived,
        data: data,
      ));
    } catch (e) {
      LoggingService.error('Failed to handle chat message received: $e');
    }
  }

  static void _handleStoreEvent(Map<String, dynamic> data) {
    try {
      _emitEvent(MetaverseEvent(
        type: MetaverseEventType.storeEvent,
        data: data,
      ));
    } catch (e) {
      LoggingService.error('Failed to handle store event: $e');
    }
  }

  static void _handleWorldEvent(Map<String, dynamic> data) {
    try {
      _emitEvent(MetaverseEvent(
        type: MetaverseEventType.worldEvent,
        data: data,
      ));
    } catch (e) {
      LoggingService.error('Failed to handle world event: $e');
    }
  }

  static void _handleMetaverseError(dynamic error) {
    LoggingService.error('Metaverse service error: $error');
    _emitEvent(MetaverseEvent(
      type: MetaverseEventType.error,
      data: {'error': error.toString()},
    ));
  }

  static void _handleMetaverseDisconnect() {
    LoggingService.info('Metaverse service disconnected');
    _isConnected = false;
    _emitEvent(MetaverseEvent(
      type: MetaverseEventType.serviceDisconnected,
      data: {},
    ));
  }

  static void _emitEvent(MetaverseEvent event) {
    _eventController?.add(event);
  }

  // Data loading
  static Future<void> _loadAvailableWorlds() async {
    try {
      // Mock loading available worlds
      _availableWorlds.addAll([
        MetaverseWorld(
          id: 'shopping_mall',
          name: 'ScanGo Shopping Mall',
          description: 'A virtual shopping mall with multiple stores',
          type: WorldType.shopping,
          capacity: 1000,
          currentVisitors: 0,
          stores: ['store_1', 'store_2', 'store_3'],
          environment: WorldEnvironment.indoor,
          features: ['virtual_currency', 'social_features', 'events'],
          createdAt: DateTime.now().subtract(Duration(days: 30)),
          isActive: true,
        ),
        MetaverseWorld(
          id: 'marketplace',
          name: 'ScanGo Marketplace',
          description: 'An open-air marketplace with various vendors',
          type: WorldType.marketplace,
          capacity: 500,
          currentVisitors: 0,
          stores: ['vendor_1', 'vendor_2', 'vendor_3'],
          environment: WorldEnvironment.outdoor,
          features: ['virtual_currency', 'social_features', 'live_events'],
          createdAt: DateTime.now().subtract(Duration(days: 20)),
          isActive: true,
        ),
        MetaverseWorld(
          id: 'showroom',
          name: 'ScanGo Showroom',
          description: 'A premium showroom for high-end products',
          type: WorldType.showroom,
          capacity: 100,
          currentVisitors: 0,
          stores: ['premium_store'],
          environment: WorldEnvironment.indoor,
          features: ['virtual_currency', 'premium_products', 'personalized_service'],
          createdAt: DateTime.now().subtract(Duration(days: 10)),
          isActive: true,
        ),
      ]);
    } catch (e) {
      LoggingService.error('Failed to load available worlds: $e');
    }
  }

  static Future<void> _loadVirtualStores() async {
    try {
      // Mock loading virtual stores
      _virtualStores.addAll([
        VirtualStore(
          id: 'store_1',
          name: 'Tech Haven',
          description: 'Electronics and gadgets store',
          category: StoreCategory.electronics,
          worldId: 'shopping_mall',
          products: [
            VirtualProduct(
              id: 'product_1',
              name: 'iPhone 15 Pro',
              description: 'Latest iPhone with advanced features',
              price: 999.99,
              currency: 'USD',
              category: ProductCategory.smartphones,
              imageUrl: 'https://api.metaverse.scango.app/images/iphone_15_pro.png',
              hologramUrl: 'https://api.metaverse.scango.app/holograms/iphone_15_pro.glb',
              features: ['5G', 'Pro Camera', 'A17 Chip', 'Face ID'],
              availability: ProductAvailability.inStock,
              rating: 4.8,
              reviews: 1250,
              storeId: 'store_1',
            ),
            VirtualProduct(
              id: 'product_2',
              name: 'MacBook Pro M3',
              description: 'Powerful laptop with M3 chip',
              price: 1999.99,
              currency: 'USD',
              category: ProductCategory.laptops,
              imageUrl: 'https://api.metaverse.scango.app/images/macbook_pro_m3.png',
              hologramUrl: 'https://api.metaverse.scango.app/holograms/macbook_pro_m3.glb',
              features: ['M3 Chip', 'Liquid Retina', 'Touch Bar', 'Long Battery'],
              availability: ProductAvailability.inStock,
              rating: 4.9,
              reviews: 890,
              storeId: 'store_1',
            ),
          ],
          owner: 'tech_company',
          rating: 4.7,
          reviews: 2340,
          isOpen: true,
          createdAt: DateTime.now().subtract(Duration(days: 15)),
          lastUpdated: DateTime.now(),
        ),
        VirtualStore(
          id: 'store_2',
          name: 'Fashion Forward',
          description: 'Fashion and apparel store',
          category: StoreCategory.fashion,
          worldId: 'shopping_mall',
          products: [
            VirtualProduct(
              id: 'product_3',
              name: 'Designer Jacket',
              description: 'Stylish designer jacket',
              price: 299.99,
              currency: 'USD',
              category: ProductCategory.clothing,
              imageUrl: 'https://api.metaverse.scango.app/images/designer_jacket.png',
              hologramUrl: 'https://api.metaverse.scango.app/holograms/designer_jacket.glb',
              features: ['Premium Material', 'Designer Brand', 'Limited Edition'],
              availability: ProductAvailability.limited,
              rating: 4.6,
              reviews: 450,
              storeId: 'store_2',
            ),
          ],
          owner: 'fashion_brand',
          rating: 4.5,
          reviews: 1230,
          isOpen: true,
          createdAt: DateTime.now().subtract(Duration(days: 12)),
          lastUpdated: DateTime.now(),
        ),
      ]);
    } catch (e) {
      LoggingService.error('Failed to load virtual stores: $e');
    }
  }

  static Future<void> _loadAvailableAvatars() async {
    try {
      // Mock loading available avatars
      _availableAvatars.addAll([
        Avatar(
          id: 'avatar_1',
          name: 'Tech Enthusiast',
          description: 'Avatar for tech lovers',
          style: AvatarStyle.modern,
          gender: AvatarGender.unisex,
          baseModel: 'humanoid',
          customizations: {
            'hair_color': 'brown',
            'eye_color': 'blue',
            'skin_tone': 'medium',
          },
          price: 100.0,
          currency: 'USD',
          isPremium: false,
          tags: ['tech', 'modern', 'professional'],
          createdAt: DateTime.now().subtract(Duration(days: 30)),
        ),
        Avatar(
          id: 'avatar_2',
          name: 'Fashion Icon',
          description: 'Stylish avatar for fashion lovers',
          style: AvatarStyle.trendy,
          gender: AvatarGender.female,
          baseModel: 'humanoid',
          customizations: {
            'hair_color': 'blonde',
            'eye_color': 'green',
            'skin_tone': 'light',
          },
          price: 150.0,
          currency: 'USD',
          isPremium: true,
          tags: ['fashion', 'trendy', 'stylish'],
          createdAt: DateTime.now().subtract(Duration(days: 25)),
        ),
      ]);
    } catch (e) {
      LoggingService.error('Failed to load available avatars: $e');
    }
  }

  // Analytics and insights
  static Future<MetaverseAnalytics> getAnalytics({
    DateTime? startDate,
    DateTime? endDate,
    String? userId,
  }) async {
    try {
      var sessions = List<ShoppingSession>.from(_activeSessions);
      
      if (userId != null) {
        sessions = sessions.where((s) => s.userId == userId).toList();
      }
      
      if (startDate != null) {
        sessions = sessions.where((s) => s.startTime.isAfter(startDate)).toList();
      }
      
      if (endDate != null) {
        sessions = sessions.where((s) => s.startTime.isBefore(endDate)).toList();
      }
      
      final worldStats = <String, int>{};
      final storeStats = <String, int>{};
      final productStats = <String, int>{};
      double totalSpent = 0.0;
      
      for (final session in sessions) {
        worldStats[session.worldId] = (worldStats[session.worldId] ?? 0) + 1;
        
        for (final storeId in session.visitedStores) {
          storeStats[storeId] = (storeStats[storeId] ?? 0) + 1;
        }
        
        for (final item in session.purchasedItems) {
          productStats[item.productId] = (productStats[item.productId] ?? 0) + 1;
          totalSpent += item.price * item.quantity;
        }
      }
      
      return MetaverseAnalytics(
        totalSessions: sessions.length,
        totalUsers: _availableAvatars.length,
        totalWorlds: _availableWorlds.length,
        totalStores: _virtualStores.length,
        worldStats: worldStats,
        storeStats: storeStats,
        productStats: productStats,
        totalSpent: totalSpent,
        averageSessionDuration: sessions.isNotEmpty
            ? Duration(milliseconds: sessions
                .map((s) => s.endTime?.difference(s.startTime).inMilliseconds ?? 0)
                .reduce((a, b) => a + b) ~/ sessions.length)
            : Duration.zero,
        startDate: startDate ?? DateTime.now().subtract(Duration(days: 30)),
        endDate: endDate ?? DateTime.now(),
      );
    } catch (e) {
      LoggingService.error('Failed to get metaverse analytics: $e');
      return MetaverseAnalytics(
        totalSessions: 0,
        totalUsers: 0,
        totalWorlds: 0,
        totalStores: 0,
        worldStats: {},
        storeStats: {},
        productStats: {},
        totalSpent: 0.0,
        averageSessionDuration: Duration.zero,
        startDate: DateTime.now(),
        endDate: DateTime.now(),
      );
    }
  }

  // Utility methods
  static String _generateSessionId() {
    return 'session_${DateTime.now().millisecondsSinceEpoch}';
  }

  static String _generateInteractionId() {
    return 'interaction_${DateTime.now().millisecondsSinceEpoch}';
  }

  static String _generateTransactionId() {
    return 'transaction_${DateTime.now().millisecondsSinceEpoch}';
  }

  static String _generateChatId() {
    return 'chat_${DateTime.now().millisecondsSinceEpoch}';
  }

  // Getters
  static bool get isInitialized => _isInitialized;
  static bool get isConnected => _isConnected;
  static MetaverseUser? get currentUser => _currentUser;
  static Map<String, MetaverseWorld> get availableWorlds => Map.from(_availableWorlds);
  static List<VirtualStore> get virtualStores => List.from(_virtualStores);
  static List<Avatar> get availableAvatars => List.from(_availableAvatars);
  static List<ShoppingSession> get activeSessions => List.from(_activeSessions);
  static Stream<MetaverseEvent> get events => _eventController?.stream ?? Stream.empty();
}

// Data models
class MetaverseUser {
  final String id;
  final String username;
  final String email;
  String? avatarId;
  final Map<String, dynamic> profile;
  final List<String> inventory;
  double currency;
  int experience;
  int level;
  final List<String> achievements;
  final List<String> friends;
  final DateTime createdAt;
  DateTime lastActive;
  bool isOnline;

  MetaverseUser({
    required this.id,
    required this.username,
    required this.email,
    this.avatarId,
    required this.profile,
    required this.inventory,
    required this.currency,
    required this.experience,
    required this.level,
    required this.achievements,
    required this.friends,
    required this.createdAt,
    required this.lastActive,
    required this.isOnline,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'email': email,
      'avatar_id': avatarId,
      'profile': profile,
      'inventory': inventory,
      'currency': currency,
      'experience': experience,
      'level': level,
      'achievements': achievements,
      'friends': friends,
      'created_at': createdAt.toIso8601String(),
      'last_active': lastActive.toIso8601String(),
      'is_online': isOnline,
    };
  }
}

class MetaverseWorld {
  final String id;
  final String name;
  final String description;
  final WorldType type;
  final int capacity;
  int currentVisitors;
  final List<String> stores;
  final WorldEnvironment environment;
  final List<String> features;
  final DateTime createdAt;
  bool isActive;

  MetaverseWorld({
    required this.id,
    required this.name,
    required this.description,
    required this.type,
    required this.capacity,
    required this.currentVisitors,
    required this.stores,
    required this.environment,
    required this.features,
    required this.createdAt,
    required this.isActive,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'type': type.name,
      'capacity': capacity,
      'current_visitors': currentVisitors,
      'stores': stores,
      'environment': environment.name,
      'features': features,
      'created_at': createdAt.toIso8601String(),
      'is_active': isActive,
    };
  }
}

class VirtualStore {
  final String id;
  final String name;
  final String description;
  final StoreCategory category;
  final String worldId;
  final List<VirtualProduct> products;
  final String owner;
  final double rating;
  final int reviews;
  final bool isOpen;
  final DateTime createdAt;
  DateTime lastUpdated;

  VirtualStore({
    required this.id,
    required this.name,
    required this.description,
    required this.category,
    required this.worldId,
    required this.products,
    required this.owner,
    required this.rating,
    required this.reviews,
    required this.isOpen,
    required this.createdAt,
    required this.lastUpdated,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'category': category.name,
      'world_id': worldId,
      'products': products.map((p) => p.toJson()).toList(),
      'owner': owner,
      'rating': rating,
      'reviews': reviews,
      'is_open': isOpen,
      'created_at': createdAt.toIso8601String(),
      'last_updated': lastUpdated.toIso8601String(),
    };
  }
}

class VirtualProduct {
  final String id;
  final String name;
  final String description;
  final double price;
  final String currency;
  final ProductCategory category;
  final String imageUrl;
  final String hologramUrl;
  final List<String> features;
  final ProductAvailability availability;
  final double rating;
  final int reviews;
  final String storeId;

  VirtualProduct({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.currency,
    required this.category,
    required this.imageUrl,
    required this.hologramUrl,
    required this.features,
    required this.availability,
    required this.rating,
    required this.reviews,
    required this.storeId,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'price': price,
      'currency': currency,
      'category': category.name,
      'image_url': imageUrl,
      'hologram_url': hologramUrl,
      'features': features,
      'availability': availability.name,
      'rating': rating,
      'reviews': reviews,
      'store_id': storeId,
    };
  }
}

class Avatar {
  final String id;
  final String name;
  final String description;
  final AvatarStyle style;
  final AvatarGender gender;
  final String baseModel;
  final Map<String, dynamic> customizations;
  final double price;
  final String currency;
  final bool isPremium;
  final List<String> tags;
  final DateTime createdAt;

  Avatar({
    required this.id,
    required this.name,
    required this.description,
    required this.style,
    required this.gender,
    required this.baseModel,
    required this.customizations,
    required this.price,
    required this.currency,
    required this.isPremium,
    required this.tags,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'style': style.name,
      'gender': gender.name,
      'base_model': baseModel,
      'customizations': customizations,
      'price': price,
      'currency': currency,
      'is_premium': isPremium,
      'tags': tags,
      'created_at': createdAt.toIso8601String(),
    };
  }
}

class ShoppingSession {
  final String id;
  final String userId;
  final String worldId;
  final DateTime startTime;
  final DateTime? endTime;
  final SessionStatus status;
  final List<String> visitedStores;
  final List<PurchasedItem> purchasedItems;
  final List<StoreInteraction> interactions;
  double currency;
  int experience;
  final Map<String, dynamic> properties;

  ShoppingSession({
    required this.id,
    required this.userId,
    required this.worldId,
    required this.startTime,
    this.endTime,
    required this.status,
    required this.visitedStores,
    required this.purchasedItems,
    required this.interactions,
    required this.currency,
    required this.experience,
    required this.properties,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'world_id': worldId,
      'start_time': startTime.toIso8601String(),
      'end_time': endTime?.toIso8601String(),
      'status': status.name,
      'visited_stores': visitedStores,
      'purchased_items': purchasedItems.map((i) => i.toJson()).toList(),
      'interactions': interactions.map((i) => i.toJson()).toList(),
      'currency': currency,
      'experience': experience,
      'properties': properties,
    };
  }
}

class StoreInteraction {
  final String id;
  final String storeId;
  final InteractionType type;
  final DateTime timestamp;
  final Map<String, dynamic> data;

  StoreInteraction({
    required this.id,
    required this.storeId,
    required this.type,
    required this.timestamp,
    required this.data,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'store_id': storeId,
      'type': type.name,
      'timestamp': timestamp.toIso8601String(),
      'data': data,
    };
  }
}

class PurchasedItem {
  final String productId;
  final String storeId;
  final int quantity;
  final double price;
  final DateTime purchaseTime;

  PurchasedItem({
    required this.productId,
    required this.storeId,
    required this.quantity,
    required this.price,
    required this.purchaseTime,
  });

  Map<String, dynamic> toJson() {
    return {
      'product_id': productId,
      'store_id': storeId,
      'quantity': quantity,
      'price': price,
      'purchase_time': purchaseTime.toIso8601String(),
    };
  }
}

class MetaverseAnalytics {
  final int totalSessions;
  final int totalUsers;
  final int totalWorlds;
  final int totalStores;
  final Map<String, int> worldStats;
  final Map<String, int> storeStats;
  final Map<String, int> productStats;
  final double totalSpent;
  final Duration averageSessionDuration;
  final DateTime startDate;
  final DateTime endDate;

  MetaverseAnalytics({
    required this.totalSessions,
    required this.totalUsers,
    required this.totalWorlds,
    required this.totalStores,
    required this.worldStats,
    required this.storeStats,
    required this.productStats,
    required this.totalSpent,
    required this.averageSessionDuration,
    required this.startDate,
    required this.endDate,
  });
}

class MetaverseEvent {
  final MetaverseEventType type;
  final Map<String, dynamic> data;
  final DateTime timestamp;

  MetaverseEvent({
    required this.type,
    required this.data,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();
}

class MetaverseUserResult {
  final bool success;
  final MetaverseUser? user;
  final String? error;

  MetaverseUserResult({
    required this.success,
    this.user,
    this.error,
  });
}

class WorldResult {
  final bool success;
  final MetaverseWorld? world;
  final ShoppingSession? session;
  final String? error;

  WorldResult({
    required this.success,
    this.world,
    this.session,
    this.error,
  });
}

class StoreResult {
  final bool success;
  final VirtualStore? store;
  final String? error;

  StoreResult({
    required this.success,
    this.store,
    this.error,
  });
}

class ProductResult {
  final bool success;
  final VirtualProduct? product;
  final String? error;

  ProductResult({
    required this.success,
    this.product,
    this.error,
  });
}

class PurchaseResult {
  final bool success;
  final String? transactionId;
  final String? error;

  PurchaseResult({
    required this.success,
    this.transactionId,
    this.error,
  });
}

class FriendResult {
  final bool success;
  final String? error;

  FriendResult({
    required this.success,
    this.error,
  });
}

class ChatResult {
  final bool success;
  final String? chatId;
  final String? error;

  ChatResult({
    required this.success,
    this.chatId,
    this.error,
  });
}

class AvatarResult {
  final bool success;
  final Avatar? avatar;
  final String? error;

  AvatarResult({
    required this.success,
    this.avatar,
    this.error,
  });
}

enum WorldType {
  shopping,
  marketplace,
  showroom,
  entertainment,
  social,
  education,
}

enum WorldEnvironment {
  indoor,
  outdoor,
  mixed,
}

enum StoreCategory {
  electronics,
  fashion,
  home,
  sports,
  books,
  food,
  toys,
  health,
}

enum ProductCategory {
  smartphones,
  laptops,
  tablets,
  clothing,
  shoes,
  accessories,
  furniture,
  books,
  electronics,
  sports,
}

enum ProductAvailability {
  inStock,
  outOfStock,
  limited,
  preorder,
}

enum AvatarStyle {
  classic,
  modern,
  trendy,
  casual,
  formal,
  sporty,
}

enum AvatarGender {
  male,
  female,
  unisex,
}

enum SessionStatus {
  active,
  inactive,
  ended,
  error,
}

enum InteractionType {
  visit,
  browse,
  purchase,
  inquiry,
  review,
  share,
}

enum MetaverseEventType {
  userCreated,
  avatarSelected,
  worldEntered,
  worldLeft,
  storeVisited,
  storeEvent,
  productBrowsed,
  productPurchased,
  userInteraction,
  friendRequestSent,
  friendRequestReceived,
  chatStarted,
  chatMessageReceived,
  userStatusUpdated,
  worldEvent,
  error,
  serviceDisconnected,
}
