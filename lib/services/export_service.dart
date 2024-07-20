import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:selfcheckoutapp/models/item.dart';
import 'package:selfcheckoutapp/services/firebase_services.dart';

class ExportService {
  static Future<void> exportCartHistory() async {
    try {
      final firebaseServices = FirebaseServices();
      final snapshot = await firebaseServices.usersCartHistoryRef
          .doc(firebaseServices.userId!)
          .collection('purchases')
          .get();
      
      final purchases = snapshot.docs.map((doc) => doc.data()).toList();
      
      // Create CSV format
      final csvData = _convertToCSV(purchases);
      
      // Save to file
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/cart_history_export.csv');
      await file.writeAsString(csvData);
      
      // Share file
      await Share.shareXFiles([XFile(file.path)], text: 'Cart History Export');
    } catch (e) {
      throw Exception('Failed to export cart history: $e');
    }
  }

  static Future<void> exportShoppingList(List<Map<String, dynamic>> shoppingList) async {
    try {
      // Create CSV format
      final csvData = _convertShoppingListToCSV(shoppingList);
      
      // Save to file
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/shopping_list_export.csv');
      await file.writeAsString(csvData);
      
      // Share file
      await Share.shareXFiles([XFile(file.path)], text: 'Shopping List Export');
    } catch (e) {
      throw Exception('Failed to export shopping list: $e');
    }
  }

  static Future<void> exportUserData() async {
    try {
      final firebaseServices = FirebaseServices();
      final userDoc = await firebaseServices.getUserData(firebaseServices.userId!);
      
      if (!userDoc.exists) {
        throw Exception('No user data found');
      }
      
      final userData = userDoc.data() as Map<String, dynamic>;
      
      // Create JSON format
      final jsonData = const JsonEncoder.withIndent('  ').convert(userData);
      
      // Save to file
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/user_data_export.json');
      await file.writeAsString(jsonData);
      
      // Share file
      await Share.shareXFiles([XFile(file.path)], text: 'User Data Export');
    } catch (e) {
      throw Exception('Failed to export user data: $e');
    }
  }

  static Future<void> exportAppData({
    List<Item>? cartItems,
    List<Map<String, dynamic>>? purchaseHistory,
    List<Map<String, dynamic>>? shoppingList,
    Map<String, dynamic>? userData,
  }) async {
    try {
      final exportData = {
        'export_date': DateTime.now().toIso8601String(),
        'version': '1.0.0',
        'user_data': userData,
        'cart_items': cartItems?.map((item) => item.toMap()).toList(),
        'purchase_history': purchaseHistory,
        'shopping_list': shoppingList,
      };
      
      // Create JSON format
      final jsonData = const JsonEncoder.withIndent('  ').convert(exportData);
      
      // Save to file
      final directory = await getApplicationDocumentsDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final file = File('${directory.path}/app_data_export_$timestamp.json');
      await file.writeAsString(jsonData);
      
      // Share file
      await Share.shareXFiles([XFile(file.path)], text: 'Complete App Data Export');
    } catch (e) {
      throw Exception('Failed to export app data: $e');
    }
  }

  static Future<void> exportToPDF({
    List<Item>? cartItems,
    List<Map<String, dynamic>>? purchaseHistory,
  }) async {
    try {
      // This would require a PDF generation library like 'pdf'
      // For now, we'll create a simple text file
      final buffer = StringBuffer();
      
      if (cartItems != null && cartItems.isNotEmpty) {
        buffer.writeln('=== CURRENT CART ===');
        buffer.writeln('Item,Price,Quantity,Weight');
        for (final item in cartItems) {
          buffer.writeln('${item.name},${item.price},${item.quantity},${item.weight}');
        }
        buffer.writeln();
      }
      
      if (purchaseHistory != null && purchaseHistory.isNotEmpty) {
        buffer.writeln('=== PURCHASE HISTORY ===');
        for (final purchase in purchaseHistory) {
          buffer.writeln('Date: ${purchase['date'] ?? 'Unknown'}');
          buffer.writeln('Total: ${purchase['total'] ?? 0}');
          buffer.writeln('Items: ${purchase['items']?.length ?? 0}');
          buffer.writeln('---');
        }
      }
      
      // Save to file
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/export_report.txt');
      await file.writeAsString(buffer.toString());
      
      // Share file
      await Share.shareXFiles([XFile(file.path)], text: 'Export Report');
    } catch (e) {
      throw Exception('Failed to export to PDF: $e');
    }
  }

  static String _convertToCSV(List<Map<String, dynamic>> data) {
    final buffer = StringBuffer();
    
    if (data.isNotEmpty) {
      // Header
      final headers = data.first.keys.toList();
      buffer.writeln(headers.join(','));
      
      // Data rows
      for (final row in data) {
        final values = headers.map((header) {
          final value = row[header]?.toString() ?? '';
          // Escape commas and quotes in values
          if (value.contains(',') || value.contains('"')) {
            return '"${value.replaceAll('"', '""')}"';
          }
          return value;
        }).toList();
        buffer.writeln(values.join(','));
      }
    }
    
    return buffer.toString();
  }

  static String _convertShoppingListToCSV(List<Map<String, dynamic>> shoppingList) {
    final buffer = StringBuffer();
    
    buffer.writeln('Title,Completed,Created At,Notes');
    
    for (final item in shoppingList) {
      final title = (item['title'] ?? '').toString().replaceAll(',', ';');
      final completed = (item['complete'] ?? false).toString();
      final createdAt = (item['createdAt'] ?? '').toString();
      final notes = (item['notes'] ?? '').toString().replaceAll(',', ';');
      
      buffer.writeln('$title,$completed,$createdAt,$notes');
    }
    
    return buffer.toString();
  }

  static Future<void> importFromFile(String filePath) async {
    try {
      final file = File(filePath);
      final content = await file.readAsString();
      
      if (filePath.endsWith('.json')) {
        await _importFromJSON(content);
      } else if (filePath.endsWith('.csv')) {
        await _importFromCSV(content);
      } else {
        throw Exception('Unsupported file format');
      }
    } catch (e) {
      throw Exception('Failed to import data: $e');
    }
  }

  static Future<void> _importFromJSON(String content) async {
    try {
      final data = json.decode(content) as Map<String, dynamic>;
      
      // Import user data
      if (data['user_data'] != null) {
        final firebaseServices = FirebaseServices();
        await firebaseServices.saveUserData(
          firebaseServices.userId!,
          data['user_data'],
        );
      }
      
      // Import cart items (if needed)
      if (data['cart_items'] != null) {
        // Logic to restore cart items
      }
      
      // Import shopping list
      if (data['shopping_list'] != null) {
        // Logic to restore shopping list
      }
    } catch (e) {
      throw Exception('Failed to parse JSON: $e');
    }
  }

  static Future<void> _importFromCSV(String content) async {
    try {
      final lines = content.split('\n');
      if (lines.isEmpty) return;
      
      final headers = lines.first.split(',');
      
      // Simple CSV parsing - would need more robust implementation for production
      for (int i = 1; i < lines.length; i++) {
        final line = lines[i].trim();
        if (line.isEmpty) continue;
        
        final values = line.split(',');
        if (values.length == headers.length) {
          final Map<String, dynamic> row = {};
          for (int j = 0; j < headers.length; j++) {
            row[headers[j].trim()] = values[j].trim();
          }
          
          // Process each row based on the data type
          // This would need to be implemented based on specific requirements
        }
      }
    } catch (e) {
      throw Exception('Failed to parse CSV: $e');
    }
  }

  static Future<void> backupToCloud() async {
    try {
      // This would integrate with cloud storage services
      // For now, we'll just export locally
      await exportAppData();
    } catch (e) {
      throw Exception('Failed to backup to cloud: $e');
    }
  }

  static Future<void> restoreFromCloud() async {
    try {
      // This would integrate with cloud storage services
      // For now, we'll just show a placeholder
      print('Cloud restore not implemented yet');
    } catch (e) {
      throw Exception('Failed to restore from cloud: $e');
    }
  }

  static Future<String> getExportDirectory() async {
    final directory = await getApplicationDocumentsDirectory();
    return directory.path;
  }

  static Future<List<File>> getExportFiles() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final files = await directory.list().where((entity) => 
        entity is File && (
          entity.path.endsWith('.csv') || 
          entity.path.endsWith('.json') || 
          entity.path.endsWith('.txt')
        )
      ).cast<File>().toList();
      
      return files;
    } catch (e) {
      return [];
    }
  }

  static Future<void> deleteExportFile(String filePath) async {
    try {
      final file = File(filePath);
      if (await file.exists()) {
        await file.delete();
      }
    } catch (e) {
      throw Exception('Failed to delete export file: $e');
    }
  }
}
