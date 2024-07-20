import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:selfcheckoutapp/constants.dart';

class AppUtils {
  static String formatPrice(double price) {
    return 'Rs ${price.toStringAsFixed(2)}';
  }

  static String formatDate(DateTime date) {
    return DateFormat('dd MMM yyyy').format(date);
  }

  static String formatDateTime(DateTime dateTime) {
    return DateFormat('dd MMM yyyy, hh:mm a').format(dateTime);
  }

  static String formatTime(TimeOfDay time) {
    final now = DateTime.now();
    final dateTime = DateTime(now.year, now.month, now.day, time.hour, time.minute);
    return DateFormat('hh:mm a').format(dateTime);
  }

  static String getRelativeTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 0) {
      return '${difference.inDays} day${difference.inDays == 1 ? '' : 's'} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hour${difference.inHours == 1 ? '' : 's'} ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minute${difference.inMinutes == 1 ? '' : 's'} ago';
    } else {
      return 'Just now';
    }
  }

  static String truncateText(String text, int maxLength) {
    if (text.length <= maxLength) return text;
    return '${text.substring(0, maxLength)}...';
  }

  static String capitalizeFirst(String text) {
    if (text.isEmpty) return text;
    return '${text[0].toUpperCase()}${text.substring(1).toLowerCase()}';
  }

  static String capitalizeWords(String text) {
    return text.split(' ').map((word) => capitalizeFirst(word)).join(' ');
  }

  static bool isValidEmail(String email) {
    final emailRegex = RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
    return emailRegex.hasMatch(email);
  }

  static bool isValidPhone(String phone) {
    final phoneRegex = RegExp(r'^[0-9]{10}$');
    return phoneRegex.hasMatch(phone.replaceAll(RegExp(r'[^\d]'), ''));
  }

  static bool isValidPassword(String password) {
    return password.length >= Constants.minPasswordLength &&
           password.contains(RegExp(r'[A-Z]')) &&
           password.contains(RegExp(r'[a-z]')) &&
           password.contains(RegExp(r'[0-9]'));
  }

  static String generateId() {
    return DateTime.now().millisecondsSinceEpoch.toString();
  }

  static String generateUniqueId() {
    final timestamp = DateTime.now().millisecondsSinceEpoch.toString();
    final random = DateTime.now().microsecond.toString();
    return '$timestamp$random';
  }

  static Color getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
      case 'success':
        return Colors.green;
      case 'pending':
      case 'processing':
        return Colors.orange;
      case 'failed':
      case 'error':
      case 'cancelled':
        return Colors.red;
      case 'delivered':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  static IconData getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
      case 'success':
        return Icons.check_circle;
      case 'pending':
      case 'processing':
        return Icons.hourglass_empty;
      case 'failed':
      case 'error':
      case 'cancelled':
        return Icons.error;
      case 'delivered':
        return Icons.local_shipping;
      default:
        return Icons.info;
    }
  }

  static String getPaymentMethodIcon(String paymentMethod) {
    switch (paymentMethod.toLowerCase()) {
      case 'credit card':
      case 'debit card':
        return '💳';
      case 'cash':
        return '💵';
      case 'paypal':
        return '💰';
      case 'google pay':
        return '📱';
      case 'apple pay':
        return '🍎';
      default:
        return '💳';
    }
  }

  static double calculateDiscount(double originalPrice, double discountPercentage) {
    return originalPrice * (discountPercentage / 100);
  }

  static double calculateTax(double amount, double taxRate) {
    return amount * (taxRate / 100);
  }

  static double calculateTotalWithTax(double amount, double taxRate) {
    return amount + calculateTax(amount, taxRate);
  }

  static String getGreeting() {
    final hour = DateTime.now().hour;
    
    if (hour < 12) {
      return 'Good Morning';
    } else if (hour < 17) {
      return 'Good Afternoon';
    } else {
      return 'Good Evening';
    }
  }

  static bool isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
           date1.month == date2.month &&
           date1.day == date2.day;
  }

  static bool isToday(DateTime date) {
    return isSameDay(date, DateTime.now());
  }

  static bool isYesterday(DateTime date) {
    final yesterday = DateTime.now().subtract(Duration(days: 1));
    return isSameDay(date, yesterday);
  }

  static List<String> splitSearchQuery(String query) {
    return query.toLowerCase().split(' ').where((word) => word.isNotEmpty).toList();
  }

  static bool matchesSearch(String text, List<String> searchTerms) {
    final lowerText = text.toLowerCase();
    return searchTerms.every((term) => lowerText.contains(term));
  }

  static String getFileExtension(String fileName) {
    return fileName.split('.').last.toLowerCase();
  }

  static bool isImageFile(String fileName) {
    final extension = getFileExtension(fileName);
    return ['jpg', 'jpeg', 'png', 'gif', 'bmp', 'webp'].contains(extension);
  }

  static bool isPdfFile(String fileName) {
    return getFileExtension(fileName) == 'pdf';
  }

  static String formatFileSize(int bytes) {
    if (bytes < 1024) {
      return '$bytes B';
    } else if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    } else if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    } else {
      return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
    }
  }

  static Future<bool> hasNetworkConnection() async {
    try {
      // This would typically use connectivity_plus package
      // For now, return true as a placeholder
      return true;
    } catch (e) {
      return false;
    }
  }

  static void showSnackBar(BuildContext context, String message, {Color? color}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color ?? Constants.primaryColor,
        duration: Duration(seconds: 3),
      ),
    );
  }

  static void showErrorSnackBar(BuildContext context, String message) {
    showSnackBar(context, message, color: Colors.red);
  }

  static void showSuccessSnackBar(BuildContext context, String message) {
    showSnackBar(context, message, color: Colors.green);
  }

  static Future<void> showLoadingDialog(BuildContext context, String message) async {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        content: Row(
          children: [
            CircularProgressIndicator(),
            SizedBox(width: 16),
            Expanded(child: Text(message)),
          ],
        ),
      ),
    );
  }

  static void hideLoadingDialog(BuildContext context) {
    Navigator.of(context).pop();
  }

  static Future<bool> showConfirmationDialog(
    BuildContext context,
    String title,
    String message,
  ) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text('Confirm'),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  static String maskSensitiveData(String data, {int visibleChars = 4}) {
    if (data.length <= visibleChars) {
      return '*' * data.length;
    }
    
    final visible = data.substring(0, visibleChars);
    final masked = '*' * (data.length - visibleChars);
    return visible + masked;
  }

  static String generateBarcode() {
    final random = DateTime.now().millisecondsSinceEpoch.toString();
    return random.substring(0, 12);
  }

  static bool isValidBarcode(String barcode) {
    // Basic validation for common barcode formats
    return barcode.length >= 8 && barcode.length <= 13 && RegExp(r'^[0-9]+$').hasMatch(barcode);
  }

  static String getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'food':
      case 'grocery':
        return '🍎';
      case 'electronics':
        return '📱';
      case 'clothing':
        return '👕';
      case 'books':
        return '📚';
      case 'toys':
        return '🎮';
      case 'home':
        return '🏠';
      case 'sports':
        return '⚽';
      case 'beauty':
        return '💄';
      case 'health':
        return '💊';
      default:
        return '📦';
    }
  }

  static List<Color> getChartColors() {
    return [
      Color(0xff1faa00),
      Color(0xffD50000),
      Color(0xff2196F3),
      Color(0xffFF9800),
      Color(0xff9C27B0),
      Color(0xff607D8B),
      Color(0xff795548),
      Color(0xff009688),
    ];
  }

  static String getInitials(String name) {
    if (name.isEmpty) return '';
    
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    } else {
      return name.substring(0, 1).toUpperCase();
    }
  }

  static Color getRandomColor() {
    final colors = getChartColors();
    return colors[DateTime.now().millisecond % colors.length];
  }

  static String sanitizeFileName(String fileName) {
    return fileName
        .replaceAll(RegExp(r'[^\w\s.-]'), '')
        .replaceAll(RegExp(r'\s+'), '_')
        .toLowerCase();
  }

  static String formatDuration(Duration duration) {
    if (duration.inDays > 0) {
      return '${duration.inDays}d ${duration.inHours % 24}h';
    } else if (duration.inHours > 0) {
      return '${duration.inHours}h ${duration.inMinutes % 60}m';
    } else if (duration.inMinutes > 0) {
      return '${duration.inMinutes}m ${duration.inSeconds % 60}s';
    } else {
      return '${duration.inSeconds}s';
    }
  }

  static bool isWeekend(DateTime date) {
    return date.weekday == DateTime.saturday || date.weekday == DateTime.sunday;
  }

  static DateTime startOfDay(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  static DateTime endOfDay(DateTime date) {
    return DateTime(date.year, date.month, date.day, 23, 59, 59);
  }
}
