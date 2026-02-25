import 'package:get/get.dart';

import '../../../data/models/brain_event_model.dart';
import '../../../services/brain_api_service.dart';
import '../../../services/brain_websocket_service.dart';

/// ViewModel for the Events page.
///
/// Fetches brain events via REST (paginated history) and subscribes to
/// live event updates via WebSocket. Supports component and search filtering.
class EventsViewModel extends GetxController {
  final _api = Get.find<BrainApiService>();
  final _ws = Get.find<BrainWebSocketService>();

  // ---------------------------------------------------------------------------
  // Loading state
  // ---------------------------------------------------------------------------

  /// Whether the initial data load is in progress.
  final RxBool isLoading = true.obs;

  // ---------------------------------------------------------------------------
  // Live feed (from WebSocket)
  // ---------------------------------------------------------------------------

  /// Parsed live events derived from the WebSocket live event feed.
  final liveEvents = <BrainEventModel>[].obs;

  /// Whether the live feed auto-scroll is paused (e.g. user hovering).
  final isPaused = false.obs;

  // ---------------------------------------------------------------------------
  // History (from REST API)
  // ---------------------------------------------------------------------------

  /// Paginated history events from the REST API.
  final historyEvents = <BrainEventModel>[].obs;

  /// Whether a history fetch is currently in progress.
  final isLoadingHistory = false.obs;

  /// Total number of events matching the current filter.
  final historyTotal = 0.obs;

  /// Current pagination offset.
  final historyOffset = 0.obs;

  /// Page size for history pagination.
  final historyLimit = 50.obs;

  // ---------------------------------------------------------------------------
  // Filters
  // ---------------------------------------------------------------------------

  /// Currently selected component filter (null = all).
  final selectedComponent = Rxn<String>();

  /// Currently selected project filter (null = all).
  final selectedProject = Rxn<String>();

  /// Free-text search query (filters by event name).
  final searchQuery = ''.obs;

  /// Available component names for filter chips.
  final components = <String>[
    'schedules',
    'cache',
    'coordination',
    'tasks',
    'monitoring',
    'sync',
    'instances',
  ];

  // ---------------------------------------------------------------------------
  // Lifecycle
  // ---------------------------------------------------------------------------

  @override
  void onInit() {
    super.onInit();
    _loadInitialData();

    // Sync live events from the WebSocket feed.
    ever<List<Map<String, dynamic>>>(_ws.liveEventFeed, _onLiveEventFeedUpdate);

    // Re-fetch history when the backend pushes a brain_events update.
    ever<Map<String, dynamic>?>(_ws.brainEvents, (_) => fetchHistory());
  }

  Future<void> _loadInitialData() async {
    isLoading.value = true;
    await fetchHistory();
    isLoading.value = false;
  }

  // ---------------------------------------------------------------------------
  // Live feed
  // ---------------------------------------------------------------------------

  void _onLiveEventFeedUpdate(List<Map<String, dynamic>> rawEvents) {
    final parsed = rawEvents
        .map((e) => BrainEventModel.fromJson(e))
        .toList()
        .reversed
        .toList();

    // Apply component filter.
    final component = selectedComponent.value;
    final query = searchQuery.value.toLowerCase();

    final filtered = parsed.where((e) {
      if (component != null && e.component != component) return false;
      if (query.isNotEmpty && !e.eventName.toLowerCase().contains(query)) {
        return false;
      }
      return true;
    }).toList();

    liveEvents.assignAll(filtered);
  }

  /// Filtered view of live events (re-computed when filters change).
  List<BrainEventModel> get filteredLiveEvents => liveEvents;

  // ---------------------------------------------------------------------------
  // History
  // ---------------------------------------------------------------------------

  /// Fetch paginated event history from the REST API.
  Future<void> fetchHistory() async {
    isLoadingHistory.value = true;

    final result = await _api.getBrainEvents(
      component: selectedComponent.value,
      eventName: searchQuery.value.isNotEmpty ? searchQuery.value : null,
      limit: historyLimit.value,
      offset: historyOffset.value,
    );

    if (result != null) {
      final events = (result['events'] as List<dynamic>?)
              ?.map((e) => BrainEventModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [];
      historyEvents.assignAll(events);
      historyTotal.value = result['total'] as int? ?? events.length;
    }

    isLoadingHistory.value = false;
  }

  /// Navigate to the next page of history results.
  void nextPage() {
    if (historyOffset.value + historyLimit.value < historyTotal.value) {
      historyOffset.value += historyLimit.value;
      fetchHistory();
    }
  }

  /// Navigate to the previous page of history results.
  void prevPage() {
    if (historyOffset.value > 0) {
      historyOffset.value =
          (historyOffset.value - historyLimit.value).clamp(0, historyTotal.value);
      fetchHistory();
    }
  }

  /// Set the component filter and re-fetch.
  void setComponentFilter(String? component) {
    if (selectedComponent.value == component) {
      selectedComponent.value = null;
    } else {
      selectedComponent.value = component;
    }
    historyOffset.value = 0;
    fetchHistory();
    // Re-filter live events.
    _onLiveEventFeedUpdate(_ws.liveEventFeed);
  }

  /// Update the search query and re-fetch.
  void setSearchQuery(String query) {
    searchQuery.value = query;
    historyOffset.value = 0;
    fetchHistory();
    _onLiveEventFeedUpdate(_ws.liveEventFeed);
  }

  /// Clear all active filters and re-fetch.
  void clearFilters() {
    selectedComponent.value = null;
    selectedProject.value = null;
    searchQuery.value = '';
    historyOffset.value = 0;
    fetchHistory();
    _onLiveEventFeedUpdate(_ws.liveEventFeed);
  }

  /// Refresh all data.
  Future<void> refreshData() async {
    await fetchHistory();
  }

  /// WebSocket live event feed (raw observable for external use).
  RxList<Map<String, dynamic>> get liveEventFeed => _ws.liveEventFeed;
}
