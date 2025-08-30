import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../settings_controller.dart';
class LlmSettingsTab extends GetView<SettingsController> {
  const LlmSettingsTab({super.key});
  @override
  Widget build(BuildContext context) {
    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 800),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    _buildSectionHeader('Model Configuration', Icons.psychology_alt),
                    FilledButton.icon(
                      icon: const Icon(Icons.sync, size: 18),
                      label: const Text('Apply & Reload Model'),
                      onPressed: controller.applyAndReloadLlm,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildModelConfigSection(),
                const SizedBox(height: 32),
                _buildPerformanceSection(),
                const SizedBox(height: 32),
                _buildPromptSection(),
              ],
            ),
          ),
        ),
      ),
    );
  }
  Widget _buildModelConfigSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Get.theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Get.theme.colorScheme.outlineVariant),
      ),
      child: Column(
        children: [
          _buildModelPathRow(
            label: 'Language Model',
            description: 'GGUF model file for text generation',
            pathBuilder: () => controller.settings.modelPath.value,
            onBrowse: controller.pickModelFile,
            onClear: () => controller.settings.modelPath.value = '',
          ),
          const SizedBox(height: 20),
          _buildModelPathRow(
            label: 'Vision Model (Optional)',
            description: 'GGUF model file for image understanding',
            pathBuilder: () => controller.settings.visionModelPath.value,
            onBrowse: controller.pickVisionModelFile,
            onClear: () => controller.settings.visionModelPath.value = '',
          ),
        ],
      ),
    );
  }
  Widget _buildPerformanceSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('Performance & Quality', Icons.speed),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Get.theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Get.theme.colorScheme.outlineVariant),
          ),
          child: Column(
            children: [
              Obx(() => _buildSliderSetting(
                label: 'Temperature',
                description: 'Controls randomness (0=deterministic, 2=creative)',
                value: controller.settings.temperature.value,
                min: 0.0, max: 2.0, divisions: 40,
                onChanged: (v) => controller.settings.temperature.value = v,
              )),
              const SizedBox(height: 24),
              Row(children: [
                Expanded(child: _buildNumberField(label: 'Context Size', description: 'Context window', value: controller.settings.contextSize.value.toString(), suffix: 'tokens', onChanged: (v) => controller.settings.contextSize.value = int.tryParse(v) ?? 4096)),
                const SizedBox(width: 16),
                Expanded(child: _buildNumberField(label: 'GPU Layers', description: 'Layers to offload (-1 for all)', value: controller.settings.gpuLayers.value.toString(), suffix: 'layers', onChanged: (v) => controller.settings.gpuLayers.value = int.tryParse(v) ?? -1)),
              ]),
              const SizedBox(height: 16),
              Row(children: [
                Expanded(child: _buildNumberField(label: 'CPU Threads', description: 'Threads to use', value: controller.settings.cpuThreads.value.toString(), suffix: 'threads', onChanged: (v) => controller.settings.cpuThreads.value = int.tryParse(v) ?? 4)),
                const SizedBox(width: 16),
                Expanded(child: _buildNumberField(label: 'Batch Size', description: 'Processing batch', value: controller.settings.batchSize.value.toString(), suffix: 'tokens', onChanged: (v) => controller.settings.batchSize.value = int.tryParse(v) ?? 512)),
              ]),
              const SizedBox(height: 24),
              ExpansionTile(
                title: const Text('Advanced Parameters', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                leading: const Icon(Icons.tune, size: 20),
                children: [
                  const SizedBox(height: 16),
                  Obx(() => _buildSliderSetting(label: 'Top-p (Nucleus Sampling)', description: 'Cumulative probability for token selection', value: controller.settings.topP.value, min: 0.0, max: 1.0, divisions: 20, onChanged: (v) => controller.settings.topP.value = v)),
                  const SizedBox(height: 16),
                  Obx(() => _buildSliderSetting(label: 'Top-k', description: 'Number of tokens to consider', value: controller.settings.topK.value.toDouble(), min: 1, max: 100, divisions: 99, isInt: true, onChanged: (v) => controller.settings.topK.value = v.toInt())),
                  const SizedBox(height: 16),
                  Obx(() => _buildSliderSetting(label: 'Repeat Penalty', description: 'Penalty for repeating tokens', value: controller.settings.repeatPenalty.value, min: 1.0, max: 1.5, divisions: 10, onChanged: (v) => controller.settings.repeatPenalty.value = v)),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
  Widget _buildPromptSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('Prompt Configuration', Icons.edit_note),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Get.theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Get.theme.colorScheme.outlineVariant),
          ),
          child: Obx(() => _buildDropdownField(
            label: 'Prompt Template',
            description: 'Pre-configured templates for different models',
            value: controller.settings.selectedPromptTemplate.value,
            items: controller.settings.promptTemplates,
            onChanged: (v) => controller.settings.selectedPromptTemplate.value = v ?? 'ChatML',
          )),
        ),
      ],
    );
  }
  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(children: [
      Icon(icon, size: 20, color: Get.theme.colorScheme.primary),
      const SizedBox(width: 8),
      Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
    ]);
  }
}
Widget _buildModelPathRow({ required String label, required String description, required String Function() pathBuilder, required VoidCallback onBrowse, required VoidCallback onClear }) {
  return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
    Text(description, style: TextStyle(fontSize: 12, color: Get.theme.colorScheme.onSurfaceVariant)),
    const SizedBox(height: 8),
    Obx(() => Row(children: [
      Expanded(child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(color: Get.theme.colorScheme.surfaceContainerHighest.withValues(alpha: .3), borderRadius: BorderRadius.circular(6), border: Border.all(color: Get.theme.colorScheme.outlineVariant)),
        child: Row(children: [
          Icon(Icons.insert_drive_file, size: 18, color: Get.theme.colorScheme.onSurfaceVariant),
          const SizedBox(width: 8),
          Expanded(child: Text(pathBuilder().isEmpty ? 'No model selected' : pathBuilder(), style: TextStyle(fontSize: 13, color: pathBuilder().isEmpty ? Get.theme.colorScheme.onSurfaceVariant.withValues(alpha: .5) : Get.theme.colorScheme.onSurface), overflow: TextOverflow.ellipsis)),
        ]),
      )),
      const SizedBox(width: 8),
      FilledButton.tonalIcon(onPressed: onBrowse, icon: const Icon(Icons.folder_open, size: 18), label: const Text('Browse')),
      if (pathBuilder().isNotEmpty) ...[const SizedBox(width: 8), IconButton(onPressed: onClear, icon: const Icon(Icons.clear, size: 20), tooltip: 'Clear')]
    ])),
  ]);
}
Widget _buildSliderSetting({ required String label, required String description, required double value, required double min, required double max, required int divisions, required ValueChanged<double> onChanged, bool isInt = false }) {
  return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
        Text(description, style: TextStyle(fontSize: 12, color: Get.theme.colorScheme.onSurfaceVariant)),
      ])),
      Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6), decoration: BoxDecoration(color: Get.theme.colorScheme.primaryContainer.withValues(alpha: .5), borderRadius: BorderRadius.circular(6)), child: Text(isInt ? value.toInt().toString() : value.toStringAsFixed(2), style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Get.theme.colorScheme.primary))),
    ]),
    const SizedBox(height: 8),
    SliderTheme(
      data: SliderThemeData(trackHeight: 6, thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8), overlayShape: const RoundSliderOverlayShape(overlayRadius: 16), activeTrackColor: Get.theme.colorScheme.primary, inactiveTrackColor: Get.theme.colorScheme.surfaceContainerHighest, thumbColor: Get.theme.colorScheme.primary, overlayColor: Get.theme.colorScheme.primary.withValues(alpha: .1)),
      child: Slider(value: value, min: min, max: max, divisions: divisions, onChanged: onChanged),
    ),
  ]);
}
Widget _buildNumberField({ required String label, required String description, required String value, required String suffix, required ValueChanged<String> onChanged }) {
  return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
    Text(description, style: TextStyle(fontSize: 11, color: Get.theme.colorScheme.onSurfaceVariant)),
    const SizedBox(height: 6),
    TextFormField(
      initialValue: value,
      onChanged: onChanged,
      keyboardType: const TextInputType.numberWithOptions(signed: true), 
      style: const TextStyle(fontSize: 13),
      decoration: InputDecoration(
        suffixText: suffix,
        suffixStyle: TextStyle(fontSize: 12, color: Get.theme.colorScheme.onSurfaceVariant),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: BorderSide(color: Get.theme.colorScheme.outlineVariant)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: BorderSide(color: Get.theme.colorScheme.primary, width: 2)),
      ),
    ),
  ]);
}
Widget _buildDropdownField({ required String label, required String description, required String value, required List<String> items, required ValueChanged<String?> onChanged }) {
  return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
    Text(description, style: TextStyle(fontSize: 11, color: Get.theme.colorScheme.onSurfaceVariant)),
    const SizedBox(height: 6),
    DropdownButtonFormField<String>(
      initialValue: items.contains(value) ? value : null, 
      items: items.map((item) => DropdownMenuItem(value: item, child: Text(item, style: const TextStyle(fontSize: 13)))).toList(),
      onChanged: onChanged,
      decoration: InputDecoration(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: BorderSide(color: Get.theme.colorScheme.outlineVariant)),
      ),
    ),
  ]);
}