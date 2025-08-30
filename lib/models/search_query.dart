import 'package:objectbox/objectbox.dart';

@Entity()
class SearchQuery {
  @Id()
  int id = 0;
  
  String originalQuery;
  DateTime timestamp;
  String searchProvider;
  
  // Store the final report when complete
  String? finalReport;
  
  // Basic status for UI display
  String? lastStatus; // Last status message shown in UI
  
  SearchQuery({
    this.id = 0,
    required this.originalQuery,
    DateTime? timestamp,
    required this.searchProvider,
    this.finalReport,
    this.lastStatus,
  }) : timestamp = timestamp ?? DateTime.now();
}