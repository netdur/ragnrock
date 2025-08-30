import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../models/search_query.dart';
import '../../services/objectbox_service.dart';
import '../sessions/sessions_results_controller.dart';
import '../sessions/sessions_panel_controller.dart';

class SearchScreenController extends GetxController {
  final searchTextController = TextEditingController();
  final searchFocusNode = FocusNode();
  final Rxn<SearchQuery> activeSession = Rxn<SearchQuery>();
  
  final ObjectBoxService _objectBoxService = Get.find<ObjectBoxService>();
  
  @override
  void onInit() {
    super.onInit();

    Get.put(SessionsResultsController());

    ever(activeSession, (session) {
      if (session != null) {
        if (searchTextController.text != session.originalQuery) {
          searchTextController.text = session.originalQuery;
        }
        searchFocusNode.requestFocus();
        searchTextController.selection = TextSelection.fromPosition(
          TextPosition(offset: searchTextController.text.length),
        );
      }
    });
  }

  @override
  void onReady() {
    super.onReady();
    
    // Check if there are existing sessions
    final sessionsPanelController = Get.find<SessionsPanelController>();
    if (sessionsPanelController.sessions.isEmpty) {
      startNewSearch();
    } else {
      // Set the most recent session as active
      setActiveSession(sessionsPanelController.sessions.first);
    }
  }

  @override
  void onClose() {
    searchTextController.dispose();
    searchFocusNode.dispose();
    super.onClose();
  }

  void performSearch() async {
    final searchTerm = searchTextController.text.trim();
    if (searchTerm.isEmpty) return;

    // Ensure we have an active session
    if (activeSession.value == null) {
      startNewSearch();
    }

    // Update the session
    final currentSession = activeSession.value!;
    currentSession.originalQuery = searchTerm;
    currentSession.timestamp = DateTime.now();
    currentSession.lastStatus = "Processing...";

    // Save to database
    _objectBoxService.updateSearchQuery(currentSession);
    
    // Update the sessions panel
    final sessionsPanelController = Get.find<SessionsPanelController>();
    sessionsPanelController.updateSession(currentSession);

    // Clear the search field
    searchTextController.clear();
    activeSession.refresh();
    searchFocusNode.unfocus();

    // Execute the search in SessionsResultsController
    final resultsController = Get.find<SessionsResultsController>();
    await resultsController.execute(searchTerm);
    
    // After search completes, update the session with the final report
    if (resultsController.finalReportContent.value.isNotEmpty) {
      currentSession.finalReport = resultsController.finalReportContent.value;
      currentSession.lastStatus = "Complete";
      _objectBoxService.updateSearchQuery(currentSession);
      sessionsPanelController.updateSession(currentSession);
    }
  }

  void startNewSearch() {
    final sessionsPanelController = Get.find<SessionsPanelController>();
    sessionsPanelController.startNewSearch();
    // The new session will be set as active by the panel controller
  }

  void setActiveSession(SearchQuery session) {
    activeSession.value = session;
    
    // If switching to a completed session, restore its report
    if (session.finalReport != null && session.finalReport!.isNotEmpty) {
      final resultsController = Get.find<SessionsResultsController>();
      resultsController.finalReportContent.value = session.finalReport!;
      resultsController.processStep.value = ProcessStep.completed;
    }
  }
  
  // Save the current session's report (called when report generation completes)
  void saveCurrentSessionReport(String report) {
    if (activeSession.value != null) {
      activeSession.value!.finalReport = report;
      activeSession.value!.lastStatus = "Complete";
      _objectBoxService.updateSearchQuery(activeSession.value!);
      
      final sessionsPanelController = Get.find<SessionsPanelController>();
      sessionsPanelController.updateSession(activeSession.value!);
    }
  }
}