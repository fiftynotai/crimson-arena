/// Per-project token and duration breakdown for a single agent.
///
/// Returned by the brain's `/api/agent-metrics/by-project?agent=X` endpoint.
/// Each entry represents an agent's cumulative metrics within one project.
class AgentProjectMetrics {
  final String projectSlug;
  final int inputTokens;
  final int outputTokens;
  final int cacheRead;
  final int cacheCreate;
  final int totalDurationMs;
  final int eventCount;
  final String? lastEventAt;

  const AgentProjectMetrics({
    required this.projectSlug,
    required this.inputTokens,
    required this.outputTokens,
    required this.cacheRead,
    required this.cacheCreate,
    required this.totalDurationMs,
    required this.eventCount,
    this.lastEventAt,
  });

  factory AgentProjectMetrics.fromJson(Map<String, dynamic> json) =>
      AgentProjectMetrics(
        projectSlug: json['project_slug'] as String? ?? '',
        inputTokens: json['input_tokens'] as int? ?? 0,
        outputTokens: json['output_tokens'] as int? ?? 0,
        cacheRead: json['cache_read'] as int? ?? 0,
        cacheCreate: json['cache_create'] as int? ?? 0,
        totalDurationMs: json['total_duration_ms'] as int? ?? 0,
        eventCount: json['event_count'] as int? ?? 0,
        lastEventAt: json['last_event_at'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'project_slug': projectSlug,
        'input_tokens': inputTokens,
        'output_tokens': outputTokens,
        'cache_read': cacheRead,
        'cache_create': cacheCreate,
        'total_duration_ms': totalDurationMs,
        'event_count': eventCount,
        'last_event_at': lastEventAt,
      };
}

extension AgentProjectMetricsExtensions on AgentProjectMetrics {
  /// Total tokens consumed across all four buckets.
  int get totalTokens => inputTokens + outputTokens + cacheRead + cacheCreate;

  /// Duration in seconds.
  double get durationSeconds => totalDurationMs / 1000;
}
