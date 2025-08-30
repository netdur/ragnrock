import 'package:flutter/material.dart';
import 'package:get/get.dart';
class SettingsButton extends StatelessWidget {
  const SettingsButton({super.key});
  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.settings_outlined),
      onPressed: () {
        Get.toNamed('/settings');
      },
    );
  }
}