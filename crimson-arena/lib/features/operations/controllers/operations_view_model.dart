import 'package:get/get.dart';

import '../../../data/models/project_model.dart';
import '../../../data/models/session_model.dart';
import '../../../services/brain_api_service.dart';
import '../../../services/brain_websocket_service.dart';

/// ViewModel for the Operations page.
///
/// Manages brain infrastructure data: health, sync status, knowledge base,
/// registered projects, and recent sessions.
///
/// Data flows from two sources:
/// 1. REST (initial load)
/// 2. WebSocket streams (real-time updates)
class OperationsViewModel extends GetxController {
  final BrainApiService _apiService = Get.find();
  final BrainWebSocketService _wsService = Get.find();

  // ---------------------------------------------------------------------------
  // Loading state
  // ---------------------------------------------------------------------------

  /// True during initial data fetch.
  final RxBool isLoading = true.obs;

  // ---------------------------------------------------------------------------
  // Reactive state
  // ---------------------------------------------------------------------------

  /// Brain health data (DB status, uptime, memory, etc.)
  final Rx<Map<String, dynamic>?> brainHealth =
      Rx<Map<String, dynamic>?>(null);

  /// Sync pipeline status (last push/pull, queue depth, online/offline).
  final Rx<Map<String, dynamic>?> syncStatus =
      Rx<Map<String, dynamic>?>(null);

  /// Knowledge base state (entry counts, categories, last updated).
  final Rx<Map<String, dynamic>?> knowledgeState =
      Rx<Map<String, dynamic>?>(null);

  /// Registered brain projects.
  final RxList<ProjectModel> projects = <ProjectModel>[].obs;

  /// Recent brain sessions.
  final RxList<SessionModel> sessions = <SessionModel>[].obs;

  // ---------------------------------------------------------------------------
  // Lifecycle
  // ---------------------------------------------------------------------------

  @override
  void onInit() {
    super.onInit();
    _fetchInitialData();
    _setupWebSocketListeners();
  }

  // ---------------------------------------------------------------------------
  // Initial data fetch
  // ---------------------------------------------------------------------------

  Future<void> _fetchInitialData() async {
    isLoading.value = true;

    await Future.wait([
      _fetchBrainHealth(),
      _fetchSyncStatus(),
      _fetchKnowledge(),
      _fetchProjects(),
      _fetchSessions(),
    ]);

    isLoading.value = false;
  }

  // ---------------------------------------------------------------------------
  // REST data fetching
  // ---------------------------------------------------------------------------

  Future<void> _fetchBrainHealth() async {
    final data = await _apiService.getBrainHealth();
    if (data != null) {
      brainHealth.value = data;
    }
  }

  Future<void> _fetchSyncStatus() async {
    final data = await _apiService.getSyncStatus();
    if (data != null) {
      syncStatus.value = data;
    }
  }

  Future<void> _fetchKnowledge() async {
    final data = await _apiService.getBrainKnowledge();
    if (data != null) {
      knowledgeState.value = data;
    }
  }

  Future<void> _fetchProjects() async {
    final data = await _apiService.getBrainProjects();
    if (data != null) {
      _parseProjects(data);
    }
  }

  Future<void> _fetchSessions() async {
    final data = await _apiService.getBrainSessions();
    if (data != null) {
      _parseSessions(data);
    }
  }

  // ---------------------------------------------------------------------------
  // Data parsing
  // ---------------------------------------------------------------------------

  void _parseProjects(Map<String, dynamic> data) {
    final raw = data['projects'] as List<dynamic>? ?? [];
    projects.value = raw
        .whereType<Map<String, dynamic>>()
        .map(ProjectModel.fromJson)
        .toList()
      ..sort((a, b) => a.name.compareTo(b.name));
  }

  void _parseSessions(Map<String, dynamic> data) {
    final raw = data['sessions'] as List<dynamic>? ?? [];
    sessions.value = raw
        .whereType<Map<String, dynamic>>()
        .map(SessionModel.fromJson)
        .toList();
  }

  // ---------------------------------------------------------------------------
  // WebSocket listeners
  // ---------------------------------------------------------------------------

  void _setupWebSocketListeners() {
    ever(_wsService.brainHealth, (Map<String, dynamic>? data) {
      if (data != null) brainHealth.value = data;
    });

    ever(_wsService.syncStatus, (Map<String, dynamic>? data) {
      if (data != null) syncStatus.value = data;
    });

    ever(_wsService.knowledgeState, (Map<String, dynamic>? data) {
      if (data != null) knowledgeState.value = data;
    });

    ever(_wsService.brainProjects, (Map<String, dynamic>? data) {
      if (data != null) _parseProjects(data);
    });

    ever(_wsService.brainSessions, (Map<String, dynamic>? data) {
      if (data != null) _parseSessions(data);
    });

    // Brain state composite may include nested health/sync/knowledge data.
    ever(_wsService.brainState, (Map<String, dynamic>? data) {
      if (data == null) return;
      final health = data['health'] as Map<String, dynamic>?;
      if (health != null) brainHealth.value = health;

      final sync = data['sync'] as Map<String, dynamic>?;
      if (sync != null) syncStatus.value = sync;

      final knowledge = data['knowledge'] as Map<String, dynamic>?;
      if (knowledge != null) knowledgeState.value = knowledge;

      final projectsData = data['projects'];
      if (projectsData is Map<String, dynamic>) {
        _parseProjects(projectsData);
      }

      final sessionsData = data['sessions'];
      if (sessionsData is Map<String, dynamic>) {
        _parseSessions(sessionsData);
      }
    });
  }

  // ---------------------------------------------------------------------------
  // Public actions
  // ---------------------------------------------------------------------------

  /// Refresh all operations data.
  Future<void> refreshData() async {
    await Future.wait([
      _fetchBrainHealth(),
      _fetchSyncStatus(),
      _fetchKnowledge(),
      _fetchProjects(),
      _fetchSessions(),
    ]);
  }
}
