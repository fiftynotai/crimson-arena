import 'dart:convert';

/// A brain event record from the Igris brain event log.
///
/// Represents a single event emitted by a brain component (session,
/// instance, hook, etc.) and stored in the brain database.
class BrainEventModel {
  final int id;
  final String eventName;
  final String component;
  final Map<String, dynamic> payload;
  final String? machineHostname;
  final String? projectSlug;
  final String? instanceId;
  final String createdAt;

  const BrainEventModel({
    required this.id,
    required this.eventName,
    required this.component,
    required this.payload,
    this.machineHostname,
    this.projectSlug,
    this.instanceId,
    required this.createdAt,
  });

  factory BrainEventModel.fromJson(Map<String, dynamic> json) =>
      BrainEventModel(
        id: json['id'] as int? ?? 0,
        eventName: json['event_name'] as String? ?? '',
        component: json['component'] as String? ?? '',
        payload: json['payload'] is String
            ? _tryParseJson(json['payload'] as String)
            : (json['payload'] as Map<String, dynamic>? ?? {}),
        machineHostname: json['machine_hostname'] as String?,
        projectSlug: json['project_slug'] as String?,
        instanceId: json['instance_id'] as String?,
        createdAt: json['created_at'] as String? ?? json['timestamp'] as String? ?? '',
      );

  static Map<String, dynamic> _tryParseJson(String s) {
    try {
      return Map<String, dynamic>.from(jsonDecode(s) as Map);
    } catch (_) {
      return {};
    }
  }

  // ---------------------------------------------------------------------------
  // Convenience getters for context correlation
  // ---------------------------------------------------------------------------

  /// Extracts the brief ID from the event payload.
  ///
  /// Brief events use `brief_id`; some payloads also use `briefId`.
  String? get briefId =>
      payload['brief_id'] as String? ?? payload['briefId'] as String?;

  /// Extracts the task ID from the event payload.
  ///
  /// Task events use `task_id`; `task.failed` uses camelCase `taskId`.
  String? get taskId =>
      payload['task_id'] as String? ?? payload['taskId'] as String?;

  /// Whether this event has any navigable context links.
  bool get hasContextLinks =>
      briefId != null || taskId != null || instanceId != null;

  Map<String, dynamic> toJson() => {
        'id': id,
        'event_name': eventName,
        'component': component,
        'payload': payload,
        'machine_hostname': machineHostname,
        'project_slug': projectSlug,
        'instance_id': instanceId,
        'created_at': createdAt,
      };
}
