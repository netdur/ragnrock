import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:llama_cpp_dart/llama_cpp_dart.dart';
import '../../../services/llm_service.dart';
class ServiceIndicator extends StatelessWidget {
  const ServiceIndicator({super.key});
  @override
  Widget build(BuildContext context) {
    final LlmService llmService = Get.find<LlmService>();
    return Obx(() {
      final status = llmService.status.value;
      Widget icon;
      String text;
      switch (status) {
        case LlamaStatus.loading:
        case LlamaStatus.generating:
          icon = const SizedBox(
            width: 12,
            height: 12,
            child: CircularProgressIndicator(strokeWidth: 2),
          );
          text = status == LlamaStatus.loading ? "Loading..." : "Generating...";
          break;
        case LlamaStatus.ready:
          icon = const Icon(Icons.circle, color: Colors.green, size: 12);
          text = "Ready";
          break;
        case LlamaStatus.error:
          icon = const Icon(Icons.circle, color: Colors.red, size: 12);
          text = "Error";
          break;
        case LlamaStatus.uninitialized:
        case LlamaStatus.disposed:
        icon = const Icon(Icons.circle, color: Colors.grey, size: 12);
          text = "Offline";
          break;
      }
      return Tooltip(
        message: 'LLM Service Status: $text',
        child: Row(
          children: [
            icon,
            const SizedBox(width: 8),
            Text(text),
          ],
        ),
      );
    });
  }
}