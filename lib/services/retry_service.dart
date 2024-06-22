import 'dart:async';
import 'package:flutter/material.dart';

typedef RetryFunction<T> = Future<T> Function();

class RetryConfig {
  final int maxAttempts;
  final Duration initialDelay;
  final double backoffMultiplier;
  final Duration maxDelay;

  const RetryConfig({
    this.maxAttempts = 3,
    this.initialDelay = const Duration(seconds: 1),
    this.backoffMultiplier = 2.0,
    this.maxDelay = const Duration(seconds: 30),
  });
}

class RetryService {
  static Future<T> retryWithBackoff<T>(
    RetryFunction<T> function, {
    RetryConfig config = const RetryConfig(),
    bool Function(dynamic error)? shouldRetry,
    void Function(int attempt, dynamic error)? onRetry,
  }) async {
    dynamic lastError;
    
    for (int attempt = 1; attempt <= config.maxAttempts; attempt++) {
      try {
        return await function();
      } catch (error) {
        lastError = error;
        
        // Check if we should retry
        if (shouldRetry != null && !shouldRetry(error)) {
          rethrow;
        }
        
        // If this is the last attempt, throw the error
        if (attempt == config.maxAttempts) {
          rethrow;
        }
        
        // Notify about retry
        onRetry?.call(attempt, error);
        
        // Calculate delay and wait
        final delay = _calculateDelay(attempt, config);
        await Future.delayed(delay);
      }
    }
    
    throw lastError;
  }

  static Duration _calculateDelay(int attempt, RetryConfig config) {
    final delay = config.initialDelay * 
        (config.backoffMultiplier * (attempt - 1));
    return delay > config.maxDelay ? config.maxDelay : delay;
  }

  static Future<T> retryWithDialog<T>(
    BuildContext context,
    RetryFunction<T> function, {
    RetryConfig config = const RetryConfig(),
    String operationName = 'operation',
  }) async {
    Completer<T> completer = Completer<T>();
    int attemptCount = 0;
    
    void showRetryDialog(String errorMessage) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          title: Text('Operation Failed'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('$operationName failed.'),
              SizedBox(height: 8),
              Text('Error: $errorMessage'),
              SizedBox(height: 16),
              if (attemptCount < config.maxAttempts)
                Text('Attempts remaining: ${config.maxAttempts - attemptCount}')
              else
                Text('Maximum retry attempts reached.'),
            ],
          ),
          actions: [
            if (attemptCount < config.maxAttempts)
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  _performRetry();
                },
                child: Text('Retry'),
              ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                if (!completer.isCompleted) {
                  completer.completeError(Exception('Operation cancelled by user'));
                }
              },
              child: Text('Cancel'),
            ),
          ],
        ),
      );
    }

    Future<void> _performRetry() async {
      attemptCount++;
      
      try {
        final result = await function();
        if (!completer.isCompleted) {
          completer.complete(result);
        }
      } catch (error) {
        showRetryDialog(error.toString());
      }
    }

    // Start the first attempt
    await _performRetry();
    
    return completer.future;
  }

  static bool shouldRetryNetworkError(dynamic error) {
    // Don't retry on authentication errors or validation errors
    final errorString = error.toString().toLowerCase();
    return !errorString.contains('authentication') &&
           !errorString.contains('permission') &&
           !errorString.contains('validation') &&
           !errorString.contains('not found');
  }

  static bool shouldRetryFirebaseError(dynamic error) {
    // Don't retry on permission denied or not found errors
    final errorString = error.toString().toLowerCase();
    return !errorString.contains('permission-denied') &&
           !errorString.contains('not-found') &&
           !errorString.contains('already-exists');
  }
}
