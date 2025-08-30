// ignore_for_file: avoid_print

import 'dart:convert';
import 'package:http/http.dart' as http;

class BraveSearchResult {
  final String title;
  final String description;
  final String url;
  final String displayUrl;
  final String? thumbnailUrl;
  final DateTime? publishedTime;
  final String? language;
  final Map<String, dynamic>? extra;

  BraveSearchResult({
    required this.title,
    required this.description,
    required this.url,
    required this.displayUrl,
    this.thumbnailUrl,
    this.publishedTime,
    this.language,
    this.extra,
  });

  factory BraveSearchResult.fromJson(Map<String, dynamic> json) {
    DateTime? publishedTime;
    if (json['age'] != null) {
      try {
        publishedTime = DateTime.parse(json['age']);
      } catch (_) {}
    }

    return BraveSearchResult(
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      url: json['url'] ?? '',
      displayUrl: json['display_url'] ?? json['url'] ?? '',
      thumbnailUrl: json['thumbnail']?['src'],
      publishedTime: publishedTime,
      language: json['language'],
      extra: json['extra'],
    );
  }
}

class BraveSearchService {
  final String apiKey;
  final String freshness;
  final String country;
  final int timeout;

  static const String _baseUrl = 'https://api.search.brave.com/res/v1';

  BraveSearchService({
    required this.apiKey,
    this.freshness = 'all',
    this.country = 'all',
    this.timeout = 30,
  });

  // Convert freshness settings to Brave API format
  String _getFreshnessParam() {
    switch (freshness.toLowerCase()) {
      case 'last 24 hours':
      case '24h':
        return 'pd'; // past day
      case 'last week':
      case 'week':
        return 'pw'; // past week
      case 'last month':
      case 'month':
        return 'pm'; // past month
      case 'last year':
      case 'year':
        return 'py'; // past year
      default:
        return ''; // all time
    }
  }

  // Convert country settings to Brave API format
  String _getCountryParam() {
    switch (country.toUpperCase()) {
      case 'US':
      case 'UNITED STATES':
        return 'US';
      case 'GB':
      case 'UK':
      case 'UNITED KINGDOM':
        return 'GB';
      case 'DE':
      case 'GERMANY':
        return 'DE';
      case 'FR':
      case 'FRANCE':
        return 'FR';
      case 'ES':
      case 'SPAIN':
        return 'ES';
      case 'IT':
      case 'ITALY':
        return 'IT';
      case 'JP':
      case 'JAPAN':
        return 'JP';
      case 'CN':
      case 'CHINA':
        return 'CN';
      case 'IN':
      case 'INDIA':
        return 'IN';
      case 'BR':
      case 'BRAZIL':
        return 'BR';
      case 'CA':
      case 'CANADA':
        return 'CA';
      case 'AU':
      case 'AUSTRALIA':
        return 'AU';
      default:
        return 'ALL';
    }
  }

  Future<List<BraveSearchResult>> search(
    String query, {
    int limit = 20,
    int offset = 0,
    bool safeSearch = true,
    String? searchLang,
    String? uiLang,
  }) async {
    if (apiKey.isEmpty) {
      throw Exception('Brave API key is required');
    }

    try {
      print('[BraveSearch] Searching for: "$query" (limit: $limit, offset: $offset)');

      final List<BraveSearchResult> allResults = [];
      int currentOffset = offset;

      // Brave API returns max 20 results per request
      while (allResults.length < limit) {
        final resultsToFetch = (limit - allResults.length).clamp(1, 20);

        final queryParams = <String, String>{
          'q': query,
          'count': resultsToFetch.toString(),
          'offset': currentOffset.toString(),
        };

        // Add optional parameters
        if (safeSearch) {
          queryParams['safesearch'] = 'moderate';
        }

        final freshnessParam = _getFreshnessParam();
        if (freshnessParam.isNotEmpty) {
          queryParams['freshness'] = freshnessParam;
        }

        final countryParam = _getCountryParam();
        if (countryParam != 'ALL') {
          queryParams['country'] = countryParam;
        }

        if (searchLang != null && searchLang.isNotEmpty) {
          queryParams['search_lang'] = searchLang;
        }

        if (uiLang != null && uiLang.isNotEmpty) {
          queryParams['ui_lang'] = uiLang;
        }

        final uri = Uri.parse('$_baseUrl/web/search').replace(
          queryParameters: queryParams,
        );

        print('[BraveSearch] API request: ${uri.toString().replaceAll(apiKey, 'API_KEY_HIDDEN')}');

        final response = await http.get(
          uri,
          headers: {
            'Accept': 'application/json',
            'Accept-Encoding': 'gzip',
            'X-Subscription-Token': apiKey,
          },
        ).timeout(
          Duration(seconds: timeout),
          onTimeout: () {
            throw Exception('Brave search timeout after $timeout seconds');
          },
        );

        if (response.statusCode == 200) {
          final data = json.decode(response.body);

          // Check if we have web results
          if (data['web'] != null && data['web']['results'] != null) {
            final results = data['web']['results'] as List;

            for (final item in results) {
              allResults.add(BraveSearchResult.fromJson(item));
              if (allResults.length >= limit) break;
            }

            print('[BraveSearch] Retrieved ${results.length} results (total: ${allResults.length})');

            // If we got fewer results than requested, we've reached the end
            if (results.length < resultsToFetch) {
              break;
            }

            currentOffset += results.length;
          } else {
            // No more results available
            print('[BraveSearch] No more results available');
            break;
          }
        } else if (response.statusCode == 401) {
          throw Exception('Brave API authentication failed. Please check your API key.');
        } else if (response.statusCode == 429) {
          throw Exception('Brave API rate limit exceeded. Please try again later.');
        } else if (response.statusCode == 400) {
          final error = json.decode(response.body);
          throw Exception('Brave API error: ${error['message'] ?? 'Bad request'}');
        } else {
          throw Exception('Brave API error: ${response.statusCode} - ${response.reasonPhrase}');
        }
      }

      print('[BraveSearch] Total results found: ${allResults.length}');
      return allResults;
    } catch (e) {
      print('[BraveSearch] Error: $e');
      rethrow;
    }
  }

  // Search for news specifically
  Future<List<BraveSearchResult>> searchNews(
    String query, {
    int limit = 20,
    int offset = 0,
  }) async {
    if (apiKey.isEmpty) {
      throw Exception('Brave API key is required');
    }

    try {
      print('[BraveSearch] Searching news for: "$query"');

      final queryParams = <String, String>{
        'q': query,
        'count': limit.clamp(1, 20).toString(),
        'offset': offset.toString(),
      };

      final freshnessParam = _getFreshnessParam();
      if (freshnessParam.isNotEmpty) {
        queryParams['freshness'] = freshnessParam;
      }

      final countryParam = _getCountryParam();
      if (countryParam != 'ALL') {
        queryParams['country'] = countryParam;
      }

      final uri = Uri.parse('$_baseUrl/news/search').replace(
        queryParameters: queryParams,
      );

      final response = await http.get(
        uri,
        headers: {
          'Accept': 'application/json',
          'Accept-Encoding': 'gzip',
          'X-Subscription-Token': apiKey,
        },
      ).timeout(
        Duration(seconds: timeout),
        onTimeout: () {
          throw Exception('Brave news search timeout after $timeout seconds');
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final results = <BraveSearchResult>[];

        if (data['results'] != null) {
          for (final item in data['results']) {
            results.add(BraveSearchResult.fromJson(item));
          }
        }

        print('[BraveSearch] Found ${results.length} news results');
        return results;
      } else {
        throw Exception('Brave news API error: ${response.statusCode}');
      }
    } catch (e) {
      print('[BraveSearch] News search error: $e');
      rethrow;
    }
  }

  // Get first result
  Future<BraveSearchResult?> getFirstResult(String query) async {
    final results = await search(query, limit: 1);
    return results.isNotEmpty ? results.first : null;
  }
}