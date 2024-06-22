import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

class ImageCacheService {
  static final ImageCacheService _instance = ImageCacheService._internal();
  factory ImageCacheService() => _instance;
  ImageCacheService._internal();

  final Map<String, Uint8List> _memoryCache = {};
  final Map<String, File> _fileCache = {};
  Directory? _cacheDir;

  Future<void> init() async {
    _cacheDir = await getTemporaryDirectory();
  }

  Future<Uint8List?> getImage(String url) async {
    // Check memory cache first
    if (_memoryCache.containsKey(url)) {
      return _memoryCache[url];
    }

    // Check file cache
    if (_fileCache.containsKey(url)) {
      final file = _fileCache[url]!;
      if (await file.exists()) {
        final bytes = await file.readAsBytes();
        _memoryCache[url] = bytes;
        return bytes;
      }
    }

    // Download and cache
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final bytes = response.bodyBytes;
        _memoryCache[url] = bytes;
        
        // Save to file cache
        if (_cacheDir != null) {
          final fileName = url.hashCode.toString();
          final file = File('${_cacheDir!.path}/$fileName');
          await file.writeAsBytes(bytes);
          _fileCache[url] = file;
        }
        
        return bytes;
      }
    } catch (e) {
      print('Error caching image: $e');
    }

    return null;
  }

  void clearCache() {
    _memoryCache.clear();
    _fileCache.clear();
  }

  Future<void> clearFileCache() async {
    if (_cacheDir != null) {
      final files = _cacheDir!.listSync();
      for (final file in files) {
        if (file is File) {
          await file.delete();
        }
      }
    }
    _fileCache.clear();
  }
}
