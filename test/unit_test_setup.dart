import 'package:flutter_test/flutter_test.dart';
import 'package:selfcheckoutapp/services/firebase_services.dart';
import 'package:selfcheckoutapp/services/error_handler.dart';
import 'package:selfcheckoutapp/models/item.dart';
import 'package:selfcheckoutapp/models/todo.dart';

// Test utilities and helpers
class TestUtils {
  static Item createTestItem({
    String name = 'Test Item',
    String barcode = '123456789',
    double price = 10.99,
    double weight = 1.5,
    int quantity = 1,
    String photo = 'test.jpg',
  }) {
    return Item(
      name: name,
      barcode: barcode,
      price: price,
      weight: weight,
      quantity: quantity,
      photo: photo,
    );
  }

  static ToDo createTestTodo({
    String title = 'Test Todo',
    bool complete = false,
  }) {
    return ToDo(
      title: title,
      complete: complete,
    );
  }

  static AppError createTestError({
    String message = 'Test error',
    ErrorType type = ErrorType.unknown,
  }) {
    return AppError(
      message: message,
      type: type,
      details: 'Test error details',
    );
  }
}

// Mock Firebase Services for testing
class MockFirebaseServices extends FirebaseServices {
  bool _shouldFail = false;
  String _testUserId = 'test_user_123';
  String _testEmail = 'test@example.com';
  String _testUserName = 'Test User';

  void setShouldFail(bool shouldFail) {
    _shouldFail = shouldFail;
  }

  @override
  String getUserId() {
    if (_shouldFail) throw Exception('Failed to get user ID');
    return _testUserId;
  }

  @override
  String getCurrentEmail() {
    if (_shouldFail) throw Exception('Failed to get email');
    return _testEmail;
  }

  @override
  String getCurrentUserName() {
    if (_shouldFail) throw Exception('Failed to get user name');
    return _testUserName;
  }
}

// Test configuration
void main() {
  group('Test Setup Validation', () {
    test('Test utilities create valid test objects', () {
      final item = TestUtils.createTestItem();
      expect(item.name, equals('Test Item'));
      expect(item.price, equals(10.99));
      expect(item.quantity, equals(1));
    });

    test('Mock Firebase Services work correctly', () {
      final mockService = MockFirebaseServices();
      expect(mockService.getUserId(), equals('test_user_123'));
      expect(mockService.getCurrentEmail(), equals('test@example.com'));
      expect(mockService.getCurrentUserName(), equals('Test User'));
    });

    test('Mock Firebase Services handle failures', () {
      final mockService = MockFirebaseServices();
      mockService.setShouldFail(true);
      
      expect(() => mockService.getUserId(), throwsException);
      expect(() => mockService.getCurrentEmail(), throwsException);
      expect(() => mockService.getCurrentUserName(), throwsException);
    });
  });
}
