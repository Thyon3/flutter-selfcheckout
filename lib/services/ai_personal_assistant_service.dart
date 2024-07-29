import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:selfcheckoutapp/services/logging_service.dart';
import 'package:selfcheckoutapp/services/cache_service.dart';
import 'package:selfcheckoutapp/services/security_service.dart';
import 'package:selfcheckoutapp/services/preferences_service.dart';

class AIPersonalAssistantService {
  static const String _baseUrl = 'https://api.aiassistant.scango.app';
  static const String _apiKey = 'ai_assistant_api_key_12345';
  static const String _cacheKey = 'ai_assistant_cache';
  static const String _historyKey = 'ai_assistant_history';
  
  static bool _isInitialized = false;
  static bool _isActive = false;
  static StreamSubscription? _assistantSubscription;
  static final List<AssistantMessage> _conversationHistory = [];
  static final List<AssistantProfile> _availableProfiles = [];
  static AssistantProfile? _currentProfile;
  static AssistantSession? _currentSession;
  static StreamController<AssistantEvent>? _eventController;

  // AI personal assistant service initialization
  static Future<bool> initialize() async {
    try {
      if (_isInitialized) return true;
      
      LoggingService.info('Initializing AI personal assistant service');
      
      // Initialize event controller
      _eventController = StreamController<AssistantEvent>.broadcast();
      
      // Load conversation history
      await _loadConversationHistory();
      
      // Load available profiles
      await _loadAvailableProfiles();
      
      // Initialize default profiles if none exist
      if (_availableProfiles.isEmpty) {
        await _initializeDefaultProfiles();
      }
      
      _isInitialized = true;
      
      LoggingService.info('AI personal assistant service initialized successfully');
      return true;
    } catch (e) {
      LoggingService.error('Failed to initialize AI personal assistant service: $e');
      return false;
    }
  }

  // Assistant session management
  static Future<AssistantResult> startAssistantSession({
    String? userId,
    AssistantProfile? profile,
    Map<String, dynamic>? context,
  }) async {
    try {
      if (!_isInitialized) {
        await initialize();
      }
      
      if (_isActive) {
        return AssistantResult(
          success: false,
          error: 'Assistant session already active',
        );
      }
      
      // Select profile
      final selectedProfile = profile ?? _availableProfiles.first;
      _currentProfile = selectedProfile;
      
      // Create session
      final session = AssistantSession(
        id: _generateSessionId(),
        userId: userId ?? 'current_user',
        profileId: selectedProfile.id,
        context: context ?? {},
        startedAt: DateTime.now(),
        isActive: true,
      );
      
      _currentSession = session;
      
      // Connect to AI assistant
      final success = await _connectToAssistant(session);
      
      if (success) {
        _isActive = true;
        
        // Send welcome message
        await _sendAssistantMessage(
          type: AssistantMessageType.welcome,
          content: selectedProfile.welcomeMessage,
        );
        
        // Emit session started event
        _emitEvent(AssistantEvent(
          type: AssistantEventType.sessionStarted,
          data: session.toJson(),
        ));
        
        LoggingService.info('AI assistant session started: ${session.id}');
        return AssistantResult(
          success: true,
          session: session,
        );
      }
      
      return AssistantResult(
        success: false,
        error: 'Failed to connect to AI assistant',
      );
    } catch (e) {
      LoggingService.error('Failed to start assistant session: $e');
      return AssistantResult(
        success: false,
        error: e.toString(),
      );
    }
  }

  static Future<bool> _connectToAssistant(AssistantSession session) async {
    try {
      // Mock connection to AI assistant
      await Future.delayed(Duration(milliseconds: 1500));
      
      // Initialize WebSocket connection (mock)
      _assistantSubscription = _mockAssistantStream().listen(
        _handleAssistantMessage,
        onError: _handleAssistantError,
        onDone: _handleAssistantDisconnect,
      );
      
      return true;
    } catch (e) {
      LoggingService.error('Failed to connect to assistant: $e');
      return false;
    }
  }

  static Stream<AssistantMessage> _mockAssistantStream() async* {
    // Mock assistant message stream
    while (_isActive) {
      await Future.delayed(Duration(seconds: 2));
      
      // Occasionally send proactive messages
      if (Random().nextDouble() > 0.8) {
        final proactiveMessages = [
          'Is there anything specific you\'d like help with today?',
          'I notice you\'ve been browsing clothing items. Can I help you find something?',
          'Would you like me to show you some personalized recommendations?',
          'How can I assist you with your shopping today?',
        ];
        
        final message = proactiveMessages[Random().nextInt(proactiveMessages.length)];
        
        yield AssistantMessage(
          id: _generateMessageId(),
          sessionId: _currentSession?.id ?? '',
          type: AssistantMessageType.proactive,
          content: message,
          timestamp: DateTime.now(),
          isFromAssistant: true,
        );
      }
    }
  }

  static Future<void> stopAssistantSession() async {
    try {
      if (!_isActive || _currentSession == null) return;
      
      // Send goodbye message
      await _sendAssistantMessage(
        type: AssistantMessageType.goodbye,
        content: _currentProfile?.goodbyeMessage ?? 'Goodbye! Have a great day!',
      );
      
      // Close connections
      await _assistantSubscription?.cancel();
      _assistantSubscription = null;
      
      _currentSession!.isActive = false;
      _currentSession!.endedAt = DateTime.now();
      
      // Save session
      await _saveSession(_currentSession!);
      
      _isActive = false;
      _currentSession = null;
      
      // Emit session ended event
      _emitEvent(AssistantEvent(
        type: AssistantEventType.sessionEnded,
        data: {},
      ));
      
      LoggingService.info('AI assistant session ended');
    } catch (e) {
      LoggingService.error('Failed to stop assistant session: $e');
    }
  }

  // Message handling
  static Future<AssistantMessage> sendMessage({
    required String message,
    Map<String, dynamic>? context,
  }) async {
    try {
      if (!_isActive || _currentSession == null) {
        throw Exception('No active assistant session');
      }
      
      // Create user message
      final userMessage = AssistantMessage(
        id: _generateMessageId(),
        sessionId: _currentSession!.id,
        type: AssistantMessageType.user,
        content: message,
        timestamp: DateTime.now(),
        isFromAssistant: false,
        context: context ?? {},
      );
      
      // Add to conversation history
      _conversationHistory.add(userMessage);
      
      // Process message and get AI response
      final aiResponse = await _processUserMessage(userMessage);
      
      // Add AI response to history
      _conversationHistory.add(aiResponse);
      
      // Save conversation history
      await _saveConversationHistory();
      
      LoggingService.info('Assistant message processed: ${message.substring(0, 50)}...');
      return aiResponse;
    } catch (e) {
      LoggingService.error('Failed to send message: $e');
      rethrow;
    }
  }

  static Future<AssistantMessage> _processUserMessage(AssistantMessage userMessage) async {
    try {
      // Analyze user intent
      final intent = await _analyzeIntent(userMessage.content);
      
      // Generate response based on intent
      String response;
      AssistantMessageType responseType;
      
      switch (intent.type) {
        case 'product_search':
          response = await _handleProductSearch(intent);
          responseType = AssistantMessageType.productRecommendation;
          break;
        case 'price_inquiry':
          response = await _handlePriceInquiry(intent);
          responseType = AssistantMessageType.priceInfo;
          break;
        case 'shopping_help':
          response = await _handleShoppingHelp(intent);
          responseType = AssistantMessageType.shoppingAdvice;
          break;
        case 'general_question':
          response = await _handleGeneralQuestion(intent);
          responseType = AssistantMessageType.general;
          break;
        case 'order_status':
          response = await _handleOrderStatus(intent);
          responseType = AssistantMessageType.orderInfo;
          break;
        default:
          response = await _handleGeneralQuestion(intent);
          responseType = AssistantMessageType.general;
      }
      
      return AssistantMessage(
        id: _generateMessageId(),
        sessionId: userMessage.sessionId,
        type: responseType,
        content: response,
        timestamp: DateTime.now(),
        isFromAssistant: true,
        intent: intent,
      );
    } catch (e) {
      LoggingService.error('Failed to process user message: $e');
      
      return AssistantMessage(
        id: _generateMessageId(),
        sessionId: userMessage.sessionId,
        type: AssistantMessageType.error,
        content: 'I apologize, but I encountered an error processing your request. Please try again.',
        timestamp: DateTime.now(),
        isFromAssistant: true,
      );
    }
  }

  static Future<AssistantIntent> _analyzeIntent(String message) async {
    try {
      // Mock intent analysis
      await Future.delayed(Duration(milliseconds: 500));
      
      final lowerMessage = message.toLowerCase();
      
      if (lowerMessage.contains('search') || lowerMessage.contains('find') || lowerMessage.contains('look for')) {
        return AssistantIntent(
          type: 'product_search',
          confidence: 0.8,
          entities: {
            'query': _extractSearchQuery(message),
          },
        );
      } else if (lowerMessage.contains('price') || lowerMessage.contains('cost') || lowerMessage.contains('how much')) {
        return AssistantIntent(
          type: 'price_inquiry',
          confidence: 0.9,
          entities: {
            'product': _extractProductName(message),
          },
        );
      } else if (lowerMessage.contains('help') || lowerMessage.contains('advice') || lowerMessage.contains('recommend')) {
        return AssistantIntent(
          type: 'shopping_help',
          confidence: 0.7,
          entities: {},
        );
      } else if (lowerMessage.contains('order') || lowerMessage.contains('delivery') || lowerMessage.contains('status')) {
        return AssistantIntent(
          type: 'order_status',
          confidence: 0.8,
          entities: {},
        );
      } else {
        return AssistantIntent(
          type: 'general_question',
          confidence: 0.6,
          entities: {},
        );
      }
    } catch (e) {
      LoggingService.error('Failed to analyze intent: $e');
      return AssistantIntent(
        type: 'general_question',
        confidence: 0.0,
        entities: {},
      );
    }
  }

  // Intent handlers
  static Future<String> _handleProductSearch(AssistantIntent intent) async {
    try {
      final query = intent.entities['query'] as String? ?? '';
      
      // Mock product search
      await Future.delayed(Duration(milliseconds: 1000));
      
      final products = [
        'iPhone 15 Pro',
        'Nike Air Max',
        'Samsung Galaxy Watch',
        'Adidas Ultraboost',
        'Sony WH-1000XM5',
      ];
      
      final matchingProducts = products.where((product) => 
          product.toLowerCase().contains(query.toLowerCase())).toList();
      
      if (matchingProducts.isNotEmpty) {
        final response = 'I found ${matchingProducts.length} products matching "$query":\n\n';
        final productDetails = matchingProducts.map((product) => 
            '• $product - Rs ${Random().nextInt(50000) + 10000}').join('\n');
        
        return response + productDetails + '\n\nWould you like more details about any of these products?';
      } else {
        return 'I couldn\'t find any products matching "$query". Would you like me to search for something else or show you our popular items?';
      }
    } catch (e) {
      LoggingService.error('Failed to handle product search: $e');
      return 'I apologize, but I had trouble searching for products. Please try again.';
    }
  }

  static Future<String> _handlePriceInquiry(AssistantIntent intent) async {
    try {
      final product = intent.entities['product'] as String? ?? '';
      
      // Mock price lookup
      await Future.delayed(Duration(milliseconds: 500));
      
      final price = Random().nextInt(50000) + 1000;
      
      return 'The $product costs Rs $price. Would you like to add it to your cart or see more details?';
    } catch (e) {
      LoggingService.error('Failed to handle price inquiry: $e');
      return 'I apologize, but I couldn\'t find the price information. Please try again.';
    }
  }

  static Future<String> _handleShoppingHelp(AssistantIntent intent) async {
    try {
      final helpResponses = [
        'I\'d be happy to help! What specifically are you looking for today?',
        'I can help you find products, check prices, and provide recommendations. What would you like to do?',
        'Based on your shopping history, I recommend checking out our new arrivals. Would you like to see them?',
        'I can assist you with finding the perfect item. What\'s your budget and preferences?',
      ];
      
      return helpResponses[Random().nextInt(helpResponses.length)];
    } catch (e) {
      LoggingService.error('Failed to handle shopping help: $e');
      return 'I\'m here to help with your shopping needs. What can I assist you with?';
    }
  }

  static Future<String> _handleGeneralQuestion(AssistantIntent intent) async {
    try {
      final generalResponses = [
        'That\'s an interesting question! Let me help you with that.',
        'I understand what you\'re asking. Here\'s what I can tell you...',
        'Based on what you\'ve told me, I think...',
        'That\'s a great question! Let me provide some information.',
      ];
      
      return generalResponses[Random().nextInt(generalResponses.length)];
    } catch (e) {
      LoggingService.error('Failed to handle general question: $e');
      return 'I\'m here to help! Could you please provide more details about what you\'d like to know?';
    }
  }

  static Future<String> _handleOrderStatus(AssistantIntent intent) async {
    try {
      // Mock order status check
      await Future.delayed(Duration(milliseconds: 800));
      
      final statuses = ['Processing', 'Shipped', 'Out for Delivery', 'Delivered'];
      final status = statuses[Random().nextInt(statuses.length)];
      
      return 'I found your recent order. It\'s currently: $status. Would you like more details about your order?';
    } catch (e) {
      LoggingService.error('Failed to handle order status: $e);
      return 'I apologize, but I couldn\'t find your order information. Please check your order number and try again.';
    }
  }

  // Personalization features
  static Future<void> learnFromInteraction({
    required String userMessage,
    required String assistantResponse,
    required AssistantIntent intent,
  }) async {
    try {
      // Store interaction for learning
      final interaction = {
        'user_message': userMessage,
        'assistant_response': assistantResponse,
        'intent': intent.type,
        'timestamp': DateTime.now().toIso8601String(),
      };
      
      // Save to learning cache
      await CacheService.cacheData(
        'ai_learning_${DateTime.now().millisecondsSinceEpoch}',
        json.encode(interaction),
        ttlHours: 24 * 7, // 1 week
      );
      
      LoggingService.info('Learned from interaction: ${intent.type}');
    } catch (e) {
      LoggingService.error('Failed to learn from interaction: $e');
    }
  }

  static Future<List<String>> getPersonalizedRecommendations() async {
    try {
      // Mock personalized recommendations based on history
      await Future.delayed(Duration(milliseconds: 1000));
      
      final recommendations = [
        'iPhone 15 Pro - Based on your interest in smartphones',
        'Nike Air Max - Perfect for your active lifestyle',
        'Samsung Galaxy Watch - Complements your phone choice',
        'Adidas Ultraboost - Great for your fitness goals',
        'Sony WH-1000XM5 - Premium audio experience',
      ];
      
      return recommendations;
    } catch (e) {
      LoggingService.error('Failed to get personalized recommendations: $e');
      return [];
    }
  }

  static Future<void> updatePreferences({
    String? preferredCategory,
    double? budgetRange,
    List<String>? favoriteBrands,
    String? shoppingStyle,
  }) async {
    try {
      final preferences = <String, dynamic>{
        'preferred_category': preferredCategory,
        'budget_range': budgetRange,
        'favorite_brands': favoriteBrands,
        'shopping_style': shoppingStyle,
        'updated_at': DateTime.now().toIso8601String(),
      };
      
      // Save preferences
      await PreferencesService.setCustomPreference('ai_assistant_preferences', preferences);
      
      // Update current session context
      if (_currentSession != null) {
        _currentSession!.context.addAll(preferences);
      }
      
      LoggingService.info('AI assistant preferences updated');
    } catch (e) {
      LoggingService.error('Failed to update preferences: $e');
    }
  }

  // Voice integration
  static Future<AssistantMessage> sendVoiceMessage({
    required Uint8List audioData,
    String? language,
  }) async {
    try {
      // Mock speech-to-text conversion
      await Future.delayed(Duration(milliseconds: 1500));
      
      final transcribedText = 'I\'m looking for a new smartphone';
      
      // Process as regular message
      return await sendMessage(message: transcribedText);
    } catch (e) {
      LoggingService.error('Failed to process voice message: $e');
      rethrow;
    }
  }

  static Future<Uint8List?> generateVoiceResponse({
    required String text,
    String? voice,
    double? speed,
  }) async {
    try {
      // Mock text-to-speech conversion
      await Future.delayed(Duration(milliseconds: 2000));
      
      // Generate mock audio data
      final audioData = Uint8List.fromList(List.generate(
        1024 * 10, // 10KB of mock audio data
        (_) => Random().nextInt(256),
      ));
      
      return audioData;
    } catch (e) {
      LoggingService.error('Failed to generate voice response: $e');
      return null;
    }
  }

  // Event handlers
  static void _handleAssistantMessage(dynamic message) {
    try {
      final data = json.decode(message);
      final assistantMessage = AssistantMessage.fromJson(data);
      
      _conversationHistory.add(assistantMessage);
      
      // Emit message received event
      _emitEvent(AssistantEvent(
        type: AssistantEventType.messageReceived,
        data: assistantMessage.toJson(),
      ));
    } catch (e) {
      LoggingService.error('Failed to handle assistant message: $e');
    }
  }

  static void _handleAssistantError(dynamic error) {
    LoggingService.error('Assistant error: $error');
    _emitEvent(AssistantEvent(
      type: AssistantEventType.error,
      data: {'error': error.toString()},
    ));
  }

  static void _handleAssistantDisconnect() {
    LoggingService.info('Assistant disconnected');
    _isActive = false;
    _emitEvent(AssistantEvent(
      type: AssistantEventType.sessionEnded,
      data: {},
    ));
  }

  static void _emitEvent(AssistantEvent event) {
    _eventController?.add(event);
  }

  static Future<void> _sendAssistantMessage({
    required AssistantMessageType type,
    required String content,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final message = AssistantMessage(
        id: _generateMessageId(),
        sessionId: _currentSession?.id ?? '',
        type: type,
        content: content,
        timestamp: DateTime.now(),
        isFromAssistant: true,
        metadata: metadata ?? {},
      );
      
      _conversationHistory.add(message);
      
      // Emit message sent event
      _emitEvent(AssistantEvent(
        type: AssistantEventType.messageSent,
        data: message.toJson(),
      ));
    } catch (e) {
      LoggingService.error('Failed to send assistant message: $e');
    }
  }

  // Utility methods
  static String _extractSearchQuery(String message) {
    // Mock search query extraction
    final words = message.toLowerCase().split(' ');
    final searchKeywords = ['search', 'find', 'look for', 'show me'];
    
    for (final keyword in searchKeywords) {
      if (words.contains(keyword)) {
        final index = words.indexOf(keyword);
        if (index < words.length - 1) {
          return words.sublist(index + 1).join(' ');
        }
      }
    }
    
    return message;
  }

  static String _extractProductName(String message) {
    // Mock product name extraction
    final products = ['iphone', 'samsung', 'nike', 'adidas', 'sony'];
    final lowerMessage = message.toLowerCase();
    
    for (final product in products) {
      if (lowerMessage.contains(product)) {
        return product;
      }
    }
    
    return 'product';
  }

  static Future<void> _loadConversationHistory() async {
    try {
      final cachedData = await CacheService.getCachedData(_historyKey);
      if (cachedData != null) {
        final historyData = json.decode(cachedData);
        _conversationHistory.clear();
        _conversationHistory.addAll(
          (historyData as List).map((item) => AssistantMessage.fromJson(item)),
        );
      }
    } catch (e) {
      LoggingService.error('Failed to load conversation history: $e');
    }
  }

  static Future<void> _saveConversationHistory() async {
    try {
      final data = json.encode(_conversationHistory.map((m) => m.toJson()).toList());
      await CacheService.cacheData(_historyKey, data, ttlHours: 24);
    } catch (e) {
      LoggingService.error('Failed to save conversation history: $e');
    }
  }

  static Future<void> _loadAvailableProfiles() async {
    try {
      // Load profiles from cache
      final cachedData = await CacheService.getCachedData('ai_assistant_profiles');
      if (cachedData != null) {
        final profilesData = json.decode(cachedData);
        _availableProfiles.clear();
        _availableProfiles.addAll(
          (profilesData as List).map((item) => AssistantProfile.fromJson(item)),
        );
      }
    } catch (e) {
      LoggingService.error('Failed to load available profiles: $e');
    }
  }

  static Future<void> _saveProfiles() async {
    try {
      final data = json.encode(_availableProfiles.map((p) => p.toJson()).toList());
      await CacheService.cacheData('ai_assistant_profiles', data, ttlHours: 24);
    } catch (e) {
      LoggingService.error('Failed to save profiles: $e');
    }
  }

  static Future<void> _initializeDefaultProfiles() async {
    _availableProfiles.addAll([
      AssistantProfile(
        id: 'shopping_assistant',
        name: 'Shopping Assistant',
        description: 'Specialized in helping with shopping decisions',
        personality: 'friendly',
        welcomeMessage: 'Hello! I\'m your personal shopping assistant. How can I help you find the perfect items today?',
        goodbyeMessage: 'Thank you for shopping with us! Have a wonderful day!',
        capabilities: ['product_search', 'price_comparison', 'recommendations', 'shopping_advice'],
        isActive: true,
      ),
      AssistantProfile(
        id: 'style_advisor',
        name: 'Style Advisor',
        description: 'Fashion and style expert',
        personality: 'trendy',
        welcomeMessage: 'Hey there! I\'m your style advisor. Let\'s find you something amazing today!',
        goodbyeMessage: 'Looking forward to helping you stay stylish! See you soon!',
        capabilities: ['fashion_advice', 'outfit_recommendations', 'trend_analysis'],
        isActive: true,
      ),
      AssistantProfile(
        id: 'tech_expert',
        name: 'Tech Expert',
        description: 'Technology and electronics specialist',
        personality: 'knowledgeable',
        welcomeMessage: 'Hello! I\'m your tech expert. I can help you find the perfect gadgets and electronics.',
        goodbyeMessage: 'Happy tech shopping! Feel free to ask me anything about technology anytime.',
        capabilities: ['tech_recommendations', 'specifications', 'comparisons'],
        isActive: true,
      ),
    ]);
    
    await _saveProfiles();
  }

  static Future<void> _saveSession(AssistantSession session) async {
    try {
      final key = 'ai_session_${session.id}';
      final data = json.encode(session.toJson());
      await CacheService.cacheData(key, data, ttlHours: 24);
    } catch (e) {
      LoggingService.error('Failed to save session: $e');
    }
  }

  static String _generateSessionId() {
    return 'ai_session_${DateTime.now().millisecondsSinceEpoch}';
  }

  static String _generateMessageId() {
    return 'ai_msg_${DateTime.now().millisecondsSinceEpoch}';
  }

  // Getters
  static bool get isInitialized => _isInitialized;
  static bool get isActive => _isActive;
  static AssistantSession? get currentSession => _currentSession;
  static AssistantProfile? get currentProfile => _currentProfile;
  static List<AssistantMessage> get conversationHistory => List.from(_conversationHistory);
  static List<AssistantProfile> get availableProfiles => List.from(_availableProfiles);
  static Stream<AssistantEvent> get events => _eventController?.stream ?? Stream.empty();
}

// Data models
class AssistantSession {
  final String id;
  final String userId;
  final String profileId;
  final Map<String, dynamic> context;
  final DateTime startedAt;
  final DateTime? endedAt;
  bool isActive;

  AssistantSession({
    required this.id,
    required this.userId,
    required this.profileId,
    required this.context,
    required this.startedAt,
    this.endedAt,
    required this.isActive,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'profile_id': profileId,
      'context': context,
      'started_at': startedAt.toIso8601String(),
      'ended_at': endedAt?.toIso8601String(),
      'is_active': isActive,
    };
  }
}

class AssistantProfile {
  final String id;
  final String name;
  final String description;
  final String personality;
  final String welcomeMessage;
  final String goodbyeMessage;
  final List<String> capabilities;
  final bool isActive;

  AssistantProfile({
    required this.id,
    required this.name,
    required this.description,
    required this.personality,
    required this.welcomeMessage,
    required this.goodbyeMessage,
    required this.capabilities,
    required this.isActive,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'personality': personality,
      'welcome_message': welcomeMessage,
      'goodbye_message': goodbyeMessage,
      'capabilities': capabilities,
      'is_active': isActive,
    };
  }

  factory AssistantProfile.fromJson(Map<String, dynamic> json) {
    return AssistantProfile(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      personality: json['personality'],
      welcomeMessage: json['welcome_message'],
      goodbyeMessage: json['goodbye_message'],
      capabilities: List<String>.from(json['capabilities']),
      isActive: json['is_active'],
    );
  }
}

class AssistantMessage {
  final String id;
  final String sessionId;
  final AssistantMessageType type;
  final String content;
  final DateTime timestamp;
  final bool isFromAssistant;
  final AssistantIntent? intent;
  final Map<String, dynamic> context;
  final Map<String, dynamic> metadata;

  AssistantMessage({
    required this.id,
    required this.sessionId,
    required this.type,
    required this.content,
    required this.timestamp,
    required this.isFromAssistant,
    this.intent,
    this.context = const {},
    this.metadata = const {},
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'session_id': sessionId,
      'type': type.name,
      'content': content,
      'timestamp': timestamp.toIso8601String(),
      'is_from_assistant': isFromAssistant,
      'intent': intent?.toJson(),
      'context': context,
      'metadata': metadata,
    };
  }

  factory AssistantMessage.fromJson(Map<String, dynamic> json) {
    return AssistantMessage(
      id: json['id'],
      sessionId: json['session_id'],
      type: AssistantMessageType.values.firstWhere(
        (t) => t.name == json['type'],
        orElse: () => AssistantMessageType.user,
      ),
      content: json['content'],
      timestamp: DateTime.parse(json['timestamp']),
      isFromAssistant: json['is_from_assistant'],
      intent: json['intent'] != null ? AssistantIntent.fromJson(json['intent']) : null,
      context: Map<String, dynamic>.from(json['context'] ?? {}),
      metadata: Map<String, dynamic>.from(json['metadata'] ?? {}),
    );
  }
}

class AssistantIntent {
  final String type;
  final double confidence;
  final Map<String, dynamic> entities;

  AssistantIntent({
    required this.type,
    required this.confidence,
    required this.entities,
  });

  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'confidence': confidence,
      'entities': entities,
    };
  }

  factory AssistantIntent.fromJson(Map<String, dynamic> json) {
    return AssistantIntent(
      type: json['type'],
      confidence: json['confidence'].toDouble(),
      entities: Map<String, dynamic>.from(json['entities']),
    );
  }
}

class AssistantEvent {
  final AssistantEventType type;
  final Map<String, dynamic> data;
  final DateTime timestamp;

  AssistantEvent({
    required this.type,
    required this.data,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();
}

class AssistantResult {
  final bool success;
  final AssistantSession? session;
  final String? error;

  AssistantResult({
    required this.success,
    this.session,
    this.error,
  });
}

enum AssistantMessageType {
  user,
  welcome,
  goodbye,
  productRecommendation,
  priceInfo,
  shoppingAdvice,
  orderInfo,
  general,
  proactive,
  error,
}

enum AssistantEventType {
  sessionStarted,
  sessionEnded,
  messageSent,
  messageReceived,
  error,
}
