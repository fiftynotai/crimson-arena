import 'dart:convert';

/// A task record from the Igris brain task queue.
///
/// Represents a unit of work that can be claimed by a worker instance,
/// with lifecycle states (pending, active, blocked, done, failed).
class TaskModel {
  final String id;
  final String taskType;
  final String scope;
  final String title;
  final String? description;
  final String? briefId;
  final String? projectSlug;
  final String? parentId;
  final String status;
  final int priority;
  final String? assignee;
  final String? dueAt;
  final String? deferUntil;
  final String? createdBy;
  final String? failReason;
  final int retryCount;
  final int maxRetries;
  final Map<String, dynamic> metadata;
  final String createdAt;
  final String updatedAt;

  const TaskModel({
    required this.id,
    required this.taskType,
    required this.scope,
    required this.title,
    this.description,
    this.briefId,
    this.projectSlug,
    this.parentId,
    required this.status,
    required this.priority,
    this.assignee,
    this.dueAt,
    this.deferUntil,
    this.createdBy,
    this.failReason,
    this.retryCount = 0,
    this.maxRetries = 3,
    this.metadata = const {},
    required this.createdAt,
    required this.updatedAt,
  });

  factory TaskModel.fromJson(Map<String, dynamic> json) => TaskModel(
        id: json['id'] as String? ?? '',
        taskType: json['task_type'] as String? ?? '',
        scope: json['scope'] as String? ?? '',
        title: json['title'] as String? ?? '',
        description: json['description'] as String?,
        briefId: json['brief_id'] as String?,
        projectSlug: json['project_slug'] as String?,
        parentId: json['parent_id'] as String?,
        status: json['status'] as String? ?? 'pending',
        priority: json['priority'] as int? ?? 3,
        assignee: json['assignee'] as String?,
        dueAt: json['due_at'] as String?,
        deferUntil: json['defer_until'] as String?,
        createdBy: json['created_by'] as String?,
        failReason: json['fail_reason'] as String?,
        retryCount: json['retry_count'] as int? ?? 0,
        maxRetries: json['max_retries'] as int? ?? 3,
        metadata: json['metadata'] is String
            ? _tryParseJson(json['metadata'] as String)
            : (json['metadata'] as Map<String, dynamic>? ?? {}),
        createdAt: json['created_at'] as String? ?? '',
        updatedAt: json['updated_at'] as String? ?? '',
      );

  static Map<String, dynamic> _tryParseJson(String s) {
    try {
      return Map<String, dynamic>.from(jsonDecode(s) as Map);
    } catch (_) {
      return {};
    }
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'task_type': taskType,
        'scope': scope,
        'title': title,
        'description': description,
        'brief_id': briefId,
        'project_slug': projectSlug,
        'parent_id': parentId,
        'status': status,
        'priority': priority,
        'assignee': assignee,
        'due_at': dueAt,
        'defer_until': deferUntil,
        'created_by': createdBy,
        'fail_reason': failReason,
        'retry_count': retryCount,
        'max_retries': maxRetries,
        'metadata': metadata,
        'created_at': createdAt,
        'updated_at': updatedAt,
      };

  /// True if the task is awaiting assignment.
  bool get isPending => status == 'pending';

  /// True if the task is currently being worked on.
  bool get isActive => status == 'active';

  /// True if the task is blocked by a dependency or issue.
  bool get isBlocked => status == 'blocked';

  /// True if the task has been completed successfully.
  bool get isDone => status == 'done';

  /// True if the task has failed after retries.
  bool get isFailed => status == 'failed';
}
