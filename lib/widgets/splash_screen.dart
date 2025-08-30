import 'dart:io' show Platform;
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:macos_window_utils/macos_window_utils.dart';
import '../services/objectbox_service.dart';
import '../services/settings_service.dart';
import '../services/llm_service.dart';
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}
class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _setupMacWindow(); 
      await _initServices(); 
      await Future.delayed(const Duration(seconds: 1));
      if (!mounted) return;
      Get.offAllNamed('/search'); 
    });
  }
  Future<void> _setupMacWindow() async {
    if (!Platform.isMacOS) return;
    try {
      await WindowManipulator.initialize();
      await WindowManipulator.makeTitlebarTransparent();
      await WindowManipulator.enableFullSizeContentView();
      await WindowManipulator.setMaterial(
        NSVisualEffectViewMaterial.windowBackground,
      );
      await WindowManipulator.hideTitle();
    } catch (e) {
      debugPrint('macOS window setup failed: $e');
    }
  }
  Future<void> _initServices() async {
    final obj = Get.find<ObjectBoxService>();
    final set = Get.find<SettingsService>();
    final llm = Get.find<LlmService>();
    await Future.wait([
      obj.init(), 
      set.init(), 
    ]);
    llm.initialize();
  }
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Image.asset('assets/logo.png', height: 64 * 4),
          SizedBox(height: 16),
          CircularProgressIndicator(),
        ],
      ),
    );
  }
}