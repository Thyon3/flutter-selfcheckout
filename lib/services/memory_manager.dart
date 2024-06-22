import 'dart:async';
import 'package:flutter/material.dart';

class MemoryManager {
  static final MemoryManager _instance = MemoryManager._internal();
  factory MemoryManager() => _instance;
  MemoryManager._internal();

  final Map<String, StreamSubscription> _subscriptions = {};
  final Map<String, Timer> _timers = {};
  final Map<String, PageController> _pageControllers = {};
  final Map<String, ScrollController> _scrollControllers = {};
  final Map<String, TextEditingController> _textControllers = {};

  // Stream management
  void addStreamSubscription(String key, StreamSubscription subscription) {
    _subscriptions[key]?.cancel();
    _subscriptions[key] = subscription;
  }

  void cancelStreamSubscription(String key) {
    _subscriptions[key]?.cancel();
    _subscriptions.remove(key);
  }

  void cancelAllStreamSubscriptions() {
    for (final subscription in _subscriptions.values) {
      subscription.cancel();
    }
    _subscriptions.clear();
  }

  // Timer management
  void addTimer(String key, Timer timer) {
    _timers[key]?.cancel();
    _timers[key] = timer;
  }

  void cancelTimer(String key) {
    _timers[key]?.cancel();
    _timers.remove(key);
  }

  void cancelAllTimers() {
    for (final timer in _timers.values) {
      timer.cancel();
    }
    _timers.clear();
  }

  // Controller management
  void addPageController(String key, PageController controller) {
    _pageControllers[key]?.dispose();
    _pageControllers[key] = controller;
  }

  void disposePageController(String key) {
    _pageControllers[key]?.dispose();
    _pageControllers.remove(key);
  }

  void addScrollController(String key, ScrollController controller) {
    _scrollControllers[key]?.dispose();
    _scrollControllers[key] = controller;
  }

  void disposeScrollController(String key) {
    _scrollControllers[key]?.dispose();
    _scrollControllers.remove(key);
  }

  void addTextController(String key, TextEditingController controller) {
    _textControllers[key]?.dispose();
    _textControllers[key] = controller;
  }

  void disposeTextController(String key) {
    _textControllers[key]?.dispose();
    _textControllers.remove(key);
  }

  // Cleanup all resources
  void disposeAll() {
    cancelAllStreamSubscriptions();
    cancelAllTimers();
    
    for (final controller in _pageControllers.values) {
      controller.dispose();
    }
    _pageControllers.clear();
    
    for (final controller in _scrollControllers.values) {
      controller.dispose();
    }
    _scrollControllers.clear();
    
    for (final controller in _textControllers.values) {
      controller.dispose();
    }
    _textControllers.clear();
  }
}
