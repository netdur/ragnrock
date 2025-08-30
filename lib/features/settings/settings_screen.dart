import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'settings_controller.dart';
import 'tabs/llm_tab.dart';
import 'tabs/search_tab.dart';
class SettingsScreen extends GetView<SettingsController> {
  const SettingsScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Row(
        children: [
          _buildSidebar(context),
          const VerticalDivider(width: 1, thickness: 1),
          Expanded(
            child: Column(
              children: [
                _buildHeader(context),
                const Divider(height: 1, thickness: 1),
                Expanded(child: Obx(() => _buildContent())),
              ],
            ),
          ),
        ],
      ),
    );
  }
  Widget _buildSidebar(BuildContext context) {
    return Container(
      width: 240,
      color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.3), 
      child: Column(
        children: [
          Container(
            height: 60,
            padding: const EdgeInsets.all(16),
            alignment: Alignment.centerLeft,
            child: Text(
              'Settings',
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w600),
            ),
          ),
          const Divider(height: 1, thickness: 1),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 8),
              children: [
                _buildNavSection('CONFIGURATION'),
                Obx(
                  () => _buildNavItem(
                    icon: Icons.search,
                    label: 'Search Engines',
                    index: 0,
                    isSelected: controller.selectedTabIndex.value == 0,
                  ),
                ),
                Obx(
                  () => _buildNavItem(
                    icon: Icons.psychology,
                    label: 'LLM Settings',
                    index: 1,
                    isSelected: controller.selectedTabIndex.value == 1,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  Widget _buildNavSection(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: Get.theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.6), 
          letterSpacing: 0.5,
        ),
      ),
    );
  }
  Widget _buildNavItem({
    required IconData icon,
    required String label,
    required int index,
    required bool isSelected,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: isSelected
            ? Get.theme.colorScheme.primary.withValues(alpha: 0.1) 
            : Colors.transparent,
        borderRadius: BorderRadius.circular(6),
      ),
      child: ListTile(
        dense: true,
        leading: Icon(
          icon,
          size: 20,
          color: isSelected ? Get.theme.colorScheme.primary : null,
        ),
        title: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.w500 : FontWeight.normal,
            color: isSelected ? Get.theme.colorScheme.primary : null,
          ),
        ),
        onTap: () => controller.selectedTabIndex.value = index,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
      ),
    );
  }
  Widget _buildHeader(BuildContext context) {
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Get.back(),
            tooltip: 'Back',
          ),
          const SizedBox(width: 16),
          Obx(
            () => Text(
              _getPageTitle(),
              style: Theme.of(context).textTheme.headlineSmall,
            ),
          ),
          const Spacer(),
          TextButton.icon(
            icon: const Icon(Icons.restore, size: 20),
            label: const Text('Reset to Defaults'),
            onPressed: controller.resetToDefaults,
          ),
          const SizedBox(width: 12),
          FilledButton.icon(
            icon: const Icon(Icons.save, size: 20),
            label: const Text('Save Settings'),
            onPressed: controller.saveSettings,
          ),
        ],
      ),
    );
  }
  String _getPageTitle() {
    switch (controller.selectedTabIndex.value) {
      case 0:
        return 'Search Engines Configuration';
      case 1:
        return 'Language Model Settings';
      default:
        return 'Settings';
    }
  }
  Widget _buildContent() {
    switch (controller.selectedTabIndex.value) {
      case 0:
        return const SearchSettingsTab();
      case 1:
        return const LlmSettingsTab();
      default:
        return const Center(child: Text('An error has occurred.'));
    }
  }
}