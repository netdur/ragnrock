import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../sessions/session_results.dart';
import 'search_screen_controller.dart';
import '../sessions/sessions_panel.dart';
import 'widgets/search_area.dart';
import 'widgets/service_indicator.dart';
import 'widgets/settings_button.dart';

class SearchScreen extends GetView<SearchScreenController> {
  const SearchScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return KeyboardListener(
      focusNode: FocusNode(),
      onKeyEvent: (event) {
        if (event is KeyDownEvent &&
            event.logicalKey == LogicalKeyboardKey.slash) {
          controller.searchFocusNode.requestFocus();
        }
      },
      child: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth > 700) {
            return buildDesktopLayout();
          } else {
            return buildMobileLayout();
          }
        },
      ),
    );
  }

  Widget buildDesktopLayout() {
    return Material(
      color: Colors.transparent,
      child: Stack(
        children: [
          Row(
            children: [
              const SizedBox(width: 250, child: SessionsPanel()),
              Expanded(
                child: Obx(() {
                  if (controller.activeSession.value?.originalQuery.isEmpty ??
                      true) {
                    return const SearchArea();
                  } else {
                    return const SessionResult();
                  }
                }),
              ),
            ],
          ),
          Positioned(
            top: 24,
            right: 64,
            child: Row(
              children: const [
                ServiceIndicator(),
                SizedBox(width: 8),
                SettingsButton(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget buildMobileLayout() {
    return Scaffold(
      body: Stack(
        children: [
          Obx(() {
            if (controller.activeSession.value?.originalQuery.isEmpty ?? true) {
              return const SearchArea();
            } else {
              return const SessionResult(); // Changed from ResultsDisplay
            }
          }),
          Positioned(
            top: 16,
            right: 16,
            child: Row(
              children: const [
                ServiceIndicator(),
                SizedBox(width: 8),
                SettingsButton(),
              ],
            ),
          ),
          Positioned(
            top: 16,
            left: 16,
            child: SafeArea(
              child: Builder(
                builder: (context) {
                  return IconButton(
                    icon: const Icon(Icons.menu),
                    onPressed: () {
                      Scaffold.of(context).openDrawer();
                    },
                    tooltip: 'Open Sessions',
                  );
                },
              ),
            ),
          ),
        ],
      ),
      drawer: const Drawer(child: SessionsPanel()),
    );
  }
}
