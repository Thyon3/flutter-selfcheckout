import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:selfcheckoutapp/services/logging_service.dart';
import 'package:selfcheckoutapp/services/cache_service.dart';
import 'package:selfcheckoutapp/services/security_service.dart';

class NeuralSearchService {
  static const String _baseUrl = 'https://api.neural.scango.app';
  static const String _apiKey = 'neural_search_api_key_12345';
  static const String _cacheKey = 'neural_search_cache';
  static const String _embeddingsKey = 'neural_embeddings_cache';
  
  static bool _isInitialized = false;
  static bool _isModelLoaded = false;
  static final Map<String, ProductEmbedding> _productEmbeddings = {};
  static final Map<String, UserEmbedding> _userEmbeddings = {};
  static final List<SearchQuery> _searchHistory = [];
  static StreamController<NeuralSearchEvent>? _eventController;

  // Neural search service initialization
  static Future<bool> initialize() async {
    try {
      if (_isInitialized) return true;
      
      LoggingService.info('Initializing neural search service');
      
      // Initialize event controller
      _eventController = StreamController<NeuralSearchEvent>.broadcast();
      
      // Load neural model
      await _loadNeuralModel();
      
      // Load embeddings
      await _loadEmbeddings();
      
      // Load search history
      await _loadSearchHistory();
      
      _isInitialized = true;
      
      LoggingService.info('Neural search service initialized successfully');
      return true;
    } catch (e) {
      LoggingService.error('Failed to initialize neural search service: $e');
      return false;
    }
  }

  // Neural model management
  static Future<void> _loadNeuralModel() async {
    try {
      // Mock neural model loading
      await Future.delayed(Duration(seconds: 3));
      
      _isModelLoaded = true;
      
      LoggingService.info('Neural model loaded successfully');
    } catch (e) {
      LoggingService.error('Failed to load neural model: $e');
      _isModelLoaded = false;
    }
  }

  // Embeddings management
  static Future<void> _loadEmbeddings() async {
    try {
      // Load product embeddings
      await _loadProductEmbeddings();
      
      // Load user embeddings
      await _loadUserEmbeddings();
      
      LoggingService.info('Embeddings loaded successfully');
    } catch (e) {
      LoggingService.error('Failed to load embeddings: $e');
    }
  }

  static Future<void> _loadProductEmbeddings() async {
    try {
      // Mock loading product embeddings from cache
      final cachedData = await CacheService.getCachedData(_embeddingsKey);
      if (cachedData != null) {
        final embeddingsData = json.decode(cachedData);
        _productEmbeddings.clear();
        for (final entry in embeddingsData['products'].entries) {
          _productEmbeddings[entry.key] = ProductEmbedding.fromJson(entry.value);
        }
      } else {
        // Generate mock embeddings
        await _generateMockProductEmbeddings();
      }
    } catch (e) {
      LoggingService.error('Failed to load product embeddings: $e');
    }
  }

  static Future<void> _loadUserEmbeddings() async {
    try {
      // Mock loading user embeddings
      final cachedData = await CacheService.getCachedData('user_embeddings');
      if (cachedData != null) {
        final embeddingsData = json.decode(cachedData);
        _userEmbeddings.clear();
        for (final entry in embeddingsData.entries) {
          _userEmbeddings[entry.key] = UserEmbedding.fromJson(entry.value);
        }
      }
    } catch (e) {
      LoggingService.error('Failed to load user embeddings: $e');
    }
  }

  static Future<void> _generateMockProductEmbeddings() async {
    try {
      final mockProducts = [
        'iPhone 15 Pro',
        'Samsung Galaxy S24',
        'Nike Air Max',
        'Adidas Ultraboost',
        'Sony WH-1000XM5',
        'Apple Watch Series 9',
        'MacBook Pro M3',
        'iPad Pro',
        'Dyson V15 Detect',
        'Instant Pot Duo',
      ];
      
      for (final product in mockProducts) {
        final embedding = ProductEmbedding(
          productId: product.replaceAll(' ', '_').toLowerCase(),
          productName: product,
          embedding: _generateRandomEmbedding(),
          category: _getProductCategory(product),
          attributes: _getProductAttributes(product),
          lastUpdated: DateTime.now(),
        );
        
        _productEmbeddings[embedding.productId] = embedding;
      }
      
      // Save embeddings
      await _saveEmbeddings();
    } catch (e) {
      LoggingService.error('Failed to generate mock product embeddings: $e');
    }
  }

  static List<double> _generateRandomEmbedding() {
    // Generate 384-dimensional embedding (typical for sentence transformers)
    return List.generate(384, (_) => (Random().nextDouble() - 0.5) * 2);
  }

  static String _getProductCategory(String product) {
    if (product.toLowerCase().contains('iphone') || product.toLowerCase().contains('samsung')) {
      return 'smartphones';
    } else if (product.toLowerCase().contains('nike') || product.toLowerCase().contains('adidas')) {
      return 'footwear';
    } else if (product.toLowerCase().contains('sony') || product.toLowerCase().contains('airpods')) {
      return 'audio';
    } else if (product.toLowerCase().contains('watch')) {
      return 'wearables';
    } else if (product.toLowerCase().contains('macbook') || product.toLowerCase().contains('ipad')) {
      return 'computers';
    } else if (product.toLowerCase().contains('dyson') || product.toLowerCase().contains('instant')) {
      return 'appliances';
    }
    return 'other';
  }

  static Map<String, dynamic> _getProductAttributes(String product) {
    return {
      'brand': _extractBrand(product),
      'price_range': _getPriceRange(product),
      'popularity': Random().nextDouble(),
      'rating': 3.5 + Random().nextDouble() * 1.5,
      'features': _getProductFeatures(product),
    };
  }

  static String _extractBrand(String product) {
    final brands = ['Apple', 'Samsung', 'Nike', 'Adidas', 'Sony', 'Dyson', 'Instant Pot'];
    for (final brand in brands) {
      if (product.toLowerCase().contains(brand.toLowerCase())) {
        return brand;
      }
    }
    return 'Unknown';
  }

  static String _getPriceRange(String product) {
    final ranges = ['budget', 'mid-range', 'premium', 'luxury'];
    return ranges[Random().nextInt(ranges.length)];
  }

  static List<String> _getProductFeatures(String product) {
    final allFeatures = [
      'wireless', 'bluetooth', 'water_resistant', 'fast_charging',
      'touch_screen', 'camera', 'gps', 'heart_rate_monitor', 'noise_cancelling',
      'voice_assistant', 'waterproof', 'lightweight', 'durable', 'eco_friendly'
    ];
    
    final featureCount = Random().nextInt(4) + 2;
    final features = <String>[];
    
    for (int i = 0; i < featureCount; i++) {
      final feature = allFeatures[Random().nextInt(allFeatures.length)];
      if (!features.contains(feature)) {
        features.add(feature);
      }
    }
    
    return features;
  }

  static Future<void> _saveEmbeddings() async {
    try {
      final data = {
        'products': _productEmbeddings.map((key, value) => MapEntry(key, value.toJson())),
        'users': _userEmbeddings.map((key, value) => MapEntry(key, value.toJson())),
      };
      
      await CacheService.cacheData(_embeddingsKey, json.encode(data), ttlHours: 24);
    } catch (e) {
      LoggingService.error('Failed to save embeddings: $e');
    }
  }

  // Neural search operations
  static Future<NeuralSearchResult> search({
    required String query,
    String? userId,
    SearchType searchType = SearchType.semantic,
    int maxResults = 10,
    List<String>? categories,
    Map<String, dynamic>? filters,
  }) async {
    try {
      if (!_isInitialized) {
        await initialize();
      }
      
      if (!_isModelLoaded) {
        return NeuralSearchResult(
          success: false,
          error: 'Neural model not loaded',
        );
      }
      
      // Generate query embedding
      final queryEmbedding = await _generateQueryEmbedding(query);
      
      // Perform search based on type
      List<ProductSearchResult> results;
      
      switch (searchType) {
        case SearchType.semantic:
          results = await _performSemanticSearch(queryEmbedding, maxResults, categories, filters);
          break;
        case SearchType.hybrid:
          results = await _performHybridSearch(query, queryEmbedding, maxResults, categories, filters);
          break;
        case SearchType.personalized:
          results = await _performPersonalizedSearch(queryEmbedding, userId, maxResults, categories, filters);
          break;
      }
      
      // Record search query
      await _recordSearchQuery(query, userId, searchType, results.length);
      
      // Update user embedding if user is provided
      if (userId != null) {
        await _updateUserEmbedding(userId, queryEmbedding);
      }
      
      // Emit search completed event
      _emitEvent(NeuralSearchEvent(
        type: NeuralSearchEventType.searchCompleted,
        data: {
          'query': query,
          'user_id': userId,
          'results_count': results.length,
          'search_type': searchType.name,
        },
      ));
      
      LoggingService.info('Neural search completed: $query (${results.length} results)');
      return NeuralSearchResult(
        success: true,
        query: query,
        results: results,
        searchType: searchType,
        processingTime: Duration(milliseconds: 500), // Mock processing time
      );
    } catch (e) {
      LoggingService.error('Failed to perform neural search: $e');
      return NeuralSearchResult(
        success: false,
        error: e.toString(),
      );
    }
  }

  static Future<List<double>> _generateQueryEmbedding(String query) async {
    try {
      // Mock query embedding generation
      await Future.delayed(Duration(milliseconds: 200));
      
      // Generate embedding based on query hash for consistency
      final hash = query.hashCode;
      final random = Random(hash);
      
      return List.generate(384, (_) => (random.nextDouble() - 0.5) * 2);
    } catch (e) {
      LoggingService.error('Failed to generate query embedding: $e');
      rethrow;
    }
  }

  static Future<List<ProductSearchResult>> _performSemanticSearch(
    List<double> queryEmbedding,
    int maxResults,
    List<String>? categories,
    Map<String, dynamic>? filters,
  ) async {
    try {
      final similarities = <String, double>{};
      
      // Calculate cosine similarity for each product
      for (final entry in _productEmbeddings.entries) {
        final product = entry.value;
        
        // Apply category filter
        if (categories != null && !categories.contains(product.category)) {
          continue;
        }
        
        // Apply filters
        if (!_passesFilters(product, filters)) {
          continue;
        }
        
        // Calculate cosine similarity
        final similarity = _calculateCosineSimilarity(queryEmbedding, product.embedding);
        similarities[entry.key] = similarity;
      }
      
      // Sort by similarity
      final sortedEntries = similarities.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      
      // Convert to search results
      final results = sortedEntries.take(maxResults).map((entry) {
        final product = _productEmbeddings[entry.key]!;
        return ProductSearchResult(
          productId: product.productId,
          productName: product.productName,
          category: product.category,
          similarity: entry.value,
          score: entry.value,
          attributes: product.attributes,
          explanation: _generateExplanation(query, product, entry.value),
        );
      }).toList();
      
      return results;
    } catch (e) {
      LoggingService.error('Failed to perform semantic search: $e');
      return [];
    }
  }

  static Future<List<ProductSearchResult>> _performHybridSearch(
    String query,
    List<double> queryEmbedding,
    int maxResults,
    List<String>? categories,
    Map<String, dynamic>? filters,
  ) async {
    try {
      // Get semantic search results
      final semanticResults = await _performSemanticSearch(
        queryEmbedding,
        maxResults * 2, // Get more results for hybrid scoring
        categories,
        filters,
      );
      
      // Get keyword search results (mock)
      final keywordResults = await _performKeywordSearch(query, maxResults * 2);
      
      // Combine and re-score
      final combinedResults = <String, ProductSearchResult>{};
      
      // Add semantic results
      for (final result in semanticResults) {
        combinedResults[result.productId] = result;
      }
      
      // Add keyword results and update scores
      for (final result in keywordResults) {
        if (combinedResults.containsKey(result.productId)) {
          // Combine scores (weighted average)
          final existing = combinedResults[result.productId]!;
          final combinedScore = (existing.score * 0.7) + (result.score * 0.3);
          combinedResults[result.productId] = ProductSearchResult(
            productId: result.productId,
            productName: result.productName,
            category: result.category,
            similarity: existing.similarity,
            score: combinedScore,
            attributes: result.attributes,
            explanation: 'Hybrid search combining semantic and keyword matching',
          );
        } else {
          combinedResults[result.productId] = result;
        }
      }
      
      // Sort by combined score and return top results
      final sortedResults = combinedResults.values.toList()
        ..sort((a, b) => b.score.compareTo(a.score));
      
      return sortedResults.take(maxResults).toList();
    } catch (e) {
      LoggingService.error('Failed to perform hybrid search: $e');
      return [];
    }
  }

  static Future<List<ProductSearchResult>> _performPersonalizedSearch(
    List<double> queryEmbedding,
    String? userId,
    int maxResults,
    List<String>? categories,
    Map<String, dynamic>? filters,
  ) async {
    try {
      // Get semantic search results
      final semanticResults = await _performSemanticSearch(
        queryEmbedding,
        maxResults * 2,
        categories,
        filters,
      );
      
      if (userId == null || !_userEmbeddings.containsKey(userId)) {
        return semanticResults.take(maxResults).toList();
      }
      
      // Get user embedding
      final userEmbedding = _userEmbeddings[userId]!;
      
      // Re-rank based on user preferences
      final personalizedResults = semanticResults.map((result) {
        double personalizedScore = result.score;
        
        // Boost score based on user category preferences
        if (userEmbedding.categoryPreferences.containsKey(result.category)) {
          final categoryBoost = userEmbedding.categoryPreferences[result.category]!;
          personalizedScore *= (1 + categoryBoost);
        }
        
        // Boost score based on user brand preferences
        final brand = result.attributes['brand'] as String? ?? 'Unknown';
        if (userEmbedding.brandPreferences.containsKey(brand)) {
          final brandBoost = userEmbedding.brandPreferences[brand]!;
          personalizedScore *= (1 + brandBoost);
        }
        
        return ProductSearchResult(
          productId: result.productId,
          productName: result.productName,
          category: result.category,
          similarity: result.similarity,
          score: personalizedScore,
          attributes: result.attributes,
          explanation: 'Personalized based on your preferences and search history',
        );
      }).toList();
      
      // Sort by personalized score
      personalizedResults.sort((a, b) => b.score.compareTo(a.score));
      
      return personalizedResults.take(maxResults).toList();
    } catch (e) {
      LoggingService.error('Failed to perform personalized search: $e');
      return [];
    }
  }

  static Future<List<ProductSearchResult>> _performKeywordSearch(
    String query,
    int maxResults,
  ) async {
    try {
      // Mock keyword search
      await Future.delayed(Duration(milliseconds: 100));
      
      final queryWords = query.toLowerCase().split(' ');
      final results = <ProductSearchResult>[];
      
      for (final entry in _productEmbeddings.entries) {
        final product = entry.value;
        double score = 0;
        
        // Calculate keyword match score
        for (final word in queryWords) {
          if (product.productName.toLowerCase().contains(word)) {
            score += 1.0;
          }
          if (product.category.toLowerCase().contains(word)) {
            score += 0.5;
          }
          final brand = product.attributes['brand'] as String? ?? '';
          if (brand.toLowerCase().contains(word)) {
            score += 0.8;
          }
          final features = product.attributes['features'] as List<String>? ?? [];
          for (final feature in features) {
            if (feature.toLowerCase().contains(word)) {
              score += 0.3;
            }
          }
        }
        
        if (score > 0) {
          results.add(ProductSearchResult(
            productId: product.productId,
            productName: product.productName,
            category: product.category,
            similarity: score / queryWords.length,
            score: score / queryWords.length,
            attributes: product.attributes,
            explanation: 'Keyword matching: ${score.toStringAsFixed(1)} matches',
          ));
        }
      }
      
      // Sort by score and return top results
      results.sort((a, b) => b.score.compareTo(a.score));
      return results.take(maxResults).toList();
    } catch (e) {
      LoggingService.error('Failed to perform keyword search: $e');
      return [];
    }
  }

  static double _calculateCosineSimilarity(List<double> a, List<double> b) {
    if (a.length != b.length) return 0.0;
    
    double dotProduct = 0.0;
    double normA = 0.0;
    double normB = 0.0;
    
    for (int i = 0; i < a.length; i++) {
      dotProduct += a[i] * b[i];
      normA += a[i] * a[i];
      normB += b[i] * b[i];
    }
    
    if (normA == 0 || normB == 0) return 0.0;
    
    return dotProduct / (sqrt(normA) * sqrt(normB));
  }

  static bool _passesFilters(ProductEmbedding product, Map<String, dynamic>? filters) {
    if (filters == null || filters.isEmpty) return true;
    
    // Brand filter
    if (filters.containsKey('brand')) {
      final brand = product.attributes['brand'] as String? ?? '';
      if (brand != filters['brand']) return false;
    }
    
    // Price range filter
    if (filters.containsKey('price_range')) {
      final priceRange = product.attributes['price_range'] as String? ?? '';
      if (priceRange != filters['price_range']) return false;
    }
    
    // Rating filter
    if (filters.containsKey('min_rating')) {
      final rating = product.attributes['rating'] as double? ?? 0.0;
      if (rating < filters['min_rating']) return false;
    }
    
    return true;
  }

  static String _generateExplanation(String query, ProductEmbedding product, double similarity) {
    final explanations = [
      'High semantic similarity to your query',
      'Matches your search intent well',
      'Relevant to your search terms',
      'Similar to what you\'re looking for',
    ];
    
    return explanations[Random().nextInt(explanations.length)];
  }

  // User embedding management
  static Future<void> _updateUserEmbedding(String userId, List<double> queryEmbedding) async {
    try {
      UserEmbedding userEmbedding;
      
      if (_userEmbeddings.containsKey(userId)) {
        userEmbedding = _userEmbeddings[userId]!;
        
        // Update embedding with exponential moving average
        final alpha = 0.1; // Learning rate
        for (int i = 0; i < queryEmbedding.length; i++) {
          userEmbedding.embedding[i] = (1 - alpha) * userEmbedding.embedding[i] + alpha * queryEmbedding[i];
        }
        
        userEmbedding.lastUpdated = DateTime.now();
      } else {
        userEmbedding = UserEmbedding(
          userId: userId,
          embedding: List.from(queryEmbedding),
          categoryPreferences: {},
          brandPreferences: {},
          searchHistory: [],
          lastUpdated: DateTime.now(),
        );
        
        _userEmbeddings[userId] = userEmbedding;
      }
      
      // Update preferences based on recent searches
      await _updateUserPreferences(userId);
      
      // Save user embeddings
      await _saveUserEmbeddings();
    } catch (e) {
      LoggingService.error('Failed to update user embedding: $e');
    }
  }

  static Future<void> _updateUserPreferences(String userId) async {
    try {
      final userEmbedding = _userEmbeddings[userId];
      if (userEmbedding == null) return;
      
      // Get recent search history
      final recentSearches = _searchHistory
          .where((s) => s.userId == userId)
          .toList()
          ..sort((a, b) => b.timestamp.compareTo(a.timestamp))
          ..take(20);
      
      // Update category preferences
      final categoryCounts = <String, int>{};
      for (final search in recentSearches) {
        for (final result in search.results) {
          categoryCounts[result.category] = (categoryCounts[result.category] ?? 0) + 1;
        }
      }
      
      final totalSearches = recentSearches.length;
      userEmbedding.categoryPreferences.clear();
      
      for (final entry in categoryCounts.entries) {
        userEmbedding.categoryPreferences[entry.key] = entry.value / totalSearches;
      }
      
      // Update brand preferences
      final brandCounts = <String, int>{};
      for (final search in recentSearches) {
        for (final result in search.results) {
          final brand = result.attributes['brand'] as String? ?? 'Unknown';
          brandCounts[brand] = (brandCounts[brand] ?? 0) + 1;
        }
      }
      
      userEmbedding.brandPreferences.clear();
      
      for (final entry in brandCounts.entries) {
        userEmbedding.brandPreferences[entry.key] = entry.value / totalSearches;
      }
    } catch (e) {
      LoggingService.error('Failed to update user preferences: $e');
    }
  }

  static Future<void> _saveUserEmbeddings() async {
    try {
      final data = _userEmbeddings.map((key, value) => MapEntry(key, value.toJson()));
      await CacheService.cacheData('user_embeddings', json.encode(data), ttlHours: 24);
    } catch (e) {
      LoggingService.error('Failed to save user embeddings: $e');
    }
  }

  // Search history management
  static Future<void> _recordSearchQuery(
    String query,
    String? userId,
    SearchType searchType,
    int resultsCount,
  ) async {
    try {
      final searchQuery = SearchQuery(
        id: _generateSearchId(),
        query: query,
        userId: userId,
        searchType: searchType,
        resultsCount: resultsCount,
        timestamp: DateTime.now(),
      );
      
      _searchHistory.add(searchQuery);
      
      // Keep only last 1000 searches
      if (_searchHistory.length > 1000) {
        _searchHistory.removeAt(0);
      }
      
      // Save search history
      await _saveSearchHistory();
    } catch (e) {
      LoggingService.error('Failed to record search query: $e');
    }
  }

  static Future<void> _loadSearchHistory() async {
    try {
      final cachedData = await CacheService.getCachedData(_cacheKey);
      if (cachedData != null) {
        final historyData = json.decode(cachedData);
        _searchHistory.clear();
        _searchHistory.addAll(
          (historyData as List).map((item) => SearchQuery.fromJson(item)),
        );
      }
    } catch (e) {
      LoggingService.error('Failed to load search history: $e');
    }
  }

  static Future<void> _saveSearchHistory() async {
    try {
      final data = json.encode(_searchHistory.map((s) => s.toJson()).toList());
      await CacheService.cacheData(_cacheKey, data, ttlHours: 24);
    } catch (e) {
      LoggingService.error('Failed to save search history: $e');
    }
  }

  // Analytics and insights
  static Future<SearchAnalytics> getAnalytics({
    String? userId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      var searches = List<SearchQuery>.from(_searchHistory);
      
      if (userId != null) {
        searches = searches.where((s) => s.userId == userId).toList();
      }
      
      if (startDate != null) {
        searches = searches.where((s) => s.timestamp.isAfter(startDate)).toList();
      }
      
      if (endDate != null) {
        searches = searches.where((s) => s.timestamp.isBefore(endDate)).toList();
      }
      
      final searchTypeStats = <SearchType, int>{};
      final dailySearchCounts = <DateTime, int>{};
      
      for (final search in searches) {
        searchTypeStats[search.searchType] = (searchTypeStats[search.searchType] ?? 0) + 1;
        
        final day = DateTime(search.timestamp.year, search.timestamp.month, search.timestamp.day);
        dailySearchCounts[day] = (dailySearchCounts[day] ?? 0) + 1;
      }
      
      return SearchAnalytics(
        totalSearches: searches.length,
        searchTypeStats: searchTypeStats,
        dailySearchCounts: dailySearchCounts,
        averageResultsPerSearch: searches.isEmpty ? 0.0 : 
            searches.map((s) => s.resultsCount).reduce((a, b) => a + b) / searches.length,
        startDate: startDate ?? DateTime.now().subtract(Duration(days: 30)),
        endDate: endDate ?? DateTime.now(),
      );
    } catch (e) {
      LoggingService.error('Failed to get search analytics: $e');
      return SearchAnalytics(
        totalSearches: 0,
        searchTypeStats: {},
        dailySearchCounts: {},
        averageResultsPerSearch: 0.0,
        startDate: DateTime.now(),
        endDate: DateTime.now(),
      );
    }
  }

  // Event handling
  static void _emitEvent(NeuralSearchEvent event) {
    _eventController?.add(event);
  }

  static String _generateSearchId() {
    return 'search_${DateTime.now().millisecondsSinceEpoch}';
  }

  // Getters
  static bool get isInitialized => _isInitialized;
  static bool get isModelLoaded => _isModelLoaded;
  static Map<String, ProductEmbedding> get productEmbeddings => Map.from(_productEmbeddings);
  static Map<String, UserEmbedding> get userEmbeddings => Map.from(_userEmbeddings);
  static List<SearchQuery> get searchHistory => List.from(_searchHistory);
  static Stream<NeuralSearchEvent> get events => _eventController?.stream ?? Stream.empty();
}

// Data models
class ProductEmbedding {
  final String productId;
  final String productName;
  final List<double> embedding;
  final String category;
  final Map<String, dynamic> attributes;
  final DateTime lastUpdated;

  ProductEmbedding({
    required this.productId,
    required this.productName,
    required this.embedding,
    required this.category,
    required this.attributes,
    required this.lastUpdated,
  });

  Map<String, dynamic> toJson() {
    return {
      'product_id': productId,
      'product_name': productName,
      'embedding': embedding,
      'category': category,
      'attributes': attributes,
      'last_updated': lastUpdated.toIso8601String(),
    };
  }

  factory ProductEmbedding.fromJson(Map<String, dynamic> json) {
    return ProductEmbedding(
      productId: json['product_id'],
      productName: json['product_name'],
      embedding: List<double>.from(json['embedding']),
      category: json['category'],
      attributes: Map<String, dynamic>.from(json['attributes']),
      lastUpdated: DateTime.parse(json['last_updated']),
    );
  }
}

class UserEmbedding {
  final String userId;
  List<double> embedding;
  final Map<String, double> categoryPreferences;
  final Map<String, double> brandPreferences;
  final List<String> searchHistory;
  final DateTime lastUpdated;

  UserEmbedding({
    required this.userId,
    required this.embedding,
    required this.categoryPreferences,
    required this.brandPreferences,
    required this.searchHistory,
    required this.lastUpdated,
  });

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'embedding': embedding,
      'category_preferences': categoryPreferences,
      'brand_preferences': brandPreferences,
      'search_history': searchHistory,
      'last_updated': lastUpdated.toIso8601String(),
    };
  }

  factory UserEmbedding.fromJson(Map<String, dynamic> json) {
    return UserEmbedding(
      userId: json['user_id'],
      embedding: List<double>.from(json['embedding']),
      categoryPreferences: Map<String, double>.from(json['category_preferences']),
      brandPreferences: Map<String, double>.from(json['brand_preferences']),
      searchHistory: List<String>.from(json['search_history']),
      lastUpdated: DateTime.parse(json['last_updated']),
    );
  }
}

class SearchQuery {
  final String id;
  final String query;
  final String? userId;
  final SearchType searchType;
  final int resultsCount;
  final DateTime timestamp;
  final List<ProductSearchResult>? results;

  SearchQuery({
    required this.id,
    required this.query,
    this.userId,
    required this.searchType,
    required this.resultsCount,
    required this.timestamp,
    this.results,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'query': query,
      'user_id': userId,
      'search_type': searchType.name,
      'results_count': resultsCount,
      'timestamp': timestamp.toIso8601String(),
      'results': results?.map((r) => r.toJson()).toList(),
    };
  }

  factory SearchQuery.fromJson(Map<String, dynamic> json) {
    return SearchQuery(
      id: json['id'],
      query: json['query'],
      userId: json['user_id'],
      searchType: SearchType.values.firstWhere(
        (t) => t.name == json['search_type'],
        orElse: () => SearchType.semantic,
      ),
      resultsCount: json['results_count'],
      timestamp: DateTime.parse(json['timestamp']),
      results: json['results'] != null
          ? (json['results'] as List).map((r) => ProductSearchResult.fromJson(r)).toList()
          : null,
    );
  }
}

class ProductSearchResult {
  final String productId;
  final String productName;
  final String category;
  final double similarity;
  final double score;
  final Map<String, dynamic> attributes;
  final String explanation;

  ProductSearchResult({
    required this.productId,
    required this.productName,
    required this.category,
    required this.similarity,
    required this.score,
    required this.attributes,
    required this.explanation,
  });

  Map<String, dynamic> toJson() {
    return {
      'product_id': productId,
      'product_name': productName,
      'category': category,
      'similarity': similarity,
      'score': score,
      'attributes': attributes,
      'explanation': explanation,
    };
  }

  factory ProductSearchResult.fromJson(Map<String, dynamic> json) {
    return ProductSearchResult(
      productId: json['product_id'],
      productName: json['product_name'],
      category: json['category'],
      similarity: json['similarity'].toDouble(),
      score: json['score'].toDouble(),
      attributes: Map<String, dynamic>.from(json['attributes']),
      explanation: json['explanation'],
    );
  }
}

class SearchAnalytics {
  final int totalSearches;
  final Map<SearchType, int> searchTypeStats;
  final Map<DateTime, int> dailySearchCounts;
  final double averageResultsPerSearch;
  final DateTime startDate;
  final DateTime endDate;

  SearchAnalytics({
    required this.totalSearches,
    required this.searchTypeStats,
    required this.dailySearchCounts,
    required this.averageResultsPerSearch,
    required this.startDate,
    required this.endDate,
  });
}

class NeuralSearchEvent {
  final NeuralSearchEventType type;
  final Map<String, dynamic> data;
  final DateTime timestamp;

  NeuralSearchEvent({
    required this.type,
    required this.data,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();
}

class NeuralSearchResult {
  final bool success;
  final String? query;
  final List<ProductSearchResult>? results;
  final SearchType? searchType;
  final Duration? processingTime;
  final String? error;

  NeuralSearchResult({
    required this.success,
    this.query,
    this.results,
    this.searchType,
    this.processingTime,
    this.error,
  });
}

enum SearchType {
  semantic,
  hybrid,
  personalized,
}

enum NeuralSearchEventType {
  searchCompleted,
  modelLoaded,
  embeddingsUpdated,
  error,
}
