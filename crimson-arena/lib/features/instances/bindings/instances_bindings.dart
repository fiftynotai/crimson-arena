import 'package:get/get.dart';

import '../controllers/instances_view_model.dart';

/// Dependency bindings for the Instances page.
class InstancesBindings implements Bindings {
  @override
  void dependencies() {
    if (!Get.isRegistered<InstancesViewModel>()) {
      Get.put<InstancesViewModel>(InstancesViewModel(), permanent: true);
    }
  }
}
