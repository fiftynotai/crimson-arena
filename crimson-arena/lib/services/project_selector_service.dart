import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

import '../data/models/project_model.dart';
import 'brain_api_service.dart';
import 'brain_websocket_service.dart';

/// Global project selector service.
///
/// Owns the current project filter selection and the list of available
/// projects. ViewModels listen to [selectedProjectSlug] via `ever()` to
/// re-fetch or re-filter data when the user changes the global project.
///
/// Selection is persisted to [GetStorage] so it survives page refreshes.
class ProjectSelectorService extends GetxService {
  static const String _storageKey = 'selected_project';

  final BrainApiService _api = Get.find();
  final BrainWebSocketService _ws = Get.find();

  late final GetStorage _storage;

  // ---------------------------------------------------------------------------
  // Reactive state
  // ---------------------------------------------------------------------------

  /// Currently selected project slug. `null` means "All Projects".
  final selectedProjectSlug = Rxn<String>();

  /// Available projects from the brain.
  final projects = <ProjectModel>[].obs;

  /// Whether the project list is still loading.
  final isLoading = true.obs;

  // ---------------------------------------------------------------------------
  // Computed getters
  // ---------------------------------------------------------------------------

  /// The currently selected project model, or `null` when showing all.
  ProjectModel? get selectedProject {
    final slug = selectedProjectSlug.value;
    if (slug == null) return null;
    return projects.firstWhereOrNull((p) => p.slug == slug);
  }

  // ---------------------------------------------------------------------------
  // Lifecycle
  // ---------------------------------------------------------------------------

  @override
  void onInit() {
    super.onInit();
    _storage = GetStorage();

    // Restore persisted selection.
    final persisted = _storage.read<String>(_storageKey);
    if (persisted != null && persisted.isNotEmpty) {
      selectedProjectSlug.value = persisted;
    }

    // Fetch projects via REST.
    _fetchProjects();

    // Listen for WebSocket project updates.
    ever(_ws.brainProjects, (Map<String, dynamic>? data) {
      if (data != null) {
        _parseProjects(data);
      }
    });
  }

  // ---------------------------------------------------------------------------
  // Data fetching
  // ---------------------------------------------------------------------------

  Future<void> _fetchProjects() async {
    isLoading.value = true;
    final data = await _api.getBrainProjects();
    if (data != null) {
      _parseProjects(data);
    }
    isLoading.value = false;
  }

  void _parseProjects(Map<String, dynamic> data) {
    final raw = data['projects'] as List<dynamic>? ?? [];
    projects.value = raw
        .whereType<Map<String, dynamic>>()
        .map(ProjectModel.fromJson)
        .toList()
      ..sort((a, b) => a.name.compareTo(b.name));

    // Validate that the persisted slug still exists.
    final slug = selectedProjectSlug.value;
    if (slug != null && !projects.any((p) => p.slug == slug)) {
      selectedProjectSlug.value = null;
      _storage.remove(_storageKey);
    }
  }

  // ---------------------------------------------------------------------------
  // Public actions
  // ---------------------------------------------------------------------------

  /// Select a project by slug. Pass `null` to show all projects.
  void selectProject(String? slug) {
    selectedProjectSlug.value = slug;
    if (slug != null) {
      _storage.write(_storageKey, slug);
    } else {
      _storage.remove(_storageKey);
    }
  }
}
