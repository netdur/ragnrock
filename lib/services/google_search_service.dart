// ignore_for_file: avoid_print

import 'dart:convert';
import 'package:http/http.dart' as http;

class GoogleSearchResult {
  final String title;
  final String snippet;
  final String link;
  final String displayLink;
  final Map<String, dynamic>? metadata;

  GoogleSearchResult({
    required this.title,
    required this.snippet,
    required this.link,
    required this.displayLink,
    this.metadata,
  });

  factory GoogleSearchResult.fromJson(Map<String, dynamic> json) {
    return GoogleSearchResult(
      title: json['title'] ?? '',
      snippet: json['snippet'] ?? '',
      link: json['link'] ?? '',
      displayLink: json['displayLink'] ?? '',
      metadata: json['pagemap'],
    );
  }
}

class GoogleSearchService {
  final String apiKey;
  final String searchEngineId;
  final String safeSearch;
  final int timeout;

  GoogleSearchService({
    required this.apiKey,
    required this.searchEngineId,
    this.safeSearch = 'moderate',
    this.timeout = 30,
  });

  Future<List<GoogleSearchResult>> search(
    String query, {
    int limit = 10,
    int startIndex = 1,
  }) async {
    if (apiKey.isEmpty || searchEngineId.isEmpty) {
      throw Exception('Google API key and Search Engine ID are required');
    }

    try {
      print('[GoogleSearch] Searching for: "$query" (limit: $limit)');
      
      final List<GoogleSearchResult> allResults = [];
      int currentIndex = startIndex;
      
      // Google API returns max 10 results per request
      while (allResults.length < limit) {
        final resultsToFetch = (limit - allResults.length).clamp(1, 10);
        
        final uri = Uri.https(
          'www.googleapis.com',
          '/customsearch/v1',
          {
            'key': apiKey,
            'cx': searchEngineId,
            'q': query,
            'num': resultsToFetch.toString(),
            'start': currentIndex.toString(),
            'safe': safeSearch.toLowerCase(),
          },
        );

        print('[GoogleSearch] Fetching from index $currentIndex, requesting $resultsToFetch results');
        
        final response = await http.get(uri).timeout(
          Duration(seconds: timeout),
          onTimeout: () {
            throw Exception('Google search timeout after $timeout seconds');
          },
        );

        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          
          // Check if we have search results
          if (data['items'] != null) {
            final items = data['items'] as List;
            
            for (final item in items) {
              allResults.add(GoogleSearchResult.fromJson(item));
              if (allResults.length >= limit) break;
            }
            
            print('[GoogleSearch] Retrieved ${items.length} results (total: ${allResults.length})');
            
            // If we got fewer results than requested, we've reached the end
            if (items.length < resultsToFetch) {
              break;
            }
            
            currentIndex += items.length;
          } else {
            // No more results available
            print('[GoogleSearch] No more results available');
            break;
          }
        } else if (response.statusCode == 429) {
          throw Exception('Google API rate limit exceeded. Please try again later.');
        } else if (response.statusCode == 400) {
          final error = json.decode(response.body);
          throw Exception('Google API error: ${error['error']['message'] ?? 'Bad request'}');
        } else {
          throw Exception('Google API error: ${response.statusCode} - ${response.reasonPhrase}');
        }
      }
      
      print('[GoogleSearch] Total results found: ${allResults.length}');
      return allResults;
      
    } catch (e) {
      print('[GoogleSearch] Error: $e');
      rethrow;
    }
  }

  Future<GoogleSearchResult?> getFirstResult(String query) async {
    final results = await search(query, limit: 1);
    return results.isNotEmpty ? results.first : null;
  }
}