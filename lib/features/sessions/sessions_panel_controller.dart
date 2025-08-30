import 'package:get/get.dart';
import '../../models/search_query.dart';
import '../../services/objectbox_service.dart';
import '../search/search_screen_controller.dart';

class SessionsPanelController extends GetxController {
  final ObjectBoxService _objectBoxService = Get.find<ObjectBoxService>();
  final RxList<SearchQuery> sessions = <SearchQuery>[].obs;
  
  @override
  void onInit() {
    super.onInit();
    loadSessions();
  }
  
  void loadSessions() {
    final recentSearches = _objectBoxService.getRecentSearches(limit: 50);
    sessions.assignAll(recentSearches);
  }
  
  void startNewSearch() {
    final newSession = SearchQuery(
      originalQuery: '',
      searchProvider: 'default_provider',
    );
    
    // Save to database
    final id = _objectBoxService.saveSearchQuery(newSession);
    newSession.id = id;
    
    // Add to list at the beginning
    sessions.insert(0, newSession);
    
    // Set as active session
    final searchController = Get.find<SearchScreenController>();
    searchController.setActiveSession(newSession);
  }
  
  void selectSession(SearchQuery session) {
    final searchController = Get.find<SearchScreenController>();
    searchController.setActiveSession(session);
  }
  
  void deleteSession(SearchQuery session) {
    _objectBoxService.deleteSearchQuery(session.id);
    sessions.remove(session);
    
    // If this was the active session, start a new one
    final searchController = Get.find<SearchScreenController>();
    if (searchController.activeSession.value?.id == session.id) {
      startNewSearch();
    }
  }
  
  void refreshSessions() {
    loadSessions();
  }
  
  // Called when a session is updated (e.g., after search completes)
  void updateSession(SearchQuery session) {
    _objectBoxService.updateSearchQuery(session);
    
    // Update in the list
    final index = sessions.indexWhere((s) => s.id == session.id);
    if (index != -1) {
      sessions[index] = session;
    }
  }
}