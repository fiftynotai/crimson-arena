import 'package:get/get.dart';

import '../controllers/events_view_model.dart';

/// Dependency bindings for the Events page.
class EventsBindings implements Bindings {
  @override
  void dependencies() {
    Get.lazyPut<EventsViewModel>(
      () => EventsViewModel(),
      fenix: true,
    );
  }
}
