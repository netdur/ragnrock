import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../settings_controller.dart';
class SearchSettingsTab extends GetView<SettingsController> {
  const SearchSettingsTab({super.key});
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
                _buildProvidersSection(),
                const SizedBox(height: 32),
                _buildBehaviorSection(),
              ],
            ),
          ),
        ),
      ),
    );
  }
  Widget _buildProvidersSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('Search Providers', Icons.cloud_queue),
        const SizedBox(height: 16),
        _buildGoogleSearchCard(),
        const SizedBox(height: 16),
        _buildBraveSearchCard(),
        const SizedBox(height: 16),
        _buildWikipediaSearchCard(),
        const SizedBox(height: 16),
        _buildElasticsearchCard(),
      ],
    );
  }
  Widget _buildBehaviorSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('Search Behavior', Icons.tune),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Get.theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Get.theme.colorScheme.outlineVariant),
          ),
          child: Row(
            children: [
              Expanded(
                child: Obx(() => _DesktopDropdown(
                  label: 'Default Search Engine',
                  value: controller.settings.defaultSearchEngine.value,
                  items: const ['Google', 'Brave', 'Wikipedia', 'Elasticsearch'],
                  onChanged: (v) => controller.settings.defaultSearchEngine.value = v ?? 'Google',
                )),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _DesktopTextField(
                  label: 'Search Timeout (seconds)',
                  initialValue: controller.settings.searchTimeout.value.toString(),
                  keyboardType: TextInputType.number,
                  onChanged: (v) => controller.settings.searchTimeout.value = int.tryParse(v) ?? 30,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _DesktopTextField(
                  label: 'Retry Attempts',
                  initialValue: controller.settings.retryAttempts.value.toString(),
                  keyboardType: TextInputType.number,
                  onChanged: (v) => controller.settings.retryAttempts.value = int.tryParse(v) ?? 3,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
  Widget _buildGoogleSearchCard() {
    return Obx(() => _ProviderCard(
      icon: Icons.search, iconColor: const Color(0xFF4285F4),
      title: 'Google Search', subtitle: 'Search using Google Custom Search API',
      enabled: controller.settings.isGoogleEnabled.value,
      onEnabledChanged: (v) => controller.settings.isGoogleEnabled.value = v,
      children: [
        Row(children: [
          Expanded(child: _DesktopTextField(label: 'API Key', initialValue: controller.settings.googleApiKey.value, onChanged: (v) => controller.settings.googleApiKey.value = v, obscureText: true)),
          const SizedBox(width: 16),
          Expanded(child: _DesktopTextField(label: 'Custom Search Engine ID', initialValue: controller.settings.googleCseId.value, onChanged: (v) => controller.settings.googleCseId.value = v)),
          const SizedBox(width: 16),
          Expanded(child: _DesktopDropdown(label: 'Safe Search', value: controller.settings.googleSafeSearch.value, items: controller.settings.safeSearchLevels, onChanged: (v) => controller.settings.googleSafeSearch.value = v ?? 'Moderate')),
        ]),
      ],
    ));
  }
  Widget _buildBraveSearchCard() {
    return Obx(() => _ProviderCard(
      icon: Icons.shield, iconColor: const Color(0xFFFB542B),
      title: 'Brave Search', subtitle: 'Privacy-focused search engine',
      enabled: controller.settings.isBraveEnabled.value,
      onEnabledChanged: (v) => controller.settings.isBraveEnabled.value = v,
      children: [
        Row(children: [
          Expanded(flex: 2, child: _DesktopTextField(label: 'API Key', initialValue: controller.settings.braveApiKey.value, onChanged: (v) => controller.settings.braveApiKey.value = v, obscureText: true)),
          const SizedBox(width: 16),
          Expanded(child: _DesktopTextField(label: 'Result Count', initialValue: controller.settings.braveResultsPerQuery.value.toString(), onChanged: (v) => controller.settings.braveResultsPerQuery.value = int.tryParse(v) ?? 20, keyboardType: TextInputType.number)),
        ]),
        const SizedBox(height: 16),
        Row(children: [
          Expanded(child: _DesktopDropdown(label: 'Freshness', value: controller.settings.braveFreshness.value, items: controller.settings.freshnessOptions, onChanged: (v) => controller.settings.braveFreshness.value = v ?? 'All Time')),
          const SizedBox(width: 16),
          Expanded(child: _DesktopDropdown(label: 'Country', value: controller.settings.braveCountry.value, items: controller.settings.countryOptions, onChanged: (v) => controller.settings.braveCountry.value = v ?? 'All Countries')),
        ]),
      ],
    ));
  }
  Widget _buildWikipediaSearchCard() {
    return Obx(() => _ProviderCard(
      icon: Icons.public, iconColor: const Color(0xFF000000),
      title: 'Wikipedia', subtitle: 'Free encyclopedia with millions of articles',
      enabled: controller.settings.isWikipediaEnabled.value,
      onEnabledChanged: (v) => controller.settings.isWikipediaEnabled.value = v,
      children: [
        Row(children: [
          Expanded(child: _DesktopDropdown(label: 'Language', value: controller.settings.wikipediaLanguage.value, items: controller.settings.wikipediaLanguageOptions, onChanged: (v) => controller.settings.wikipediaLanguage.value = v ?? 'en')),
          const SizedBox(width: 16),
          Expanded(child: _DesktopTextField(label: 'Result Count', initialValue: controller.settings.wikipediaResultsPerQuery.value.toString(), onChanged: (v) => controller.settings.wikipediaResultsPerQuery.value = int.tryParse(v) ?? 10, keyboardType: TextInputType.number)),
        ]),
      ],
    ));
  }

  Widget _buildElasticsearchCard() {
    return Obx(() => _ProviderCard(
      icon: Icons.storage, iconColor: const Color(0xFF005571),
      title: 'Elasticsearch', subtitle: 'Local search engine for private data',
      enabled: controller.settings.isElasticEnabled.value,
      onEnabledChanged: (v) => controller.settings.isElasticEnabled.value = v,
      children: [
        Row(children: [
          Expanded(flex: 2, child: _DesktopTextField(label: 'Host URL', initialValue: controller.settings.elasticHost.value, onChanged: (v) => controller.settings.elasticHost.value = v)),
          const SizedBox(width: 16),
          SizedBox(width: 120, child: _DesktopTextField(label: 'Port', initialValue: controller.settings.elasticPort.value, onChanged: (v) => controller.settings.elasticPort.value = v, keyboardType: TextInputType.number)),
        ]),
        const SizedBox(height: 16),
        Row(children: [
          Expanded(child: _DesktopTextField(label: 'Username (optional)', initialValue: controller.settings.elasticUsername.value, onChanged: (v) => controller.settings.elasticUsername.value = v)),
          const SizedBox(width: 16),
          Expanded(child: _DesktopTextField(label: 'Password (optional)', initialValue: controller.settings.elasticPassword.value, onChanged: (v) => controller.settings.elasticPassword.value = v, obscureText: true)),
        ]),
        const SizedBox(height: 16),
        Row(children: [
          Expanded(child: _DesktopTextField(label: 'Index Pattern', hint: 'research-*', initialValue: controller.settings.elasticIndexPattern.value, onChanged: (v) => controller.settings.elasticIndexPattern.value = v)),
          const SizedBox(width: 16),
          SizedBox(width: 120, child: _DesktopTextField(label: 'Timeout (s)', initialValue: controller.settings.elasticTimeout.value.toString(), keyboardType: TextInputType.number, onChanged: (v) => controller.settings.elasticTimeout.value = int.tryParse(v) ?? 30)),
        ]),
      ],
    ));
  }
  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(children: [
      Icon(icon, size: 20, color: Get.theme.colorScheme.primary),
      const SizedBox(width: 8),
      Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
    ]);
  }
}
class _ProviderCard extends StatelessWidget {
  final IconData icon; final Color iconColor; final String title; final String subtitle; final bool enabled; final ValueChanged<bool> onEnabledChanged; final List<Widget> children;
  const _ProviderCard({ required this.icon, required this.iconColor, required this.title, required this.subtitle, required this.enabled, required this.onEnabledChanged, required this.children });
  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(color: enabled ? Theme.of(context).colorScheme.surface : Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: .3), borderRadius: BorderRadius.circular(8), border: Border.all(color: enabled ? Theme.of(context).colorScheme.primary.withValues(alpha: .3) : Theme.of(context).colorScheme.outlineVariant, width: enabled ? 1.5 : 1)),
      child: Column(children: [
        Padding(padding: const EdgeInsets.all(16), child: Row(children: [
          Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: iconColor.withValues(alpha: .1), borderRadius: BorderRadius.circular(6)), child: Icon(icon, color: iconColor, size: 24)),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            Text(subtitle, style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant)),
          ])),
          Switch(value: enabled, onChanged: onEnabledChanged),
        ])),
        if (enabled) ...[ const Divider(height: 1), Padding(padding: const EdgeInsets.all(20), child: Column(children: children)) ],
      ]),
    );
  }
}
class _DesktopTextField extends StatelessWidget {
  final String label; final String? hint; final String? initialValue; final ValueChanged<String>? onChanged; final TextInputType? keyboardType; final bool obscureText;
  const _DesktopTextField({ required this.label, this.hint, this.initialValue, this.onChanged, this.keyboardType, this.obscureText = false });
  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
      const SizedBox(height: 6),
      TextFormField(initialValue: initialValue, onChanged: onChanged, keyboardType: keyboardType, obscureText: obscureText, style: const TextStyle(fontSize: 13), decoration: InputDecoration(hintText: hint, hintStyle: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: .5)), contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10), border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)), enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: BorderSide(color: Theme.of(context).colorScheme.outlineVariant)), focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: BorderSide(color: Theme.of(context).colorScheme.primary, width: 2)))),
    ]);
  }
}
class _DesktopDropdown extends StatelessWidget {
  final String label; final String value; final List<String> items; final ValueChanged<String?>? onChanged;
  const _DesktopDropdown({ required this.label, required this.value, required this.items, this.onChanged });
  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
      const SizedBox(height: 6),
      DropdownButtonFormField<String>(
        initialValue: items.contains(value) ? value : null,
        items: items.map((item) => DropdownMenuItem(value: item, child: Text(item, style: const TextStyle(fontSize: 13)))).toList(),
        onChanged: onChanged,
        decoration: InputDecoration(contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10), border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)), enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: BorderSide(color: Theme.of(context).colorScheme.outlineVariant))),
      ),
    ]);
  }
}