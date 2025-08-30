// ignore_for_file: avoid_print

import 'dart:convert';
import 'dart:io';
import 'package:get/get.dart';
import 'package:path_provider/path_provider.dart';
class SettingsService extends GetxService {
  late File _settingsFile;
  final isGoogleEnabled = true.obs;
  final googleApiKey = ''.obs;
  final googleCseId = ''.obs;
  final googleSafeSearch = 'Moderate'.obs;
  final isBraveEnabled = false.obs;
  final braveApiKey = ''.obs;
  final braveResultsPerQuery = 20.obs;
  final braveFreshness = 'All Time'.obs;
  final braveCountry = 'All Countries'.obs;
  final isElasticEnabled = false.obs;
  final elasticHost = 'localhost'.obs;
  final elasticPort = '9200'.obs;
  final elasticUsername = ''.obs;
  final elasticPassword = ''.obs;
  final elasticIndexPattern = ''.obs;
  final elasticTimeout = 30.obs;
  
  // Wikipedia settings
  final isWikipediaEnabled = true.obs;
  final wikipediaLanguage = 'en'.obs;
  final wikipediaResultsPerQuery = 10.obs;
  final wikipediaLanguageOptions = ['en', 'es', 'fr', 'de', 'ja', 'zh', 'ru', 'it', 'pt', 'fa'];
  
  final defaultSearchEngine = 'Google'.obs;
  final searchTimeout = 30.obs;
  final retryAttempts = 3.obs;
  final modelPath = ''.obs;
  final visionModelPath = ''.obs;
  final contextSize = 4096.obs;
  final temperature = 0.8.obs;
  final topP = 0.95.obs;
  final topK = 40.obs;
  final repeatPenalty = 1.1.obs;
  final cpuThreads = 4.obs;
  final gpuLayers = (-1).obs; 
  final batchSize = 512.obs;
  final selectedPromptTemplate = 'ChatML'.obs;
  final promptTemplates = ['ChatML', 'Alpaca', 'Gemma', 'Harmony'];
  final safeSearchLevels = ['Off', 'Moderate', 'Strict'];
  final freshnessOptions = ['All Time', 'Last 24 Hours', 'Last Week', 'Last Month', 'Last Year'];
  final countryOptions = ['All Countries', 'US', 'GB', 'DE', 'FR']; 
  Future<SettingsService> init() async {
    await _initFilePath();
    await loadSettings();
    return this;
  }
  Future<void> _initFilePath() async {
    try {
      final supportDir = await getApplicationSupportDirectory();
      final appDir = Directory('${supportDir.path}/Ragnrock');
      if (!await appDir.exists()) {
        await appDir.create(recursive: true);
      }
      _settingsFile = File('${appDir.path}/settings.json');
      print('Settings file path: ${_settingsFile.path}');
    } catch (e) {
      print("Error initializing settings file path: $e");
    }
  }
  Future<void> saveSettings() async {
    try {
      final settingsMap = {
        'search': {
          'google_enabled': isGoogleEnabled.value,
          'google_api_key': googleApiKey.value,
          'google_cse_id': googleCseId.value,
          'google_safe_search': googleSafeSearch.value,
          'brave_enabled': isBraveEnabled.value,
          'brave_api_key': braveApiKey.value,
          'brave_results_per_query': braveResultsPerQuery.value,
          'brave_freshness': braveFreshness.value,
          'brave_country': braveCountry.value,
          'elastic_enabled': isElasticEnabled.value,
          'elastic_host': elasticHost.value,
          'elastic_port': elasticPort.value,
          'elastic_username': elasticUsername.value,
          'elastic_password': elasticPassword.value,
          'elastic_index_pattern': elasticIndexPattern.value,
          'elastic_timeout': elasticTimeout.value,
          
          // Wikipedia settings
          'wikipedia_enabled': isWikipediaEnabled.value,
          'wikipedia_language': wikipediaLanguage.value,
          'wikipedia_results_per_query': wikipediaResultsPerQuery.value,
          
          'default_search_engine': defaultSearchEngine.value,
          'search_timeout': searchTimeout.value,
          'retry_attempts': retryAttempts.value,
        },
        'llm': {
          'model_path': modelPath.value,
          'vision_model_path': visionModelPath.value,
          'context_size': contextSize.value,
          'temperature': temperature.value,
          'top_p': topP.value,
          'top_k': topK.value,
          'repeat_penalty': repeatPenalty.value,
          'cpu_threads': cpuThreads.value,
          'gpu_layers': gpuLayers.value,
          'batch_size': batchSize.value,
          'prompt_template': selectedPromptTemplate.value,
        },
      };
      const encoder = JsonEncoder.withIndent('  ');
      final jsonString = encoder.convert(settingsMap);
      await _settingsFile.writeAsString(jsonString);
      print('Settings saved successfully.');
    } catch (e) {
      print('Error saving settings: $e');
    }
  }
  Future<void> loadSettings() async {
    try {
      if (!await _settingsFile.exists() || (await _settingsFile.readAsString()).isEmpty) {
        print('Settings file not found or empty. Using default values.');
        return;
      }
      final jsonString = await _settingsFile.readAsString();
      final settingsMap = jsonDecode(jsonString) as Map<String, dynamic>;
      final search = settingsMap['search'] as Map<String, dynamic>? ?? {};
      isGoogleEnabled.value = search['google_enabled'] ?? true;
      googleApiKey.value = search['google_api_key'] ?? '';
      googleCseId.value = search['google_cse_id'] ?? '';
      googleSafeSearch.value = search['google_safe_search'] ?? 'Moderate';
      isBraveEnabled.value = search['brave_enabled'] ?? false;
      braveApiKey.value = search['brave_api_key'] ?? '';
      braveResultsPerQuery.value = search['brave_results_per_query'] ?? 20;
      braveFreshness.value = search['brave_freshness'] ?? 'All Time';
      braveCountry.value = search['brave_country'] ?? 'All Countries';
      isElasticEnabled.value = search['elastic_enabled'] ?? false;
      elasticHost.value = search['elastic_host'] ?? 'localhost';
      elasticPort.value = search['elastic_port'] ?? '9200';
      elasticUsername.value = search['elastic_username'] ?? '';
      elasticPassword.value = search['elastic_password'] ?? '';
      elasticIndexPattern.value = search['elastic_index_pattern'] ?? '';
      elasticTimeout.value = search['elastic_timeout'] ?? 30;
      
      // Load Wikipedia settings
      isWikipediaEnabled.value = search['wikipedia_enabled'] ?? true;
      wikipediaLanguage.value = search['wikipedia_language'] ?? 'en';
      wikipediaResultsPerQuery.value = search['wikipedia_results_per_query'] ?? 10;
      
      defaultSearchEngine.value = search['default_search_engine'] ?? 'Google';
      searchTimeout.value = search['search_timeout'] ?? 30;
      retryAttempts.value = search['retry_attempts'] ?? 3;
      final llm = settingsMap['llm'] as Map<String, dynamic>? ?? {};
      modelPath.value = llm['model_path'] ?? '';
      visionModelPath.value = llm['vision_model_path'] ?? '';
      contextSize.value = llm['context_size'] ?? 4096;
      temperature.value = llm['temperature'] ?? 0.8;
      topP.value = llm['top_p'] ?? 0.95;
      topK.value = llm['top_k'] ?? 40;
      repeatPenalty.value = llm['repeat_penalty'] ?? 1.1;
      cpuThreads.value = llm['cpu_threads'] ?? 4;
      gpuLayers.value = llm['gpu_layers'] ?? -1;
      batchSize.value = llm['batch_size'] ?? 512;
      selectedPromptTemplate.value = llm['prompt_template'] ?? 'ChatML';
      print('Settings loaded successfully.');
    } catch (e) {
      print('Error loading settings: $e');
    }
  }
}