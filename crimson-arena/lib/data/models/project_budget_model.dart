/// Per-agent cost breakdown within a project budget period.
///
/// Contains token counts, event count, and computed dollar costs
/// for a single agent's usage.
class AgentCostBreakdown {
  final String agent;
  final int inputTokens;
  final int outputTokens;
  final int cacheRead;
  final int cacheCreate;
  final int eventCount;
  final double inputCost;
  final double outputCost;
  final double cacheReadCost;
  final double cacheCreateCost;
  final double totalCost;

  const AgentCostBreakdown({
    required this.agent,
    required this.inputTokens,
    required this.outputTokens,
    required this.cacheRead,
    required this.cacheCreate,
    required this.eventCount,
    required this.inputCost,
    required this.outputCost,
    required this.cacheReadCost,
    required this.cacheCreateCost,
    required this.totalCost,
  });

  factory AgentCostBreakdown.fromJson(Map<String, dynamic> json) =>
      AgentCostBreakdown(
        agent: json['agent'] as String? ?? 'unknown',
        inputTokens: json['input_tokens'] as int? ?? 0,
        outputTokens: json['output_tokens'] as int? ?? 0,
        cacheRead: json['cache_read'] as int? ?? 0,
        cacheCreate: json['cache_create'] as int? ?? 0,
        eventCount: json['event_count'] as int? ?? 0,
        inputCost: (json['input_cost'] as num?)?.toDouble() ?? 0.0,
        outputCost: (json['output_cost'] as num?)?.toDouble() ?? 0.0,
        cacheReadCost: (json['cache_read_cost'] as num?)?.toDouble() ?? 0.0,
        cacheCreateCost:
            (json['cache_create_cost'] as num?)?.toDouble() ?? 0.0,
        totalCost: (json['total_cost'] as num?)?.toDouble() ?? 0.0,
      );

  Map<String, dynamic> toJson() => {
        'agent': agent,
        'input_tokens': inputTokens,
        'output_tokens': outputTokens,
        'cache_read': cacheRead,
        'cache_create': cacheCreate,
        'event_count': eventCount,
        'input_cost': inputCost,
        'output_cost': outputCost,
        'cache_read_cost': cacheReadCost,
        'cache_create_cost': cacheCreateCost,
        'total_cost': totalCost,
      };
}

/// Per-project budget tracking for a given period.
///
/// Aggregates token usage and dollar costs across all agents,
/// optionally compared against a budget limit with alert levels.
class ProjectBudgetModel {
  final String projectSlug;
  final String period;
  final double? budgetLimit;
  final List<AgentCostBreakdown> byAgent;
  final int totalInputTokens;
  final int totalOutputTokens;
  final int totalCacheRead;
  final int totalCacheCreate;
  final int totalEventCount;
  final double inputCost;
  final double outputCost;
  final double cacheReadCost;
  final double cacheCreateCost;
  final double totalCost;
  final double? budgetRatio;
  final String? alertLevel;

  const ProjectBudgetModel({
    required this.projectSlug,
    required this.period,
    this.budgetLimit,
    required this.byAgent,
    required this.totalInputTokens,
    required this.totalOutputTokens,
    required this.totalCacheRead,
    required this.totalCacheCreate,
    required this.totalEventCount,
    required this.inputCost,
    required this.outputCost,
    required this.cacheReadCost,
    required this.cacheCreateCost,
    required this.totalCost,
    this.budgetRatio,
    this.alertLevel,
  });

  factory ProjectBudgetModel.fromJson(Map<String, dynamic> json) {
    final agentList = json['by_agent'] as List<dynamic>? ?? [];
    final totals = json['totals'] as Map<String, dynamic>? ?? {};
    final cost = json['cost'] as Map<String, dynamic>? ?? {};

    return ProjectBudgetModel(
      projectSlug: json['project_slug'] as String? ?? '',
      period: json['period'] as String? ?? 'monthly',
      budgetLimit: (json['budget_limit'] as num?)?.toDouble(),
      byAgent: agentList
          .whereType<Map<String, dynamic>>()
          .map(AgentCostBreakdown.fromJson)
          .toList(),
      totalInputTokens: totals['input_tokens'] as int? ?? 0,
      totalOutputTokens: totals['output_tokens'] as int? ?? 0,
      totalCacheRead: totals['cache_read'] as int? ?? 0,
      totalCacheCreate: totals['cache_create'] as int? ?? 0,
      totalEventCount: totals['event_count'] as int? ?? 0,
      inputCost: (cost['input_cost'] as num?)?.toDouble() ?? 0.0,
      outputCost: (cost['output_cost'] as num?)?.toDouble() ?? 0.0,
      cacheReadCost: (cost['cache_read_cost'] as num?)?.toDouble() ?? 0.0,
      cacheCreateCost:
          (cost['cache_create_cost'] as num?)?.toDouble() ?? 0.0,
      totalCost: (cost['total_cost'] as num?)?.toDouble() ?? 0.0,
      budgetRatio: (json['budget_ratio'] as num?)?.toDouble(),
      alertLevel: json['alert_level'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'project_slug': projectSlug,
        'period': period,
        'budget_limit': budgetLimit,
        'by_agent': byAgent.map((a) => a.toJson()).toList(),
        'totals': {
          'input_tokens': totalInputTokens,
          'output_tokens': totalOutputTokens,
          'cache_read': totalCacheRead,
          'cache_create': totalCacheCreate,
          'event_count': totalEventCount,
        },
        'cost': {
          'input_cost': inputCost,
          'output_cost': outputCost,
          'cache_read_cost': cacheReadCost,
          'cache_create_cost': cacheCreateCost,
          'total_cost': totalCost,
        },
        'budget_ratio': budgetRatio,
        'alert_level': alertLevel,
      };
}

extension ProjectBudgetModelExtensions on ProjectBudgetModel {
  /// Whether this budget has a spending limit configured.
  bool get hasLimit => budgetLimit != null && budgetLimit! > 0;

  /// Percentage of budget consumed, clamped to 0-100.
  double get percentage =>
      budgetRatio != null ? (budgetRatio! * 100).clamp(0, 100) : 0;

  /// Human-readable period label.
  String get periodLabel {
    switch (period) {
      case 'monthly':
        return 'Last 30 days';
      case 'weekly':
        return 'Last 7 days';
      case 'daily':
        return 'Today';
      default:
        return period;
    }
  }
}
