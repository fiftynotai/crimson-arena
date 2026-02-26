import 'dart:async';

import 'package:get/get.dart';

import '../../../data/models/agent_model.dart';
import '../../../data/models/brain_event_model.dart';
import '../../../data/models/brief_model.dart';
import '../../../data/models/instance_model.dart';
import '../../../data/models/task_model.dart';
import '../../../services/brain_api_service.dart';
import '../../../services/brain_websocket_service.dart';
import '../../../services/project_selector_service.dart';

/// ViewModel for the Home page.
///
/// Manages focused dashboard state: agents, instances summary, recent tasks,
/// recent events, and project-scoped briefs.
///
/// Data flows from two sources:
/// 1. REST polling (initial load + periodic fallback)
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
  // Agents
  // ---------------------------------------------------------------------------

  /// Agent roster indexed by agent name.
  final RxMap<String, AgentModel> agents = <String, AgentModel>{}.obs;

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
  // Polling timers
  // ---------------------------------------------------------------------------

  Timer? _stateTimer;

  // ---------------------------------------------------------------------------
  // Lifecycle
  // ---------------------------------------------------------------------------

  @override
  void onInit() {
    super.onInit();
    _fetchInitialData();
    _setupWebSocketListeners();
    _setupPollingTimers();

    // Re-fetch data when the global project selector changes.
    ever(_projectSelector.selectedProjectSlug, (_) => refreshData());
  }

  @override
  void onClose() {
    _stateTimer?.cancel();
    super.onClose();
  }

  // ---------------------------------------------------------------------------
  // Initial data fetch
  // ---------------------------------------------------------------------------

  Future<void> _fetchInitialData() async {
    isLoading.value = true;

    await Future.wait([
      _fetchState(),
      _fetchInstances(),
      _fetchRecentTasks(),
      _fetchRecentEvents(),
    ]);

    isLoading.value = false;
  }

  // ---------------------------------------------------------------------------
  // REST data fetching
  // ---------------------------------------------------------------------------

  Future<void> _fetchState() async {
    final state = await _apiService.getState();
    if (state != null) {
      _parseState(state);
    }
  }

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
  // State parsing
  // ---------------------------------------------------------------------------

  void _parseState(Map<String, dynamic> state) {
    // Agents
    final agentsData = state['agents'] as Map<String, dynamic>?;
    if (agentsData != null) {
      _parseAgents(agentsData);
    }
  }

  void _parseAgents(Map<String, dynamic> agentsData) {
    agents.clear();
    for (final entry in agentsData.entries) {
      if (entry.value is Map<String, dynamic>) {
        agents[entry.key] = AgentModel.fromJson(
          entry.key,
          entry.value as Map<String, dynamic>,
        );
      }
    }
  }

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
    // Full state updates (for agents)
    ever(_wsService.state, (Map<String, dynamic>? wsState) {
      if (wsState != null) {
        _parseState(wsState);
      }
    });

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
  // Polling fallback
  // ---------------------------------------------------------------------------

  void _setupPollingTimers() {
    // State polling every 10s as fallback when WebSocket is disconnected.
    _stateTimer = Timer.periodic(
      const Duration(milliseconds: 10000),
      (_) {
        if (!_wsService.isConnected.value) {
          _fetchState();
        }
      },
    );
  }

  // ---------------------------------------------------------------------------
  // Public actions
  // ---------------------------------------------------------------------------

  /// Refresh all data.
  Future<void> refreshData() async {
    await Future.wait([
      _fetchState(),
      _fetchInstances(),
      _fetchRecentTasks(),
      _fetchRecentEvents(),
    ]);
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
