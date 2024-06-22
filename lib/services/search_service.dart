import 'package:flutter/material.dart';

class SearchService {
  static List<String> searchItems(List<String> items, String query) {
    if (query.isEmpty) return items;
    
    return items.where((item) => 
      item.toLowerCase().contains(query.toLowerCase())
    ).toList();
  }
}
