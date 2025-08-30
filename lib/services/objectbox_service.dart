// ignore_for_file: avoid_print

import 'dart:io';
import 'package:get/get.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import '../objectbox.g.dart';
import '../models/search_query.dart';

class ObjectBoxService extends GetxService {
  Store? _store;  // Make nullable to check if already initialized
  
  // Only one box now - for SearchQuery
  late final Box<SearchQuery> searchQueryBox;

  // Add a getter to ensure store is initialized
  Store get store {
    if (_store == null) {
      throw Exception('ObjectBoxService not initialized. Call init() first.');
    }
    return _store!;
  }

  // The init method opens the store and initializes the boxes
  Future<void> init() async {
    // Check if already initialized
    if (_store != null) {
      print('ObjectBox already initialized, skipping...');
      return;
    }
    
    try {
      // Get the application documents directory
      final Directory appDocDir = await getApplicationDocumentsDirectory();
      
      // Create a subdirectory for objectbox
      final String dbPath = path.join(appDocDir.path, 'objectbox');
      
      // Log the path for debugging
      print('ObjectBox database path: $dbPath');
      
      // Open the ObjectBox store with the specific directory
      _store = await openStore(directory: dbPath);
      
      // Initialize the search query box
      searchQueryBox = store.box<SearchQuery>();
      
      print('ObjectBox initialized successfully at: $dbPath');
    } catch (e) {
      print('Failed to initialize ObjectBox: $e');
      
      // If there's a schema mismatch, try to recover
      if (e.toString().contains('entity ID') || 
          e.toString().contains('UID')) {
        await _handleSchemaMismatch();
      } else {
        rethrow;
      }
    }
  }
  
  // Handle schema mismatches by recreating the database
  Future<void> _handleSchemaMismatch() async {
    print('Handling schema mismatch - recreating database...');
    
    // Close existing store if it exists
    if (_store != null) {
      _store!.close();
      _store = null;
    }
    
    final Directory appDocDir = await getApplicationDocumentsDirectory();
    final String dbPath = path.join(appDocDir.path, 'objectbox');
    
    // Delete the existing database
    if (Directory(dbPath).existsSync()) {
      Directory(dbPath).deleteSync(recursive: true);
      print('Deleted corrupted database');
    }
    
    // Try to open store again with fresh database
    _store = await openStore(directory: dbPath);
    
    // Reinitialize box
    searchQueryBox = store.box<SearchQuery>();
    
    print('Database recreated successfully');
  }

  // Close method to properly shut down the service
  void close() {
    _store?.close();
    _store = null;
  }
  
  // CRUD operations remain the same...
  
  // CREATE - Save a new search query or update existing
  int saveSearchQuery(SearchQuery query) {
    return searchQueryBox.put(query);
  }
  
  // CREATE MANY - Save multiple queries
  List<int> saveSearchQueries(List<SearchQuery> queries) {
    return searchQueryBox.putMany(queries);
  }
  
  // READ - Get a single query by ID
  SearchQuery? getSearchQuery(int id) {
    return searchQueryBox.get(id);
  }
  
  // READ - Get all queries
  List<SearchQuery> getAllSearchQueries() {
    return searchQueryBox.getAll();
  }
  
  // READ - Get recent searches with limit
  List<SearchQuery> getRecentSearches({int limit = 50}) {
    final query = searchQueryBox
        .query()
        .order(SearchQuery_.timestamp, flags: Order.descending)
        .build();
    
    final results = query.find();
    query.close();
    
    return results.take(limit).toList();
  }
  
  // READ - Search by query text
  List<SearchQuery> searchByText(String searchText) {
    final query = searchQueryBox
        .query(SearchQuery_.originalQuery.contains(searchText, caseSensitive: false))
        .order(SearchQuery_.timestamp, flags: Order.descending)
        .build();
    
    final results = query.find();
    query.close();
    
    return results;
  }
  
  // UPDATE - Update an existing query
  void updateSearchQuery(SearchQuery query) {
    searchQueryBox.put(query);
  }
  
  // UPDATE - Update final report for a query
  void updateFinalReport(int queryId, String report) {
    final query = searchQueryBox.get(queryId);
    if (query != null) {
      query.finalReport = report;
      searchQueryBox.put(query);
    }
  }
  
  // UPDATE - Update status for a query
  void updateQueryStatus(int queryId, String status) {
    final query = searchQueryBox.get(queryId);
    if (query != null) {
      query.lastStatus = status;
      searchQueryBox.put(query);
    }
  }
  
  // DELETE - Delete a single query
  bool deleteSearchQuery(int id) {
    return searchQueryBox.remove(id);
  }
  
  // DELETE - Delete multiple queries
  int deleteSearchQueries(List<int> ids) {
    return searchQueryBox.removeMany(ids);
  }
  
  // DELETE - Clear all queries
  void clearAllSearchQueries() {
    searchQueryBox.removeAll();
    print('All search queries cleared');
  }
  
  // Get database size info
  Future<Map<String, dynamic>> getDatabaseInfo() async {
    final Directory appDocDir = await getApplicationDocumentsDirectory();
    final String dbPath = path.join(appDocDir.path, 'objectbox');
    
    if (Directory(dbPath).existsSync()) {
      int totalSize = 0;
      final dir = Directory(dbPath);
      
      await for (final file in dir.list(recursive: true, followLinks: false)) {
        if (file is File) {
          totalSize += await file.length();
        }
      }
      
      return {
        'path': dbPath,
        'exists': true,
        'sizeInBytes': totalSize,
        'sizeInMB': (totalSize / (1024 * 1024)).toStringAsFixed(2),
        'searchQueries': searchQueryBox.count(),
      };
    }
    
    return {
      'path': dbPath,
      'exists': false,
    };
  }
  
  @override
  void onClose() {
    close();
    super.onClose();
  }
}