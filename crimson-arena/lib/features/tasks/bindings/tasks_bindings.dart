import 'package:get/get.dart';

import '../controllers/tasks_view_model.dart';

/// Dependency bindings for the Tasks page.
class TasksBindings implements Bindings {
  @override
  void dependencies() {
    if (!Get.isRegistered<TasksViewModel>()) {
      Get.put<TasksViewModel>(TasksViewModel(), permanent: true);
    }
  }
}
