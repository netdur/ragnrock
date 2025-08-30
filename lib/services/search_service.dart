// ignore_for_file: avoid_print

import 'package:get/get.dart';
import 'settings_service.dart';
import 'wikipedia_service.dart';
import 'google_search_service.dart';
import 'brave_search_service.dart';
import 'elastic_search_service.dart';

// Unified search result that all engines will map to
class UnifiedSearchResult {
 final String title;
 final String snippet;
 final String url;
 final String source;
 final Map<String, dynamic>? metadata;

 UnifiedSearchResult({
   required this.title,
   required this.snippet,
   required this.url,
   required this.source,
   this.metadata,
 });
}

enum SearchEngine {
 google,
 brave,
 elastic,
 wikipedia,
}

class SearchService extends GetxService {
 final SettingsService _settings = Get.find<SettingsService>();
 
 // Service instances
 GoogleSearchService? _googleService;
 BraveSearchService? _braveService;
 ElasticSearchService? _elasticService;
 WikipediaService? _wikipediaService;
 
 // Initialize the service
 Future<SearchService> init() async {
   await _initializeEngines();
   
   // Listen to settings changes to reinitialize services
   ever(_settings.googleApiKey, (_) => _initializeGoogleService());
   ever(_settings.googleCseId, (_) => _initializeGoogleService());
   ever(_settings.googleSafeSearch, (_) => _initializeGoogleService());
   
   ever(_settings.braveApiKey, (_) => _initializeBraveService());
   ever(_settings.braveFreshness, (_) => _initializeBraveService());
   ever(_settings.braveCountry, (_) => _initializeBraveService());
   
   ever(_settings.elasticHost, (_) => _initializeElasticService());
   ever(_settings.elasticPort, (_) => _initializeElasticService());
   ever(_settings.elasticUsername, (_) => _initializeElasticService());
   ever(_settings.elasticPassword, (_) => _initializeElasticService());
   ever(_settings.elasticIndexPattern, (_) => _initializeElasticService());
   
   ever(_settings.wikipediaLanguage, (_) => _initializeWikipediaService());
   
   return this;
 }

 Future<void> _initializeEngines() async {
   _initializeGoogleService();
   _initializeBraveService();
   await _initializeElasticService();
   _initializeWikipediaService();
 }

 void _initializeGoogleService() {
   if (_settings.isGoogleEnabled.value &&
       _settings.googleApiKey.value.isNotEmpty &&
       _settings.googleCseId.value.isNotEmpty) {
     _googleService = GoogleSearchService(
       apiKey: _settings.googleApiKey.value,
       searchEngineId: _settings.googleCseId.value,
       safeSearch: _settings.googleSafeSearch.value,
       timeout: _settings.searchTimeout.value,
     );
     print('[SearchService] Google service initialized');
   } else {
     _googleService = null;
     print('[SearchService] Google service not initialized (disabled or missing credentials)');
   }
 }

 void _initializeBraveService() {
   if (_settings.isBraveEnabled.value &&
       _settings.braveApiKey.value.isNotEmpty) {
     _braveService = BraveSearchService(
       apiKey: _settings.braveApiKey.value,
       freshness: _settings.braveFreshness.value,
       country: _settings.braveCountry.value,
       timeout: _settings.searchTimeout.value,
     );
     print('[SearchService] Brave service initialized');
   } else {
     _braveService = null;
     print('[SearchService] Brave service not initialized (disabled or missing API key)');
   }
 }

 Future<void> _initializeElasticService() async {
   if (_settings.isElasticEnabled.value &&
       _settings.elasticHost.value.isNotEmpty &&
       _settings.elasticPort.value.isNotEmpty &&
       _settings.elasticIndexPattern.value.isNotEmpty) {
     
     _elasticService = ElasticSearchService(
       host: _settings.elasticHost.value,
       port: _settings.elasticPort.value,
       username: _settings.elasticUsername.value.isNotEmpty 
           ? _settings.elasticUsername.value 
           : null,
       password: _settings.elasticPassword.value.isNotEmpty 
           ? _settings.elasticPassword.value 
           : null,
       indexPattern: _settings.elasticIndexPattern.value,
       timeout: _settings.elasticTimeout.value,
     );
     
     final connected = await _elasticService!.testConnection();
     if (connected) {
       print('[SearchService] Elasticsearch service initialized and connected');
       final indices = await _elasticService!.getIndices();
       if (indices.isNotEmpty) {
         print('[SearchService] Available Elasticsearch indices: ${indices.join(', ')}');
       }
     } else {
       print('[SearchService] Elasticsearch connection failed');
       _elasticService = null;
     }
   } else {
     _elasticService = null;
     print('[SearchService] Elasticsearch service not initialized (disabled or missing configuration)');
   }
 }

 void _initializeWikipediaService() {
   if (_settings.isWikipediaEnabled.value) {
     _wikipediaService = WikipediaService(
       language: _settings.wikipediaLanguage.value,
     );
     print('[SearchService] Wikipedia service initialized');
   } else {
     _wikipediaService = null;
     print('[SearchService] Wikipedia service not initialized (disabled)');
   }
 }

 // Get the default search engine
 SearchEngine get defaultEngine {
   final engineName = _settings.defaultSearchEngine.value.toLowerCase();
   print('[SearchService] Default engine: $engineName');
   switch (engineName) {
     case 'google':
       return SearchEngine.google;
     case 'brave':
       return SearchEngine.brave;
     case 'elastic':
     case 'elasticsearch':
       return SearchEngine.elastic;
     case 'wikipedia':
        print('[SearchService] Wikipedia engine');
       return SearchEngine.wikipedia;
     default:
       print('[SearchService] Default engine not found, using fallback');
       // Fallback to first available engine
       if (_googleService != null) return SearchEngine.google;
       if (_braveService != null) return SearchEngine.brave;
       if (_elasticService != null) return SearchEngine.elastic;
       if (_wikipediaService != null) return SearchEngine.wikipedia;
       throw Exception('No search engine available');
   }
 }

 // Check if a specific engine is available
 bool isEngineAvailable(SearchEngine engine) {
   switch (engine) {
     case SearchEngine.google:
       return _googleService != null;
     case SearchEngine.brave:
       return _braveService != null;
     case SearchEngine.elastic:
       return _elasticService != null;
     case SearchEngine.wikipedia:
        print('[SearchService] Wikipedia engine ${_wikipediaService != null}');
       return _wikipediaService != null;
   }
 }

 // Get list of available engines
 List<SearchEngine> get availableEngines {
   final engines = <SearchEngine>[];
   if (_googleService != null) engines.add(SearchEngine.google);
   if (_braveService != null) engines.add(SearchEngine.brave);
   if (_elasticService != null) engines.add(SearchEngine.elastic);
   if (_wikipediaService != null) engines.add(SearchEngine.wikipedia);
   return engines;
 }

 // Main search method - uses default engine
 Future<List<UnifiedSearchResult>> search(
   String query, {
   int? limit,
   SearchEngine? engine,
   Map<String, dynamic>? filters,
   List<String>? searchFields,
 }) async {
   final selectedEngine = engine ?? defaultEngine;
   
   if (!isEngineAvailable(selectedEngine)) {
     throw Exception('Search engine ${selectedEngine.name} is not available');
   }

   print('[SearchService] Searching with ${selectedEngine.name} for: "$query"');
   
   switch (selectedEngine) {
     case SearchEngine.google:
       return _searchWithGoogle(query, limit: limit);
     case SearchEngine.brave:
       return _searchWithBrave(query, limit: limit);
     case SearchEngine.elastic:
       return _searchWithElastic(
         query, 
         limit: limit,
         filters: filters,
         searchFields: searchFields,
       );
     case SearchEngine.wikipedia:
       return _searchWithWikipedia(query, limit: limit);
   }
 }

 // Search with all available engines
 Future<Map<SearchEngine, List<UnifiedSearchResult>>> searchAll(
   String query, {
   int? limit,
 }) async {
   final results = <SearchEngine, List<UnifiedSearchResult>>{};
   
   for (final engine in availableEngines) {
     try {
       results[engine] = await search(query, limit: limit, engine: engine);
     } catch (e) {
       print('[SearchService] Error searching with ${engine.name}: $e');
       results[engine] = [];
     }
   }
   
   return results;
 }

 // Google-specific search
 Future<List<UnifiedSearchResult>> _searchWithGoogle(
   String query, {
   int? limit,
 }) async {
   if (_googleService == null) {
     throw Exception('Google service not initialized');
   }

   final googleLimit = limit ?? _settings.braveResultsPerQuery.value;
   final results = await _googleService!.search(query, limit: googleLimit);
   
   return results.map((r) => UnifiedSearchResult(
     title: r.title,
     snippet: r.snippet,
     url: r.link,
     source: 'Google',
     metadata: {
       'displayLink': r.displayLink,
       if (r.metadata != null) ...r.metadata!,
     },
   )).toList();
 }

 // Brave-specific search
 Future<List<UnifiedSearchResult>> _searchWithBrave(
   String query, {
   int? limit,
 }) async {
   if (_braveService == null) {
     throw Exception('Brave service not initialized');
   }

   final braveLimit = limit ?? _settings.braveResultsPerQuery.value;
   final results = await _braveService!.search(query, limit: braveLimit);
   
   return results.map((r) => UnifiedSearchResult(
     title: r.title,
     snippet: r.description,
     url: r.url,
     source: 'Brave',
     metadata: {
       'displayUrl': r.displayUrl,
       if (r.thumbnailUrl != null) 'thumbnail': r.thumbnailUrl,
       if (r.publishedTime != null) 'publishedTime': r.publishedTime!.toIso8601String(),
       if (r.language != null) 'language': r.language,
       if (r.extra != null) ...r.extra!,
     },
   )).toList();
 }

 // Elasticsearch-specific search
 Future<List<UnifiedSearchResult>> _searchWithElastic(
   String query, {
   int? limit,
   Map<String, dynamic>? filters,
   List<String>? searchFields,
 }) async {
   if (_elasticService == null) {
     throw Exception('Elasticsearch service not initialized');
   }

   final elasticLimit = limit ?? _settings.braveResultsPerQuery.value;
   final highlightFields = searchFields ?? ['title', 'content', 'description', 'body', 'text'];
   
   final results = await _elasticService!.search(
     query,
     limit: elasticLimit,
     searchFields: searchFields,
     highlightFields: highlightFields,
     filters: filters,
   );
   
   return results.map((r) {
     String snippet = '';
     if (r.highlights != null && r.highlights!.isNotEmpty) {
       snippet = r.highlights!.values
           .expand((fragments) => fragments)
           .join(' ... ');
     } else {
       snippet = r.content;
       if (snippet.length > 300) {
         snippet = '${snippet.substring(0, 300)}...';
       }
     }
     
     return UnifiedSearchResult(
       title: r.title,
       snippet: snippet,
       url: r.url.isNotEmpty ? r.url : 'elastic://${r.index}/${r.id}',
       source: 'Elasticsearch',
       metadata: {
         'index': r.index,
         'id': r.id,
         'score': r.score,
         if (r.timestamp != null) 'timestamp': r.timestamp!.toIso8601String(),
         'source': r.source,
       },
     );
   }).toList();
 }

 // Wikipedia-specific search
 Future<List<UnifiedSearchResult>> _searchWithWikipedia(
   String query, {
   int? limit,
 }) async {
   if (_wikipediaService == null) {
     throw Exception('Wikipedia service not initialized');
   }

   final wikiLimit = limit ?? _settings.wikipediaResultsPerQuery.value;
   final results = await _wikipediaService!.search(query, limit: wikiLimit);
   
   return results.map((r) => UnifiedSearchResult(
     title: r.title,
     snippet: r.snippet,
     url: 'https://${_settings.wikipediaLanguage.value}.wikipedia.org/wiki/${Uri.encodeComponent(r.title.replaceAll(' ', '_'))}',
     source: 'Wikipedia',
     metadata: {
       'size': r.size,
       'timestamp': r.timestamp,
     },
   )).toList();
 }

 // Get Wikipedia article with full content
 Future<WikipediaArticle?> getWikipediaArticle(
   String title, {
   bool includeSections = true,
   bool includeCategories = true,
 }) async {
   if (_wikipediaService == null) {
     throw Exception('Wikipedia service not initialized');
   }

   return await _wikipediaService!.getArticle(
     title,
     includeSections: includeSections,
     includeCategories: includeCategories,
   );
 }

 // Search news with Brave
 Future<List<UnifiedSearchResult>> searchNews(
   String query, {
   int? limit,
 }) async {
   if (_braveService == null) {
     throw Exception('Brave service not initialized (required for news search)');
   }

   final braveLimit = limit ?? _settings.braveResultsPerQuery.value;
   final results = await _braveService!.searchNews(query, limit: braveLimit);
   
   return results.map((r) => UnifiedSearchResult(
     title: r.title,
     snippet: r.description,
     url: r.url,
     source: 'Brave News',
     metadata: {
       'displayUrl': r.displayUrl,
       if (r.thumbnailUrl != null) 'thumbnail': r.thumbnailUrl,
       if (r.publishedTime != null) 'publishedTime': r.publishedTime!.toIso8601String(),
       if (r.language != null) 'language': r.language,
       if (r.extra != null) ...r.extra!,
     },
   )).toList();
 }

 // Advanced Elasticsearch features
 Future<List<UnifiedSearchResult>> searchSimilar(
   String documentId,
   String index, {
   int? limit,
 }) async {
   if (_elasticService == null) {
     throw Exception('Elasticsearch service not initialized');
   }

   final results = await _elasticService!.moreLikeThis(
     documentId,
     index,
     limit: limit ?? 10,
   );

   return results.map((r) => UnifiedSearchResult(
     title: r.title,
     snippet: r.content.length > 300 
         ? '${r.content.substring(0, 300)}...' 
         : r.content,
     url: r.url.isNotEmpty ? r.url : 'elastic://${r.index}/${r.id}',
     source: 'Elasticsearch (Similar)',
     metadata: {
       'index': r.index,
       'id': r.id,
       'score': r.score,
     },
   )).toList();
 }

 // Get Elasticsearch indices
 Future<List<String>> getElasticIndices() async {
   if (_elasticService == null) {
     return [];
   }
   return await _elasticService!.getIndices();
 }

 // Test Elasticsearch connection
 Future<bool> testElasticConnection() async {
   if (_elasticService == null) {
     return false;
   }
   return await _elasticService!.testConnection();
 }

 // Download full content
 Future<String?> getFullContent(String url) async {
   if (url.contains('wikipedia.org')) {
     final uri = Uri.parse(url);
     final pathSegments = uri.pathSegments;
     if (pathSegments.length >= 2 && pathSegments[0] == 'wiki') {
       final title = Uri.decodeComponent(pathSegments[1].replaceAll('_', ' '));
       final article = await _wikipediaService?.getArticle(title);
       return article?.extract;
     }
   }
   return null;
 }

 @override
 void onClose() {
   _wikipediaService?.dispose();
   super.onClose();
 }
}