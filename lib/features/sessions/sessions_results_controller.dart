// ignore_for_file: avoid_print

import 'dart:async';
import 'package:get/get.dart';
import 'package:llama_cpp_dart/llama_cpp_dart.dart';
import 'package:ragnrock/services/search_service.dart';
import 'package:ragnrock/services/settings_service.dart';
import '../../services/llm_service.dart';
import '../../services/query_refiner_service.dart';

enum ProcessStep {
  idle,
  refining,
  searching,
  downloading,
  generating,
  completed,
  error,
}

enum DownloadStatus { pending, downloading, analyzing, completed, failed }

class SearchResult {
  final String query;
  final List<UnifiedSearchResult> results;
  final List<dynamic> articles; // Can be WikipediaArticle or other content
  final Rx<DownloadStatus> status;

  SearchResult({
    required this.query,
    List<UnifiedSearchResult>? results,
    List<dynamic>? articles,
    DownloadStatus initialStatus = DownloadStatus.pending,
  })  : results = results ?? [],
        articles = articles ?? [],
        status = initialStatus.obs;
}

class SessionsResultsController extends GetxController {
  final QueryRefinerService _queryRefiner = Get.find();
  final LlmService _llmService = Get.find<LlmService>();
  final SettingsService _settings = Get.find<SettingsService>();
  final SearchService _searchService = Get.find<SearchService>();

  // --- UI State Observables ---
  final processStep = ProcessStep.idle.obs;
  final refinedQueries = <String>[].obs;
  final searchResults = <SearchResult>[].obs;
  final searchStatus = ''.obs;
  final finalReportContent = ''.obs;
  final errorMessage = ''.obs;

  // Progress tracking
  final currentProgress = ''.obs;
  final progressDetail = ''.obs;

  // Private state
  String _originalPrompt = "";
  LlamaScope? _activeScope;
  StreamSubscription<String>? _streamSubscription;
  StreamSubscription<dynamic>? _completionSubscription;
  final _reportBuffer = StringBuffer();

  // Configuration constants
  static const int _articlesPerQuery = 2; // Top N articles to download per query

  Future<void> execute(String prompt) async {
    _originalPrompt = prompt;
    print('[SessionsResults] Starting with prompt: "$prompt"');

    try {
      await resetProcessState(starting: true);

      // Step 1: Refine query
      await _refineQuery(prompt);

      // Step 2: Search using configured engine
      await _searchAllQueries();

      // Step 3: Download/process articles
      await _downloadArticles();

      // Step 4: Generate report (UI moves to completed inside the completion event)
      await _generateReport();

      // Final confirmation (idempotent if already set by completion handler)
      processStep.value = ProcessStep.completed;
      searchStatus.value = 'Search completed successfully!';
      currentProgress.value = 'Complete';
      progressDetail.value = '';
      print('[SessionsResults] Process completed successfully');
    } catch (e) {
      print('[SessionsResults] Error: $e');
      processStep.value = ProcessStep.error;
      errorMessage.value = e.toString();
      searchStatus.value = 'Search failed: ${e.toString()}';
      currentProgress.value = 'Error';
      progressDetail.value = e.toString();
      await _cleanupScope();
    }
  }

  Future<void> _refineQuery(String prompt) async {
    processStep.value = ProcessStep.refining;
    searchStatus.value = 'Refining search queries...';
    currentProgress.value = 'Analyzing query...';
    progressDetail.value = '';

    final queries = await _queryRefiner.refineAndSplit(prompt);
    print('[SessionsResults] Refined into ${queries.length} queries: $queries');

    refinedQueries.assignAll(queries);
    searchResults.assignAll(queries.map((q) => SearchResult(query: q)).toList());

    currentProgress.value = 'Ready to search';
    progressDetail.value = '${queries.length} search queries prepared';
  }

  Future<void> _searchAllQueries() async {
    processStep.value = ProcessStep.searching;

    final engineName = _searchService.defaultEngine.name;
    searchStatus.value = 'Searching with $engineName...';

    final searchLimit = _searchService.defaultEngine == SearchEngine.wikipedia
        ? _settings.wikipediaResultsPerQuery.value
        : _settings.braveResultsPerQuery.value;

    for (int i = 0; i < searchResults.length; i++) {
      final searchResult = searchResults[i];
      currentProgress.value = 'Searching ${i + 1}/${searchResults.length}';
      progressDetail.value = searchResult.query;

      searchResult.status.value = DownloadStatus.downloading;

      try {
        final results = await _searchService.search(
          searchResult.query,
          limit: searchLimit,
        );

        print(
          '[SessionsResults] Query "${searchResult.query}" found ${results.length} results from $engineName',
        );

        searchResult.results
          ..clear()
          ..addAll(results);
        searchResult.status.value = DownloadStatus.completed;
      } catch (e) {
        print('[SessionsResults] Search failed for "${searchResult.query}": $e');
        searchResult.status.value = DownloadStatus.failed;
      }
    }

    final successfulSearches =
        searchResults.where((sr) => sr.status.value == DownloadStatus.completed).length;
    currentProgress.value = 'Search complete';
    progressDetail.value = '$successfulSearches/${searchResults.length} searches successful';
  }

  Future<void> _downloadArticles() async {
    processStep.value = ProcessStep.downloading;
    searchStatus.value = 'Processing content...';

    int totalArticles = 0;
    int downloadedArticles = 0;

    for (final searchResult in searchResults) {
      if (searchResult.status.value == DownloadStatus.completed) {
        totalArticles += searchResult.results.take(_articlesPerQuery).length;
      }
    }

    for (final searchResult in searchResults) {
      if (searchResult.status.value != DownloadStatus.completed) continue;

      searchResult.status.value = DownloadStatus.analyzing;
      final articlesToDownload = searchResult.results.take(_articlesPerQuery).toList();

      for (final result in articlesToDownload) {
        downloadedArticles++;
        currentProgress.value = 'Processing $downloadedArticles/$totalArticles';
        progressDetail.value = result.title;

        try {
          if (result.source == 'Wikipedia') {
            final article = await _searchService.getWikipediaArticle(
              result.title,
              includeSections: true,
              includeCategories: true,
            );
            if (article != null) {
              searchResult.articles.add(article);
              print('[SessionsResults] Downloaded Wikipedia article: "${result.title}"');
            }
          } else {
            searchResult.articles.add({
              'title': result.title,
              'extract': result.snippet,
              'url': result.url,
              'source': result.source,
              'metadata': result.metadata,
            });
            print('[SessionsResults] Processed ${result.source} result: "${result.title}"');
          }
        } catch (e) {
          print('[SessionsResults] Failed to process "${result.title}": $e');
        }
      }

      searchResult.status.value = DownloadStatus.completed;
    }

    currentProgress.value = 'Processing complete';
    progressDetail.value =
        '${searchResults.fold(0, (sum, sr) => sum + sr.articles.length)} items processed';
  }

  /// Pure event-driven generation: relies on `completions.listen` "done" event.
  Future<void> _generateReport() async {
    processStep.value = ProcessStep.generating;
    searchStatus.value = 'Generating final report...';
    currentProgress.value = 'Generating report...';
    progressDetail.value = 'Analyzing ${_getTotalArticleCount()} sources';

    final reportData = _prepareReportData();

    _activeScope = _llmService.getScope();
    _reportBuffer.clear();
    finalReportContent.value = '';

    final completer = Completer<void>();

    // Token stream -> live UI updates
    _streamSubscription = _activeScope!.stream.listen(
      (text) {
        _reportBuffer.write(text);
        finalReportContent.value = _reportBuffer.toString();
      },
      onError: (error) {
        print('[SessionsResults] Stream error: $error');
        if (!completer.isCompleted) completer.completeError(error);
      },
      cancelOnError: true,
    );

    // SPECIAL "DONE" EVENT — your canonical source of truth
    _completionSubscription = _activeScope!.completions.listen(
      (event) {
        // event.success / event.error as provided by your lib
        final ok = (event as dynamic).success == true;

        if (ok) {
          progressDetail.value = 'Report ready';
          currentProgress.value = 'Complete';
          // You can also set completed here; execute() will set it again after return.
          // processStep.value = ProcessStep.completed;
        } else {
          final err = (event as dynamic).error?.toString() ?? 'Generation failed';
          errorMessage.value = err;
          processStep.value = ProcessStep.error;
          searchStatus.value = 'Search failed: $err';
          currentProgress.value = 'Error';
          progressDetail.value = err;
        }

        if (!completer.isCompleted) completer.complete();
      },
      onError: (error) {
        print('[SessionsResults] Completion error: $error');
        if (!completer.isCompleted) completer.completeError(error);
      },
      onDone: () {
        // In case the stream closes without an event (defensive)
        if (!completer.isCompleted) completer.complete();
      },
      cancelOnError: true,
    );

    // Build and send prompt
    final prompt = _buildReportPrompt(reportData);
    print('[SessionsResults] Sending report prompt; total sources: ${_getTotalArticleCount()}');
    print('[SessionsResults] Prompt length: ${prompt.length} chars');

    final history = ChatHistory()
      ..addMessage(role: Role.user, content: prompt)
      ..addMessage(role: Role.assistant, content: "");

    // Your examples keep the last assistant open and still receive the completion event.
    await _activeScope!.sendPrompt(
      history.exportFormat(ChatFormat.gemini, leaveLastAssistantOpen: true),
    );

    // Wait strictly for your completion signal (no timers)
    try {
      await completer.future;
    } finally {
      await _cleanupScope();
    }
  }

  Future<void> _cleanupScope() async {
    final s1 = _streamSubscription?.cancel();
    final s2 = _completionSubscription?.cancel();
    _streamSubscription = null;
    _completionSubscription = null;

    _activeScope?.dispose();
    _activeScope = null;

    await Future.wait([
      if (s1 != null) s1,
      if (s2 != null) s2,
    ]);
  }

  String _prepareReportData() {
    final buffer = StringBuffer();
    buffer.writeln('# Search Report\n');
    buffer.writeln('## Original Query: $_originalPrompt\n');
    buffer.writeln('## Refined Queries:');
    for (final query in refinedQueries) {
      buffer.writeln('- $query');
    }
    buffer.writeln();

    print('[SessionsResults] Preparing report data with the following sources:');
    for (final searchResult in searchResults) {
      print('  - Query: "${searchResult.query}"');
      print('    Sources found: ${searchResult.articles.length}');
      for (final article in searchResult.articles) {
        if (article is Map) {
          print('      * "${article['title']}" from ${article['source']} (${article['url']})');
        } else {
          print('      * "${article.title}" from ${article.url ?? "Wikipedia"}');
        }
      }
    }

    for (final searchResult in searchResults) {
      buffer.writeln('## Query: ${searchResult.query}\n');

      if (searchResult.articles.isNotEmpty) {
        buffer.writeln('### Sources Found (${searchResult.articles.length}):\n');

        for (final article in searchResult.articles) {
          if (article is Map) {
            buffer.writeln('**${article['title']}**');
            buffer.writeln('Source: ${article['source']}');
            buffer.writeln('URL: ${article['url']}');
            final extract = article['extract'];
            if (extract != null && extract is String && extract.isNotEmpty) {
              buffer.writeln('\nSummary:');
              buffer.writeln(extract);
            }
            buffer.writeln();
          } else {
            buffer.writeln('**${article.title}**');
            if (article.url != null) buffer.writeln('URL: ${article.url}');
            if (article.extract != null && article.extract!.isNotEmpty) {
              buffer.writeln('\nSummary:');
              buffer.writeln(article.extract!);
            }
            if (article.sections.isNotEmpty) {
              buffer.writeln('\nSections: ${article.sections.map((s) => s.title).join(', ')}');
            }
            buffer.writeln();
          }
        }
      } else {
        buffer.writeln('No sources found for this query.\n');
      }
    }

    return buffer.toString();
  }

  String _buildReportPrompt(String reportData) {
    print('[SessionsResults] Building report prompt with research data from:');
    final lines = reportData.split('\n');
    bool inSourcesSection = false;
    for (final line in lines) {
      if (line.contains('### Sources Found')) {
        inSourcesSection = true;
        continue;
      }
      if (inSourcesSection && line.startsWith('**') && line.contains('**')) {
        final title = line.substring(2, line.indexOf('**', 2));
        print('  - Source: "$title"');
      }
    }

    return '''You are a sharp, friendly blogger. Write a short, engaging blog post that answers: "$_originalPrompt".

Hard rules:
- Start writing immediately. First line must be: **TL;DR:** (no text before it).
- TL;DR section should not have words salade, it must answwer users quetion straight and short.
- No prefaces or meta language (e.g., "let's", "here's a draft", "based on the data", "I will…").
- Don't mention the prompt, research, limitations, or instructions.
- 500–700 words, conversational and crisp; no corporate tone.
- Organize by themes; include only essential stats.
- Cite facts with inline markdown links.
- No tables.

Format (Markdown to follow exactly):
**TL;DR:** 1–2 sentences
## [Theme 1]
2–3 short sentences, optional brief bullets
## [Theme 2–3]
Short paragraphs
> One striking quote or stat (with source)
## So what?
3–5 concrete next steps
**Sources**
- [Name](url)
- [Name](url)

Research Data:
$reportData

Write the post now, starting with the TL;DR line immediately.''';
  }

  int _getTotalArticleCount() {
    return searchResults.fold(0, (sum, sr) => sum + sr.articles.length);
  }

  Future<void> resetProcessState({bool starting = false}) async {
    processStep.value = starting ? ProcessStep.refining : ProcessStep.idle;
    refinedQueries.clear();
    searchResults.clear();
    searchStatus.value = '';
    finalReportContent.value = '';
    errorMessage.value = '';
    currentProgress.value = '';
    progressDetail.value = '';
    _reportBuffer.clear();

    // Preserve prompt when starting a fresh run; clear only when fully resetting.
    if (!starting) _originalPrompt = '';

    await _cleanupScope(); // await to avoid late events from prior runs
  }

  Future<void> cancelOperation() async {
    print('[SessionsResults] Operation cancelled by user');
    await _activeScope?.stop();
    // await _activeScope?.dispose();
    processStep.value = ProcessStep.idle;
    currentProgress.value = 'Cancelled';
    progressDetail.value = '';
  }

  @override
  void onClose() {
    print('[SessionsResults] Controller closing');
    _cleanupScope();
    super.onClose();
  }
}
