import 'package:flutter/material.dart';
import 'dart:core';

class SearchService {
  static List<String> filterList(List<String> items, String query) {
    if (query.isEmpty) return items;
    
    return items.where((item) {
      return item.toLowerCase().contains(query.toLowerCase());
    }).toList();
  }

  static List<Map<String, dynamic>> filterProducts(
    List<Map<String, dynamic>> products, 
    String query
  ) {
    if (query.isEmpty) return products;
    
    return products.where((product) {
      final name = product['name']?.toString().toLowerCase() ?? '';
      final barcode = product['barcode']?.toString().toLowerCase() ?? '';
      final description = product['description']?.toString().toLowerCase() ?? '';
      
      return name.contains(query.toLowerCase()) ||
             barcode.contains(query.toLowerCase()) ||
             description.contains(query.toLowerCase());
    }).toList();
  }

  static List<Map<String, dynamic>> sortProducts(
    List<Map<String, dynamic>> products,
    String sortBy,
  ) {
    switch (sortBy.toLowerCase()) {
      case 'name':
        products.sort((a, b) => (a['name'] ?? '').compareTo(b['name'] ?? ''));
        break;
      case 'price':
        products.sort((a, b) => (a['price'] ?? 0.0).compareTo(b['price'] ?? 0.0));
        break;
      case 'barcode':
        products.sort((a, b) => (a['barcode'] ?? '').compareTo(b['barcode'] ?? ''));
        break;
      default:
        break;
    }
    return products;
  }
}
