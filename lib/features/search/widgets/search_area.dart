import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../search_screen_controller.dart';
class SearchArea extends GetView<SearchScreenController> {
  const SearchArea({super.key});
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final borderColor = isDark ? Colors.grey.shade800 : Colors.grey.shade300;
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: 700,
            maxHeight: MediaQuery.of(context).size.height * 0.4,
          ),
          child: Container(
            padding: const EdgeInsets.all(8.0),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24.0),
              border: Border.all(color: borderColor),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min, 
              children: [
                Flexible( 
                  child: SingleChildScrollView( 
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: TextField(
                        controller: controller.searchTextController,
                        focusNode: controller.searchFocusNode,
                        maxLines: null,
                        minLines: 1,
                        keyboardType: TextInputType.multiline,
                        style: const TextStyle(fontSize: 16),
                        decoration: const InputDecoration(
                          hintText: "Enter your search query...",
                          border: InputBorder.none,
                        ),
                        onSubmitted: (_) => controller.performSearch(),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    IconButton(
                      onPressed: () {},
                      icon: const Icon(Icons.add),
                      tooltip: "Attach file",
                    ),
                    TextButton.icon(
                      onPressed: () {},
                      icon: const Icon(Icons.tune, size: 20),
                      label: const Text("Tools"),
                    ),
                    const Spacer(),
                    IconButton(
                      style: IconButton.styleFrom(
                        padding: const EdgeInsets.all(12),
                      ),
                      onPressed: controller.performSearch,
                      icon: const Icon(Icons.send),
                      tooltip: "Search",
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}