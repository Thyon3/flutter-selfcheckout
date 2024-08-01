import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:selfcheckoutapp/services/logging_service.dart';
import 'package:selfcheckoutapp/services/cache_service.dart';
import 'package:selfcheckoutapp/services/security_service.dart';

class AdvancedVoiceAssistantService {
  static const String _baseUrl = 'https://api.voice.scango.app';
  static const String _wsUrl = 'wss://voice.scango.app/ws';
  static const String _apiKey = 'voice_assistant_api_key_12345';
  static const String _cacheKey = 'voice_assistant_cache';
  
  static bool _isInitialized = false;
  static bool _isVoiceSessionActive = false;
  static WebSocketChannel? _voiceChannel;
  static StreamSubscription? _voiceSubscription;
  static VoiceSession? _currentSession;
  static final Map<String, VoiceCommand> _availableCommands = {};
  static final List<VoiceSession> _sessionHistory = [];
  static final Map<String, UserProfile> _userProfiles = {};
  static StreamController<VoiceEvent>? _eventController;

  // Advanced voice assistant service initialization
  static Future<bool> initialize() async {
    try {
      if (_isInitialized) return true;
      
      LoggingService.info('Initializing advanced voice assistant service');
      
      // Initialize event controller
      _eventController = StreamController<VoiceEvent>.broadcast();
      
      // Connect to voice service
      await _connectToVoiceService();
      
      // Load available commands
      await _loadAvailableCommands();
      
      // Load user profiles
      await _loadUserProfiles();
      
      // Load session history
      await _loadSessionHistory();
      
      _isInitialized = true;
      
      LoggingService.info('Advanced voice assistant service initialized successfully');
      return true;
    } catch (e) {
      LoggingService.error('Failed to initialize advanced voice assistant service: $e');
      return false;
    }
  }

  // Voice service connection
  static Future<void> _connectToVoiceService() async {
    try {
      _voiceChannel = WebSocketChannel.connect(Uri.parse('$_wsUrl/assistant'));
      
      // Authenticate
      final authMessage = {
        'type': 'auth',
        'api_key': _apiKey,
        'timestamp': DateTime.now().toIso8601String(),
      };
      
      _voiceChannel!.sink.add(json.encode(authMessage));
      
      // Listen for voice events
      _voiceSubscription = _voiceChannel!.stream.listen(
        _handleVoiceEvent,
        onError: _handleVoiceError,
        onDone: _handleVoiceDisconnect,
      );
      
      LoggingService.info('Connected to voice assistant service');
    } catch (e) {
      LoggingService.error('Failed to connect to voice service: $e');
    }
  }

  // Voice session management
  static Future<VoiceSessionResult> startVoiceSession({
    required String sessionId,
    required String userId,
    VoiceSessionType sessionType = VoiceSessionType.general,
    Map<String, dynamic>? sessionConfig,
  }) async {
    try {
      if (!_isInitialized) {
        await initialize();
      }
      
      if (_isVoiceSessionActive) {
        return VoiceSessionResult(
          success: false,
          error: 'Voice session already active',
        );
      }
      
      // Get or create user profile
      final userProfile = await _getUserProfile(userId);
      
      // Create voice session
      final session = VoiceSession(
        id: sessionId,
        userId: userId,
        type: sessionType,
        status: VoiceSessionStatus.initializing,
        startTime: DateTime.now(),
        endTime: null,
        commands: [],
        responses: [],
        context: VoiceContext(
          currentIntent: null,
          entities: {},
          conversationHistory: [],
          userPreferences: userProfile.preferences,
          sessionState: {},
        ),
        config: sessionConfig ?? {},
        metadata: {
          'user_language': userProfile.language,
          'user_accent': userProfile.accent,
          'voice_profile': userProfile.voiceProfile,
        },
      );
      
      _currentSession = session;
      _isVoiceSessionActive = true;
      
      // Initialize voice session
      await _initializeVoiceSession(session);
      
      // Emit session started event
      _emitEvent(VoiceEvent(
        type: VoiceEventType.sessionStarted,
        data: session.toJson(),
      ));
      
      LoggingService.info('Voice session started: $sessionId');
      return VoiceSessionResult(
        success: true,
        session: session,
      );
    } catch (e) {
      LoggingService.error('Failed to start voice session: $e');
      return VoiceSessionResult(
        success: false,
        error: e.toString(),
      );
    }
  }

  static Future<void> _initializeVoiceSession(VoiceSession session) async {
    try {
      // Mock voice session initialization
      await Future.delayed(Duration(seconds: 2));
      
      session.status = VoiceSessionStatus.active;
      
      // Send initialization message to voice service
      final initMessage = {
        'type': 'initialize_session',
        'session_id': session.id,
        'user_id': session.userId,
        'session_type': session.type.name,
        'config': session.config,
        'metadata': session.metadata,
        'timestamp': DateTime.now().toIso8601String(),
      };
      
      _voiceChannel?.sink.add(json.encode(initMessage));
      
      LoggingService.info('Voice session initialized: ${session.id}');
    } catch (e) {
      LoggingService.error('Failed to initialize voice session: $e');
      session.status = VoiceSessionStatus.error;
    }
  }

  static Future<void> stopVoiceSession() async {
    try {
      if (!_isVoiceSessionActive || _currentSession == null) return;
      
      final session = _currentSession!;
      
      // Stop voice session
      await _stopVoiceSession(session);
      
      session.status = VoiceSessionStatus.ended;
      session.endTime = DateTime.now();
      
      // Add to history
      _sessionHistory.add(session);
      
      // Save session history
      await _saveSessionHistory();
      
      _isVoiceSessionActive = false;
      _currentSession = null;
      
      // Emit session ended event
      _emitEvent(VoiceEvent(
        type: VoiceEventType.sessionEnded,
        data: session.toJson(),
      ));
      
      LoggingService.info('Voice session stopped: ${session.id}');
    } catch (e) {
      LoggingService.error('Failed to stop voice session: $e');
    }
  }

  static Future<void> _stopVoiceSession(VoiceSession session) async {
    try {
      // Send session end message
      final endMessage = {
        'type': 'end_session',
        'session_id': session.id,
        'timestamp': DateTime.now().toIso8601String(),
      };
      
      _voiceChannel?.sink.add(json.encode(endMessage));
      
      LoggingService.info('Voice session cleanup completed');
    } catch (e) {
      LoggingService.error('Failed to stop voice session: $e');
    }
  }

  // Voice command processing
  static Future<VoiceCommandResult> processVoiceCommand({
    required String commandText,
    required String audioData,
    String? language,
    Map<String, dynamic>? context,
  }) async {
    try {
      if (!_isVoiceSessionActive || _currentSession == null) {
        return VoiceCommandResult(
          success: false,
          error: 'No active voice session',
        );
      }
      
      final session = _currentSession!;
      
      // Create voice command
      final command = VoiceCommand(
        id: _generateCommandId(),
        text: commandText,
        audioData: audioData,
        language: language ?? 'en-US',
        confidence: 0.0,
        intent: null,
        entities: {},
        timestamp: DateTime.now(),
        processingTime: Duration.zero,
        metadata: context ?? {},
      );
      
      session.commands.add(command);
      
      // Process command
      final processedCommand = await _processCommand(command, session);
      
      // Update command in session
      final commandIndex = session.commands.indexWhere((c) => c.id == command.id);
      if (commandIndex != -1) {
        session.commands[commandIndex] = processedCommand;
      }
      
      // Generate response
      final response = await _generateResponse(processedCommand, session);
      
      session.responses.add(response);
      
      // Update context
      await _updateContext(processedCommand, response, session);
      
      // Emit command processed event
      _emitEvent(VoiceEvent(
        type: VoiceEventType.commandProcessed,
        data: {
          'command_id': processedCommand.id,
          'intent': processedCommand.intent,
          'confidence': processedCommand.confidence,
          'response_id': response.id,
        },
      ));
      
      LoggingService.info('Voice command processed: ${processedCommand.intent}');
      return VoiceCommandResult(
        success: true,
        command: processedCommand,
        response: response,
      );
    } catch (e) {
      LoggingService.error('Failed to process voice command: $e');
      return VoiceCommandResult(
        success: false,
        error: e.toString(),
      );
    }
  }

  static Future<VoiceCommand> _processCommand(VoiceCommand command, VoiceSession session) async {
    try {
      // Mock voice command processing
      await Future.delayed(Duration(milliseconds: 1500));
      
      final startTime = DateTime.now();
      
      // Speech to text (already provided)
      String text = command.text;
      
      // Intent recognition
      final intent = await _recognizeIntent(text);
      
      // Entity extraction
      final entities = await _extractEntities(text, intent);
      
      // Confidence calculation
      final confidence = await _calculateConfidence(text, intent, entities);
      
      final processingTime = DateTime.now().difference(startTime);
      
      return VoiceCommand(
        id: command.id,
        text: text,
        audioData: command.audioData,
        language: command.language,
        confidence: confidence,
        intent: intent,
        entities: entities,
        timestamp: command.timestamp,
        processingTime: processingTime,
        metadata: command.metadata,
      );
    } catch (e) {
      LoggingService.error('Failed to process command: $e');
      return command;
    }
  }

  static Future<String> _recognizeIntent(String text) async {
    try {
      // Mock intent recognition
      final lowerText = text.toLowerCase();
      
      // Shopping intents
      if (lowerText.contains('add') && lowerText.contains('cart')) {
        return 'add_to_cart';
      } else if (lowerText.contains('remove') && lowerText.contains('cart')) {
        return 'remove_from_cart';
      } else if (lowerText.contains('checkout')) {
        return 'checkout';
      } else if (lowerText.contains('search') || lowerText.contains('find')) {
        return 'search_product';
      } else if (lowerText.contains('compare')) {
        return 'compare_products';
      } else if (lowerText.contains('show') || lowerText.contains('display')) {
        return 'show_product';
      }
      
      // Navigation intents
      if (lowerText.contains('go to') || lowerText.contains('navigate')) {
        return 'navigate';
      } else if (lowerText.contains('back')) {
        return 'go_back';
      } else if (lowerText.contains('home')) {
        return 'go_home';
      }
      
      // General intents
      if (lowerText.contains('help')) {
        return 'help';
      } else if (lowerText.contains('what') || lowerText.contains('tell me')) {
        return 'information';
      } else if (lowerText.contains('hello') || lowerText.contains('hi')) {
        return 'greeting';
      } else if (lowerText.contains('thank')) {
        return 'gratitude';
      } else if (lowerText.contains('goodbye') || lowerText.contains('bye')) {
        return 'farewell';
      }
      
      return 'unknown';
    } catch (e) {
      LoggingService.error('Failed to recognize intent: $e');
      return 'unknown';
    }
  }

  static Future<Map<String, dynamic>> _extractEntities(String text, String intent) async {
    try {
      final entities = <String, dynamic>{};
      
      switch (intent) {
        case 'add_to_cart':
          entities['product'] = _extractProductName(text);
          entities['quantity'] = _extractQuantity(text);
          break;
        case 'remove_from_cart':
          entities['product'] = _extractProductName(text);
          break;
        case 'search_product':
          entities['product'] = _extractProductName(text);
          entities['category'] = _extractCategory(text);
          break;
        case 'compare_products':
          entities['products'] = _extractMultipleProducts(text);
          break;
        case 'show_product':
          entities['product'] = _extractProductName(text);
          break;
        case 'navigate':
          entities['destination'] = _extractDestination(text);
          break;
      }
      
      return entities;
    } catch (e) {
      LoggingService.error('Failed to extract entities: $e');
      return {};
    }
  }

  static String? _extractProductName(String text) {
    // Mock product name extraction
    final products = ['iphone', 'samsung', 'macbook', 'ipad', 'nike', 'adidas'];
    final lowerText = text.toLowerCase();
    
    for (final product in products) {
      if (lowerText.contains(product)) {
        return product;
      }
    }
    
    return null;
  }

  static int _extractQuantity(String text) {
    // Mock quantity extraction
    final words = text.toLowerCase().split(' ');
    
    for (final word in words) {
      final number = int.tryParse(word);
      if (number != null && number > 0) {
        return number;
      }
      
      // Handle number words
      switch (word) {
        case 'one':
          return 1;
        case 'two':
          return 2;
        case 'three':
          return 3;
        case 'four':
          return 4;
        case 'five':
          return 5;
      }
    }
    
    return 1; // Default quantity
  }

  static String? _extractCategory(String text) {
    // Mock category extraction
    final categories = ['electronics', 'clothing', 'shoes', 'books', 'sports'];
    final lowerText = text.toLowerCase();
    
    for (final category in categories) {
      if (lowerText.contains(category)) {
        return category;
      }
    }
    
    return null;
  }

  static List<String> _extractMultipleProducts(String text) {
    // Mock multiple product extraction
    final products = <String>[];
    final lowerText = text.toLowerCase();
    
    final allProducts = ['iphone', 'samsung', 'macbook', 'ipad', 'nike', 'adidas'];
    
    for (final product in allProducts) {
      if (lowerText.contains(product)) {
        products.add(product);
      }
    }
    
    return products;
  }

  static String? _extractDestination(String text) {
    // Mock destination extraction
    final destinations = ['home', 'cart', 'checkout', 'search', 'profile', 'settings'];
    final lowerText = text.toLowerCase();
    
    for (final destination in destinations) {
      if (lowerText.contains(destination)) {
        return destination;
      }
    }
    
    return null;
  }

  static Future<double> _calculateConfidence(String text, String intent, Map<String, dynamic> entities) async {
    try {
      // Mock confidence calculation
      double confidence = 0.5;
      
      // Increase confidence based on intent recognition
      if (intent != 'unknown') {
        confidence += 0.2;
      }
      
      // Increase confidence based on entity extraction
      if (entities.isNotEmpty) {
        confidence += 0.2;
      }
      
      // Increase confidence based on text length and clarity
      if (text.length > 5) {
        confidence += 0.1;
      }
      
      // Add random variation
      confidence += (Random().nextDouble() - 0.5) * 0.2;
      
      return confidence.clamp(0.0, 1.0);
    } catch (e) {
      LoggingService.error('Failed to calculate confidence: $e');
      return 0.0;
    }
  }

  static Future<VoiceResponse> _generateResponse(VoiceCommand command, VoiceSession session) async {
    try {
      // Mock response generation
      await Future.delayed(Duration(milliseconds: 1000));
      
      String responseText = '';
      String audioData = '';
      ResponseType responseType = ResponseType.text;
      
      switch (command.intent) {
        case 'add_to_cart':
          final product = command.entities['product'] as String?;
          final quantity = command.entities['quantity'] as int? ?? 1;
          responseText = product != null 
              ? 'Added $quantity ${quantity == 1 ? 'item' : 'items'} of $product to your cart.'
              : 'I need to know which product to add to your cart.';
          responseType = ResponseType.action;
          break;
        case 'remove_from_cart':
          final product = command.entities['product'] as String?;
          responseText = product != null 
              ? 'Removed $product from your cart.'
              : 'I need to know which product to remove from your cart.';
          responseType = ResponseType.action;
          break;
        case 'checkout':
          responseText = 'Taking you to checkout. Please review your items before proceeding.';
          responseType = ResponseType.navigation;
          break;
        case 'search_product':
          final product = command.entities['product'] as String?;
          final category = command.entities['category'] as String?;
          if (product != null) {
            responseText = 'Searching for $product...';
          } else if (category != null) {
            responseText = 'Searching in $category category...';
          } else {
            responseText = 'What would you like me to search for?';
          }
          responseType = ResponseType.search;
          break;
        case 'compare_products':
          final products = command.entities['products'] as List<String>? ?? [];
          if (products.length >= 2) {
            responseText = 'Comparing ${products.join(' and ')}...';
          } else {
            responseText = 'I need at least two products to compare.';
          }
          responseType = ResponseType.information;
          break;
        case 'show_product':
          final product = command.entities['product'] as String?;
          responseText = product != null 
              ? 'Showing details for $product.'
              : 'Which product would you like me to show?';
          responseType = ResponseType.display;
          break;
        case 'navigate':
          final destination = command.entities['destination'] as String?;
          responseText = destination != null 
              ? 'Navigating to $destination.'
              : 'Where would you like to go?';
          responseType = ResponseType.navigation;
          break;
        case 'help':
          responseText = 'I can help you with shopping, searching products, adding items to cart, and navigating the app. Just tell me what you need!';
          responseType = ResponseType.help;
          break;
        case 'information':
          responseText = 'I can provide information about products, prices, and features. What would you like to know?';
          responseType = ResponseType.information;
          break;
        case 'greeting':
          responseText = 'Hello! How can I help you with your shopping today?';
          responseType = ResponseType.greeting;
          break;
        case 'gratitude':
          responseText = 'You\'re welcome! Is there anything else I can help you with?';
          responseType = ResponseType.gratitude;
          break;
        case 'farewell':
          responseText = 'Goodbye! Have a great day and happy shopping!';
          responseType = ResponseType.farewell;
          break;
        default:
          responseText = 'I didn\'t understand that. Could you please rephrase your request?';
          responseType = ResponseType.error;
          break;
      }
      
      // Generate audio response (mock)
      audioData = _generateAudioResponse(responseText);
      
      return VoiceResponse(
        id: _generateResponseId(),
        commandId: command.id,
        text: responseText,
        audioData: audioData,
        responseType: responseType,
        confidence: 0.9,
        timestamp: DateTime.now(),
        metadata: {
          'intent': command.intent,
          'entities': command.entities,
        },
      );
    } catch (e) {
      LoggingService.error('Failed to generate response: $e');
      return VoiceResponse(
        id: _generateResponseId(),
        commandId: command.id,
        text: 'Sorry, I encountered an error processing your request.',
        audioData: '',
        responseType: ResponseType.error,
        confidence: 0.0,
        timestamp: DateTime.now(),
        metadata: {},
      );
    }
  }

  static String _generateAudioResponse(String text) {
    // Mock audio response generation
    return 'audio_data_${DateTime.now().millisecondsSinceEpoch}';
  }

  static Future<void> _updateContext(VoiceCommand command, VoiceResponse response, VoiceSession session) async {
    try {
      // Update conversation context
      session.context.currentIntent = command.intent;
      session.context.entities.addAll(command.entities);
      
      // Add to conversation history
      session.context.conversationHistory.add({
        'command': command.text,
        'intent': command.intent,
        'response': response.text,
        'timestamp': DateTime.now().toIso8601String(),
      });
      
      // Keep only last 10 conversations
      if (session.context.conversationHistory.length > 10) {
        session.context.conversationHistory.removeRange(0, session.context.conversationHistory.length - 10);
      }
      
      // Update session state
      session.context.sessionState['last_intent'] = command.intent;
      session.context.sessionState['last_command_time'] = command.timestamp.toIso8601String();
      
      LoggingService.info('Context updated for session: ${session.id}');
    } catch (e) {
      LoggingService.error('Failed to update context: $e');
    }
  }

  // Voice commands management
  static Future<CommandResult> registerCommand({
    required String commandId,
    required String name,
    required String description,
    required List<String> patterns,
    required String intent,
    Map<String, dynamic>? parameters,
    bool isActive = true,
  }) async {
    try {
      final voiceCommand = VoiceCommandDefinition(
        id: commandId,
        name: name,
        description: description,
        patterns: patterns,
        intent: intent,
        parameters: parameters ?? {},
        isActive: isActive,
        createdAt: DateTime.now(),
        usageCount: 0,
        successRate: 0.0,
      );
      
      _availableCommands[commandId] = voiceCommand;
      
      // Save command
      await _saveCommand(voiceCommand);
      
      // Emit command registered event
      _emitEvent(VoiceEvent(
        type: VoiceEventType.commandRegistered,
        data: voiceCommand.toJson(),
      ));
      
      LoggingService.info('Voice command registered: $commandId');
      return CommandResult(
        success: true,
        command: voiceCommand,
      );
    } catch (e) {
      LoggingService.error('Failed to register voice command: $e');
      return CommandResult(
        success: false,
        error: e.toString(),
      );
    }
  }

  static Future<bool> unregisterCommand(String commandId) async {
    try {
      if (!_availableCommands.containsKey(commandId)) {
        return false;
      }
      
      _availableCommands.remove(commandId);
      
      // Emit command unregistered event
      _emitEvent(VoiceEvent(
        type: VoiceEventType.commandUnregistered,
        data: {
          'command_id': commandId,
        },
      ));
      
      LoggingService.info('Voice command unregistered: $commandId');
      return true;
    } catch (e) {
      LoggingService.error('Failed to unregister voice command: $e');
      return false;
    }
  }

  // User profile management
  static Future<UserProfile> _getUserProfile(String userId) async {
    try {
      if (_userProfiles.containsKey(userId)) {
        return _userProfiles[userId]!;
      }
      
      // Create default profile
      final profile = UserProfile(
        id: userId,
        name: 'User $userId',
        language: 'en-US',
        accent: 'neutral',
        voiceProfile: 'default',
        preferences: {
          'speech_rate': 1.0,
          'volume': 0.8,
          'pitch': 1.0,
          'wake_word_enabled': true,
          'continuous_listening': false,
        },
        createdAt: DateTime.now(),
        lastUpdated: DateTime.now(),
      );
      
      _userProfiles[userId] = profile;
      await _saveUserProfile(profile);
      
      return profile;
    } catch (e) {
      LoggingService.error('Failed to get user profile: $e');
      rethrow;
    }
  }

  static Future<bool> updateUserProfile({
    required String userId,
    String? name,
    String? language,
    String? accent,
    String? voiceProfile,
    Map<String, dynamic>? preferences,
  }) async {
    try {
      final profile = await _getUserProfile(userId);
      
      if (name != null) profile.name = name;
      if (language != null) profile.language = language;
      if (accent != null) profile.accent = accent;
      if (voiceProfile != null) profile.voiceProfile = voiceProfile;
      if (preferences != null) profile.preferences.addAll(preferences);
      
      profile.lastUpdated = DateTime.now();
      
      await _saveUserProfile(profile);
      
      // Emit profile updated event
      _emitEvent(VoiceEvent(
        type: VoiceEventType.profileUpdated,
        data: profile.toJson(),
      ));
      
      LoggingService.info('User profile updated: $userId');
      return true;
    } catch (e) {
      LoggingService.error('Failed to update user profile: $e');
      return false;
    }
  }

  // Voice analytics
  static Future<VoiceAnalytics> getAnalytics({
    String? userId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      var sessions = List<VoiceSession>.from(_sessionHistory);
      
      if (userId != null) {
        sessions = sessions.where((s) => s.userId == userId).toList();
      }
      
      if (startDate != null) {
        sessions = sessions.where((s) => s.startTime.isAfter(startDate)).toList();
      }
      
      if (endDate != null) {
        sessions = sessions.where((s) => s.startTime.isBefore(endDate)).toList();
      }
      
      if (_isVoiceSessionActive && _currentSession != null) {
        sessions.add(_currentSession!);
      }
      
      final intentStats = <String, int>{};
      final languageStats = <String, int>{};
      final responseTimeStats = <String, List<Duration>>{};
      
      Duration totalResponseTime = Duration.zero;
      int totalCommands = 0;
      
      for (final session in sessions) {
        for (final command in session.commands) {
          if (command.intent != null) {
            intentStats[command.intent!] = (intentStats[command.intent!] ?? 0) + 1;
          }
          
          languageStats[command.language] = (languageStats[command.language] ?? 0) + 1;
          
          totalResponseTime += command.processingTime;
          totalCommands++;
        }
      }
      
      return VoiceAnalytics(
        totalSessions: sessions.length,
        totalCommands: totalCommands,
        intentStats: intentStats,
        languageStats: languageStats,
        averageResponseTime: totalCommands > 0 
            ? Duration(milliseconds: totalResponseTime.inMilliseconds ~/ totalCommands)
            : Duration.zero,
        startDate: startDate ?? DateTime.now().subtract(Duration(days: 30)),
        endDate: endDate ?? DateTime.now(),
      );
    } catch (e) {
      LoggingService.error('Failed to get voice analytics: $e');
      return VoiceAnalytics(
        totalSessions: 0,
        totalCommands: 0,
        intentStats: {},
        languageStats: {},
        averageResponseTime: Duration.zero,
        startDate: DateTime.now(),
        endDate: DateTime.now(),
      );
    }
  }

  // Event handling
  static void _handleVoiceEvent(dynamic event) {
    try {
      final data = json.decode(event);
      final eventType = data['type'];
      
      switch (eventType) {
        case 'speech_recognized':
          _handleSpeechRecognized(data);
          break;
        case 'response_generated':
          _handleResponseGenerated(data);
          break;
        case 'error_occurred':
          _handleErrorOccurred(data);
          break;
      }
    } catch (e) {
      LoggingService.error('Failed to handle voice event: $e');
    }
  }

  static void _handleSpeechRecognized(Map<String, dynamic> data) {
    try {
      _emitEvent(VoiceEvent(
        type: VoiceEventType.speechRecognized,
        data: data,
      ));
    } catch (e) {
      LoggingService.error('Failed to handle speech recognized: $e');
    }
  }

  static void _handleResponseGenerated(Map<String, dynamic> data) {
    try {
      _emitEvent(VoiceEvent(
        type: VoiceEventType.responseGenerated,
        data: data,
      ));
    } catch (e) {
      LoggingService.error('Failed to handle response generated: $e');
    }
  }

  static void _handleErrorOccurred(Map<String, dynamic> data) {
    try {
      _emitEvent(VoiceEvent(
        type: VoiceEventType.errorOccurred,
        data: data,
      ));
    } catch (e) {
      LoggingService.error('Failed to handle error occurred: $e');
    }
  }

  static void _handleVoiceError(dynamic error) {
    LoggingService.error('Voice service error: $error');
    _emitEvent(VoiceEvent(
      type: VoiceEventType.serviceError,
      data: {'error': error.toString()},
    ));
  }

  static void _handleVoiceDisconnect() {
    LoggingService.info('Voice service disconnected');
    _emitEvent(VoiceEvent(
      type: VoiceEventType.serviceDisconnected,
      data: {},
    ));
  }

  static void _emitEvent(VoiceEvent event) {
    _eventController?.add(event);
  }

  // Data persistence
  static Future<void> _saveSessionHistory() async {
    try {
      final data = json.encode(_sessionHistory.map((s) => s.toJson()).toList());
      await CacheService.cacheData(_cacheKey, data, ttlHours: 24);
    } catch (e) {
      LoggingService.error('Failed to save session history: $e');
    }
  }

  static Future<void> _loadSessionHistory() async {
    try {
      final cachedData = await CacheService.getCachedData(_cacheKey);
      if (cachedData != null) {
        final historyData = json.decode(cachedData);
        _sessionHistory.clear();
        _sessionHistory.addAll(
          (historyData as List).map((item) => VoiceSession.fromJson(item)),
        );
      }
    } catch (e) {
      LoggingService.error('Failed to load session history: $e');
    }
  }

  static Future<void> _saveCommand(VoiceCommandDefinition command) async {
    try {
      final key = 'voice_command_${command.id}';
      final data = json.encode(command.toJson());
      await CacheService.cacheData(key, data, ttlHours: 24);
    } catch (e) {
      LoggingService.error('Failed to save voice command: $e');
    }
  }

  static Future<void> _saveUserProfile(UserProfile profile) async {
    try {
      final key = 'user_profile_${profile.id}';
      final data = json.encode(profile.toJson());
      await CacheService.cacheData(key, data, ttlHours: 24);
    } catch (e) {
      LoggingService.error('Failed to save user profile: $e');
    }
  }

  // Data loading
  static Future<void> _loadAvailableCommands() async {
    try {
      // Mock loading available commands
      _availableCommands.addAll([
        VoiceCommandDefinition(
          id: 'add_to_cart_cmd',
          name: 'Add to Cart',
          description: 'Add items to shopping cart',
          patterns: ['add * to cart', 'put * in cart', 'cart add *'],
          intent: 'add_to_cart',
          parameters: {'product': 'string', 'quantity': 'number'},
          isActive: true,
          createdAt: DateTime.now().subtract(Duration(days: 7)),
          usageCount: 0,
          successRate: 0.0,
        ),
        VoiceCommandDefinition(
          id: 'search_cmd',
          name: 'Search Product',
          description: 'Search for products',
          patterns: ['search *', 'find *', 'look for *'],
          intent: 'search_product',
          parameters: {'product': 'string', 'category': 'string'},
          isActive: true,
          createdAt: DateTime.now().subtract(Duration(days: 5)),
          usageCount: 0,
          successRate: 0.0,
        ),
        VoiceCommandDefinition(
          id: 'checkout_cmd',
          name: 'Checkout',
          description: 'Proceed to checkout',
          patterns: ['checkout', 'pay now', 'buy now'],
          intent: 'checkout',
          parameters: {},
          isActive: true,
          createdAt: DateTime.now().subtract(Duration(days: 3)),
          usageCount: 0,
          successRate: 0.0,
        ),
      ]);
    } catch (e) {
      LoggingService.error('Failed to load available commands: $e');
    }
  }

  static Future<void> _loadUserProfiles() async {
    try {
      // Mock loading user profiles
      final cachedData = await CacheService.getCachedData('user_profiles');
      if (cachedData != null) {
        final profilesData = json.decode(cachedData);
        _userProfiles.clear();
        for (final entry in profilesData.entries) {
          _userProfiles[entry.key] = UserProfile.fromJson(entry.value);
        }
      }
    } catch (e) {
      LoggingService.error('Failed to load user profiles: $e');
    }
  }

  // Utility methods
  static String _generateCommandId() {
    return 'cmd_${DateTime.now().millisecondsSinceEpoch}';
  }

  static String _generateResponseId() {
    return 'resp_${DateTime.now().millisecondsSinceEpoch}';
  }

  // Getters
  static bool get isInitialized => _isInitialized;
  static bool get isVoiceSessionActive => _isVoiceSessionActive;
  static VoiceSession? get currentSession => _currentSession;
  static Map<String, VoiceCommandDefinition> get availableCommands => Map.from(_availableCommands);
  static List<VoiceSession> get sessionHistory => List.from(_sessionHistory);
  static Map<String, UserProfile> get userProfiles => Map.from(_userProfiles);
  static Stream<VoiceEvent> get events => _eventController?.stream ?? Stream.empty();
}

// Data models
class VoiceSession {
  final String id;
  final String userId;
  final VoiceSessionType type;
  VoiceSessionStatus status;
  final DateTime startTime;
  final DateTime? endTime;
  final List<VoiceCommand> commands;
  final List<VoiceResponse> responses;
  final VoiceContext context;
  final Map<String, dynamic> config;
  final Map<String, dynamic> metadata;

  VoiceSession({
    required this.id,
    required this.userId,
    required this.type,
    required this.status,
    required this.startTime,
    this.endTime,
    required this.commands,
    required this.responses,
    required this.context,
    required this.config,
    required this.metadata,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'type': type.name,
      'status': status.name,
      'start_time': startTime.toIso8601String(),
      'end_time': endTime?.toIso8601String(),
      'commands': commands.map((cmd) => cmd.toJson()).toList(),
      'responses': responses.map((resp) => resp.toJson()).toList(),
      'context': context.toJson(),
      'config': config,
      'metadata': metadata,
    };
  }

  factory VoiceSession.fromJson(Map<String, dynamic> json) {
    return VoiceSession(
      id: json['id'],
      userId: json['user_id'],
      type: VoiceSessionType.values.firstWhere(
        (t) => t.name == json['type'],
        orElse: () => VoiceSessionType.general,
      ),
      status: VoiceSessionStatus.values.firstWhere(
        (s) => s.name == json['status'],
        orElse: () => VoiceSessionStatus.initializing,
      ),
      startTime: DateTime.parse(json['start_time']),
      endTime: json['end_time'] != null ? DateTime.parse(json['end_time']) : null,
      commands: (json['commands'] as List)
          .map((cmd) => VoiceCommand.fromJson(cmd))
          .toList(),
      responses: (json['responses'] as List)
          .map((resp) => VoiceResponse.fromJson(resp))
          .toList(),
      context: VoiceContext.fromJson(json['context']),
      config: Map<String, dynamic>.from(json['config']),
      metadata: Map<String, dynamic>.from(json['metadata']),
    );
  }
}

class VoiceCommand {
  final String id;
  final String text;
  final String audioData;
  final String language;
  final double confidence;
  final String? intent;
  final Map<String, dynamic> entities;
  final DateTime timestamp;
  final Duration processingTime;
  final Map<String, dynamic> metadata;

  VoiceCommand({
    required this.id,
    required this.text,
    required this.audioData,
    required this.language,
    required this.confidence,
    this.intent,
    required this.entities,
    required this.timestamp,
    required this.processingTime,
    required this.metadata,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'text': text,
      'audio_data': audioData,
      'language': language,
      'confidence': confidence,
      'intent': intent,
      'entities': entities,
      'timestamp': timestamp.toIso8601String(),
      'processing_time': processingTime.inMilliseconds,
      'metadata': metadata,
    };
  }

  factory VoiceCommand.fromJson(Map<String, dynamic> json) {
    return VoiceCommand(
      id: json['id'],
      text: json['text'],
      audioData: json['audio_data'],
      language: json['language'],
      confidence: json['confidence'].toDouble(),
      intent: json['intent'],
      entities: Map<String, dynamic>.from(json['entities']),
      timestamp: DateTime.parse(json['timestamp']),
      processingTime: Duration(milliseconds: json['processing_time']),
      metadata: Map<String, dynamic>.from(json['metadata']),
    );
  }
}

class VoiceResponse {
  final String id;
  final String commandId;
  final String text;
  final String audioData;
  final ResponseType responseType;
  final double confidence;
  final DateTime timestamp;
  final Map<String, dynamic> metadata;

  VoiceResponse({
    required this.id,
    required this.commandId,
    required this.text,
    required this.audioData,
    required this.responseType,
    required this.confidence,
    required this.timestamp,
    required this.metadata,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'command_id': commandId,
      'text': text,
      'audio_data': audioData,
      'response_type': responseType.name,
      'confidence': confidence,
      'timestamp': timestamp.toIso8601String(),
      'metadata': metadata,
    };
  }

  factory VoiceResponse.fromJson(Map<String, dynamic> json) {
    return VoiceResponse(
      id: json['id'],
      commandId: json['command_id'],
      text: json['text'],
      audioData: json['audio_data'],
      responseType: ResponseType.values.firstWhere(
        (t) => t.name == json['response_type'],
        orElse: () => ResponseType.text,
      ),
      confidence: json['confidence'].toDouble(),
      timestamp: DateTime.parse(json['timestamp']),
      metadata: Map<String, dynamic>.from(json['metadata']),
    );
  }
}

class VoiceContext {
  String? currentIntent;
  final Map<String, dynamic> entities;
  final List<Map<String, dynamic>> conversationHistory;
  final Map<String, dynamic> userPreferences;
  final Map<String, dynamic> sessionState;

  VoiceContext({
    this.currentIntent,
    required this.entities,
    required this.conversationHistory,
    required this.userPreferences,
    required this.sessionState,
  });

  Map<String, dynamic> toJson() {
    return {
      'current_intent': currentIntent,
      'entities': entities,
      'conversation_history': conversationHistory,
      'user_preferences': userPreferences,
      'session_state': sessionState,
    };
  }

  factory VoiceContext.fromJson(Map<String, dynamic> json) {
    return VoiceContext(
      currentIntent: json['current_intent'],
      entities: Map<String, dynamic>.from(json['entities']),
      conversationHistory: List<Map<String, dynamic>>.from(json['conversation_history']),
      userPreferences: Map<String, dynamic>.from(json['user_preferences']),
      sessionState: Map<String, dynamic>.from(json['session_state']),
    );
  }
}

class VoiceCommandDefinition {
  final String id;
  final String name;
  final String description;
  final List<String> patterns;
  final String intent;
  final Map<String, dynamic> parameters;
  final bool isActive;
  final DateTime createdAt;
  final int usageCount;
  final double successRate;

  VoiceCommandDefinition({
    required this.id,
    required this.name,
    required this.description,
    required this.patterns,
    required this.intent,
    required this.parameters,
    required this.isActive,
    required this.createdAt,
    required this.usageCount,
    required this.successRate,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'patterns': patterns,
      'intent': intent,
      'parameters': parameters,
      'is_active': isActive,
      'created_at': createdAt.toIso8601String(),
      'usage_count': usageCount,
      'success_rate': successRate,
    };
  }

  factory VoiceCommandDefinition.fromJson(Map<String, dynamic> json) {
    return VoiceCommandDefinition(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      patterns: List<String>.from(json['patterns']),
      intent: json['intent'],
      parameters: Map<String, dynamic>.from(json['parameters']),
      isActive: json['is_active'],
      createdAt: DateTime.parse(json['created_at']),
      usageCount: json['usage_count'],
      successRate: json['success_rate'].toDouble(),
    );
  }
}

class UserProfile {
  final String id;
  String name;
  String language;
  String accent;
  String voiceProfile;
  final Map<String, dynamic> preferences;
  final DateTime createdAt;
  DateTime lastUpdated;

  UserProfile({
    required this.id,
    required this.name,
    required this.language,
    required this.accent,
    required this.voiceProfile,
    required this.preferences,
    required this.createdAt,
    required this.lastUpdated,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'language': language,
      'accent': accent,
      'voice_profile': voiceProfile,
      'preferences': preferences,
      'created_at': createdAt.toIso8601String(),
      'last_updated': lastUpdated.toIso8601String(),
    };
  }

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'],
      name: json['name'],
      language: json['language'],
      accent: json['accent'],
      voiceProfile: json['voice_profile'],
      preferences: Map<String, dynamic>.from(json['preferences']),
      createdAt: DateTime.parse(json['created_at']),
      lastUpdated: DateTime.parse(json['last_updated']),
    );
  }
}

class VoiceAnalytics {
  final int totalSessions;
  final int totalCommands;
  final Map<String, int> intentStats;
  final Map<String, int> languageStats;
  final Duration averageResponseTime;
  final DateTime startDate;
  final DateTime endDate;

  VoiceAnalytics({
    required this.totalSessions,
    required this.totalCommands,
    required this.intentStats,
    required this.languageStats,
    required this.averageResponseTime,
    required this.startDate,
    required this.endDate,
  });
}

class VoiceEvent {
  final VoiceEventType type;
  final Map<String, dynamic> data;
  final DateTime timestamp;

  VoiceEvent({
    required this.type,
    required this.data,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();
}

class VoiceSessionResult {
  final bool success;
  final VoiceSession? session;
  final String? error;

  VoiceSessionResult({
    required this.success,
    this.session,
    this.error,
  });
}

class VoiceCommandResult {
  final bool success;
  final VoiceCommand? command;
  final VoiceResponse? response;
  final String? error;

  VoiceCommandResult({
    required this.success,
    this.command,
    this.response,
    this.error,
  });
}

class CommandResult {
  final bool success;
  final VoiceCommandDefinition? command;
  final String? error;

  CommandResult({
    required this.success,
    this.command,
    this.error,
  });
}

enum VoiceSessionType {
  general,
  shopping,
  navigation,
  information,
  entertainment,
}

enum VoiceSessionStatus {
  initializing,
  active,
  paused,
  ended,
  error,
}

enum ResponseType {
  text,
  audio,
  action,
  navigation,
  search,
  display,
  help,
  information,
  greeting,
  gratitude,
  farewell,
  error,
}

enum VoiceEventType {
  sessionStarted,
  sessionEnded,
  commandProcessed,
  responseGenerated,
  speechRecognized,
  commandRegistered,
  commandUnregistered,
  profileUpdated,
  serviceError,
  serviceDisconnected,
  errorOccurred,
}
