import 'dart:convert';
import 'package:http/http.dart' as http;

/// Result model for Wikipedia operations
class WikipediaResult {
  final bool success;
  final String? data;
  final String? error;
  final Map<String, dynamic>? metadata;

  WikipediaResult({
    required this.success,
    this.data,
    this.error,
    this.metadata,
  });

  factory WikipediaResult.success(String data, [Map<String, dynamic>? metadata]) {
    return WikipediaResult(
      success: true,
      data: data,
      metadata: metadata,
    );
  }

  factory WikipediaResult.failure(String error) {
    return WikipediaResult(
      success: false,
      error: error,
    );
  }
}

/// Search result model
class WikipediaSearchResult {
  final String title;
  final String snippet;
  final int wordCount;
  final int size;
  final DateTime? timestamp;
  final int pageId;

  WikipediaSearchResult({
    required this.title,
    required this.snippet,
    required this.wordCount,
    required this.size,
    this.timestamp,
    required this.pageId,
  });

  factory WikipediaSearchResult.fromJson(Map<String, dynamic> json) {

    
    DateTime? ts;
    if (json['timestamp'] != null) {
      try {
        ts = DateTime.parse(json['timestamp']);
      } catch (_) {

      }
    }

    final result = WikipediaSearchResult(
      title: json['title'] ?? '',
      snippet: _cleanHtml(json['snippet'] ?? ''),
      wordCount: json['wordcount'] ?? 0,
      size: json['size'] ?? 0,
      timestamp: ts,
      pageId: json['pageid'] ?? 0,
    );
    

    return result;
  }

  static String _cleanHtml(String html) {
    return html
        .replaceAll(RegExp(r'<[^>]+>'), '')
        .replaceAll('&quot;', '"')
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&#039;', "'")
        .trim();
  }

  Map<String, dynamic> toJson() => {
    'title': title,
    'snippet': snippet,
    'wordCount': wordCount,
    'size': size,
    'timestamp': timestamp?.toIso8601String(),
    'pageId': pageId,
  };
}

/// Article section model
class WikipediaSection {
  final String title;
  final int level;
  final String index;
  final String? number;
  final String? anchor;

  WikipediaSection({
    required this.title,
    required this.level,
    required this.index,
    this.number,
    this.anchor,
  });

  factory WikipediaSection.fromJson(Map<String, dynamic> json) {
    return WikipediaSection(
      title: json['line'] ?? '',
      level: int.tryParse(json['level']?.toString() ?? '1') ?? 1,
      index: json['index']?.toString() ?? '',
      number: json['number']?.toString(),
      anchor: json['anchor'],
    );
  }

  Map<String, dynamic> toJson() => {
    'title': title,
    'level': level,
    'index': index,
    if (number != null) 'number': number,
    if (anchor != null) 'anchor': anchor,
  };
}

/// Article metadata model
class WikipediaArticle {
  final String title;
  final int pageId;
  final String? url;
  final String? extract;
  final String? thumbnail;
  final List<WikipediaSection> sections;
  final List<String> categories;
  final List<String> externalLinks;
  final DateTime? lastModified;

  WikipediaArticle({
    required this.title,
    required this.pageId,
    this.url,
    this.extract,
    this.thumbnail,
    this.sections = const [],
    this.categories = const [],
    this.externalLinks = const [],
    this.lastModified,
  });

  Map<String, dynamic> toJson() => {
    'title': title,
    'pageId': pageId,
    if (url != null) 'url': url,
    if (extract != null) 'extract': extract,
    if (thumbnail != null) 'thumbnail': thumbnail,
    'sections': sections.map((s) => s.toJson()).toList(),
    'categories': categories,
    'externalLinks': externalLinks,
    if (lastModified != null) 'lastModified': lastModified!.toIso8601String(),
  };
}

/// Main Wikipedia service class
class WikipediaService {
  static const String _baseUrl = 'https://en.wikipedia.org/w/api.php';
  final http.Client _client;
  final String language;
  final Duration timeout;

  WikipediaService({
    http.Client? client,
    this.language = 'en',
    this.timeout = const Duration(seconds: 10),
  }) : _client = client ?? http.Client();

  /// Search Wikipedia articles
  Future<List<WikipediaSearchResult>> search(
    String query, {
    int limit = 5,
    bool includeSnippet = true,
  }) async {

    
    if (query.trim().isEmpty) {

      throw ArgumentError('Search query cannot be empty');
    }

    final params = {
      'action': 'query',
      'format': 'json',
      'list': 'search',
      'srsearch': query,
      'srlimit': limit.clamp(1, 50).toString(),
      'srprop': 'snippet|titlesnippet|size|wordcount|timestamp',
    };



    try {
      final response = await _makeRequest(params);

      
      final searchResults = response['query']?['search'] as List? ?? [];

      
      final results = searchResults
          .map((r) => WikipediaSearchResult.fromJson(r as Map<String, dynamic>))
          .toList();
          

      return results;
    } catch (e) {

      throw Exception('Search failed: $e');
    }
  }

  /// Get full article content
  Future<WikipediaArticle> getArticle(
    String title, {
    bool includeSections = true,
    bool includeCategories = false,
    bool includeLinks = false,
  }) async {

    
    if (title.trim().isEmpty) {

      throw ArgumentError('Article title cannot be empty');
    }

    // Get article content and metadata
    final params = {
      'action': 'query',
      'format': 'json',
      'prop': 'extracts|info|pageimages',
      'titles': title,
      'exintro': '0',
      'explaintext': '1',
      'inprop': 'url',
      'piprop': 'thumbnail',
      'pithumbsize': '400',
    };

    if (includeCategories) {
      params['prop'] = '${params['prop']}|categories';
      params['cllimit'] = '50';
    }

    if (includeLinks) {
      params['prop'] = '${params['prop']}|extlinks';
      params['ellimit'] = '50';
    }



    try {
      final response = await _makeRequest(params);

      
      final pages = response['query']?['pages'] as Map? ?? {};

      
      if (pages.isEmpty) {

        throw Exception('Article not found: $title');
      }

      final page = pages.values.first as Map<String, dynamic>;

      
      if (page['missing'] == true) {

        throw Exception('Article not found: $title');
      }

      // Get sections if requested
      List<WikipediaSection> sections = [];
      if (includeSections) {

        sections = await _getArticleSections(title);

      }

      // Extract categories
      List<String> categories = [];
      if (includeCategories && page['categories'] != null) {

        categories = (page['categories'] as List)
            .map((c) => (c['title'] as String).replaceFirst('Category:', ''))
            .toList();

      }

      // Extract external links
      List<String> externalLinks = [];
      if (includeLinks && page['extlinks'] != null) {

        externalLinks = (page['extlinks'] as List)
            .map((l) => l['*'] as String)
            .toList();

      }

      final article = WikipediaArticle(
        title: page['title'] ?? title,
        pageId: page['pageid'] ?? 0,
        url: page['fullurl'],
        extract: page['extract'],
        thumbnail: page['thumbnail']?['source'],
        sections: sections,
        categories: categories,
        externalLinks: externalLinks,
      );
      

      
      return article;
    } catch (e) {

      throw Exception('Failed to get article: $e');
    }
  }

  /// Get article sections/table of contents
  Future<List<WikipediaSection>> _getArticleSections(String title) async {

    
    final params = {
      'action': 'parse',
      'format': 'json',
      'page': title,
      'prop': 'sections',
    };

    try {
      final response = await _makeRequest(params);
      final sections = response['parse']?['sections'] as List? ?? [];

      
      final filteredSections = sections
          .map((s) => WikipediaSection.fromJson(s as Map<String, dynamic>))
          .where((s) => s.title.isNotEmpty)
          .toList();
          

      
      return filteredSections;
    } catch (e) {

      throw Exception('Failed to get sections: $e');
    }
  }

  /// Make HTTP request to Wikipedia API
  Future<Map<String, dynamic>> _makeRequest(Map<String, dynamic> params) async {
    final uri = Uri.parse(_baseUrl).replace(queryParameters: {
      ...params,
      'origin': '*',
    });



    try {
      final response = await _client.get(uri).timeout(timeout);
      

      
      if (response.statusCode != 200) {

        throw Exception('API error: HTTP ${response.statusCode}');
      }

      final decoded = jsonDecode(response.body) as Map<String, dynamic>;

      
      return decoded;
    } catch (e) {

      if (e.toString().contains('TimeoutException')) {
        throw Exception('Request timeout');
      }
      throw Exception('Network error: $e');
    }
  }

  // ... (rest of the methods remain the same)
  
  /// Convert HTML to plain text
  // ignore: unused_element
  static String _htmlToPlainText(String html) {
    return html
        .replaceAll(RegExp(r'<script[^>]*>.*?</script>', multiLine: true, dotAll: true), '')
        .replaceAll(RegExp(r'<style[^>]*>.*?</style>', multiLine: true, dotAll: true), '')
        .replaceAll(RegExp(r'<[^>]+>'), '')
        .replaceAll('&nbsp;', ' ')
        .replaceAll('&quot;', '"')
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&#039;', "'")
        .replaceAll(RegExp(r'\n\s*\n'), '\n\n')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  /// Dispose of the HTTP client
  void dispose() {

    _client.close();
  }
}
