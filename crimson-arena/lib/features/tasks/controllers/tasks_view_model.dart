import 'package:get/get.dart';

import '../../../data/models/task_model.dart';
import '../../../services/brain_api_service.dart';
import '../../../services/brain_websocket_service.dart';
import '../../../services/project_selector_service.dart';

/// ViewModel for the Tasks page.
///
/// Fetches brain tasks via REST and subscribes to task updates
/// via WebSocket. Parses the raw JSON into grouped, filterable
/// [TaskModel] lists for the kanban board UI.
class TasksViewModel extends GetxController {
  final _api = Get.find<BrainApiService>();
  final _ws = Get.find<BrainWebSocketService>();
  final _projectSelector = Get.find<ProjectSelectorService>();

  // -------------------------------------------------------------------------
  // Tasks grouped by status
  // -------------------------------------------------------------------------

  /// Tasks awaiting assignment.
  final pendingTasks = <TaskModel>[].obs;

  /// Tasks currently being worked on.
  final activeTasks = <TaskModel>[].obs;

  /// Tasks blocked by a dependency or issue.
  final blockedTasks = <TaskModel>[].obs;

  /// Completed tasks.
  final doneTasks = <TaskModel>[].obs;

  /// Cancelled tasks.
  final cancelledTasks = <TaskModel>[].obs;

  /// Failed tasks.
  final failedTasks = <TaskModel>[].obs;

  // -------------------------------------------------------------------------
  // Summary counts
  // -------------------------------------------------------------------------

  /// Status -> count mapping for quick access.
  final summary = <String, int>{}.obs;

  // -------------------------------------------------------------------------
  // Filters
  // -------------------------------------------------------------------------

  /// Selected project filter (null = all projects).
  final selectedProject = Rxn<String>();

  /// Selected assignee filter (null = all assignees).
  final selectedAssignee = Rxn<String>();

  /// Instance context for display when drilled from Instances page.
  final instanceContextId = Rxn<String>();
  final instanceContextHostname = Rxn<String>();

  // -------------------------------------------------------------------------
  // Loading state
  // -------------------------------------------------------------------------

  /// Whether the initial data load is in progress.
  final RxBool isLoading = true.obs;

  // -------------------------------------------------------------------------
  // Agent workload
  // -------------------------------------------------------------------------

  /// Agent name -> active task count.
  final agentWorkload = <String, int>{}.obs;

  // -------------------------------------------------------------------------
  // Derived helpers
  // -------------------------------------------------------------------------

  /// All unique project slugs found in the current task set.
  final availableProjects = <String>[].obs;

  /// All unique assignees found in the current task set.
  final availableAssignees = <String>[].obs;

  /// Total task count across all statuses.
  int get totalCount =>
      pendingTasks.length +
      activeTasks.length +
      blockedTasks.length +
      doneTasks.length +
      cancelledTasks.length +
      failedTasks.length;

  // -------------------------------------------------------------------------
  // Lifecycle
  // -------------------------------------------------------------------------

  @override
  void onInit() {
    super.onInit();
    fetchTasks();
    ever(_ws.brainTasks, (_) => _parseTasks(_ws.brainTasks.value));

    // Sync with global project selector: when the global project changes,
    // update the local filter and re-fetch from server.
    ever(_projectSelector.selectedProjectSlug, (String? slug) {
      selectedProject.value = slug;
      fetchTasks();
    });
  }

  /// Fetch tasks from the REST API.
  Future<void> fetchTasks() async {
    isLoading.value = true;
    final projectSlug = _projectSelector.selectedProjectSlug.value;
    final data = await _api.getBrainTasks(
      limit: 200,
      projectSlug: projectSlug,
    );
    _parseTasks(data);
    isLoading.value = false;
  }

  /// Refresh data (pull-to-refresh / manual refresh).
  Future<void> refreshData() async {
    final projectSlug = _projectSelector.selectedProjectSlug.value;
    final data = await _api.getBrainTasks(
      limit: 200,
      projectSlug: projectSlug,
    );
    _parseTasks(data);
  }

  // -------------------------------------------------------------------------
  // Parsing
  // -------------------------------------------------------------------------

  /// Parse raw API/WebSocket response into grouped task lists.
  ///
  /// Expected shape:
  /// ```json
  /// {
  ///   "tasks": [ { ... }, ... ],
  ///   "summary": { "pending": 3, "active": 2, ... }
  /// }
  /// ```
  void _parseTasks(Map<String, dynamic>? data) {
    if (data == null) return;

    // Parse task list
    final rawTasks = data['tasks'];
    if (rawTasks is! List) return;

    final allTasks = rawTasks
        .whereType<Map<String, dynamic>>()
        .map(TaskModel.fromJson)
        .toList();

    // Apply filters
    final filtered = allTasks.where(_matchesFilters).toList();

    // Group by status
    pendingTasks.value =
        filtered.where((t) => t.status == 'pending').toList();
    activeTasks.value =
        filtered.where((t) => t.status == 'active').toList();
    blockedTasks.value =
        filtered.where((t) => t.status == 'blocked').toList();
    doneTasks.value =
        filtered.where((t) => t.status == 'done').toList();
    cancelledTasks.value =
        filtered.where((t) => t.status == 'cancelled').toList();
    failedTasks.value =
        filtered.where((t) => t.status == 'failed').toList();

    // Sort each group by priority (lower number = higher priority)
    for (final group in [
      pendingTasks,
      activeTasks,
      blockedTasks,
      doneTasks,
      cancelledTasks,
      failedTasks,
    ]) {
      group.sort((a, b) => a.priority.compareTo(b.priority));
    }

    // Update summary
    final rawSummary = data['summary'];
    if (rawSummary is Map<String, dynamic>) {
      summary.value = rawSummary.map(
        (key, value) => MapEntry(key, value is int ? value : 0),
      );
    } else {
      summary.value = {
        'pending': pendingTasks.length,
        'active': activeTasks.length,
        'blocked': blockedTasks.length,
        'done': doneTasks.length,
        'cancelled': cancelledTasks.length,
        'failed': failedTasks.length,
      };
    }

    // Extract available filter options from all tasks (unfiltered)
    availableProjects.value = allTasks
        .map((t) => t.projectSlug)
        .whereType<String>()
        .where((s) => s.isNotEmpty)
        .toSet()
        .toList()
      ..sort();

    availableAssignees.value = allTasks
        .map((t) => t.assignee)
        .whereType<String>()
        .where((s) => s.isNotEmpty)
        .toSet()
        .toList()
      ..sort();

    // Compute agent workload
    _computeAgentWorkload(allTasks);
  }

  /// Check if a task matches the currently active filters.
  bool _matchesFilters(TaskModel task) {
    if (selectedProject.value != null &&
        task.projectSlug != selectedProject.value) {
      return false;
    }
    if (selectedAssignee.value != null &&
        task.assignee != selectedAssignee.value) {
      return false;
    }
    return true;
  }

  /// Compute agent workload from the full task list.
  void _computeAgentWorkload(List<TaskModel> allTasks) {
    final workload = <String, int>{};
    for (final task in allTasks) {
      if (task.assignee != null &&
          task.assignee!.isNotEmpty &&
          task.isActive) {
        workload[task.assignee!] = (workload[task.assignee!] ?? 0) + 1;
      }
    }
    agentWorkload.value = workload;
  }

  // -------------------------------------------------------------------------
  // Instance context (drill-down from Instances page)
  // -------------------------------------------------------------------------

  /// Set instance context for display and optionally filter by project.
  void setInstanceContext(
    String? instanceId, {
    String? hostname,
    String? projectSlug,
  }) {
    instanceContextId.value = instanceId;
    instanceContextHostname.value = hostname;
    if (projectSlug != null) {
      selectedProject.value = projectSlug;
      fetchTasks();
    }
  }

  /// Clear instance context display metadata.
  void clearInstanceContext() {
    instanceContextId.value = null;
    instanceContextHostname.value = null;
  }

  /// Whether an instance context is active.
  bool get hasInstanceContext => instanceContextId.value != null;

  // -------------------------------------------------------------------------
  // Filter actions
  // -------------------------------------------------------------------------

  /// Set project filter. Pass null to clear.
  void filterByProject(String? project) {
    selectedProject.value = project;
    // Re-parse with new filter
    _parseTasks(_ws.brainTasks.value);
  }

  /// Set assignee filter. Pass null to clear.
  void filterByAssignee(String? assignee) {
    selectedAssignee.value = assignee;
    // Re-parse with new filter
    _parseTasks(_ws.brainTasks.value);
  }

  /// Clear all filters.
  void clearFilters() {
    selectedProject.value = null;
    selectedAssignee.value = null;
    clearInstanceContext();
    _parseTasks(_ws.brainTasks.value);
  }
}
