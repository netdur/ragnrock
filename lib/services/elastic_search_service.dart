// ignore_for_file: avoid_print

import 'dart:convert';
import 'package:http/http.dart' as http;

class ElasticSearchResult {
  final String id;
  final String index;
  final double score;
  final Map<String, dynamic> source;
  final Map<String, List<String>>? highlights;

  ElasticSearchResult({
    required this.id,
    required this.index,
    required this.score,
    required this.source,
    this.highlights,
  });

  factory ElasticSearchResult.fromJson(Map<String, dynamic> json) {
    Map<String, List<String>>? highlights;
    
    if (json['highlight'] != null) {
      highlights = {};
      final highlightData = json['highlight'] as Map<String, dynamic>;
      highlightData.forEach((key, value) {
        if (value is List) {
          highlights![key] = value.cast<String>();
        }
      });
    }

    return ElasticSearchResult(
      id: json['_id'] ?? '',
      index: json['_index'] ?? '',
      score: (json['_score'] ?? 0.0).toDouble(),
      source: json['_source'] ?? {},
      highlights: highlights,
    );
  }

  // Helper methods to get common fields
  String get title {
    // Try common title field names
    return source['title'] ?? 
           source['name'] ?? 
           source['subject'] ?? 
           source['headline'] ?? 
           id;
  }

  String get content {
    // Try common content field names
    return source['content'] ?? 
           source['body'] ?? 
           source['text'] ?? 
           source['description'] ?? 
           source['summary'] ?? 
           '';
  }

  String get url {
    return source['url'] ?? 
           source['link'] ?? 
           source['path'] ?? 
           '';
  }

  DateTime? get timestamp {
    final timeField = source['timestamp'] ?? 
                     source['created_at'] ?? 
                     source['date'] ?? 
                     source['published_at'];
    
    if (timeField != null) {
      try {
        return DateTime.parse(timeField.toString());
      } catch (_) {}
    }
    return null;
  }
}

class ElasticSearchService {
  final String host;
  final String port;
  final String? username;
  final String? password;
  final String indexPattern;
  final int timeout;

  late final String _baseUrl;
  late final Map<String, String> _headers;

  ElasticSearchService({
    required this.host,
    required this.port,
    this.username,
    this.password,
    required this.indexPattern,
    this.timeout = 30,
  }) {
    // Build base URL
    _baseUrl = 'http://$host:$port';
    
    // Build headers with basic auth if credentials provided
    _headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    
    if (username != null && password != null && 
        username!.isNotEmpty && password!.isNotEmpty) {
      final credentials = base64Encode(utf8.encode('$username:$password'));
      _headers['Authorization'] = 'Basic $credentials';
    }
  }

  // Test connection to Elasticsearch
  Future<bool> testConnection() async {
    try {
      final uri = Uri.parse(_baseUrl);
      final response = await http.get(
        uri,
        headers: _headers,
      ).timeout(
        Duration(seconds: 5),
        onTimeout: () {
          throw Exception('Connection timeout');
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('[ElasticSearch] Connected to: ${data['name']} v${data['version']['number']}');
        return true;
      }
      return false;
    } catch (e) {
      print('[ElasticSearch] Connection test failed: $e');
      return false;
    }
  }

  // Get available indices matching the pattern
  Future<List<String>> getIndices() async {
    try {
      final uri = Uri.parse('$_baseUrl/_cat/indices/$indexPattern?format=json');
      final response = await http.get(
        uri,
        headers: _headers,
      ).timeout(
        Duration(seconds: timeout),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as List;
        return data.map((index) => index['index'].toString()).toList();
      }
      return [];
    } catch (e) {
      print('[ElasticSearch] Failed to get indices: $e');
      return [];
    }
  }

  // Main search method
  Future<List<ElasticSearchResult>> search(
    String query, {
    int limit = 20,
    int from = 0,
    List<String>? searchFields,
    List<String>? highlightFields,
    Map<String, dynamic>? filters,
    String? sortField,
    bool sortAscending = false,
  }) async {
    try {
      print('[ElasticSearch] Searching for: "$query" in $indexPattern (limit: $limit, from: $from)');

      // Build the search query
      final searchQuery = _buildSearchQuery(
        query,
        searchFields: searchFields,
        highlightFields: highlightFields,
        filters: filters,
        sortField: sortField,
        sortAscending: sortAscending,
      );

      final uri = Uri.parse('$_baseUrl/$indexPattern/_search?size=$limit&from=$from');
      
      final response = await http.post(
        uri,
        headers: _headers,
        body: json.encode(searchQuery),
      ).timeout(
        Duration(seconds: timeout),
        onTimeout: () {
          throw Exception('Elasticsearch search timeout after $timeout seconds');
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final hits = data['hits']['hits'] as List;
        
        final results = hits.map((hit) => ElasticSearchResult.fromJson(hit)).toList();
        
        print('[ElasticSearch] Found ${results.length} results (total: ${data['hits']['total']['value']})');
        return results;
      } else if (response.statusCode == 401) {
        throw Exception('Elasticsearch authentication failed. Please check credentials.');
      } else if (response.statusCode == 404) {
        throw Exception('Index pattern "$indexPattern" not found.');
      } else {
        final error = json.decode(response.body);
        throw Exception('Elasticsearch error: ${error['error']['reason'] ?? response.reasonPhrase}');
      }
    } catch (e) {
      print('[ElasticSearch] Search error: $e');
      rethrow;
    }
  }

  // Advanced search with aggregations
  Future<Map<String, dynamic>> searchWithAggregations(
    String query, {
    int limit = 20,
    Map<String, dynamic>? aggregations,
    List<String>? searchFields,
  }) async {
    try {
      final searchQuery = {
        'query': _buildQueryClause(query, searchFields: searchFields),
        'size': limit,
      };

      if (aggregations != null) {
        searchQuery['aggs'] = aggregations;
      }

      final uri = Uri.parse('$_baseUrl/$indexPattern/_search');
      
      final response = await http.post(
        uri,
        headers: _headers,
        body: json.encode(searchQuery),
      ).timeout(
        Duration(seconds: timeout),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Aggregation search failed: ${response.statusCode}');
      }
    } catch (e) {
      print('[ElasticSearch] Aggregation search error: $e');
      rethrow;
    }
  }

  // Build the complete search query
  Map<String, dynamic> _buildSearchQuery(
    String query, {
    List<String>? searchFields,
    List<String>? highlightFields,
    Map<String, dynamic>? filters,
    String? sortField,
    bool sortAscending = false,
  }) {
    final searchQuery = <String, dynamic>{
      'query': _buildQueryClause(query, searchFields: searchFields, filters: filters),
    };

    // Add highlighting
    if (highlightFields != null && highlightFields.isNotEmpty) {
      searchQuery['highlight'] = {
        'fields': {
          for (final field in highlightFields)
            field: {
              'pre_tags': ['<mark>'],
              'post_tags': ['</mark>'],
              'fragment_size': 150,
              'number_of_fragments': 3,
            }
        }
      };
    }

    // Add sorting
    if (sortField != null) {
      searchQuery['sort'] = [
        {
          sortField: {
            'order': sortAscending ? 'asc' : 'desc',
          }
        }
      ];
    } else {
      // Default: sort by relevance score
      searchQuery['sort'] = ['_score'];
    }

    return searchQuery;
  }

  // Build the query clause
  Map<String, dynamic> _buildQueryClause(
    String query, {
    List<String>? searchFields,
    Map<String, dynamic>? filters,
  }) {
    // Build the main text query
    Map<String, dynamic> textQuery;
    
    if (searchFields != null && searchFields.isNotEmpty) {
      // Multi-field search
      textQuery = {
        'multi_match': {
          'query': query,
          'fields': searchFields,
          'type': 'best_fields',
          'operator': 'or',
          'fuzziness': 'AUTO',
        }
      };
    } else {
      // Search all fields
      textQuery = {
        'query_string': {
          'query': query,
          'default_field': '*',
          'analyze_wildcard': true,
          'default_operator': 'OR',
        }
      };
    }

    // If no filters, return the text query directly
    if (filters == null || filters.isEmpty) {
      return textQuery;
    }

    // Combine text query with filters using bool query
    return {
      'bool': {
        'must': [textQuery],
        'filter': _buildFilterClauses(filters),
      }
    };
  }

  // Build filter clauses from filter map
  List<Map<String, dynamic>> _buildFilterClauses(Map<String, dynamic> filters) {
    final clauses = <Map<String, dynamic>>[];
    
    filters.forEach((field, value) {
      if (value is List) {
        // Multiple values - use terms query
        clauses.add({
          'terms': {field: value}
        });
      } else if (value is Map) {
        // Range query
        if (value.containsKey('from') || value.containsKey('to')) {
          final rangeQuery = <String, dynamic>{};
          if (value['from'] != null) rangeQuery['gte'] = value['from'];
          if (value['to'] != null) rangeQuery['lte'] = value['to'];
          clauses.add({
            'range': {field: rangeQuery}
          });
        }
      } else {
        // Single value - use term query
        clauses.add({
          'term': {field: value}
        });
      }
    });
    
    return clauses;
  }

  // Get a single document by ID
  Future<ElasticSearchResult?> getDocument(String index, String id) async {
    try {
      final uri = Uri.parse('$_baseUrl/$index/_doc/$id');
      
      final response = await http.get(
        uri,
        headers: _headers,
      ).timeout(
        Duration(seconds: timeout),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return ElasticSearchResult.fromJson(data);
      }
      return null;
    } catch (e) {
      print('[ElasticSearch] Failed to get document: $e');
      return null;
    }
  }

  // More like this - find similar documents
  Future<List<ElasticSearchResult>> moreLikeThis(
    String documentId,
    String index, {
    int limit = 10,
    List<String>? fields,
  }) async {
    try {
      final query = {
        'query': {
          'more_like_this': {
            'fields': fields ?? ['*'],
            'like': [
              {
                '_index': index,
                '_id': documentId,
              }
            ],
            'min_term_freq': 1,
            'max_query_terms': 25,
          }
        },
        'size': limit,
      };

      final uri = Uri.parse('$_baseUrl/$index/_search');
      
      final response = await http.post(
        uri,
        headers: _headers,
        body: json.encode(query),
      ).timeout(
        Duration(seconds: timeout),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final hits = data['hits']['hits'] as List;
        return hits.map((hit) => ElasticSearchResult.fromJson(hit)).toList();
      }
      return [];
    } catch (e) {
      print('[ElasticSearch] More like this error: $e');
      return [];
    }
  }
}