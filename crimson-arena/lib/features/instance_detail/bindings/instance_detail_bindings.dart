import 'package:get/get.dart';

import '../controllers/instance_detail_view_model.dart';

/// Dependency bindings for the Instance Detail page.
///
/// Registers [InstanceDetailViewModel] as non-permanent so it is
/// disposed when the user navigates away from the detail page.
class InstanceDetailBindings implements Bindings {
  @override
  void dependencies() {
    if (!Get.isRegistered<InstanceDetailViewModel>()) {
      Get.put<InstanceDetailViewModel>(InstanceDetailViewModel());
    }
  }
}
