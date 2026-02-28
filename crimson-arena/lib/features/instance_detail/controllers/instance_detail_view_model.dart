import 'package:get/get.dart';

import '../../../core/constants/agent_constants.dart';
import '../../../data/models/agent_nexus_entry.dart';
import '../../../data/models/brain_event_model.dart';
import '../../../data/models/execution_log_entry.dart';
import '../../../data/models/instance_model.dart';
import '../../../data/models/task_model.dart';
import '../../../data/models/team_status_model.dart';
import '../../../services/brain_api_service.dart';
import '../../../services/brain_websocket_service.dart';

/// ViewModel for the Instance Detail page.
///
/// Loads all data scoped to a single instance: agent nexus, execution log,
/// brain events (paginated), tasks (filtered by project slug), and team
/// status. Subscribes to WebSocket streams for live updates.
class InstanceDetailViewModel extends GetxController {
  final BrainApiService _api = Get.find();
  final BrainWebSocketService _ws = Get.find();

  // ---------------------------------------------------------------------------
  // Loading state
  // ---------------------------------------------------------------------------

  /// True during initial data fetch.
  final RxBool isLoading = true.obs;

  // ---------------------------------------------------------------------------
  // Reactive state
  // ---------------------------------------------------------------------------

  /// The instance ID currently being viewed.
  final RxString currentInstanceId = ''.obs;

  /// The resolved instance model.
  final Rx<InstanceModel?> instance = Rx<InstanceModel?>(null);

  /// Agent nexus data for this instance.
  final RxList<AgentNexusEntry> nexusData = <AgentNexusEntry>[].obs;

  /// Execution log entries for this instance.
  final RxList<ExecutionLogEntry> executionLogs = <ExecutionLogEntry>[].obs;

  /// Brain events filtered by instance ID.
  final RxList<BrainEventModel> instanceEvents = <BrainEventModel>[].obs;

  /// Total event count for pagination.
  final RxInt eventTotal = 0.obs;

  /// Current pagination offset for events.
  final RxInt eventOffset = 0.obs;

  /// Events page size.
  static const int _eventPageSize = 50;

  /// Tasks filtered by the instance's project slug.
  final RxList<TaskModel> instanceTasks = <TaskModel>[].obs;

  /// Team status data from WebSocket.
  final Rx<TeamStatusModel?> teamStatus = Rx<TeamStatusModel?>(null);

  /// Per-instance retry counter.
  final RxInt retryCount = 0.obs;

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

  /// Load all instance-scoped data for the given [instanceId].
  ///
  /// Finds the instance from the cached instance list, then fetches
  /// agents, execution log, events, and tasks in parallel.
  Future<void> loadInstance(String instanceId) async {
    if (instanceId == currentInstanceId.value && instance.value != null) return;

    currentInstanceId.value = instanceId;
    isLoading.value = true;

    // Clear previous data.
    instance.value = null;
    nexusData.clear();
    executionLogs.clear();
    instanceEvents.clear();
    instanceTasks.clear();
    teamStatus.value = null;
    retryCount.value = 0;
    eventOffset.value = 0;
    eventTotal.value = 0;

    // Resolve instance from the brain instances list.
    final instancesData = await _api.getBrainInstances();
    if (instancesData != null) {
      final raw = instancesData['instances'] as List<dynamic>? ?? [];
      final allInstances = raw
          .whereType<Map<String, dynamic>>()
          .map(InstanceModel.fromJson)
          .toList();
      instance.value =
          allInstances.firstWhereOrNull((i) => i.id == instanceId);
    }

    // Parallel fetch of scoped data.
    await Future.wait([
      _fetchAgents(instanceId),
      _fetchExecutionLog(instanceId),
      _fetchEvents(instanceId),
      if (instance.value != null)
        _fetchTasks(instance.value!.projectSlug),
    ]);

    // Fetch team status.
    final teamData = await _api.getTeamStatus();
    if (teamData != null) {
      teamStatus.value = TeamStatusModel.fromJson(teamData);
    }

    isLoading.value = false;
  }

  /// Force refresh all data for the current instance.
  Future<void> refreshData() async {
    if (currentInstanceId.value.isEmpty) return;
    final instanceId = currentInstanceId.value;

    // Re-resolve instance (may have updated).
    final instancesData = await _api.getBrainInstances();
    if (instancesData != null) {
      final raw = instancesData['instances'] as List<dynamic>? ?? [];
      final allInstances = raw
          .whereType<Map<String, dynamic>>()
          .map(InstanceModel.fromJson)
          .toList();
      instance.value =
          allInstances.firstWhereOrNull((i) => i.id == instanceId);
    }

    await Future.wait([
      _fetchAgents(instanceId),
      _fetchExecutionLog(instanceId),
      _fetchEvents(instanceId),
      if (instance.value != null)
        _fetchTasks(instance.value!.projectSlug),
    ]);
  }

  // ---------------------------------------------------------------------------
  // REST data fetching
  // ---------------------------------------------------------------------------

  Future<void> _fetchAgents(String instanceId) async {
    final data = await _api.getInstanceAgents(instanceId);
    if (data != null) {
      final raw = data['agents'] as List<dynamic>? ?? [];
      nexusData.value = raw
          .whereType<Map<String, dynamic>>()
          .map(AgentNexusEntry.fromJson)
          .toList();
    }
  }

  Future<void> _fetchExecutionLog(String instanceId) async {
    final data = await _api.getInstanceLog(instanceId);
    executionLogs.value =
        data.map((e) => ExecutionLogEntry.fromJson(e)).toList();

    // Count retries from log entries.
    retryCount.value =
        executionLogs.where((e) => e.eventType == 'retry').length;
  }

  Future<void> _fetchEvents(String instanceId) async {
    final data = await _api.getBrainEvents(
      instanceId: instanceId,
      limit: _eventPageSize,
      offset: eventOffset.value,
    );
    if (data != null) {
      final raw = data['events'] as List<dynamic>? ?? [];
      instanceEvents.value = raw
          .whereType<Map<String, dynamic>>()
          .map(BrainEventModel.fromJson)
          .toList();
      eventTotal.value = data['total'] as int? ?? instanceEvents.length;
    }
  }

  Future<void> _fetchTasks(String projectSlug) async {
    final data = await _api.getBrainTasks(
      projectSlug: projectSlug,
      limit: 200,
    );
    if (data != null) {
      final raw = data['tasks'] as List<dynamic>? ?? [];
      instanceTasks.value = raw
          .whereType<Map<String, dynamic>>()
          .map(TaskModel.fromJson)
          .toList();
    }
  }

  // ---------------------------------------------------------------------------
  // Pagination
  // ---------------------------------------------------------------------------

  /// Navigate to the next page of events.
  void nextEventsPage() {
    if (eventOffset.value + _eventPageSize < eventTotal.value) {
      eventOffset.value += _eventPageSize;
      _fetchEvents(currentInstanceId.value);
    }
  }

  /// Navigate to the previous page of events.
  void prevEventsPage() {
    if (eventOffset.value > 0) {
      eventOffset.value =
          (eventOffset.value - _eventPageSize).clamp(0, eventTotal.value);
      _fetchEvents(currentInstanceId.value);
    }
  }

  /// Current page number (1-based).
  int get currentPage => (eventOffset.value ~/ _eventPageSize) + 1;

  /// Total number of pages.
  int get totalPages =>
      eventTotal.value > 0
          ? ((eventTotal.value + _eventPageSize - 1) ~/ _eventPageSize)
          : 1;

  /// Whether there is a previous page of events.
  bool get hasPrevPage => eventOffset.value > 0;

  /// Whether there is a next page of events.
  bool get hasNextPage =>
      eventOffset.value + _eventPageSize < eventTotal.value;

  // ---------------------------------------------------------------------------
  // WebSocket listeners
  // ---------------------------------------------------------------------------

  void _setupWebSocketListeners() {
    // Live instance list updates -- refresh current instance model.
    ever(_ws.brainInstances, (Map<String, dynamic>? data) {
      if (data == null || currentInstanceId.value.isEmpty) return;
      final raw = data['instances'] as List<dynamic>? ?? [];
      final allInstances = raw
          .whereType<Map<String, dynamic>>()
          .map(InstanceModel.fromJson)
          .toList();
      instance.value = allInstances
          .firstWhereOrNull((i) => i.id == currentInstanceId.value);
    });

    // Per-instance agent execution events.
    ever(_ws.instanceAgentEvent, (Map<String, dynamic>? data) {
      if (data == null || currentInstanceId.value.isEmpty) return;
      final eventInstanceId = data['instance_id'] as String? ?? '';
      if (eventInstanceId != currentInstanceId.value) return;

      // Append to execution log.
      final entry = ExecutionLogEntry.fromJson(data);
      final logs = List<ExecutionLogEntry>.from(executionLogs);
      logs.add(entry);
      if (logs.length > AgentConstants.maxBattleLog) {
        logs.removeRange(0, logs.length - AgentConstants.maxBattleLog);
      }
      executionLogs.value = logs;

      // Update nexus from event.
      _updateNexusFromEvent(data);

      // Track retries.
      if (entry.eventType == 'retry') {
        retryCount.value++;
      }
    });

    // Team status updates.
    ever(_ws.teamStatus, (Map<String, dynamic>? data) {
      if (data != null) {
        teamStatus.value = TeamStatusModel.fromJson(data);
      }
    });
  }

  void _updateNexusFromEvent(Map<String, dynamic> data) {
    final agent = data['agent'] as String? ?? '';
    final eventType = data['event_type'] as String? ?? '';
    final durationMs = data['duration_ms'] as int? ?? 0;
    final inputTokens = data['input_tokens'] as int? ?? 0;
    final outputTokens = data['output_tokens'] as int? ?? 0;

    final entries = List<AgentNexusEntry>.from(nexusData);

    final idx = entries.indexWhere((e) => e.agent == agent);
    if (idx >= 0) {
      final existing = entries[idx];
      String newStatus;
      switch (eventType) {
        case 'start':
          newStatus = 'WORKING';
        case 'stop':
          newStatus = data['result'] == 'success' ||
                  data['result'] == 'APPROVE'
              ? 'DONE'
              : 'FAIL';
        case 'error':
          newStatus = 'FAIL';
        default:
          newStatus = existing.status ?? 'IDLE';
      }
      entries[idx] = AgentNexusEntry(
        agent: agent,
        status: newStatus,
        totalDurationMs: existing.totalDurationMs + durationMs,
        totalTokens: existing.totalTokens + inputTokens + outputTokens,
        eventCount: existing.eventCount + 1,
      );
    } else {
      entries.add(AgentNexusEntry(
        agent: agent,
        status: eventType == 'start' ? 'WORKING' : 'IDLE',
        totalDurationMs: durationMs,
        totalTokens: inputTokens + outputTokens,
        eventCount: 1,
      ));
    }

    nexusData.value = entries;
  }
}
