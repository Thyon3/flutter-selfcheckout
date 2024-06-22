import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

enum ErrorType {
  network,
  authentication,
  database,
  validation,
  unknown,
}

class AppError {
  final String message;
  final ErrorType type;
  final String? details;
  final DateTime timestamp;

  AppError({
    required this.message,
    required this.type,
    this.details,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  factory AppError.fromException(Exception exception) {
    if (exception is FirebaseAuthException) {
      return AppError(
        message: _getFirebaseAuthErrorMessage(exception.code),
        type: ErrorType.authentication,
        details: exception.toString(),
      );
    } else if (exception is FirebaseException) {
      return AppError(
        message: _getFirebaseErrorMessage(exception.code),
        type: ErrorType.database,
        details: exception.toString(),
      );
    } else {
      return AppError(
        message: exception.toString(),
        type: ErrorType.unknown,
        details: exception.toString(),
      );
    }
  }

  static String _getFirebaseAuthErrorMessage(String code) {
    switch (code) {
      case 'user-not-found':
        return 'No user found for this email.';
      case 'wrong-password':
        return 'Wrong password provided.';
      case 'email-already-in-use':
        return 'An account already exists for this email.';
      case 'weak-password':
        return 'The password provided is too weak.';
      case 'invalid-email':
        return 'The email address is not valid.';
      case 'user-disabled':
        return 'This user account has been disabled.';
      case 'too-many-requests':
        return 'Too many requests. Try again later.';
      default:
        return 'Authentication failed. Please try again.';
    }
  }

  static String _getFirebaseErrorMessage(String code) {
    switch (code) {
      case 'permission-denied':
        return 'You don\'t have permission to perform this action.';
      case 'not-found':
        return 'The requested document was not found.';
      case 'unavailable':
        return 'The service is currently unavailable. Please try again later.';
      case 'deadline-exceeded':
        return 'The request took too long to complete.';
      default:
        return 'Database operation failed. Please try again.';
    }
  }
}

class ErrorHandler {
  static void handleError(BuildContext context, AppError error) {
    _showErrorDialog(context, error);
    _logError(error);
  }

  static void handleException(BuildContext context, Exception exception) {
    final error = AppError.fromException(exception);
    handleError(context, error);
  }

  static void _showErrorDialog(BuildContext context, AppError error) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              _getErrorIcon(error.type),
              color: _getErrorColor(error.type),
            ),
            SizedBox(width: 8),
            Text('Error'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(error.message),
            if (error.details != null) ...[
              SizedBox(height: 8),
              Text(
                'Details: ${error.details}',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('OK'),
          ),
        ],
      ),
    );
  }

  static IconData _getErrorIcon(ErrorType type) {
    switch (type) {
      case ErrorType.network:
        return Icons.wifi_off;
      case ErrorType.authentication:
        return Icons.lock;
      case ErrorType.database:
        return Icons.storage;
      case ErrorType.validation:
        return Icons.error_outline;
      default:
        return Icons.error;
    }
  }

  static Color _getErrorColor(ErrorType type) {
    switch (type) {
      case ErrorType.network:
        return Colors.orange;
      case ErrorType.authentication:
        return Colors.red;
      case ErrorType.database:
        return Colors.purple;
      case ErrorType.validation:
        return Colors.amber;
      default:
        return Colors.grey;
    }
  }

  static void _logError(AppError error) {
    print('ERROR [${error.timestamp.toIso8601String()}]: ${error.message}');
    if (error.details != null) {
      print('Details: ${error.details}');
    }
  }
}
