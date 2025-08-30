import 'dart:async';
import 'dart:convert';
import 'package:get/get.dart';
import 'llm_service.dart';
import 'package:llama_cpp_dart/llama_cpp_dart.dart';

class QueryRefinerService extends GetxService {
  final LlmService _llmService = Get.find<LlmService>();
  
  // Returns list of refined queries
  Future<List<String>> refineAndSplit(String rawQuery) async {
    if (!_llmService.isReady) {
      return [rawQuery];
    }
    
    final LlamaScope scope = _llmService.getScope();
    final completer = Completer<List<String>>();
    final buffer = StringBuffer();
    late StreamSubscription streamSubscription;
    late StreamSubscription completionSubscription;
    
    completer.future.whenComplete(() {
      streamSubscription.cancel();
      completionSubscription.cancel();
      scope.dispose();
    });
    
    completionSubscription = scope.completions.listen(
      (event) {
        final queries = _parseResponse(buffer.toString(), rawQuery);
        if (!completer.isCompleted) {
          completer.complete(queries);
        }
      },
      onError: (e, st) {
        if (!completer.isCompleted) {
          completer.complete([rawQuery]);
        }
      },
    );
    
    streamSubscription = scope.stream.listen(
      (chunk) => buffer.write(chunk),
      onError: (e, st) {
        if (!completer.isCompleted) {
          completer.complete([rawQuery]);
        }
      },
    );
    
    ChatHistory history = ChatHistory();
    history.addMessage(
      role: Role.user, 
      content: _makeMultiQueryPrompt(rawQuery)
    );
    
    String llmPrompt = history.exportFormat(
      ChatFormat.gemini,
      leaveLastAssistantOpen: true,
    );
    
    await scope.sendPrompt(llmPrompt);
    return completer.future;
  }
  
  // Keep the original single refine method if needed
  Future<String> refine(String rawQuery) async {
    final queries = await refineAndSplit(rawQuery);
    return queries.first;
  }
  
  String _makeMultiQueryPrompt(String q) => '''
You are a query refinement assistant. Your task is to analyze a user's search query and produce optimized search queries.

IMPORTANT: If the query contains multiple distinct questions or topics that would benefit from separate searches, split them into individual queries.

For each query you produce:
1. Fix grammar, spelling, and typos
2. Use clear, concise keywords
3. Remove unnecessary filler words
4. Keep the search intent intact

Output format: Return a JSON array of refined queries.
- For single topics: return one refined query
- For multiple topics/comparisons: split into separate queries

Examples:
Input: "who score most goals messy or ronaldo?"
Output: ["messi total career goals", "ronaldo total career goals", "messi vs ronaldo goals comparison"]

Input: "weather tomorrow"
Output: ["weather forecast tomorrow"]

Input: "python tutorial and best laptop for programming"
Output: ["python tutorial beginners", "best laptop programming 2025"]

Original query: "$q"

Output only the JSON array, nothing else.
''';
  
  List<String> _parseResponse(String response, String fallback) {
    try {
      // Clean the response
      var cleaned = response.trim();
      
      // Remove markdown code blocks if present
      cleaned = cleaned.replaceAll(RegExp(r'```(?:json)?\s*'), '');
      cleaned = cleaned.replaceAll(RegExp(r'```'), '');
      cleaned = cleaned.trim();
      
      // Try to find JSON array in the response
      final jsonMatch = RegExp(r'\[.*\]', dotAll: true).firstMatch(cleaned);
      if (jsonMatch != null) {
        cleaned = jsonMatch.group(0)!;
      }
      
      // Parse JSON array
      final parsed = json.decode(cleaned);
      if (parsed is List && parsed.isNotEmpty) {
        return parsed
            .where((item) => item is String && item.toString().trim().isNotEmpty)
            .map((item) => item.toString().trim())
            .toList();
      }
    } catch (e) {
      // If JSON parsing fails, try to extract queries line by line
      final lines = response
          .split('\n')
          .map((line) => line.trim())
          .where((line) => line.isNotEmpty)
          .where((line) => !line.startsWith('#') && !line.startsWith('//'))
          .map((line) => _cleanQueryLine(line))
          .where((line) => line.isNotEmpty)
          .toList();
      
      if (lines.isNotEmpty) {
        return lines;
      }
    }
    
    // Fallback to original query
    return [fallback];
  }
  
  String _cleanQueryLine(String line) {
    // Remove common prefixes that might appear
    var cleaned = line;
    cleaned = cleaned.replaceFirst(RegExp(r'^\d+\.\s*'), ''); // Remove numbering
    cleaned = cleaned.replaceFirst(RegExp(r'^[-*]\s*'), ''); // Remove bullets
    cleaned = cleaned.replaceAll(RegExp(r'^"|"$'), ''); // Remove quotes
    cleaned = cleaned.replaceFirst(
      RegExp(r'^\s*(Query\s*\d*:|Refined\s*:|Search\s*:)\s*', caseSensitive: false),
      '',
    );
    return cleaned.trim();
  }
}