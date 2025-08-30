import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../search/search_screen_controller.dart';
import 'sessions_panel_controller.dart';

class SessionsPanel extends GetView<SessionsPanelController> {
  const SessionsPanel({super.key});
  
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: controller.startNewSearch,
              icon: const Icon(Icons.add),
              label: const Text("New Search"),
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: Obx(
              () => ListView.builder(
                itemCount: controller.sessions.length,
                itemBuilder: (context, index) {
                  final session = controller.sessions[index];
                  final activeSessionId = Get.find<SearchScreenController>().activeSession.value?.id;
                  final bool isActive = activeSessionId == session.id;
                  
                  return Dismissible(
                    key: Key('session-${session.id}'),
                    direction: DismissDirection.endToStart,
                    background: Container(
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.only(right: 20),
                      color: Colors.red,
                      child: const Icon(Icons.delete, color: Colors.white),
                    ),
                    confirmDismiss: (direction) async {
                      // Show confirmation dialog
                      return await showDialog(
                        context: context,
                        builder: (BuildContext context) {
                          return AlertDialog(
                            title: const Text("Delete Search"),
                            content: Text(
                              "Delete \"${session.originalQuery.isEmpty ? 'New Search' : session.originalQuery}\"?",
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.of(context).pop(false),
                                child: const Text("Cancel"),
                              ),
                              TextButton(
                                onPressed: () => Navigator.of(context).pop(true),
                                child: const Text("Delete", style: TextStyle(color: Colors.red)),
                              ),
                            ],
                          );
                        },
                      );
                    },
                    onDismissed: (direction) {
                      controller.deleteSession(session);
                    },
                    child: ListTile(
                      title: Text(
                        session.originalQuery.isEmpty ? "New Search" : session.originalQuery,
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                      subtitle: session.finalReport != null 
                        ? Text(
                            _formatTimestamp(session.timestamp),
                            style: TextStyle(fontSize: 11, color: Colors.grey),
                          )
                        : null,
                      selected: isActive,
                      selectedTileColor: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                      onTap: () => controller.selectSession(session),
                      leading: Icon(
                        session.finalReport != null 
                          ? Icons.check_circle_outline 
                          : Icons.chat_bubble_outline,
                        size: 20,
                        color: session.finalReport != null ? Colors.green : null,
                      ),
                      dense: true,
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);
    
    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${timestamp.month}/${timestamp.day}/${timestamp.year}';
    }
  }
}