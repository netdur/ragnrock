import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:file_picker/file_picker.dart';
import 'package:ragnrock/services/llm_service.dart';
import 'package:ragnrock/services/settings_service.dart';
class SettingsController extends GetxController {
  final SettingsService settings = Get.find<SettingsService>();
  final LlmService llm = Get.find<LlmService>();
  final selectedTabIndex = 0.obs;
  void saveSettings() {
    settings.saveSettings();
  }
  void applyAndReloadLlm() {
    saveSettings();
    llm.reloadModel();
  }
  void resetToDefaults() {
    Get.defaultDialog(
      title: 'Reset Settings',
      middleText: 'Are you sure you want to reset all settings to their default values?',
      textConfirm: 'Reset', textCancel: 'Cancel', confirmTextColor: Colors.white,
      buttonColor: Colors.red,
      onConfirm: () {
        _performReset();
        Get.back();
      },
    );
  }
  void _performReset() {
    settings.isGoogleEnabled.value = true;
    settings.googleApiKey.value = '';
    settings.googleCseId.value = '';
    settings.googleSafeSearch.value = 'Moderate';
    settings.isBraveEnabled.value = false;
    settings.braveApiKey.value = '';
    settings.braveResultsPerQuery.value = 20;
    settings.braveFreshness.value = 'All Time';
    settings.braveCountry.value = 'All Countries';
    settings.isElasticEnabled.value = false;
    settings.elasticHost.value = 'localhost';
    settings.elasticPort.value = '9200';
    settings.elasticUsername.value = '';
    settings.elasticPassword.value = '';
    settings.elasticIndexPattern.value = '';
    settings.elasticTimeout.value = 30;
    
    // Reset Wikipedia settings
    settings.isWikipediaEnabled.value = true;
    settings.wikipediaLanguage.value = 'en';
    settings.wikipediaResultsPerQuery.value = 10;
    
    settings.defaultSearchEngine.value = 'Google';
    settings.searchTimeout.value = 30;
    settings.retryAttempts.value = 3;
    settings.modelPath.value = '';
    settings.visionModelPath.value = '';
    settings.contextSize.value = 4096;
    settings.temperature.value = 0.8;
    settings.topP.value = 0.95;
    settings.topK.value = 40;
    settings.repeatPenalty.value = 1.1;
    settings.cpuThreads.value = 4;
    settings.gpuLayers.value = -1;
    settings.batchSize.value = 512;
    settings.selectedPromptTemplate.value = 'ChatML';
  }
  Future<void> pickModelFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(dialogTitle: 'Select Language Model');
      if (result != null && result.files.single.path != null) {
        settings.modelPath.value = result.files.single.path!;
      }
    } catch (_) {}
  }
  Future<void> pickVisionModelFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(dialogTitle: 'Select Vision Model');
      if (result != null && result.files.single.path != null) {
        settings.visionModelPath.value = result.files.single.path!;
      }
    } catch (_) {}
  }
}