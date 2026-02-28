import 'dart:convert';

import 'package:get/get.dart';
import 'package:http/http.dart' as http;

import '../core/constants/api_constants.dart';

/// REST API service for all Crimson Arena dashboard HTTP calls.
///
/// Wraps the `http` package. Since the Flutter Web app is served from
/// the same origin as the dashboard server, we use [Uri.base.origin]
/// as the base URL.
///
/// All methods return parsed JSON maps or `null` on failure.
class BrainApiService extends GetxService {
  final http.Client _client = http.Client();

  /// Base URL derived from the current browser origin.
  String get _baseUrl => Uri.base.origin;

  // ---------------------------------------------------------------------------
  // Internal helpers
  // ---------------------------------------------------------------------------

  Future<Map<String, dynamic>?> _getJson(String path,
      {Map<String, String>? queryParams}) async {
    try {
      final uri = Uri.parse('$_baseUrl$path').replace(
        queryParameters: queryParams,
      );
      final response = await _client.get(uri);
      if (response.statusCode != 200) return null;
      final decoded = jsonDecode(response.body);
      if (decoded is Map<String, dynamic>) return decoded;
      return null;
    } catch (_) {
      return null;
    }
  }

  Future<List<Map<String, dynamic>>> _getJsonList(String path,
      {Map<String, String>? queryParams}) async {
    try {
      final uri = Uri.parse('$_baseUrl$path').replace(
        queryParameters: queryParams,
      );
      final response = await _client.get(uri);
      if (response.statusCode != 200) return [];
      final decoded = jsonDecode(response.body);
      if (decoded is List) {
        return decoded.cast<Map<String, dynamic>>();
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  // ---------------------------------------------------------------------------
  // State & Agents
  // ---------------------------------------------------------------------------

  /// Fetch full dashboard state filtered by time range.
  Future<Map<String, dynamic>?> getState({String range = 'today'}) =>
      _getJson(ApiConstants.state, queryParams: {'range': range});

  /// Fetch agent summary with levels and RPG stats.
  Future<Map<String, dynamic>?> getAgents({String range = 'today'}) =>
      _getJson(ApiConstants.agents, queryParams: {'range': range});

  // ---------------------------------------------------------------------------
  // Budget & Pricing
  // ---------------------------------------------------------------------------

  /// Fetch today's budget consumption vs ceiling.
  Future<Map<String, dynamic>?> getBudget() =>
      _getJson(ApiConstants.budget);

  /// Fetch Claude model pricing map.
  Future<Map<String, dynamic>?> getPricing() =>
      _getJson(ApiConstants.pricing);

  // ---------------------------------------------------------------------------
  // Events
  // ---------------------------------------------------------------------------

  /// Fetch recent events (battle log).
  Future<List<Map<String, dynamic>>> getEvents({
    int limit = 50,
    String range = 'today',
  }) =>
      _getJsonList(
        ApiConstants.events,
        queryParams: {'limit': limit.toString(), 'range': range},
      );

  // ---------------------------------------------------------------------------
  // Brain Proxy
  // ---------------------------------------------------------------------------

  /// Fetch brain health and stats.
  Future<Map<String, dynamic>?> getBrainHealth() =>
      _getJson(ApiConstants.brainHealth);

  /// Fetch active brain instances.
  Future<Map<String, dynamic>?> getBrainInstances() =>
      _getJson(ApiConstants.brainInstances);

  /// Fetch per-instance agent stats.
  Future<Map<String, dynamic>?> getInstanceAgents(String instanceId) =>
      _getJson(ApiConstants.instanceAgents(instanceId));

  /// Fetch per-instance execution log.
  Future<List<Map<String, dynamic>>> getInstanceLog(
    String instanceId, {
    int limit = 50,
  }) =>
      _getJsonList(
        ApiConstants.instanceLog(instanceId),
        queryParams: {'limit': limit.toString()},
      );

  /// Fetch cross-instance agent performance summary.
  ///
  /// When [projectSlug] is provided the brain filters the summary
  /// to metrics from that single project.
  Future<Map<String, dynamic>?> getAgentMetricsSummary({
    String? projectSlug,
  }) {
    final params = <String, String>{};
    if (projectSlug != null) params['project_slug'] = projectSlug;
    return _getJson(
      ApiConstants.agentMetricsSummary,
      queryParams: params.isNotEmpty ? params : null,
    );
  }

  /// Fetch per-project metrics breakdown for a single [agent].
  Future<Map<String, dynamic>?> getAgentMetricsByProject(String agent) =>
      _getJson(ApiConstants.agentMetricsByProject(agent));

  /// Fetch registered projects.
  Future<Map<String, dynamic>?> getBrainProjects() =>
      _getJson(ApiConstants.brainProjects);

  /// Fetch per-project budget with cost breakdown.
  Future<Map<String, dynamic>?> getProjectBudget(String slug) =>
      _getJson(ApiConstants.projectBudget(slug));

  /// Fetch briefs, optionally filtered.
  Future<Map<String, dynamic>?> getBrainBriefs({
    String? status,
    String? project,
  }) {
    final params = <String, String>{};
    if (status != null) params['status'] = status;
    if (project != null) params['project'] = project;
    return _getJson(
      ApiConstants.brainBriefs,
      queryParams: params.isNotEmpty ? params : null,
    );
  }

  /// Fetch recent sessions.
  Future<Map<String, dynamic>?> getBrainSessions({int days = 7}) =>
      _getJson(
        ApiConstants.brainSessions,
        queryParams: {'days': days.toString()},
      );

  /// Fetch brain events with optional filters.
  Future<Map<String, dynamic>?> getBrainEvents({
    String? eventName,
    String? component,
    String? project,
    String? instanceId,
    String? since,
    String? until,
    int limit = 100,
    int offset = 0,
  }) {
    final params = <String, String>{
      'limit': '$limit',
      'offset': '$offset',
    };
    if (eventName != null) params['event_name'] = eventName;
    if (component != null) params['component'] = component;
    if (project != null) params['project'] = project;
    if (instanceId != null) params['instance_id'] = instanceId;
    if (since != null) params['since'] = since;
    if (until != null) params['until'] = until;
    return _getJson(ApiConstants.brainEvents, queryParams: params);
  }

  /// Fetch brain tasks with optional filters.
  Future<Map<String, dynamic>?> getBrainTasks({
    String? status,
    String? taskType,
    String? projectSlug,
    String? assignee,
    String? scope,
    int limit = 50,
    int offset = 0,
  }) {
    final params = <String, String>{
      'limit': '$limit',
      'offset': '$offset',
    };
    if (status != null) params['status'] = status;
    if (taskType != null) params['task_type'] = taskType;
    if (projectSlug != null) params['project_slug'] = projectSlug;
    if (assignee != null) params['assignee'] = assignee;
    if (scope != null) params['scope'] = scope;
    return _getJson(ApiConstants.brainTasks, queryParams: params);
  }

  // ---------------------------------------------------------------------------
  // Dashboard-specific
  // ---------------------------------------------------------------------------

  /// Fetch sync pipeline status.
  Future<Map<String, dynamic>?> getSyncStatus() =>
      _getJson(ApiConstants.syncStatus);

  /// Fetch team mode status.
  Future<Map<String, dynamic>?> getTeamStatus() =>
      _getJson(ApiConstants.teamStatus);

  /// Fetch knowledge base state.
  Future<Map<String, dynamic>?> getBrainKnowledge() =>
      _getJson(ApiConstants.brainKnowledge);

  /// Fetch skill invocation heatmap, optionally filtered by project.
  Future<Map<String, dynamic>?> getSkillHeatmap({
    String range = 'all',
    String? projectSlug,
  }) {
    final params = <String, String>{'range': range};
    if (projectSlug != null) params['project'] = projectSlug;
    return _getJson(ApiConstants.skillHeatmap, queryParams: params);
  }

  /// Fetch recent invocations for a specific skill.
  Future<Map<String, dynamic>?> getSkillUsage(
    String name, {
    int limit = 20,
    String? projectSlug,
  }) {
    final params = <String, String>{'limit': '$limit'};
    if (projectSlug != null) params['project'] = projectSlug;
    return _getJson(ApiConstants.skillUsage(name), queryParams: params);
  }

  // ---------------------------------------------------------------------------
  // Lifecycle
  // ---------------------------------------------------------------------------

  @override
  void onClose() {
    _client.close();
    super.onClose();
  }
}
