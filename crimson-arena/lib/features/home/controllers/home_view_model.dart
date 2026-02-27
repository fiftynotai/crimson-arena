import 'package:get/get.dart';

import '../../../data/models/brain_event_model.dart';
import '../../../data/models/brief_model.dart';
import '../../../data/models/instance_model.dart';
import '../../../data/models/task_model.dart';
import '../../../services/brain_api_service.dart';
import '../../../services/brain_websocket_service.dart';
import '../../../services/project_selector_service.dart';

/// ViewModel for the Home page.
///
/// Manages focused dashboard state: instances summary, recent tasks,
/// recent events, and project-scoped briefs.
///
/// Data flows from two sources:
/// 1. REST (initial load)
/// 2. WebSocket streams (real-time updates)
class HomeViewModel extends GetxController {
  final BrainApiService _apiService = Get.find();
  final BrainWebSocketService _wsService = Get.find();
  final ProjectSelectorService _projectSelector = Get.find();

  // ---------------------------------------------------------------------------
  // Loading state
  // ---------------------------------------------------------------------------

  /// True during initial data fetch.
  final RxBool isLoading = true.obs;

  // ---------------------------------------------------------------------------
  // Instances
  // ---------------------------------------------------------------------------

  /// Active brain instances.
  final RxList<InstanceModel> instances = <InstanceModel>[].obs;

  // ---------------------------------------------------------------------------
  // Recent tasks
  // ---------------------------------------------------------------------------

  /// Most recent tasks (up to 10).
  final RxList<TaskModel> recentTasks = <TaskModel>[].obs;

  // ---------------------------------------------------------------------------
  // Recent events
  // ---------------------------------------------------------------------------

  /// Most recent brain events (up to 10).
  final RxList<BrainEventModel> recentEvents = <BrainEventModel>[].obs;

  // ---------------------------------------------------------------------------
  // Briefs
  // ---------------------------------------------------------------------------

  /// Tracked briefs.
  final RxList<BriefModel> brainBriefs = <BriefModel>[].obs;

  // ---------------------------------------------------------------------------
  // Lifecycle
  // ---------------------------------------------------------------------------

  @override
  void onInit() {
    super.onInit();
    _fetchInitialData();
    _setupWebSocketListeners();

    // Re-fetch data when the global project selector changes.
    ever(_projectSelector.selectedProjectSlug, (_) => refreshData());
  }

  // ---------------------------------------------------------------------------
  // Initial data fetch
  // ---------------------------------------------------------------------------

  Future<void> _fetchInitialData() async {
    isLoading.value = true;

    await Future.wait([
      _fetchInstances(),
      _fetchRecentTasks(),
      _fetchRecentEvents(),
    ]);

    isLoading.value = false;
  }

  // ---------------------------------------------------------------------------
  // REST data fetching
  // ---------------------------------------------------------------------------

  Future<void> _fetchInstances() async {
    final data = await _apiService.getBrainInstances();
    if (data != null) {
      _parseInstances(data);
    }
  }

  Future<void> _fetchRecentTasks() async {
    final projectSlug = _projectSelector.selectedProjectSlug.value;
    final data = await _apiService.getBrainTasks(
      limit: 10,
      projectSlug: projectSlug,
    );
    if (data != null) {
      _parseRecentTasks(data);
    }
  }

  Future<void> _fetchRecentEvents() async {
    final project = _projectSelector.selectedProjectSlug.value;
    final data = await _apiService.getBrainEvents(
      limit: 10,
      project: project,
    );
    if (data != null) {
      _parseRecentEvents(data);
    }
  }

  // ---------------------------------------------------------------------------
  // Data parsing
  // ---------------------------------------------------------------------------

  void _parseInstances(Map<String, dynamic> data) {
    final raw = data['instances'] as List<dynamic>? ?? [];
    var parsed = raw
        .map((e) => InstanceModel.fromJson(e as Map<String, dynamic>))
        .toList();

    // Client-side project filter (instances API does not support server-side).
    final projectSlug = _projectSelector.selectedProjectSlug.value;
    if (projectSlug != null) {
      parsed = parsed.where((i) => i.projectSlug == projectSlug).toList();
    }

    instances.value = parsed;
  }

  void _parseRecentTasks(Map<String, dynamic> data) {
    final rawTasks = data['tasks'];
    if (rawTasks is! List) return;
    recentTasks.value = rawTasks
        .whereType<Map<String, dynamic>>()
        .map(TaskModel.fromJson)
        .toList();
  }

  void _parseRecentEvents(Map<String, dynamic> data) {
    final rawEvents = data['events'] as List<dynamic>? ?? [];
    recentEvents.value = rawEvents
        .whereType<Map<String, dynamic>>()
        .map(BrainEventModel.fromJson)
        .toList();
  }

  void _parseBriefs(dynamic data) {
    brainBriefs.clear();
    List<dynamic> briefsList;
    if (data is List) {
      briefsList = data;
    } else if (data is Map<String, dynamic>) {
      briefsList = data['briefs'] as List<dynamic>? ?? [];
    } else {
      return;
    }

    final projectSlug = _projectSelector.selectedProjectSlug.value;

    for (final item in briefsList) {
      if (item is Map<String, dynamic>) {
        final brief = BriefModel.fromJson(item);
        // Client-side project filter for briefs.
        if (projectSlug != null && brief.project != projectSlug) continue;
        brainBriefs.add(brief);
      }
    }
  }

  // ---------------------------------------------------------------------------
  // WebSocket listeners
  // ---------------------------------------------------------------------------

  void _setupWebSocketListeners() {
    // Brain briefs
    ever(_wsService.brainBriefs, (Map<String, dynamic>? data) {
      if (data != null) {
        _parseBriefs(data);
      }
    });

    // Brain state composite (includes briefs)
    ever(_wsService.brainState, (Map<String, dynamic>? data) {
      if (data != null) {
        final briefsData = data['briefs'];
        if (briefsData != null) {
          _parseBriefs(briefsData);
        }
      }
    });
  }

  // ---------------------------------------------------------------------------
  // Public actions
  // ---------------------------------------------------------------------------

  /// Refresh all data.
  Future<void> refreshData() async {
    await Future.wait([
      _fetchInstances(),
      _fetchRecentTasks(),
      _fetchRecentEvents(),
    ]);

    // Re-filter briefs from cached WebSocket data.
    final briefsData = _wsService.brainBriefs.value;
    if (briefsData != null) {
      _parseBriefs(briefsData);
    }
  }

  /// Brief status counts for display.
  Map<String, int> get briefStatusCounts {
    final counts = <String, int>{};
    for (final brief in brainBriefs) {
      counts[brief.status] = (counts[brief.status] ?? 0) + 1;
    }
    return counts;
  }
}
