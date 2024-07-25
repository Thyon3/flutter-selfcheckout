import 'dart:math';
import 'package:selfcheckoutapp/models/item.dart';
import 'package:selfcheckoutapp/utils/app_utils.dart';
import 'package:selfcheckoutapp/services/logging_service.dart';

class RecommendationService {
  static final Map<String, UserPreferences> _userPreferences = {};
  static final Map<String, List<Item>> _itemCache = {};
  static final Map<String, List<Recommendation>> _recommendationCache = {};
  
  // ML-based recommendation algorithms
  static Future<List<Recommendation>> getRecommendations(
    String userId, 
    RecommendationType type,
    {int limit = 10}
  ) async {
    try {
      LoggingService.info('Getting recommendations for user: $userId, type: $type');
      
      // Check cache first
      final cacheKey = '${userId}_${type.name}_$limit';
      if (_recommendationCache.containsKey(cacheKey)) {
        final cached = _recommendationCache[cacheKey]!;
        if (_isCacheValid(cached.first.timestamp)) {
          return cached.take(limit).toList();
        }
      }
      
      List<Recommendation> recommendations;
      
      switch (type) {
        case RecommendationType.collaborative:
          recommendations = await _getCollaborativeRecommendations(userId, limit);
          break;
        case RecommendationType.contentBased:
          recommendations = await _getContentBasedRecommendations(userId, limit);
          break;
        case RecommendationType.hybrid:
          recommendations = await _getHybridRecommendations(userId, limit);
          break;
        case RecommendationType.trending:
          recommendations = await _getTrendingRecommendations(limit);
          break;
        case RecommendationType.personalized:
          recommendations = await _getPersonalizedRecommendations(userId, limit);
          break;
        case RecommendationType.similar:
          recommendations = await _getSimilarItemsRecommendations(userId, limit);
          break;
      }
      
      // Cache recommendations
      _recommendationCache[cacheKey] = recommendations;
      
      LoggingService.info('Generated ${recommendations.length} recommendations');
      return recommendations.take(limit).toList();
    } catch (e) {
      LoggingService.error('Failed to get recommendations: $e');
      return [];
    }
  }

  static Future<List<Recommendation>> _getCollaborativeRecommendations(
    String userId, 
    int limit
  ) async {
    // Find similar users based on purchase history and preferences
    final similarUsers = await _findSimilarUsers(userId);
    final recommendations = <Recommendation>[];
    
    // Get items purchased by similar users but not by current user
    final userPurchasedItems = await _getUserPurchasedItems(userId);
    
    for (final similarUser in similarUsers) {
      final theirItems = await _getUserPurchasedItems(similarUser.userId);
      
      for (final item in theirItems) {
        if (!userPurchasedItems.any((purchased) => purchased.barcode == item.barcode)) {
          final score = _calculateCollaborativeScore(userId, similarUser.userId, item);
          
          recommendations.add(Recommendation(
            item: item,
            score: score,
            reason: 'Users like you also bought this',
            algorithm: 'collaborative_filtering',
            timestamp: DateTime.now(),
          ));
        }
      }
    }
    
    // Sort by score and return top recommendations
    recommendations.sort((a, b) => b.score.compareTo(a.score));
    return recommendations.take(limit).toList();
  }

  static Future<List<Recommendation>> _getContentBasedRecommendations(
    String userId, 
    int limit
  ) async {
    final userPreferences = await _getUserPreferences(userId);
    final userHistory = await _getUserPurchaseHistory(userId);
    final allItems = await _getAllItems();
    
    final recommendations = <Recommendation>[];
    
    for (final item in allItems) {
      // Skip if user already purchased this item
      if (userHistory.any((history) => history.item.barcode == item.barcode)) {
        continue;
      }
      
      // Calculate content-based score based on user preferences
      final score = _calculateContentBasedScore(item, userPreferences, userHistory);
      
      if (score > 0.3) { // Minimum threshold
        recommendations.add(Recommendation(
          item: item,
          score: score,
          reason: 'Based on your preferences and purchase history',
          algorithm: 'content_based_filtering',
          timestamp: DateTime.now(),
        ));
      }
    }
    
    recommendations.sort((a, b) => b.score.compareTo(a.score));
    return recommendations.take(limit).toList();
  }

  static Future<List<Recommendation>> _getHybridRecommendations(
    String userId, 
    int limit
  ) async {
    // Combine collaborative and content-based recommendations
    final collaborative = await _getCollaborativeRecommendations(userId, limit * 2);
    final contentBased = await _getContentBasedRecommendations(userId, limit * 2);
    
    // Merge and weight the recommendations
    final merged = <String, Recommendation>{};
    
    // Add collaborative recommendations (weight: 0.6)
    for (final rec in collaborative) {
      final key = rec.item.barcode;
      if (merged.containsKey(key)) {
        merged[key] = merged[key]!.copyWith(score: merged[key]!.score * 0.6 + rec.score * 0.6);
      } else {
        merged[key] = rec.copyWith(score: rec.score * 0.6);
      }
    }
    
    // Add content-based recommendations (weight: 0.4)
    for (final rec in contentBased) {
      final key = rec.item.barcode;
      if (merged.containsKey(key)) {
        merged[key] = merged[key]!.copyWith(score: merged[key]!.score + rec.score * 0.4);
      } else {
        merged[key] = rec.copyWith(score: rec.score * 0.4);
      }
    }
    
    final recommendations = merged.values.toList();
    recommendations.sort((a, b) => b.score.compareTo(a.score));
    
    return recommendations.take(limit).toList();
  }

  static Future<List<Recommendation>> _getTrendingRecommendations(int limit) async {
    final allItems = await _getAllItems();
    final recentPurchases = await _getRecentPurchases();
    
    // Calculate trending score based on recent purchase frequency
    final trendingScores = <String, double>{};
    
    for (final purchase in recentPurchases) {
      final barcode = purchase.item.barcode;
      trendingScores[barcode] = (trendingScores[barcode] ?? 0) + 1.0;
    }
    
    // Apply time decay (more recent purchases have higher weight)
    final now = DateTime.now();
    for (final purchase in recentPurchases) {
      final daysSincePurchase = now.difference(purchase.timestamp).inDays;
      final decayFactor = math.exp(-daysSincePurchase / 30.0); // 30-day half-life
      final barcode = purchase.item.barcode;
      trendingScores[barcode] = (trendingScores[barcode] ?? 0) * decayFactor;
    }
    
    final recommendations = <Recommendation>[];
    
    for (final item in allItems) {
      final score = trendingScores[item.barcode] ?? 0.0;
      if (score > 0) {
        recommendations.add(Recommendation(
          item: item,
          score: score,
          reason: 'Trending item',
          algorithm: 'trending_analysis',
          timestamp: DateTime.now(),
        ));
      }
    }
    
    recommendations.sort((a, b) => b.score.compareTo(a.score));
    return recommendations.take(limit).toList();
  }

  static Future<List<Recommendation>> _getPersonalizedRecommendations(
    String userId, 
    int limit
  ) async {
    final userPreferences = await _getUserPreferences(userId);
    final userHistory = await _getUserPurchaseHistory(userId);
    final userProfile = _buildUserProfile(userPreferences, userHistory);
    
    final allItems = await _getAllItems();
    final recommendations = <Recommendation>[];
    
    for (final item in allItems) {
      // Skip if user already purchased this item
      if (userHistory.any((history) => history.item.barcode == item.barcode)) {
        continue;
      }
      
      // Calculate personalized score using multiple factors
      final score = _calculatePersonalizedScore(item, userProfile);
      
      if (score > 0.2) {
        recommendations.add(Recommendation(
          item: item,
          score: score,
          reason: 'Personalized for you',
          algorithm: 'personalized_ml',
          timestamp: DateTime.now(),
        ));
      }
    }
    
    recommendations.sort((a, b) => b.score.compareTo(a.score));
    return recommendations.take(limit).toList();
  }

  static Future<List<Recommendation>> _getSimilarItemsRecommendations(
    String userId, 
    int limit
  ) async {
    final userHistory = await _getUserPurchaseHistory(userId);
    final allItems = await _getAllItems();
    
    if (userHistory.isEmpty) {
      return [];
    }
    
    // Get the most recently purchased item
    final lastPurchase = userHistory.last.item;
    final recommendations = <Recommendation>[];
    
    // Find similar items based on category, price range, and attributes
    for (final item in allItems) {
      if (item.barcode == lastPurchase.barcode) {
        continue; // Skip the same item
      }
      
      final similarity = _calculateItemSimilarity(lastPurchase, item);
      
      if (similarity > 0.5) {
        recommendations.add(Recommendation(
          item: item,
          score: similarity,
          reason: 'Similar to ${lastPurchase.name}',
          algorithm: 'item_similarity',
          timestamp: DateTime.now(),
        ));
      }
    }
    
    recommendations.sort((a, b) => b.score.compareTo(a.score));
    return recommendations.take(limit).toList();
  }

  // User preference management
  static Future<void> updateUserPreferences(
    String userId, 
    UserPreferences preferences
  ) async {
    _userPreferences[userId] = preferences;
    LoggingService.info('Updated preferences for user: $userId');
  }

  static Future<UserPreferences> getUserPreferences(String userId) async {
    return _userPreferences[userId] ?? UserPreferences.defaultPreferences();
  }

  static Future<void> recordUserAction(
    String userId, 
    UserAction action
  ) async {
    final preferences = await getUserPreferences(userId);
    
    // Update preferences based on user action
    switch (action.type) {
      case ActionType.purchase:
        preferences.increaseCategoryPreference(action.item.category ?? 'unknown');
        preferences.updatePriceRange(action.item.price);
        break;
      case ActionType.view:
        preferences.increaseCategoryViewCount(action.item.category ?? 'unknown');
        break;
      case ActionType.addToCart:
        preferences.increaseCategoryCartCount(action.item.category ?? 'unknown');
        break;
      case ActionType.search:
        preferences.addSearchTerm(action.searchTerm ?? '');
        break;
      case ActionType.favorite:
        preferences.addToFavorites(action.item.barcode);
        break;
    }
    
    await updateUserPreferences(userId, preferences);
  }

  // Helper methods
  static Future<List<SimilarUser>> _findSimilarUsers(String userId) async {
    final currentUserPrefs = await getUserPreferences(userId);
    final allUsers = _userPreferences.keys.toList();
    
    final similarUsers = <SimilarUser>[];
    
    for (final otherUserId in allUsers) {
      if (otherUserId == userId) continue;
      
      final otherUserPrefs = _userPreferences[otherUserId]!;
      final similarity = _calculateUserSimilarity(currentUserPrefs, otherUserPrefs);
      
      if (similarity > 0.3) {
        similarUsers.add(SimilarUser(
          userId: otherUserId,
          similarity: similarity,
        ));
      }
    }
    
    similarUsers.sort((a, b) => b.similarity.compareTo(a.similarity));
    return similarUsers.take(10).toList();
  }

  static double _calculateUserSimilarity(
    UserPreferences user1, 
    UserPreferences user2
  ) {
    // Calculate cosine similarity between user preference vectors
    final categories1 = user1.categoryPreferences;
    final categories2 = user2.categoryPreferences;
    
    double dotProduct = 0.0;
    double norm1 = 0.0;
    double norm2 = 0.0;
    
    final allCategories = {...categories1.keys, ...categories2.keys};
    
    for (final category in allCategories) {
      final val1 = categories1[category] ?? 0.0;
      final val2 = categories2[category] ?? 0.0;
      
      dotProduct += val1 * val2;
      norm1 += val1 * val1;
      norm2 += val2 * val2;
    }
    
    if (norm1 == 0 || norm2 == 0) return 0.0;
    
    return dotProduct / (math.sqrt(norm1) * math.sqrt(norm2));
  }

  static double _calculateCollaborativeScore(
    String userId, 
    String similarUserId, 
    Item item
  ) async {
    final similarity = _calculateUserSimilarity(
      await getUserPreferences(userId),
      _userPreferences[similarUserId]!,
    );
    
    final itemPopularity = await _getItemPopularity(item.barcode);
    
    return similarity * 0.7 + itemPopularity * 0.3;
  }

  static double _calculateContentBasedScore(
    Item item, 
    UserPreferences preferences, 
    List<PurchaseHistory> userHistory
  ) {
    double score = 0.0;
    
    // Category preference score
    final categoryPref = preferences.categoryPreferences[item.category ?? 'unknown'] ?? 0.0;
    score += categoryPref * 0.4;
    
    // Price range preference score
    final priceScore = _calculatePriceScore(item.price, preferences.preferredPriceRange);
    score += priceScore * 0.3;
    
    // Purchase history similarity score
    final historyScore = _calculateHistorySimilarity(item, userHistory);
    score += historyScore * 0.2;
    
    // Brand preference score (if available)
    final brandScore = _calculateBrandScore(item, preferences);
    score += brandScore * 0.1;
    
    return score.clamp(0.0, 1.0);
  }

  static double _calculatePersonalizedScore(Item item, UserProfile profile) {
    double score = 0.0;
    
    // Category affinity
    score += profile.categoryAffinity[item.category ?? 'unknown'] ?? 0.0 * 0.3;
    
    // Price sensitivity
    score += _calculatePriceScore(item.price, profile.priceRange) * 0.2;
    
    // Purchase frequency patterns
    score += profile.frequencyScore * 0.2;
    
    // Seasonal preferences
    score += _calculateSeasonalScore(item, profile.seasonalPreferences) * 0.1;
    
    // Brand loyalty
    score += profile.brandLoyalty[item.name] ?? 0.0 * 0.1;
    
    // Quality preference
    score += profile.qualityPreference * 0.1;
    
    return score.clamp(0.0, 1.0);
  }

  static double _calculateItemSimilarity(Item item1, Item item2) {
    double similarity = 0.0;
    
    // Category similarity
    if (item1.category == item2.category) {
      similarity += 0.4;
    }
    
    // Price similarity
    final priceDiff = (item1.price - item2.price).abs();
    final avgPrice = (item1.price + item2.price) / 2;
    final priceSimilarity = 1.0 - (priceDiff / avgPrice);
    similarity += priceSimilarity * 0.3;
    
    // Name similarity (simple text similarity)
    final nameSimilarity = _calculateTextSimilarity(item1.name, item2.name);
    similarity += nameSimilarity * 0.2;
    
    // Weight similarity
    if (item1.weight != null && item2.weight != null) {
      final weightDiff = (item1.weight! - item2.weight!).abs();
      final avgWeight = (item1.weight! + item2.weight!) / 2;
      final weightSimilarity = 1.0 - (weightDiff / avgWeight);
      similarity += weightSimilarity * 0.1;
    }
    
    return similarity.clamp(0.0, 1.0);
  }

  static double _calculateTextSimilarity(String text1, String text2) {
    final words1 = text1.toLowerCase().split(' ');
    final words2 = text2.toLowerCase().split(' ');
    
    final intersection = words1.where((word) => words2.contains(word)).length;
    final union = {...words1, ...words2}.length;
    
    return union > 0 ? intersection / union : 0.0;
  }

  static double _calculatePriceScore(double price, PriceRange preferredRange) {
    if (price >= preferredRange.min && price <= preferredRange.max) {
      return 1.0;
    }
    
    final distance = math.min(
      (price - preferredRange.max).abs(),
      (price - preferredRange.min).abs(),
    );
    
    return math.max(0.0, 1.0 - (distance / preferredRange.max));
  }

  static double _calculateHistorySimilarity(
    Item item, 
    List<PurchaseHistory> history
  ) {
    if (history.isEmpty) return 0.0;
    
    double similarity = 0.0;
    
    for (final purchase in history) {
      similarity += _calculateItemSimilarity(item, purchase.item);
    }
    
    return similarity / history.length;
  }

  static double _calculateBrandScore(Item item, UserPreferences preferences) {
    // Simple brand scoring based on item name
    final brandScore = preferences.brandPreferences[item.name.split(' ').first] ?? 0.0;
    return brandScore;
  }

  static double _calculateSeasonalScore(
    Item item, 
    Map<String, double> seasonalPrefs
  ) {
    final currentMonth = DateTime.now().month;
    final season = _getSeason(currentMonth);
    return seasonalPrefs[season] ?? 0.0;
  }

  static String _getSeason(int month) {
    if (month >= 3 && month <= 5) return 'spring';
    if (month >= 6 && month <= 8) return 'summer';
    if (month >= 9 && month <= 11) return 'fall';
    return 'winter';
  }

  static UserProfile _buildUserProfile(
    UserPreferences preferences, 
    List<PurchaseHistory> history
  ) {
    return UserProfile(
      categoryAffinity: preferences.categoryPreferences,
      priceRange: preferences.preferredPriceRange,
      frequencyScore: _calculateFrequencyScore(history),
      seasonalPreferences: _calculateSeasonalPreferences(history),
      brandLoyalty: _calculateBrandLoyalty(history),
      qualityPreference: preferences.qualityPreference,
    );
  }

  static double _calculateFrequencyScore(List<PurchaseHistory> history) {
    if (history.isEmpty) return 0.0;
    
    final now = DateTime.now();
    final recentPurchases = history.where(
      (purchase) => now.difference(purchase.timestamp).inDays <= 30
    ).length;
    
    return math.min(1.0, recentPurchases / 10.0);
  }

  static Map<String, double> _calculateSeasonalPreferences(List<PurchaseHistory> history) {
    final seasonalPrefs = <String, double>{};
    
    for (final purchase in history) {
      final month = purchase.timestamp.month;
      final season = _getSeason(month);
      seasonalPrefs[season] = (seasonalPrefs[season] ?? 0.0) + 1.0;
    }
    
    // Normalize
    final total = seasonalPrefs.values.fold(0.0, (sum, val) => sum + val);
    if (total > 0) {
      seasonalPrefs.forEach((key, value) {
        seasonalPrefs[key] = value / total;
      });
    }
    
    return seasonalPrefs;
  }

  static Map<String, double> _calculateBrandLoyalty(List<PurchaseHistory> history) {
    final brandLoyalty = <String, double>{};
    
    for (final purchase in history) {
      final brand = purchase.item.name.split(' ').first;
      brandLoyalty[brand] = (brandLoyalty[brand] ?? 0.0) + 1.0;
    }
    
    // Normalize
    final total = brandLoyalty.values.fold(0.0, (sum, val) => sum + val);
    if (total > 0) {
      brandLoyalty.forEach((key, value) {
        brandLoyalty[key] = value / total;
      });
    }
    
    return brandLoyalty;
  }

  // Data access methods (mock implementations)
  static Future<List<Item>> _getAllItems() async {
    // Mock implementation - would fetch from database
    return [
      Item(name: 'Fresh Tomatoes', barcode: '1234567890', price: 45.50, weight: 500, quantity: 1, photo: '', category: 'Vegetables'),
      Item(name: 'Organic Apples', barcode: '2345678901', price: 120.00, weight: 1000, quantity: 1, photo: '', category: 'Fruits'),
      Item(name: 'Whole Milk', barcode: '3456789012', price: 85.00, weight: 1000, quantity: 1, photo: '', category: 'Dairy'),
      Item(name: 'Bread', barcode: '4567890123', price: 65.00, weight: 400, quantity: 1, photo: '', category: 'Bakery'),
      Item(name: 'Eggs', barcode: '5678901234', price: 180.00, weight: 600, quantity: 1, photo: '', category: 'Dairy'),
    ];
  }

  static Future<List<Item>> _getUserPurchasedItems(String userId) async {
    // Mock implementation
    return [];
  }

  static Future<List<PurchaseHistory>> _getUserPurchaseHistory(String userId) async {
    // Mock implementation
    return [];
  }

  static Future<UserPreferences> _getUserPreferences(String userId) async {
    return _userPreferences[userId] ?? UserPreferences.defaultPreferences();
  }

  static Future<double> _getItemPopularity(String barcode) async {
    // Mock implementation
    return 0.5;
  }

  static Future<List<RecentPurchase>> _getRecentPurchases() async {
    // Mock implementation
    return [];
  }

  static bool _isCacheValid(DateTime timestamp) {
    return DateTime.now().difference(timestamp).inMinutes < 30;
  }
}

// Data models
class Recommendation {
  final Item item;
  final double score;
  final String reason;
  final String algorithm;
  final DateTime timestamp;

  Recommendation({
    required this.item,
    required this.score,
    required this.reason,
    required this.algorithm,
    required this.timestamp,
  });

  Recommendation copyWith({
    Item? item,
    double? score,
    String? reason,
    String? algorithm,
    DateTime? timestamp,
  }) {
    return Recommendation(
      item: item ?? this.item,
      score: score ?? this.score,
      reason: reason ?? this.reason,
      algorithm: algorithm ?? this.algorithm,
      timestamp: timestamp ?? this.timestamp,
    );
  }
}

class UserPreferences {
  final Map<String, double> categoryPreferences;
  final Map<String, double> categoryViewCounts;
  final Map<String, double> categoryCartCounts;
  final Map<String, double> brandPreferences;
  final PriceRange preferredPriceRange;
  final List<String> favoriteItems;
  final List<String> searchHistory;
  final double qualityPreference;
  final DateTime lastUpdated;

  UserPreferences({
    required this.categoryPreferences,
    required this.categoryViewCounts,
    required this.categoryCartCounts,
    required this.brandPreferences,
    required this.preferredPriceRange,
    required this.favoriteItems,
    required this.searchHistory,
    required this.qualityPreference,
    required this.lastUpdated,
  });

  factory UserPreferences.defaultPreferences() {
    return UserPreferences(
      categoryPreferences: {},
      categoryViewCounts: {},
      categoryCartCounts: {},
      brandPreferences: {},
      preferredPriceRange: PriceRange(min: 0, max: 1000),
      favoriteItems: [],
      searchHistory: [],
      qualityPreference: 0.5,
      lastUpdated: DateTime.now(),
    );
  }

  void increaseCategoryPreference(String category) {
    categoryPreferences[category] = (categoryPreferences[category] ?? 0.0) + 1.0;
  }

  void increaseCategoryViewCount(String category) {
    categoryViewCounts[category] = (categoryViewCounts[category] ?? 0.0) + 1.0;
  }

  void increaseCategoryCartCount(String category) {
    categoryCartCounts[category] = (categoryCartCounts[category] ?? 0.0) + 1.0;
  }

  void updatePriceRange(double price) {
    if (price < preferredPriceRange.min) {
      preferredPriceRange.min = price;
    }
    if (price > preferredPriceRange.max) {
      preferredPriceRange.max = price;
    }
  }

  void addToFavorites(String itemBarcode) {
    if (!favoriteItems.contains(itemBarcode)) {
      favoriteItems.add(itemBarcode);
    }
  }

  void addSearchTerm(String term) {
    searchHistory.remove(term);
    searchHistory.insert(0, term);
    if (searchHistory.length > 50) {
      searchHistory.removeLast();
    }
  }
}

class PriceRange {
  double min;
  double max;

  PriceRange({required this.min, required this.max});
}

class SimilarUser {
  final String userId;
  final double similarity;

  SimilarUser({required this.userId, required this.similarity});
}

class PurchaseHistory {
  final Item item;
  final DateTime timestamp;
  final double price;

  PurchaseHistory({required this.item, required this.timestamp, required this.price});
}

class RecentPurchase {
  final Item item;
  final DateTime timestamp;

  RecentPurchase({required this.item, required this.timestamp});
}

class UserProfile {
  final Map<String, double> categoryAffinity;
  final PriceRange priceRange;
  final double frequencyScore;
  final Map<String, double> seasonalPreferences;
  final Map<String, double> brandLoyalty;
  final double qualityPreference;

  UserProfile({
    required this.categoryAffinity,
    required this.priceRange,
    required this.frequencyScore,
    required this.seasonalPreferences,
    required this.brandLoyalty,
    required this.qualityPreference,
  });
}

class UserAction {
  final ActionType type;
  final Item? item;
  final String? searchTerm;
  final DateTime timestamp;

  UserAction({
    required this.type,
    this.item,
    this.searchTerm,
    required this.timestamp,
  });
}

enum RecommendationType {
  collaborative,
  contentBased,
  hybrid,
  trending,
  personalized,
  similar,
}

enum ActionType {
  purchase,
  view,
  addToCart,
  search,
  favorite,
}
