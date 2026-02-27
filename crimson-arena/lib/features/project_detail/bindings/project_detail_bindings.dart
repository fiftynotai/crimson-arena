import 'package:get/get.dart';

import '../controllers/project_detail_view_model.dart';

/// Dependency bindings for the Project Detail page.
class ProjectDetailBindings implements Bindings {
  @override
  void dependencies() {
    if (!Get.isRegistered<ProjectDetailViewModel>()) {
      Get.put<ProjectDetailViewModel>(ProjectDetailViewModel());
    }
  }
}
