import 'package:get/get.dart';

import '../controllers/operations_view_model.dart';

/// Dependency bindings for the Operations page.
class OperationsBindings implements Bindings {
  @override
  void dependencies() {
    if (!Get.isRegistered<OperationsViewModel>()) {
      Get.put<OperationsViewModel>(OperationsViewModel(), permanent: true);
    }
  }
}
