import 'dart:convert';
import 'package:csv/csv.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

class ExportService {
  static Future<void> exportCartHistory(List<Map<String, dynamic>> history) async {
    final csvData = [
      ['Date', 'Item Name', 'Price', 'Quantity', 'Total']
    ];
    
    for (final item in history) {
      csvData.add([
        item['time'] ?? '',
        item['name'] ?? '',
        item['price'] ?? '',
        item['quantity'] ?? '',
        (double.parse(item['price'].toString()) * int.parse(item['quantity'].toString())).toStringAsFixed(2),
      ]);
    }
    
    final csv = const ListToCsvConverter().convert(csvData);
    final directory = await getApplicationDocumentsDirectory();
    final file = await File('${directory.path}/cart_history.csv').writeAsString(csv);
    
    await Share.shareXFiles([XFile(file.path)], text: 'Cart History Export');
  }

  static Future<void> exportShoppingList(List<String> items) async {
    final csvData = [
      ['Item', 'Completed']
    ];
    
    for (final item in items) {
      csvData.add([item, 'No']);
    }
    
    final csv = const ListToCsvConverter().convert(csvData);
    final directory = await getApplicationDocumentsDirectory();
    final file = await File('${directory.path}/shopping_list.csv').writeAsString(csv);
    
    await Share.shareXFiles([XFile(file.path)], text: 'Shopping List Export');
  }
}
