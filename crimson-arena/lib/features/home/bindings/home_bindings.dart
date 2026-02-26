import 'package:get/get.dart';

import '../controllers/home_view_model.dart';

/// Dependency bindings for the Home page.
class HomeBindings implements Bindings {
  @override
  void dependencies() {
    if (!Get.isRegistered<HomeViewModel>()) {
      Get.put<HomeViewModel>(HomeViewModel(), permanent: true);
    }
  }
}
