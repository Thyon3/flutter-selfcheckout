import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:selfcheckoutapp/services/logging_service.dart';
import 'package:selfcheckoutapp/services/security_service.dart';

class VoiceAssistantService {
  static final Map<String, VoiceCommand> _commands = {};
  static final Map<String, ConversationContext> _contexts = {};
  static final List<VoiceSession> _sessions = [];
  
  static bool _isInitialized = false;
  static bool _isListening = false;
  static StreamSubscription? _audioStream;
  static VoiceSession? _currentSession;
  static String _preferredLanguage = 'en';

  // Voice assistant initialization
  static Future<bool> initialize({
    String? apiKey,
    String language = 'en',
  }) async {
    try {
      if (_isInitialized) return true;
      
      LoggingService.info('Initializing voice assistant service');
      
      final key = apiKey ?? 'voice_api_key_12345';
      _preferredLanguage = language;
      
      // Initialize speech recognition
      await _initializeSpeechRecognition(key);
      
      // Initialize text-to-speech
      await _initializeTextToSpeech(key);
      
      // Load default commands
      await _loadDefaultCommands();
      
      _isInitialized = true;
      
      LoggingService.info('Voice assistant service initialized successfully');
      return true;
    } catch (e) {
      LoggingService.error('Failed to initialize voice assistant: $e');
      return false;
    }
  }

  // Voice session management
  static Future<String> startSession({
    String? sessionId,
    String? userId,
    Map<String, dynamic>? context,
  }) async {
    try {
      final id = sessionId ?? _generateSessionId();
      
      final session = VoiceSession(
        id: id,
        userId: userId,
        startedAt: DateTime.now(),
        isActive: true,
        context: context ?? {},
        commands: [],
      );
      
      _sessions.add(session);
      _currentSession = session;
      
      // Create conversation context
      _contexts[id] = ConversationContext(
        sessionId: id,
        userId: userId,
        language: _preferredLanguage,
        history: [],
        preferences: {},
      );
      
      LoggingService.info('Started voice session: $id');
      return id;
    } catch (e) {
      LoggingService.error('Failed to start voice session: $e');
      rethrow;
    }
  }

  static Future<void> stopSession(String sessionId) async {
    try {
      final session = _sessions.firstWhere((s) => s.id == sessionId);
      session.isActive = false;
      session.endedAt = DateTime.now();
      
      if (_currentSession?.id == sessionId) {
        _currentSession = null;
      }
      
      _contexts.remove(sessionId);
      
      LoggingService.info('Stopped voice session: $sessionId');
    } catch (e) {
      LoggingService.error('Failed to stop voice session: $e');
    }
  }

  // Speech recognition
  static Future<bool> startListening() async {
    try {
      if (!_isInitialized) {
        await initialize();
      }
      
      if (_isListening) {
        LoggingService.warning('Already listening for voice input');
        return true;
      }
      
      _isListening = true;
      
      // Start audio capture
      await _startAudioCapture();
      
      LoggingService.info('Started listening for voice input');
      return true;
    } catch (e) {
      LoggingService.error('Failed to start listening: $e');
      return false;
    }
  }

  static Future<void> stopListening() async {
    try {
      if (!_isListening) return;
      
      _isListening = false;
      
      // Stop audio capture
      await _stopAudioCapture();
      
      LoggingService.info('Stopped listening for voice input');
    } catch (e) {
      LoggingService.error('Failed to stop listening: $e');
    }
  }

  static Future<String?> recognizeSpeech() async {
    try {
      if (!_isListening) {
        throw Exception('Not currently listening');
      }
      
      // Capture audio
      final audioData = await _captureAudio();
      
      if (audioData == null || audioData.isEmpty) {
        return null;
      }
      
      // Send to speech recognition service
      final transcript = await _sendToSpeechRecognition(audioData);
      
      if (transcript != null && _currentSession != null) {
        _currentSession!.commands.add(VoiceCommand(
          type: VoiceCommandType.recognition,
          transcript: transcript,
          timestamp: DateTime.now(),
        ));
      }
      
      return transcript;
    } catch (e) {
      LoggingService.error('Failed to recognize speech: $e');
      return null;
    }
  }

  // Text-to-speech
  static Future<void> speak({
    required String text,
    String? language,
    double volume = 1.0,
    double rate = 1.0,
    double pitch = 1.0,
  }) async {
    try {
      if (!_isInitialized) {
        await initialize();
      }
      
      final lang = language ?? _preferredLanguage;
      
      // Generate speech
      final audioData = await _generateSpeech(text, lang, volume, rate, pitch);
      
      if (audioData != null) {
        // Play audio
        await _playAudio(audioData);
        
        if (_currentSession != null) {
          _currentSession!.commands.add(VoiceCommand(
            type: VoiceCommandType.synthesis,
            transcript: text,
            timestamp: DateTime.now(),
          ));
        }
      }
      
      LoggingService.info('Spoke text: $text');
    } catch (e) {
      LoggingService.error('Failed to speak text: $e');
    }
  }

  // Command processing
  static Future<VoiceResponse> processCommand({
    required String transcript,
    String? sessionId,
    Map<String, dynamic>? context,
  }) async {
    try {
      final session = sessionId != null 
          ? _contexts[sessionId]
          : _currentSession != null ? _contexts[_currentSession!.id] : null;
      
      // Add to conversation history
      if (session != null) {
        session.history.add(ConversationMessage(
          type: ConversationMessageType.user,
          content: transcript,
          timestamp: DateTime.now(),
        ));
      }
      
      // Parse intent
      final intent = await _parseIntent(transcript, session);
      
      // Execute command
      final response = await _executeIntent(intent, session);
      
      // Add response to history
      if (session != null) {
        session.history.add(ConversationMessage(
          type: ConversationMessageType.assistant,
          content: response.text,
          timestamp: DateTime.now(),
        ));
      }
      
      LoggingService.info('Processed voice command: ${intent.intent}');
      return response;
    } catch (e) {
      LoggingService.error('Failed to process command: $e');
      return VoiceResponse(
        text: 'Sorry, I didn\'t understand that. Could you please repeat?',
        intent: 'error',
        confidence: 0.0,
        requiresAction: false,
      );
    }
  }

  // Shopping commands
  static Future<VoiceResponse> handleShoppingCommand({
    required String command,
    Map<String, dynamic>? context,
  }) async {
    try {
      final lowerCommand = command.toLowerCase();
      
      // Add to cart
      if (lowerCommand.contains('add') && lowerCommand.contains('cart')) {
        final productName = _extractProductName(command);
        if (productName != null) {
          return await _addToCart(productName);
        }
      }
      
      // Remove from cart
      if (lowerCommand.contains('remove') && lowerCommand.contains('cart')) {
        final productName = _extractProductName(command);
        if (productName != null) {
          return await _removeFromCart(productName);
        }
      }
      
      // Checkout
      if (lowerCommand.contains('checkout') || lowerCommand.contains('pay')) {
        return await _checkout();
      }
      
      // Search products
      if (lowerCommand.contains('search') || lowerCommand.contains('find')) {
        final productName = _extractProductName(command);
        if (productName != null) {
          return await _searchProducts(productName);
        }
      }
      
      // Show cart
      if (lowerCommand.contains('show') && lowerCommand.contains('cart')) {
        return await _showCart();
      }
      
      // Clear cart
      if (lowerCommand.contains('clear') && lowerCommand.contains('cart')) {
        return await _clearCart();
      }
      
      return VoiceResponse(
        text: 'I didn\'t understand that shopping command. Try saying "add [product] to cart" or "show cart".',
        intent: 'unknown_shopping_command',
        confidence: 0.3,
        requiresAction: false,
      );
    } catch (e) {
      LoggingService.error('Failed to handle shopping command: $e');
      return VoiceResponse(
        text: 'Sorry, I had trouble with that command.',
        intent: 'error',
        confidence: 0.0,
        requiresAction: false,
      );
    }
  }

  // Navigation commands
  static Future<VoiceResponse> handleNavigationCommand({
    required String command,
    Map<String, dynamic>? context,
  }) async {
    try {
      final lowerCommand = command.toLowerCase();
      
      // Go to home
      if (lowerCommand.contains('home')) {
        return await _navigateToScreen('home');
      }
      
      // Go to cart
      if (lowerCommand.contains('cart')) {
        return await _navigateToScreen('cart');
      }
      
      // Go to profile
      if (lowerCommand.contains('profile')) {
        return await _navigateToScreen('profile');
      }
      
      // Go to settings
      if (lowerCommand.contains('settings')) {
        return await _navigateToScreen('settings');
      }
      
      // Go back
      if (lowerCommand.contains('back')) {
        return await _goBack();
      }
      
      return VoiceResponse(
        text: 'I didn\'t understand that navigation command. Try saying "go to home" or "go back".',
        intent: 'unknown_navigation_command',
        confidence: 0.3,
        requiresAction: false,
      );
    } catch (e) {
      LoggingService.error('Failed to handle navigation command: $e');
      return VoiceResponse(
        text: 'Sorry, I had trouble with that navigation command.',
        intent: 'error',
        confidence: 0.0,
        requiresAction: false,
      );
    }
  }

  // Information commands
  static Future<VoiceResponse> handleInformationCommand({
    required String command,
    Map<String, dynamic>? context,
  }) async {
    try {
      final lowerCommand = command.toLowerCase();
      
      // Product information
      if (lowerCommand.contains('what is') || lowerCommand.contains('tell me about')) {
        final productName = _extractProductName(command);
        if (productName != null) {
          return await _getProductInfo(productName);
        }
      }
      
      // Price information
      if (lowerCommand.contains('how much') || lowerCommand.contains('price')) {
        final productName = _extractProductName(command);
        if (productName != null) {
          return await _getProductPrice(productName);
        }
      }
      
      // Help
      if (lowerCommand.contains('help')) {
        return await _getHelp();
      }
      
      return VoiceResponse(
        text: 'I didn\'t understand that information command. Try asking "what is [product]" or "how much is [product]".',
        intent: 'unknown_information_command',
        confidence: 0.3,
        requiresAction: false,
      );
    } catch (e) {
      LoggingService.error('Failed to handle information command: $e');
      return VoiceResponse(
        text: 'Sorry, I had trouble with that information request.',
        intent: 'error',
        confidence: 0.0,
        requiresAction: false,
      );
    }
  }

  // Custom commands
  static Future<void> addCustomCommand({
    required String intent,
    required List<String> phrases,
    required Future<VoiceResponse> Function(Map<String, dynamic>) handler,
    String? description,
  }) async {
    try {
      final command = VoiceCommand(
        intent: intent,
        phrases: phrases,
        handler: handler,
        description: description,
        createdAt: DateTime.now(),
      );
      
      _commands[intent] = command;
      
      LoggingService.info('Added custom voice command: $intent');
    } catch (e) {
      LoggingService.error('Failed to add custom command: $e');
    }
  }

  // Utility methods
  static Future<void> _initializeSpeechRecognition(String apiKey) async {
    // Mock speech recognition initialization
    LoggingService.info('Initialized speech recognition');
  }

  static Future<void> _initializeTextToSpeech(String apiKey) async {
    // Mock text-to-speech initialization
    LoggingService.info('Initialized text-to-speech');
  }

  static Future<void> _loadDefaultCommands() async {
    // Add default shopping commands
    await addCustomCommand(
      intent: 'add_to_cart',
      phrases: ['add to cart', 'put in cart', 'add item'],
      handler: (params) async {
        final productName = params['product_name'] as String?;
        if (productName != null) {
          return await _addToCart(productName);
        }
        return VoiceResponse(
          text: 'What would you like to add to cart?',
          intent: 'add_to_cart',
          confidence: 0.8,
          requiresAction: true,
        );
      },
      description: 'Add items to shopping cart',
    );
    
    // Add default navigation commands
    await addCustomCommand(
      intent: 'go_home',
      phrases: ['go home', 'home', 'main page'],
      handler: (params) async => await _navigateToScreen('home'),
      description: 'Navigate to home screen',
    );
  }

  static Future<void> _startAudioCapture() async {
    // Mock audio capture start
    LoggingService.info('Started audio capture');
  }

  static Future<void> _stopAudioCapture() async {
    // Mock audio capture stop
    LoggingService.info('Stopped audio capture');
  }

  static Future<List<int>?> _captureAudio() async {
    // Mock audio capture
    await Future.delayed(Duration(milliseconds: 2000));
    return [1, 2, 3, 4, 5]; // Mock audio data
  }

  static Future<String?> _sendToSpeechRecognition(List<int> audioData) async {
    try {
      // Mock speech recognition API call
      await Future.delayed(Duration(milliseconds: 1000));
      
      // Mock recognition results
      final mockResults = [
        'add milk to cart',
        'show my cart',
        'how much is this',
        'go to home',
        'checkout',
      ];
      
      return mockResults[Random().nextInt(mockResults.length)];
    } catch (e) {
      LoggingService.error('Speech recognition failed: $e');
      return null;
    }
  }

  static Future<List<int>?> _generateSpeech(
    String text,
    String language,
    double volume,
    double rate,
    double pitch,
  ) async {
    try {
      // Mock text-to-speech API call
      await Future.delayed(Duration(milliseconds: 1500));
      
      // Mock audio data
      return [1, 2, 3, 4, 5]; // Mock audio data
    } catch (e) {
      LoggingService.error('Speech generation failed: $e');
      return null;
    }
  }

  static Future<void> _playAudio(List<int> audioData) async {
    // Mock audio playback
    await Future.delayed(Duration(milliseconds: 2000));
    LoggingService.info('Played audio response');
  }

  static Future<VoiceIntent> _parseIntent(String transcript, ConversationContext? context) async {
    try {
      // Mock intent parsing
      final lowerTranscript = transcript.toLowerCase();
      
      // Shopping intents
      if (lowerTranscript.contains('add') && lowerTranscript.contains('cart')) {
        return VoiceIntent(
          intent: 'add_to_cart',
          entities: {
            'product_name': _extractProductName(transcript),
          },
          confidence: 0.9,
        );
      }
      
      // Navigation intents
      if (lowerTranscript.contains('go') || lowerTranscript.contains('navigate')) {
        return VoiceIntent(
          intent: 'navigate',
          entities: {
            'destination': _extractDestination(transcript),
          },
          confidence: 0.8,
        );
      }
      
      // Information intents
      if (lowerTranscript.contains('what') || lowerTranscript.contains('how')) {
        return VoiceIntent(
          intent: 'information',
          entities: {
            'query': transcript,
          },
          confidence: 0.7,
        );
      }
      
      // Default intent
      return VoiceIntent(
        intent: 'unknown',
        entities: {},
        confidence: 0.3,
      );
    } catch (e) {
      LoggingService.error('Intent parsing failed: $e');
      return VoiceIntent(
        intent: 'error',
        entities: {},
        confidence: 0.0,
      );
    }
  }

  static Future<VoiceResponse> _executeIntent(VoiceIntent intent, ConversationContext? context) async {
    try {
      switch (intent.intent) {
        case 'add_to_cart':
          return await handleShoppingCommand(
            command: 'add ${intent.entities['product_name']} to cart',
            context: context?.preferences,
          );
        case 'navigate':
          return await handleNavigationCommand(
            command: 'go to ${intent.entities['destination']}',
            context: context?.preferences,
          );
        case 'information':
          return await handleInformationCommand(
            command: intent.entities['query'] ?? '',
            context: context?.preferences,
          );
        default:
          return VoiceResponse(
            text: 'I didn\'t understand that command. Could you please repeat?',
            intent: 'unknown',
            confidence: 0.0,
            requiresAction: false,
          );
      }
    } catch (e) {
      LoggingService.error('Intent execution failed: $e');
      return VoiceResponse(
        text: 'Sorry, I had trouble processing that command.',
        intent: 'error',
        confidence: 0.0,
        requiresAction: false,
      );
    }
  }

  static String? _extractProductName(String command) {
    // Mock product name extraction
    final products = ['milk', 'bread', 'eggs', 'apples', 'tomatoes'];
    
    for (final product in products) {
      if (command.toLowerCase().contains(product)) {
        return product;
      }
    }
    
    return null;
  }

  static String? _extractDestination(String command) {
    // Mock destination extraction
    final destinations = ['home', 'cart', 'profile', 'settings'];
    
    for (final destination in destinations) {
      if (command.toLowerCase().contains(destination)) {
        return destination;
      }
    }
    
    return null;
  }

  static Future<VoiceResponse> _addToCart(String productName) async {
    return VoiceResponse(
      text: 'Added $productName to your cart',
      intent: 'add_to_cart',
      confidence: 0.9,
      requiresAction: false,
      action: 'add_to_cart',
      actionData: {'product_name': productName},
    );
  }

  static Future<VoiceResponse> _removeFromCart(String productName) async {
    return VoiceResponse(
      text: 'Removed $productName from your cart',
      intent: 'remove_from_cart',
      confidence: 0.9,
      requiresAction: false,
      action: 'remove_from_cart',
      actionData: {'product_name': productName},
    );
  }

  static Future<VoiceResponse> _checkout() async {
    return VoiceResponse(
      text: 'Proceeding to checkout',
      intent: 'checkout',
      confidence: 0.9,
      requiresAction: false,
      action: 'checkout',
    );
  }

  static Future<VoiceResponse> _searchProducts(String productName) async {
    return VoiceResponse(
      text: 'Searching for $productName',
      intent: 'search_products',
      confidence: 0.8,
      requiresAction: false,
      action: 'search_products',
      actionData: {'query': productName},
    );
  }

  static Future<VoiceResponse> _showCart() async {
    return VoiceResponse(
      text: 'Here\'s your shopping cart',
      intent: 'show_cart',
      confidence: 0.9,
      requiresAction: false,
      action: 'show_cart',
    );
  }

  static Future<VoiceResponse> _clearCart() async {
    return VoiceResponse(
      text: 'Cleared your shopping cart',
      intent: 'clear_cart',
      confidence: 0.9,
      requiresAction: false,
      action: 'clear_cart',
    );
  }

  static Future<VoiceResponse> _navigateToScreen(String screenName) async {
    return VoiceResponse(
      text: 'Navigating to $screenName',
      intent: 'navigate',
      confidence: 0.9,
      requiresAction: false,
      action: 'navigate',
      actionData: {'screen': screenName},
    );
  }

  static Future<VoiceResponse> _goBack() async {
    return VoiceResponse(
      text: 'Going back',
      intent: 'go_back',
      confidence: 0.9,
      requiresAction: false,
      action: 'go_back',
    );
  }

  static Future<VoiceResponse> _getProductInfo(String productName) async {
    return VoiceResponse(
      text: '$productName is a fresh product available in our store',
      intent: 'product_info',
      confidence: 0.8,
      requiresAction: false,
    );
  }

  static Future<VoiceResponse> _getProductPrice(String productName) async {
    return VoiceResponse(
      text: '$productName costs Rs 50.00',
      intent: 'product_price',
      confidence: 0.8,
      requiresAction: false,
    );
  }

  static Future<VoiceResponse> _getHelp() async {
    return VoiceResponse(
      text: 'You can say things like "add milk to cart", "show my cart", or "go to home". How can I help you?',
      intent: 'help',
      confidence: 0.9,
      requiresAction: false,
    );
  }

  static String _generateSessionId() {
    return 'voice_session_${DateTime.now().millisecondsSinceEpoch}';
  }

  // Getters
  static bool get isInitialized => _isInitialized;
  static bool get isListening => _isListening;
  static VoiceSession? get currentSession => _currentSession;
  static List<VoiceSession> get sessions => _sessions.where((s) => s.isActive).toList();
  static String get preferredLanguage => _preferredLanguage;
}

// Data models
class VoiceSession {
  final String id;
  final String? userId;
  final DateTime startedAt;
  DateTime? endedAt;
  bool isActive;
  final Map<String, dynamic> context;
  final List<VoiceCommand> commands;

  VoiceSession({
    required this.id,
    this.userId,
    required this.startedAt,
    this.endedAt,
    required this.isActive,
    required this.context,
    required this.commands,
  });
}

class VoiceCommand {
  final VoiceCommandType type;
  final String transcript;
  final DateTime timestamp;
  final Map<String, dynamic>? metadata;

  VoiceCommand({
    required this.type,
    required this.transcript,
    required this.timestamp,
    this.metadata,
  });
}

class CustomVoiceCommand {
  final String intent;
  final List<String> phrases;
  final Future<VoiceResponse> Function(Map<String, dynamic>) handler;
  final String? description;
  final DateTime createdAt;

  CustomVoiceCommand({
    required this.intent,
    required this.phrases,
    required this.handler,
    this.description,
    required this.createdAt,
  });
}

class ConversationContext {
  final String sessionId;
  final String? userId;
  final String language;
  final List<ConversationMessage> history;
  final Map<String, dynamic> preferences;

  ConversationContext({
    required this.sessionId,
    this.userId,
    required this.language,
    required this.history,
    required this.preferences,
  });
}

class ConversationMessage {
  final ConversationMessageType type;
  final String content;
  final DateTime timestamp;

  ConversationMessage({
    required this.type,
    required this.content,
    required this.timestamp,
  });
}

class VoiceIntent {
  final String intent;
  final Map<String, dynamic> entities;
  final double confidence;

  VoiceIntent({
    required this.intent,
    required this.entities,
    required this.confidence,
  });
}

class VoiceResponse {
  final String text;
  final String intent;
  final double confidence;
  final bool requiresAction;
  final String? action;
  final Map<String, dynamic>? actionData;

  VoiceResponse({
    required this.text,
    required this.intent,
    required this.confidence,
    required this.requiresAction,
    this.action,
    this.actionData,
  });
}

enum VoiceCommandType {
  recognition,
  synthesis,
  command,
}

enum ConversationMessageType {
  user,
  assistant,
  system,
}
