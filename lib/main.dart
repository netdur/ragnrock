import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'features/sessions/sessions_panel_controller.dart';
import 'services/objectbox_service.dart';
import 'services/search_service.dart' show SearchService;
import 'services/settings_service.dart';
import 'services/llm_service.dart';
import 'services/query_refiner_service.dart';
import 'app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize ObjectBoxService and wait for it
  final objectBoxService = Get.put<ObjectBoxService>(ObjectBoxService(), permanent: true);
  await objectBoxService.init(); // <-- Add this line!
  
  Get.put<SettingsService>(SettingsService(), permanent: true);
  Get.put<LlmService>(LlmService(), permanent: true);
  Get.putAsync<SearchService>(() async => await SearchService().init());
  Get.put(SessionsPanelController());
  Get.put<QueryRefinerService>(QueryRefinerService(), permanent: true);
  
  runApp(const RagnrockApp());
}