import 'package:flutter/material.dart';

/// A single skill invocation record returned by the skill usage endpoint.
///
/// Represents one row from the `skill_invocations` table with fields
/// for timestamp, session date, and the originating project.
@immutable
class SkillUsageModel {
  /// ISO 8601 timestamp of the invocation.
  final String ts;

  /// Date string (YYYY-MM-DD) of the session in which the skill was invoked.
  final String sessionDate;

  /// Project slug that triggered this invocation (may be empty).
  final String projectSlug;

  const SkillUsageModel({
    required this.ts,
    required this.sessionDate,
    required this.projectSlug,
  });

  /// Parse from the JSON map returned by `/api/skills/{name}/usage`.
  factory SkillUsageModel.fromJson(Map<String, dynamic> json) {
    return SkillUsageModel(
      ts: json['ts'] as String? ?? '',
      sessionDate: json['session_date'] as String? ?? '',
      projectSlug: json['project_slug'] as String? ?? '',
    );
  }
}
