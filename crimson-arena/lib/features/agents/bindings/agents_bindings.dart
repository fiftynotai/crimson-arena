import 'package:get/get.dart';

import '../controllers/agents_view_model.dart';

/// Dependency bindings for the Agents page.
class AgentsBindings implements Bindings {
  @override
  void dependencies() {
    if (!Get.isRegistered<AgentsViewModel>()) {
      Get.put<AgentsViewModel>(AgentsViewModel(), permanent: true);
    }
  }
}
