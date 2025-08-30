import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:url_launcher/url_launcher.dart';
import 'sessions_results_controller.dart';
import '../search/search_screen_controller.dart';
import '../sessions/sessions_panel_controller.dart'; // Add this import

class SessionResult extends StatefulWidget {
  const SessionResult({super.key});

  @override
  State<SessionResult> createState() => _SessionResultState();
}

class _SessionResultState extends State<SessionResult> with SingleTickerProviderStateMixin {
  bool _isExpanded = true;
  final SessionsResultsController controller = Get.find();
  final SearchScreenController searchController = Get.find();
  
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    _animationController.forward();
    
    // Start the flow automatically when a session is selected
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final session = searchController.activeSession.value;
      if (session != null && controller.processStep.value == ProcessStep.idle) {
        controller.execute(session.originalQuery);
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  String getHeaderText() {
    final progress = controller.currentProgress.value;
    if (progress.isNotEmpty) return progress;
    
    switch (controller.processStep.value) {
      case ProcessStep.idle:
        return "Ready to search";
      case ProcessStep.refining:
        return "Thinking...";
      case ProcessStep.searching:
        return "Searching Wikipedia...";
      case ProcessStep.downloading:
        return "Downloading articles...";
      case ProcessStep.generating:
        return "Generating Report...";
      case ProcessStep.completed:
        return "Report Complete ✓";
      case ProcessStep.error:
        return "Error Occurred ✗";
    }
  }

  Color getHeaderColor() {
    switch (controller.processStep.value) {
      case ProcessStep.completed:
        return Colors.green;
      case ProcessStep.error:
        return Colors.red;
      case ProcessStep.idle:
        return Colors.grey;
      default:
        return Colors.blue;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final session = searchController.activeSession.value;
      if (session == null) {
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Text(
              "No session selected",
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
        );
      }

      return SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- MODIFIED SECTION: Original Query with Context Menu ---
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: SelectableText(
                      session.originalQuery.isEmpty ? "New Search" : session.originalQuery,
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert),
                    onSelected: (String value) async {
                      if (value == 'delete') {
                        final confirm = await showDialog<bool>(
                          context: context,
                          builder: (BuildContext context) {
                            return AlertDialog(
                              title: const Text("Delete Search"),
                              content: Text(
                                "Delete \"${session.originalQuery.isEmpty ? 'New Search' : session.originalQuery}\"?\n\nThis action cannot be undone.",
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.of(context).pop(false),
                                  child: const Text("Cancel"),
                                ),
                                TextButton(
                                  onPressed: () => Navigator.of(context).pop(true),
                                  child: const Text(
                                    "Delete", 
                                    style: TextStyle(color: Colors.red),
                                  ),
                                ),
                              ],
                            );
                          },
                        );
                        
                        if (confirm == true) {
                          final sessionsPanelController = Get.find<SessionsPanelController>();
                          sessionsPanelController.deleteSession(session);
                        }
                      }
                    },
                    itemBuilder: (BuildContext context) => [
                      const PopupMenuItem<String>(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete_outline, color: Colors.red, size: 20),
                            SizedBox(width: 8),
                            Text('Delete', style: TextStyle(color: Colors.red)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              // --- END MODIFIED SECTION ---
              const SizedBox(height: 16), // Adjusted spacing

              // Expandable process panel
              Card(
                elevation: 2,
                child: Theme(
                  data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                  child: ExpansionTile(
                    initiallyExpanded: _isExpanded,
                    onExpansionChanged: (expanded) {
                      setState(() => _isExpanded = expanded);
                    },
                    leading: _getProcessIcon(),
                    title: Text(
                      getHeaderText(),
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: getHeaderColor(),
                      ),
                    ),
                    subtitle: controller.progressDetail.value.isNotEmpty
                        ? Padding(
                            padding: const EdgeInsets.only(top: 4.0),
                            child: Text(
                              controller.progressDetail.value,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                          )
                        : null,
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                        child: _buildProcessSteps(),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Final report or generating indicator
              if (controller.processStep.value == ProcessStep.generating &&
                  controller.finalReportContent.value.isNotEmpty)
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.blue.withValues(alpha: .05),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue.withValues(alpha: 0.2)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            "Generating Report...",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.blue.shade700,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      MarkdownBody(
                        data: controller.finalReportContent.value,
                        selectable: true,
                        onTapLink: (text, href, title) {
                          if (href != null) {
                            launchUrl(Uri.parse(href));
                          }
                        },
                        styleSheet: _getMarkdownStyleSheet(context),
                      ),
                    ],
                  ),
                ),

              // Final report - shows when completed
              if (controller.processStep.value == ProcessStep.completed &&
                  controller.finalReportContent.value.isNotEmpty)
                AnimatedContainer(
                  duration: const Duration(milliseconds: 500),
                  curve: Curves.easeInOut,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: .05),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.green.withValues(alpha: .2)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.check_circle, color: Colors.green, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            "Report",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.green.shade700,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      MarkdownBody(
                        data: controller.finalReportContent.value,
                        selectable: true,
                        onTapLink: (text, href, title) {
                          if (href != null) {
                            launchUrl(Uri.parse(href));
                          }
                        },
                        styleSheet: _getMarkdownStyleSheet(context),
                      ),
                    ],
                  ),
                ),
              
              // Error display
              if (controller.processStep.value == ProcessStep.error)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: .05),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red.withValues(alpha: .2)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline, color: Colors.red),
                      const SizedBox(width: 12),
                      Expanded(
                        child: SelectableText(
                          controller.errorMessage.value,
                          style: TextStyle(color: Colors.red.shade700),
                        ),
                      ),
                    ],
                  ),
                ),

              // Cancel button during processing
              if (controller.processStep.value != ProcessStep.idle &&
                  controller.processStep.value != ProcessStep.completed &&
                  controller.processStep.value != ProcessStep.error)
                Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: Center(
                    child: TextButton.icon(
                      onPressed: () => controller.cancelOperation(),
                      icon: const Icon(Icons.cancel),
                      label: const Text("Cancel"),
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.red,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      );
    });
  }

  Widget _getProcessIcon() {
    switch (controller.processStep.value) {
      case ProcessStep.idle:
        return const Icon(Icons.circle_outlined, color: Colors.grey);
      case ProcessStep.completed:
        return const Icon(Icons.check_circle, color: Colors.green);
      case ProcessStep.error:
        return const Icon(Icons.error, color: Colors.red);
      default:
        return const SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(
            strokeWidth: 2.5,
            valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
          ),
        );
    }
  }

  Widget _buildProcessSteps() {
    List<Widget> steps = [];

    // Step 1: Refined Queries
    if (controller.refinedQueries.isNotEmpty) {
      steps.add(_buildStepTile(
        icon: const Icon(Icons.check_circle, color: Colors.green),
        title: "Refined Queries (${controller.refinedQueries.length})",
        subtitle: controller.refinedQueries.join(', '),
        isCompleted: true,
      ));
    }

    // Step 2: Search Results
    if (controller.searchResults.isNotEmpty) {
      int successfulSearches = controller.searchResults
          .where((sr) => sr.status.value == DownloadStatus.completed)
          .length;
      
      steps.add(_buildStepTile(
        icon: const Icon(Icons.check_circle, color: Colors.green),
        title: "Search Results",
        subtitle: "$successfulSearches/${controller.searchResults.length} queries successful",
        isCompleted: controller.processStep.value.index > ProcessStep.searching.index,
      ));

      if (_isExpanded && controller.searchResults.isNotEmpty) {
        steps.add(const SizedBox(height: 8));
        for (var searchResult in controller.searchResults) {
          steps.add(_buildSearchResultItem(searchResult));
        }
      }
    }

    // Step 3: Current activity indicator
    if (controller.processStep.value == ProcessStep.downloading) {
      steps.add(_buildStepTile(
        icon: const SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(
            strokeWidth: 2.5,
            valueColor: AlwaysStoppedAnimation<Color>(Colors.orange),
          ),
        ),
        title: "Downloading Articles",
        subtitle: controller.progressDetail.value,
        isCompleted: false,
      ));
    }

    // Step 4: Generating Report
    if (controller.processStep.value == ProcessStep.generating) {
      steps.add(_buildStepTile(
        icon: const SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(
            strokeWidth: 2.5,
            valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
          ),
        ),
        title: "Generating Report",
        subtitle: controller.progressDetail.value,
        isCompleted: false,
      ));
    }

    // Step 5: Completed
    if (controller.processStep.value == ProcessStep.completed) {
      steps.add(_buildStepTile(
        icon: const Icon(Icons.check_circle, color: Colors.green),
        title: "Report Generated",
        subtitle: "Analysis complete",
        isCompleted: true,
      ));
    }

    if (steps.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Text(
            "Ready to start...",
            style: TextStyle(color: Colors.grey),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: steps,
    );
  }

  Widget _buildStepTile({
    required Widget icon,
    required String title,
    required String subtitle,
    required bool isCompleted,
  }) {
    return ListTile(
      leading: icon,
      title: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.w500,
          color: isCompleted ? Colors.black87 : Colors.black54,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          color: Colors.grey[600],
          fontSize: 13,
        ),
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
      dense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 0),
    );
  }

  Widget _buildSearchResultItem(SearchResult result) {
    return Obx(() {
      final status = result.status.value;
      
      Widget leadingWidget;
      Color statusColor = Colors.grey;
      
      switch (status) {
        case DownloadStatus.pending:
          leadingWidget = const Icon(Icons.schedule, color: Colors.grey, size: 16);
          statusColor = Colors.grey;
          break;
        case DownloadStatus.downloading:
        case DownloadStatus.analyzing:
          leadingWidget = const SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
            ),
          );
          statusColor = Colors.blue;
          break;
        case DownloadStatus.completed:
          leadingWidget = const Icon(Icons.check_circle, color: Colors.green, size: 16);
          statusColor = Colors.green;
          break;
        case DownloadStatus.failed:
          leadingWidget = const Icon(Icons.error_outline, color: Colors.red, size: 16);
          statusColor = Colors.red;
          break;
      }
      
      return Padding(
        padding: const EdgeInsets.only(left: 40, right: 0, top: 2, bottom: 2),
        child: Row(
          children: [
            leadingWidget,
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                result.query,
                style: TextStyle(
                  fontSize: 12,
                  color: statusColor,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (result.articles.isNotEmpty)
              Text(
                '${result.articles.length} articles',
                style: const TextStyle(
                  fontSize: 11,
                  color: Colors.grey,
                ),
              ),
          ],
        ),
      );
    });
  }
  
  MarkdownStyleSheet _getMarkdownStyleSheet(BuildContext context) {
    final theme = Theme.of(context);
    return MarkdownStyleSheet(
      h1: theme.textTheme.headlineMedium?.copyWith(
        fontWeight: FontWeight.bold,
        height: 1.5,
      ),
      h2: theme.textTheme.headlineSmall?.copyWith(
        fontWeight: FontWeight.w600,
        height: 1.4,
      ),
      h3: theme.textTheme.titleLarge?.copyWith(
        fontWeight: FontWeight.w600,
        height: 1.3,
      ),
      p: theme.textTheme.bodyLarge?.copyWith(
        height: 1.6,
      ),
      blockquote: theme.textTheme.bodyLarge?.copyWith(
        fontStyle: FontStyle.italic,
        color: theme.colorScheme.onSurfaceVariant,
      ),
      blockquoteDecoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: .3),
        borderRadius: BorderRadius.circular(4),
        border: Border(
          left: BorderSide(
            color: theme.colorScheme.primary,
            width: 4,
          ),
        ),
      ),
      code: TextStyle(
        backgroundColor: theme.colorScheme.surfaceContainerHighest.withValues(alpha: .5),
        fontFamily: 'monospace',
        fontSize: 14,
      ),
      codeblockDecoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: .3),
        borderRadius: BorderRadius.circular(8),
      ),
      listBullet: theme.textTheme.bodyLarge,
      a: TextStyle(
        color: theme.colorScheme.primary,
        decoration: TextDecoration.underline,
      ),
    );
  }
}