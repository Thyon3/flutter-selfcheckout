import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:selfcheckoutapp/services/logging_service.dart';
import 'package:selfcheckoutapp/services/cache_service.dart';
import 'package:selfcheckoutapp/services/security_service.dart';
import 'package:selfcheckoutapp/services/preferences_service.dart';

class GamificationService {
  static const String _achievementsKey = 'gamification_achievements';
  static const String _userStatsKey = 'gamification_user_stats';
  static const String _rewardsKey = 'gamification_rewards';
  static const String _leaderboardKey = 'gamification_leaderboard';
  static const String _challengesKey = 'gamification_challenges';
  
  static bool _isInitialized = false;
  static UserStats? _currentUserStats;
  static final List<Achievement> _availableAchievements = [];
  static final List<Reward> _availableRewards = [];
  static final List<Challenge> _activeChallenges = [];
  static final List<LeaderboardEntry> _leaderboard = [];
  static StreamController<GamificationEvent>? _eventController;

  // Gamification service initialization
  static Future<bool> initialize() async {
    try {
      if (_isInitialized) return true;
      
      LoggingService.info('Initializing gamification service');
      
      // Initialize event controller
      _eventController = StreamController<GamificationEvent>.broadcast();
      
      // Load user stats
      await _loadUserStats();
      
      // Load achievements
      await _loadAchievements();
      
      // Load rewards
      await _loadRewards();
      
      // Load challenges
      await _loadChallenges();
      
      // Load leaderboard
      await _loadLeaderboard();
      
      // Initialize default achievements if none exist
      if (_availableAchievements.isEmpty) {
        await _initializeDefaultAchievements();
      }
      
      // Initialize default rewards if none exist
      if (_availableRewards.isEmpty) {
        await _initializeDefaultRewards();
      }
      
      // Initialize default challenges if none exist
      if (_activeChallenges.isEmpty) {
        await _initializeDefaultChallenges();
      }
      
      _isInitialized = true;
      
      LoggingService.info('Gamification service initialized successfully');
      return true;
    } catch (e) {
      LoggingService.error('Failed to initialize gamification service: $e');
      return false;
    }
  }

  // User stats management
  static Future<UserStats> getUserStats() async {
    if (!_isInitialized) {
      await initialize();
    }
    
    if (_currentUserStats == null) {
      _currentUserStats = UserStats(
        userId: 'current_user',
        level: 1,
        experience: 0,
        points: 0,
        streak: 0,
        totalPurchases: 0,
        totalSpent: 0.0,
        achievementsUnlocked: [],
        rewardsRedeemed: [],
        challengesCompleted: [],
        lastActiveDate: DateTime.now(),
        createdAt: DateTime.now(),
      );
      await _saveUserStats();
    }
    
    return _currentUserStats!;
  }

  static Future<void> updateUserStats({
    int? experience,
    int? points,
    int? streak,
    int? totalPurchases,
    double? totalSpent,
  }) async {
    try {
      final stats = await getUserStats();
      
      if (experience != null) {
        stats.experience += experience;
        await _checkLevelUp(stats);
      }
      
      if (points != null) {
        stats.points += points;
      }
      
      if (streak != null) {
        stats.streak = streak;
      }
      
      if (totalPurchases != null) {
        stats.totalPurchases += totalPurchases;
      }
      
      if (totalSpent != null) {
        stats.totalSpent += totalSpent;
      }
      
      stats.lastActiveDate = DateTime.now();
      
      await _saveUserStats();
      
      // Emit stats updated event
      _emitEvent(GamificationEvent(
        type: GamificationEventType.statsUpdated,
        data: stats.toJson(),
      ));
      
      LoggingService.info('User stats updated');
    } catch (e) {
      LoggingService.error('Failed to update user stats: $e');
    }
  }

  // Achievements
  static Future<List<Achievement>> getAchievements() async {
    if (!_isInitialized) {
      await initialize();
    }
    return List.from(_availableAchievements);
  }

  static Future<Achievement?> unlockAchievement(String achievementId) async {
    try {
      final achievement = _availableAchievements.firstWhere(
        (a) => a.id == achievementId,
        orElse: () => throw Exception('Achievement not found: $achievementId'),
      );
      
      final stats = await getUserStats();
      
      if (stats.achievementsUnlocked.contains(achievementId)) {
        LoggingService.warning('Achievement already unlocked: $achievementId');
        return null;
      }
      
      // Check if requirements are met
      if (!_checkAchievementRequirements(achievement, stats)) {
        LoggingService.warning('Achievement requirements not met: $achievementId');
        return null;
      }
      
      // Unlock achievement
      stats.achievementsUnlocked.add(achievementId);
      stats.experience += achievement.experienceReward;
      stats.points += achievement.pointsReward;
      
      await _saveUserStats();
      
      // Emit achievement unlocked event
      _emitEvent(GamificationEvent(
        type: GamificationEventType.achievementUnlocked,
        data: achievement.toJson(),
      ));
      
      LoggingService.info('Achievement unlocked: $achievementId');
      return achievement;
    } catch (e) {
      LoggingService.error('Failed to unlock achievement: $e');
      return null;
    }
  }

  static Future<bool> checkAndUnlockAchievements() async {
    try {
      final stats = await getUserStats();
      bool anyUnlocked = false;
      
      for (final achievement in _availableAchievements) {
        if (!stats.achievementsUnlocked.contains(achievement.id) &&
            _checkAchievementRequirements(achievement, stats)) {
          await unlockAchievement(achievement.id);
          anyUnlocked = true;
        }
      }
      
      return anyUnlocked;
    } catch (e) {
      LoggingService.error('Failed to check and unlock achievements: $e');
      return false;
    }
  }

  static bool _checkAchievementRequirements(Achievement achievement, UserStats stats) {
    try {
      switch (achievement.type) {
        case AchievementType.firstPurchase:
          return stats.totalPurchases >= 1;
        case AchievementType.purchasesMilestone:
          final target = achievement.requirements['purchases'] as int? ?? 0;
          return stats.totalPurchases >= target;
        case AchievementType.spendingMilestone:
          final target = achievement.requirements['amount'] as double? ?? 0.0;
          return stats.totalSpent >= target;
        case AchievementType.streakMilestone:
          final target = achievement.requirements['days'] as int? ?? 0;
          return stats.streak >= target;
        case AchievementType.levelMilestone:
          final target = achievement.requirements['level'] as int? ?? 0;
          return stats.level >= target;
        case AchievementType.achievementCollector:
          final target = achievement.requirements['count'] as int? ?? 0;
          return stats.achievementsUnlocked.length >= target;
        case AchievementType.challengeMaster:
          final target = achievement.requirements['count'] as int? ?? 0;
          return stats.challengesCompleted.length >= target;
        default:
          return false;
      }
    } catch (e) {
      LoggingService.error('Failed to check achievement requirements: $e');
      return false;
    }
  }

  // Rewards
  static Future<List<Reward>> getRewards() async {
    if (!_isInitialized) {
      await initialize();
    }
    return List.from(_availableRewards);
  }

  static Future<Reward?> redeemReward(String rewardId) async {
    try {
      final reward = _availableRewards.firstWhere(
        (r) => r.id == rewardId,
        orElse: () => throw Exception('Reward not found: $rewardId'),
      );
      
      final stats = await getUserStats();
      
      if (stats.points < reward.cost) {
        LoggingService.warning('Insufficient points for reward: $rewardId');
        return null;
      }
      
      // Redeem reward
      stats.points -= reward.cost;
      stats.rewardsRedeemed.add(rewardId);
      
      await _saveUserStats();
      
      // Apply reward effect
      await _applyRewardEffect(reward);
      
      // Emit reward redeemed event
      _emitEvent(GamificationEvent(
        type: GamificationEventType.rewardRedeemed,
        data: reward.toJson(),
      ));
      
      LoggingService.info('Reward redeemed: $rewardId');
      return reward;
    } catch (e) {
      LoggingService.error('Failed to redeem reward: $e');
      return null;
    }
  }

  static Future<void> _applyRewardEffect(Reward reward) async {
    try {
      switch (reward.type) {
        case RewardType.discount:
          // Store discount in preferences for use in checkout
          await PreferencesService.setRewardDiscount(reward.value);
          break;
        case RewardType.freeItem:
          // Store free item reward
          await PreferencesService.setRewardFreeItem(reward.value);
          break;
        case RewardType.pointsBonus:
          // Add bonus points
          await updateUserStats(points: reward.value);
          break;
        case RewardType.experienceBonus:
          // Add bonus experience
          await updateUserStats(experience: reward.value);
          break;
        case RewardType.badge:
          // Add badge to user profile
          await PreferencesService.addUserBadge(reward.value);
          break;
        case RewardType.specialOffer:
          // Store special offer
          await PreferencesService.setSpecialOffer(reward.value);
          break;
      }
    } catch (e) {
      LoggingService.error('Failed to apply reward effect: $e');
    }
  }

  // Challenges
  static Future<List<Challenge>> getChallenges() async {
    if (!_isInitialized) {
      await initialize();
    }
    return List.from(_activeChallenges);
  }

  static Future<Challenge?> startChallenge(String challengeId) async {
    try {
      final challenge = _activeChallenges.firstWhere(
        (c) => c.id == challengeId,
        orElse: () => throw Exception('Challenge not found: $challengeId'),
      );
      
      if (challenge.status == ChallengeStatus.completed) {
        LoggingService.warning('Challenge already completed: $challengeId');
        return null;
      }
      
      if (challenge.status == ChallengeStatus.inProgress) {
        LoggingService.warning('Challenge already in progress: $challengeId');
        return challenge;
      }
      
      // Start challenge
      challenge.status = ChallengeStatus.inProgress;
      challenge.startedAt = DateTime.now();
      
      await _saveChallenges();
      
      // Emit challenge started event
      _emitEvent(GamificationEvent(
        type: GamificationEventType.challengeStarted,
        data: challenge.toJson(),
      ));
      
      LoggingService.info('Challenge started: $challengeId');
      return challenge;
    } catch (e) {
      LoggingService.error('Failed to start challenge: $e');
      return null;
    }
  }

  static Future<Challenge?> completeChallenge(String challengeId) async {
    try {
      final challenge = _activeChallenges.firstWhere(
        (c) => c.id == challengeId,
        orElse: () => throw Exception('Challenge not found: $challengeId'),
      );
      
      if (challenge.status != ChallengeStatus.inProgress) {
        LoggingService.warning('Challenge not in progress: $challengeId');
        return null;
      }
      
      // Complete challenge
      challenge.status = ChallengeStatus.completed;
      challenge.completedAt = DateTime.now();
      
      final stats = await getUserStats();
      stats.challengesCompleted.add(challengeId);
      stats.experience += challenge.experienceReward;
      stats.points += challenge.pointsReward;
      
      await _saveUserStats();
      await _saveChallenges();
      
      // Emit challenge completed event
      _emitEvent(GamificationEvent(
        type: GamificationEventType.challengeCompleted,
        data: challenge.toJson(),
      ));
      
      LoggingService.info('Challenge completed: $challengeId');
      return challenge;
    } catch (e) {
      LoggingService.error('Failed to complete challenge: $e');
      return null;
    }
  }

  static Future<void> updateChallengeProgress(String challengeId, int progress) async {
    try {
      final challenge = _activeChallenges.firstWhere(
        (c) => c.id == challengeId,
      );
      
      challenge.currentProgress = progress;
      
      // Check if challenge is completed
      if (progress >= challenge.targetProgress) {
        await completeChallenge(challengeId);
      } else {
        await _saveChallenges();
      }
    } catch (e) {
      LoggingService.error('Failed to update challenge progress: $e');
    }
  }

  // Leaderboard
  static Future<List<LeaderboardEntry>> getLeaderboard({int limit = 50}) async {
    if (!_isInitialized) {
      await initialize();
    }
    
    final sortedLeaderboard = List<LeaderboardEntry>.from(_leaderboard)
      ..sort((a, b) => b.points.compareTo(a.points));
    
    return sortedLeaderboard.take(limit).toList();
  }

  static Future<LeaderboardEntry?> getUserLeaderboardEntry() async {
    try {
      final stats = await getUserStats();
      final entry = LeaderboardEntry(
        userId: stats.userId,
        username: 'User', // Would get from user profile
        level: stats.level,
        points: stats.points,
        achievements: stats.achievementsUnlocked.length,
        lastUpdated: DateTime.now(),
      );
      
      return entry;
    } catch (e) {
      LoggingService.error('Failed to get user leaderboard entry: $e');
      return null;
    }
  }

  static Future<void> updateLeaderboard() async {
    try {
      final userEntry = await getUserLeaderboardEntry();
      if (userEntry != null) {
        // Remove existing entry for this user
        _leaderboard.removeWhere((entry) => entry.userId == userEntry.userId);
        
        // Add updated entry
        _leaderboard.add(userEntry);
        
        // Keep only top 100 entries
        _leaderboard.sort((a, b) => b.points.compareTo(a.points));
        if (_leaderboard.length > 100) {
          _leaderboard.removeRange(100, _leaderboard.length);
        }
        
        await _saveLeaderboard();
      }
    } catch (e) {
      LoggingService.error('Failed to update leaderboard: $e');
    }
  }

  // Shopping actions
  static Future<void> onPurchaseCompleted({
    required double amount,
    required List<String> productIds,
    int itemCount = 1,
  }) async {
    try {
      // Update user stats
      await updateUserStats(
        totalPurchases: itemCount,
        totalSpent: amount,
        points: (amount * 10).round(), // 1 point per 0.1 spent
        experience: 10 * itemCount, // 10 XP per item
      );
      
      // Update streak
      await _updateStreak();
      
      // Check achievements
      await checkAndUnlockAchievements();
      
      // Update challenges progress
      await _updateChallengesProgress('purchase', itemCount);
      
      // Update leaderboard
      await updateLeaderboard();
      
      LoggingService.info('Purchase gamification actions completed');
    } catch (e) {
      LoggingService.error('Failed to process purchase gamification: $e');
    }
  }

  static Future<void> onProductViewed(String productId) async {
    try {
      // Update challenges progress
      await _updateChallengesProgress('view', 1);
      
      // Add small experience for browsing
      await updateUserStats(experience: 1);
    } catch (e) {
      LoggingService.error('Failed to process product view gamification: $e');
    }
  }

  static Future<void> onProductAddedToCart(String productId) async {
    try {
      // Update challenges progress
      await _updateChallengesProgress('cart', 1);
      
      // Add experience for cart activity
      await updateUserStats(experience: 2);
    } catch (e) {
      LoggingService.error('Failed to process cart addition gamification: $e');
    }
  }

  // Utility methods
  static Future<void> _checkLevelUp(UserStats stats) async {
    try {
      final requiredExp = _getExperienceForLevel(stats.level + 1);
      
      if (stats.experience >= requiredExp) {
        stats.level++;
        stats.experience -= requiredExp;
        
        // Emit level up event
        _emitEvent(GamificationEvent(
          type: GamificationEventType.levelUp,
          data: {
            'new_level': stats.level,
            'experience': stats.experience,
          },
        ));
        
        // Recursively check for multiple level ups
        await _checkLevelUp(stats);
      }
    } catch (e) {
      LoggingService.error('Failed to check level up: $e');
    }
  }

  static int _getExperienceForLevel(int level) {
    // Exponential growth: 100 * (1.5 ^ (level - 1))
    return (100 * pow(1.5, level - 1)).round();
  }

  static Future<void> _updateStreak() async {
    try {
      final stats = await getUserStats();
      final now = DateTime.now();
      final lastActive = stats.lastActiveDate;
      
      if (lastActive != null) {
        final daysDiff = now.difference(lastActive).inDays;
        
        if (daysDiff == 1) {
          // Consecutive day
          await updateUserStats(streak: stats.streak + 1);
        } else if (daysDiff > 1) {
          // Streak broken
          await updateUserStats(streak: 1);
        }
        // If daysDiff == 0, same day, no change
      }
    } catch (e) {
      LoggingService.error('Failed to update streak: $e');
    }
  }

  static Future<void> _updateChallengesProgress(String action, int count) async {
    try {
      for (final challenge in _activeChallenges) {
        if (challenge.status == ChallengeStatus.inProgress &&
            challenge.type == action) {
          final newProgress = challenge.currentProgress + count;
          await updateChallengeProgress(challenge.id, newProgress);
        }
      }
    } catch (e) {
      LoggingService.error('Failed to update challenges progress: $e');
    }
  }

  static void _emitEvent(GamificationEvent event) {
    _eventController?.add(event);
  }

  // Data persistence
  static Future<void> _saveUserStats() async {
    try {
      if (_currentUserStats != null) {
        final data = json.encode(_currentUserStats!.toJson());
        await SecurityService.secureStore(_userStatsKey, data);
      }
    } catch (e) {
      LoggingService.error('Failed to save user stats: $e');
    }
  }

  static Future<void> _loadUserStats() async {
    try {
      final data = await SecurityService.secureRetrieve(_userStatsKey);
      if (data != null) {
        final statsData = json.decode(data);
        _currentUserStats = UserStats.fromJson(statsData);
      }
    } catch (e) {
      LoggingService.error('Failed to load user stats: $e');
    }
  }

  static Future<void> _saveAchievements() async {
    try {
      final data = json.encode(_availableAchievements.map((a) => a.toJson()).toList());
      await CacheService.cacheData(_achievementsKey, data, ttlHours: 24);
    } catch (e) {
      LoggingService.error('Failed to save achievements: $e');
    }
  }

  static Future<void> _loadAchievements() async {
    try {
      final data = await CacheService.getCachedData(_achievementsKey);
      if (data != null) {
        final achievementsData = json.decode(data);
        _availableAchievements.clear();
        _availableAchievements.addAll(
          (achievementsData as List).map((a) => Achievement.fromJson(a)),
        );
      }
    } catch (e) {
      LoggingService.error('Failed to load achievements: $e');
    }
  }

  static Future<void> _saveRewards() async {
    try {
      final data = json.encode(_availableRewards.map((r) => r.toJson()).toList());
      await CacheService.cacheData(_rewardsKey, data, ttlHours: 24);
    } catch (e) {
      LoggingService.error('Failed to save rewards: $e');
    }
  }

  static Future<void> _loadRewards() async {
    try {
      final data = await CacheService.getCachedData(_rewardsKey);
      if (data != null) {
        final rewardsData = json.decode(data);
        _availableRewards.clear();
        _availableRewards.addAll(
          (rewardsData as List).map((r) => Reward.fromJson(r)),
        );
      }
    } catch (e) {
      LoggingService.error('Failed to load rewards: $e');
    }
  }

  static Future<void> _saveChallenges() async {
    try {
      final data = json.encode(_activeChallenges.map((c) => c.toJson()).toList());
      await CacheService.cacheData(_challengesKey, data, ttlHours: 24);
    } catch (e) {
      LoggingService.error('Failed to save challenges: $e');
    }
  }

  static Future<void> _loadChallenges() async {
    try {
      final data = await CacheService.getCachedData(_challengesKey);
      if (data != null) {
        final challengesData = json.decode(data);
        _activeChallenges.clear();
        _activeChallenges.addAll(
          (challengesData as List).map((c) => Challenge.fromJson(c)),
        );
      }
    } catch (e) {
      LoggingService.error('Failed to load challenges: $e');
    }
  }

  static Future<void> _saveLeaderboard() async {
    try {
      final data = json.encode(_leaderboard.map((e) => e.toJson()).toList());
      await CacheService.cacheData(_leaderboardKey, data, ttlHours: 1);
    } catch (e) {
      LoggingService.error('Failed to save leaderboard: $e');
    }
  }

  static Future<void> _loadLeaderboard() async {
    try {
      final data = await CacheService.getCachedData(_leaderboardKey);
      if (data != null) {
        final leaderboardData = json.decode(data);
        _leaderboard.clear();
        _leaderboard.addAll(
          (leaderboardData as List).map((e) => LeaderboardEntry.fromJson(e)),
        );
      }
    } catch (e) {
      LoggingService.error('Failed to load leaderboard: $e');
    }
  }

  // Default data initialization
  static Future<void> _initializeDefaultAchievements() async {
    _availableAchievements.addAll([
      Achievement(
        id: 'first_purchase',
        name: 'First Purchase',
        description: 'Complete your first purchase',
        type: AchievementType.firstPurchase,
        requirements: {},
        experienceReward: 50,
        pointsReward: 100,
        badge: '🛍️',
        isHidden: false,
      ),
      Achievement(
        id: 'purchases_10',
        name: 'Regular Shopper',
        description: 'Complete 10 purchases',
        type: AchievementType.purchasesMilestone,
        requirements: {'purchases': 10},
        experienceReward: 200,
        pointsReward: 500,
        badge: '⭐',
        isHidden: false,
      ),
      Achievement(
        id: 'spend_1000',
        name: 'Big Spender',
        description: 'Spend Rs 1000 total',
        type: AchievementType.spendingMilestone,
        requirements: {'amount': 1000.0},
        experienceReward: 300,
        pointsReward: 1000,
        badge: '💰',
        isHidden: false,
      ),
      Achievement(
        id: 'streak_7',
        name: 'Weekly Warrior',
        description: 'Maintain a 7-day streak',
        type: AchievementType.streakMilestone,
        requirements: {'days': 7},
        experienceReward: 150,
        pointsReward: 300,
        badge: '🔥',
        isHidden: false,
      ),
      Achievement(
        id: 'level_10',
        name: 'Experienced Shopper',
        description: 'Reach level 10',
        type: AchievementType.levelMilestone,
        requirements: {'level': 10},
        experienceReward: 500,
        pointsReward: 2000,
        badge: '🏆',
        isHidden: false,
      ),
    ]);
    
    await _saveAchievements();
  }

  static Future<void> _initializeDefaultRewards() async {
    _availableRewards.addAll([
      Reward(
        id: 'discount_10',
        name: '10% Discount',
        description: 'Get 10% off your next purchase',
        type: RewardType.discount,
        cost: 500,
        value: 10,
        isAvailable: true,
        expiresAt: DateTime.now().add(Duration(days: 30)),
      ),
      Reward(
        id: 'free_delivery',
        name: 'Free Delivery',
        description: 'Get free delivery on your next order',
        type: RewardType.specialOffer,
        cost: 300,
        value: 'free_delivery',
        isAvailable: true,
        expiresAt: DateTime.now().add(Duration(days: 7)),
      ),
      Reward(
        id: 'points_100',
        name: '100 Bonus Points',
        description: 'Get 100 bonus points',
        type: RewardType.pointsBonus,
        cost: 1000,
        value: 100,
        isAvailable: true,
        expiresAt: null,
      ),
      Reward(
        id: 'experience_50',
        name: '50 Bonus XP',
        description: 'Get 50 bonus experience points',
        type: RewardType.experienceBonus,
        cost: 800,
        value: 50,
        isAvailable: true,
        expiresAt: null,
      ),
    ]);
    
    await _saveRewards();
  }

  static Future<void> _initializeDefaultChallenges() async {
    _activeChallenges.addAll([
      Challenge(
        id: 'daily_shopper',
        name: 'Daily Shopper',
        description: 'Make a purchase today',
        type: 'purchase',
        targetProgress: 1,
        currentProgress: 0,
        experienceReward: 25,
        pointsReward: 50,
        status: ChallengeStatus.available,
        expiresAt: DateTime.now().add(Duration(days: 1)),
      ),
      Challenge(
        id: 'weekly_warrior',
        name: 'Weekly Warrior',
        description: 'Make 5 purchases this week',
        type: 'purchase',
        targetProgress: 5,
        currentProgress: 0,
        experienceReward: 100,
        pointsReward: 250,
        status: ChallengeStatus.available,
        expiresAt: DateTime.now().add(Duration(days: 7)),
      ),
      Challenge(
        id: 'browser',
        name: 'Product Browser',
        description: 'View 20 products',
        type: 'view',
        targetProgress: 20,
        currentProgress: 0,
        experienceReward: 30,
        pointsReward: 75,
        status: ChallengeStatus.available,
        expiresAt: DateTime.now().add(Duration(days: 3)),
      ),
    ]);
    
    await _saveChallenges();
  }

  // Getters
  static bool get isInitialized => _isInitialized;
  static Stream<GamificationEvent> get events => _eventController?.stream ?? Stream.empty();
}

// Data models
class UserStats {
  final String userId;
  int level;
  int experience;
  int points;
  int streak;
  int totalPurchases;
  double totalSpent;
  List<String> achievementsUnlocked;
  List<String> rewardsRedeemed;
  List<String> challengesCompleted;
  DateTime lastActiveDate;
  DateTime createdAt;

  UserStats({
    required this.userId,
    required this.level,
    required this.experience,
    required this.points,
    required this.streak,
    required this.totalPurchases,
    required this.totalSpent,
    required this.achievementsUnlocked,
    required this.rewardsRedeemed,
    required this.challengesCompleted,
    required this.lastActiveDate,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'level': level,
      'experience': experience,
      'points': points,
      'streak': streak,
      'total_purchases': totalPurchases,
      'total_spent': totalSpent,
      'achievements_unlocked': achievementsUnlocked,
      'rewards_redeemed': rewardsRedeemed,
      'challenges_completed': challengesCompleted,
      'last_active_date': lastActiveDate.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory UserStats.fromJson(Map<String, dynamic> json) {
    return UserStats(
      userId: json['user_id'],
      level: json['level'],
      experience: json['experience'],
      points: json['points'],
      streak: json['streak'],
      totalPurchases: json['total_purchases'],
      totalSpent: json['total_spent'].toDouble(),
      achievementsUnlocked: List<String>.from(json['achievements_unlocked']),
      rewardsRedeemed: List<String>.from(json['rewards_redeemed']),
      challengesCompleted: List<String>.from(json['challenges_completed']),
      lastActiveDate: DateTime.parse(json['last_active_date']),
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}

class Achievement {
  final String id;
  final String name;
  final String description;
  final AchievementType type;
  final Map<String, dynamic> requirements;
  final int experienceReward;
  final int pointsReward;
  final String badge;
  final bool isHidden;

  Achievement({
    required this.id,
    required this.name,
    required this.description,
    required this.type,
    required this.requirements,
    required this.experienceReward,
    required this.pointsReward,
    required this.badge,
    required this.isHidden,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'type': type.name,
      'requirements': requirements,
      'experience_reward': experienceReward,
      'points_reward': pointsReward,
      'badge': badge,
      'is_hidden': isHidden,
    };
  }

  factory Achievement.fromJson(Map<String, dynamic> json) {
    return Achievement(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      type: AchievementType.values.firstWhere(
        (t) => t.name == json['type'],
        orElse: () => AchievementType.firstPurchase,
      ),
      requirements: Map<String, dynamic>.from(json['requirements']),
      experienceReward: json['experience_reward'],
      pointsReward: json['points_reward'],
      badge: json['badge'],
      isHidden: json['is_hidden'],
    );
  }
}

class Reward {
  final String id;
  final String name;
  final String description;
  final RewardType type;
  final int cost;
  final dynamic value;
  final bool isAvailable;
  final DateTime? expiresAt;

  Reward({
    required this.id,
    required this.name,
    required this.description,
    required this.type,
    required this.cost,
    required this.value,
    required this.isAvailable,
    this.expiresAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'type': type.name,
      'cost': cost,
      'value': value,
      'is_available': isAvailable,
      'expires_at': expiresAt?.toIso8601String(),
    };
  }

  factory Reward.fromJson(Map<String, dynamic> json) {
    return Reward(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      type: RewardType.values.firstWhere(
        (t) => t.name == json['type'],
        orElse: () => RewardType.discount,
      ),
      cost: json['cost'],
      value: json['value'],
      isAvailable: json['is_available'],
      expiresAt: json['expires_at'] != null ? DateTime.parse(json['expires_at']) : null,
    );
  }
}

class Challenge {
  final String id;
  final String name;
  final String description;
  final String type;
  final int targetProgress;
  int currentProgress;
  final int experienceReward;
  final int pointsReward;
  ChallengeStatus status;
  final DateTime? startedAt;
  final DateTime? completedAt;
  final DateTime? expiresAt;

  Challenge({
    required this.id,
    required this.name,
    required this.description,
    required this.type,
    required this.targetProgress,
    required this.currentProgress,
    required this.experienceReward,
    required this.pointsReward,
    required this.status,
    this.startedAt,
    this.completedAt,
    this.expiresAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'type': type,
      'target_progress': targetProgress,
      'current_progress': currentProgress,
      'experience_reward': experienceReward,
      'points_reward': pointsReward,
      'status': status.name,
      'started_at': startedAt?.toIso8601String(),
      'completed_at': completedAt?.toIso8601String(),
      'expires_at': expiresAt?.toIso8601String(),
    };
  }

  factory Challenge.fromJson(Map<String, dynamic> json) {
    return Challenge(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      type: json['type'],
      targetProgress: json['target_progress'],
      currentProgress: json['current_progress'],
      experienceReward: json['experience_reward'],
      pointsReward: json['points_reward'],
      status: ChallengeStatus.values.firstWhere(
        (s) => s.name == json['status'],
        orElse: () => ChallengeStatus.available,
      ),
      startedAt: json['started_at'] != null ? DateTime.parse(json['started_at']) : null,
      completedAt: json['completed_at'] != null ? DateTime.parse(json['completed_at']) : null,
      expiresAt: json['expires_at'] != null ? DateTime.parse(json['expires_at']) : null,
    );
  }
}

class LeaderboardEntry {
  final String userId;
  final String username;
  final int level;
  final int points;
  final int achievements;
  final DateTime lastUpdated;

  LeaderboardEntry({
    required this.userId,
    required this.username,
    required this.level,
    required this.points,
    required this.achievements,
    required this.lastUpdated,
  });

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'username': username,
      'level': level,
      'points': points,
      'achievements': achievements,
      'last_updated': lastUpdated.toIso8601String(),
    };
  }

  factory LeaderboardEntry.fromJson(Map<String, dynamic> json) {
    return LeaderboardEntry(
      userId: json['user_id'],
      username: json['username'],
      level: json['level'],
      points: json['points'],
      achievements: json['achievements'],
      lastUpdated: DateTime.parse(json['last_updated']),
    );
  }
}

class GamificationEvent {
  final GamificationEventType type;
  final Map<String, dynamic> data;
  final DateTime timestamp;

  GamificationEvent({
    required this.type,
    required this.data,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();
}

enum AchievementType {
  firstPurchase,
  purchasesMilestone,
  spendingMilestone,
  streakMilestone,
  levelMilestone,
  achievementCollector,
  challengeMaster,
}

enum RewardType {
  discount,
  freeItem,
  pointsBonus,
  experienceBonus,
  badge,
  specialOffer,
}

enum ChallengeStatus {
  available,
  inProgress,
  completed,
  expired,
}

enum GamificationEventType {
  statsUpdated,
  levelUp,
  achievementUnlocked,
  rewardRedeemed,
  challengeStarted,
  challengeCompleted,
}
