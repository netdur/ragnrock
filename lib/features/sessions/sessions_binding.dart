import 'package:get/get.dart';

import 'sessions_results_controller.dart';

class SessionsBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => SessionsResultsController());
  }
}