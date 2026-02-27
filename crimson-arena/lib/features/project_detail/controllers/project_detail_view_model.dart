import 'package:get/get.dart';

import '../../../data/models/brain_event_model.dart';
import '../../../data/models/brief_model.dart';
import '../../../data/models/instance_model.dart';
import '../../../data/models/project_model.dart';
import '../../../data/models/task_model.dart';
import '../../../services/brain_api_service.dart';
import '../../../services/brain_websocket_service.dart';
import '../../../services/project_selector_service.dart';

/// ViewModel for the Project Detail page.
///
/// Loads all data scoped to a single project: instances, briefs, tasks,
/// events, and sessions. Subscribes to WebSocket streams for live updates
/// filtered by the current project slug.
class ProjectDetailViewModel extends GetxController {
  final BrainApiService _api = Get.find();
  final BrainWebSocketService _ws = Get.find();
  final ProjectSelectorService _projectSelector = Get.find();

  // ---------------------------------------------------------------------------
  // Loading state
  // ---------------------------------------------------------------------------

  /// True during initial data fetch.
  final RxBool isLoading = true.obs;

  // ---------------------------------------------------------------------------
  // Reactive state
  // ---------------------------------------------------------------------------

  /// The project slug currently being viewed.
  final RxString currentSlug = ''.obs;

  /// The project model for the current slug.
  final Rx<ProjectModel?> project = Rx<ProjectModel?>(null);

  /// Instances belonging to this project.
  final RxList<InstanceModel> instances = <InstanceModel>[].obs;

  /// Briefs belonging to this project.
  final RxList<BriefModel> briefs = <BriefModel>[].obs;

  /// Tasks belonging to this project.
  final RxList<TaskModel> tasks = <TaskModel>[].obs;

  /// Recent events for this project.
  final RxList<BrainEventModel> recentEvents = <BrainEventModel>[].obs;

  // ---------------------------------------------------------------------------
  // Lifecycle
  // ---------------------------------------------------------------------------

  @override
  void onInit() {
    super.onInit();
    _setupWebSocketListeners();
  }

  // ---------------------------------------------------------------------------
  // Data loading
  // ---------------------------------------------------------------------------

  /// Load all project-scoped data for the given [slug].
  ///
  /// Skips re-loading if the slug has not changed (avoids redundant fetches
  /// when the GetX builder re-runs).
  Future<void> loadProject(String slug) async {
    if (slug == currentSlug.value && project.value != null) return;

    currentSlug.value = slug;
    isLoading.value = true;

    // Clear previous data.
    project.value = null;
    instances.clear();
    briefs.clear();
    tasks.clear();
    recentEvents.clear();

    // Resolve project model from the ProjectSelectorService cache.
    project.value =
        _projectSelector.projects.firstWhereOrNull((p) => p.slug == slug);

    // Parallel fetch of all scoped data.
    await Future.wait([
      _fetchInstances(),
      _fetchBriefs(slug),
      _fetchTasks(slug),
      _fetchEvents(slug),
    ]);

    isLoading.value = false;
  }

  /// Force refresh all data for the current project.
  Future<void> refreshData() async {
    if (currentSlug.value.isEmpty) return;
    final slug = currentSlug.value;

    project.value =
        _projectSelector.projects.firstWhereOrNull((p) => p.slug == slug);

    await Future.wait([
      _fetchInstances(),
      _fetchBriefs(slug),
      _fetchTasks(slug),
      _fetchEvents(slug),
    ]);
  }

  // ---------------------------------------------------------------------------
  // REST data fetching
  // ---------------------------------------------------------------------------

  Future<void> _fetchInstances() async {
    final data = await _api.getBrainInstances();
    if (data != null) {
      final raw = data['instances'] as List<dynamic>? ?? [];
      final allInstances = raw
          .whereType<Map<String, dynamic>>()
          .map(InstanceModel.fromJson)
          .toList();
      // Client-side filter by project slug.
      instances.value = allInstances
          .where((i) => i.projectSlug == currentSlug.value)
          .toList();
    }
  }

  Future<void> _fetchBriefs(String slug) async {
    final data = await _api.getBrainBriefs(project: slug);
    if (data != null) {
      final raw = data['briefs'] as List<dynamic>? ?? [];
      briefs.value = raw
          .whereType<Map<String, dynamic>>()
          .map(BriefModel.fromJson)
          .toList();
    }
  }

  Future<void> _fetchTasks(String slug) async {
    final data = await _api.getBrainTasks(projectSlug: slug, limit: 200);
    if (data != null) {
      final raw = data['tasks'] as List<dynamic>? ?? [];
      tasks.value = raw
          .whereType<Map<String, dynamic>>()
          .map(TaskModel.fromJson)
          .toList();
    }
  }

  Future<void> _fetchEvents(String slug) async {
    final data = await _api.getBrainEvents(project: slug, limit: 20);
    if (data != null) {
      final raw = data['events'] as List<dynamic>? ?? [];
      recentEvents.value = raw
          .whereType<Map<String, dynamic>>()
          .map(BrainEventModel.fromJson)
          .toList();
    }
  }

  // ---------------------------------------------------------------------------
  // WebSocket listeners
  // ---------------------------------------------------------------------------

  void _setupWebSocketListeners() {
    ever(_ws.brainInstances, (Map<String, dynamic>? data) {
      if (data == null || currentSlug.value.isEmpty) return;
      final raw = data['instances'] as List<dynamic>? ?? [];
      final allInstances = raw
          .whereType<Map<String, dynamic>>()
          .map(InstanceModel.fromJson)
          .toList();
      instances.value = allInstances
          .where((i) => i.projectSlug == currentSlug.value)
          .toList();
    });

    ever(_ws.brainBriefs, (Map<String, dynamic>? data) {
      if (data == null || currentSlug.value.isEmpty) return;
      final raw = data['briefs'] as List<dynamic>? ?? [];
      final allBriefs = raw
          .whereType<Map<String, dynamic>>()
          .map(BriefModel.fromJson)
          .toList();
      briefs.value = allBriefs
          .where((b) => b.project == currentSlug.value)
          .toList();
    });

    ever(_ws.brainTasks, (Map<String, dynamic>? data) {
      if (data == null || currentSlug.value.isEmpty) return;
      final raw = data['tasks'] as List<dynamic>? ?? [];
      final allTasks = raw
          .whereType<Map<String, dynamic>>()
          .map(TaskModel.fromJson)
          .toList();
      tasks.value = allTasks
          .where((t) => t.projectSlug == currentSlug.value)
          .toList();
    });

    ever(_ws.brainEvents, (Map<String, dynamic>? data) {
      if (data == null || currentSlug.value.isEmpty) return;
      final raw = data['events'] as List<dynamic>? ?? [];
      final allEvents = raw
          .whereType<Map<String, dynamic>>()
          .map(BrainEventModel.fromJson)
          .toList();
      recentEvents.value = allEvents
          .where((e) => e.projectSlug == currentSlug.value)
          .take(20)
          .toList();
    });

    // Update project model when the project list changes.
    ever(_ws.brainProjects, (Map<String, dynamic>? data) {
      if (data == null || currentSlug.value.isEmpty) return;
      project.value = _projectSelector.projects
          .firstWhereOrNull((p) => p.slug == currentSlug.value);
    });
  }

  // ---------------------------------------------------------------------------
  // Computed properties
  // ---------------------------------------------------------------------------

  /// Brief status counts: status string -> count.
  Map<String, int> get briefStatusCounts {
    final counts = <String, int>{};
    for (final brief in briefs) {
      counts[brief.status] = (counts[brief.status] ?? 0) + 1;
    }
    return counts;
  }

  /// Task status counts: status string -> count.
  Map<String, int> get taskStatusCounts {
    final counts = <String, int>{};
    for (final task in tasks) {
      counts[task.status] = (counts[task.status] ?? 0) + 1;
    }
    return counts;
  }

  /// Agent workload: assignee name -> task count (active tasks only).
  Map<String, int> get taskAgentWorkload {
    final workload = <String, int>{};
    for (final task in tasks) {
      if (task.assignee != null &&
          task.assignee!.isNotEmpty &&
          task.isActive) {
        workload[task.assignee!] = (workload[task.assignee!] ?? 0) + 1;
      }
    }
    return workload;
  }

  /// Number of active instances for this project.
  int get activeInstanceCount => instances.where((i) => i.isActive).length;

  /// Total instance count for this project.
  int get totalInstanceCount => instances.length;
}
