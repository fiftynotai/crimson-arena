import 'package:get/get.dart';

import '../controllers/events_view_model.dart';

/// Dependency bindings for the Events page.
class EventsBindings implements Bindings {
  @override
  void dependencies() {
    if (!Get.isRegistered<EventsViewModel>()) {
      Get.put<EventsViewModel>(EventsViewModel(), permanent: true);
    }
  }
}
