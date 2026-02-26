import 'package:crimson_arena/data/models/brain_event_model.dart';
import 'package:crimson_arena/features/events/controllers/events_view_model.dart';
import 'package:crimson_arena/services/brain_api_service.dart';
import 'package:crimson_arena/services/brain_websocket_service.dart';
import 'package:crimson_arena/services/project_selector_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:mocktail/mocktail.dart';

class MockBrainApiService extends GetxService
    with Mock
    implements BrainApiService {}

class MockBrainWebSocketService extends GetxService
    with Mock
    implements BrainWebSocketService {}

class MockProjectSelectorService extends GetxService
    with Mock
    implements ProjectSelectorService {}

void main() {
  late EventsViewModel vm;
  late MockBrainApiService mockApi;
  late MockBrainWebSocketService mockWs;

  setUp(() {
    Get.testMode = true;

    mockApi = MockBrainApiService();
    mockWs = MockBrainWebSocketService();

    // Stub the reactive observables on the mock WS service.
    when(() => mockWs.liveEventFeed).thenReturn(<Map<String, dynamic>>[].obs);
    when(() => mockWs.brainEvents).thenReturn(Rx<Map<String, dynamic>?>(null));

    final mockProjectSelector = MockProjectSelectorService();
    when(() => mockProjectSelector.selectedProjectSlug)
        .thenReturn(Rxn<String>());
    Get.put<ProjectSelectorService>(mockProjectSelector);

    // Stub the API call to return an empty result by default.
    when(() => mockApi.getBrainEvents(
          component: any(named: 'component'),
          eventName: any(named: 'eventName'),
          project: any(named: 'project'),
          since: any(named: 'since'),
          until: any(named: 'until'),
          limit: any(named: 'limit'),
          offset: any(named: 'offset'),
        )).thenAnswer((_) async => {
          'events': <Map<String, dynamic>>[],
          'total': 0,
        });

    Get.put<BrainApiService>(mockApi);
    Get.put<BrainWebSocketService>(mockWs);

    vm = EventsViewModel();
  });

  tearDown(() {
    Get.reset();
  });

  group('EventsViewModel', () {
    test('initial state has correct defaults', () {
      expect(vm.historyEvents, isEmpty);
      expect(vm.liveEvents, isEmpty);
      expect(vm.isPaused.value, isFalse);
      expect(vm.historyOffset.value, 0);
      expect(vm.historyLimit.value, 50);
      expect(vm.historyTotal.value, 0);
      expect(vm.selectedComponent.value, isNull);
      expect(vm.selectedProject.value, isNull);
      expect(vm.searchQuery.value, isEmpty);
    });

    test('components list has expected entries', () {
      expect(vm.components, contains('schedules'));
      expect(vm.components, contains('cache'));
      expect(vm.components, contains('coordination'));
      expect(vm.components, contains('tasks'));
      expect(vm.components, contains('monitoring'));
      expect(vm.components, contains('sync'));
      expect(vm.components, contains('instances'));
      expect(vm.components.length, 7);
    });

    test('setComponentFilter toggles component selection', () {
      vm.setComponentFilter('cache');
      expect(vm.selectedComponent.value, 'cache');

      // Toggling same component clears it.
      vm.setComponentFilter('cache');
      expect(vm.selectedComponent.value, isNull);
    });

    test('setComponentFilter resets offset to 0', () {
      vm.historyOffset.value = 50;
      vm.setComponentFilter('tasks');
      expect(vm.historyOffset.value, 0);
    });

    test('setSearchQuery updates query and resets offset', () {
      vm.historyOffset.value = 100;
      vm.setSearchQuery('heartbeat');
      expect(vm.searchQuery.value, 'heartbeat');
      expect(vm.historyOffset.value, 0);
    });

    test('clearFilters resets all filter state', () {
      vm.selectedComponent.value = 'cache';
      vm.selectedProject.value = 'igris-ai';
      vm.searchQuery.value = 'test';
      vm.historyOffset.value = 50;

      vm.clearFilters();

      expect(vm.selectedComponent.value, isNull);
      expect(vm.selectedProject.value, isNull);
      expect(vm.searchQuery.value, isEmpty);
      expect(vm.historyOffset.value, 0);
    });

    test('nextPage advances offset when more results exist', () {
      vm.historyTotal.value = 200;
      vm.historyLimit.value = 50;
      vm.historyOffset.value = 0;

      vm.nextPage();
      expect(vm.historyOffset.value, 50);
    });

    test('nextPage does not advance past total', () {
      vm.historyTotal.value = 50;
      vm.historyLimit.value = 50;
      vm.historyOffset.value = 0;

      vm.nextPage();
      expect(vm.historyOffset.value, 0);
    });

    test('prevPage decreases offset', () {
      vm.historyTotal.value = 200;
      vm.historyLimit.value = 50;
      vm.historyOffset.value = 100;

      vm.prevPage();
      expect(vm.historyOffset.value, 50);
    });

    test('prevPage clamps at 0', () {
      vm.historyOffset.value = 0;

      vm.prevPage();
      expect(vm.historyOffset.value, 0);
    });

    test('fetchHistory parses API response correctly', () async {
      when(() => mockApi.getBrainEvents(
            component: any(named: 'component'),
            eventName: any(named: 'eventName'),
            project: any(named: 'project'),
            since: any(named: 'since'),
            until: any(named: 'until'),
            limit: any(named: 'limit'),
            offset: any(named: 'offset'),
          )).thenAnswer((_) async => {
            'events': [
              {
                'id': 1,
                'event_name': 'heartbeat',
                'component': 'monitoring',
                'payload': <String, dynamic>{},
                'created_at': '2026-02-26T10:00:00Z',
              },
              {
                'id': 2,
                'event_name': 'task_claimed',
                'component': 'tasks',
                'payload': {'task_id': 'T-001'},
                'created_at': '2026-02-26T10:01:00Z',
              },
            ],
            'total': 42,
          });

      await vm.fetchHistory();

      expect(vm.historyEvents.length, 2);
      expect(vm.historyEvents[0].eventName, 'heartbeat');
      expect(vm.historyEvents[1].eventName, 'task_claimed');
      expect(vm.historyTotal.value, 42);
      expect(vm.isLoadingHistory.value, isFalse);
    });

    test('fetchHistory handles null API response', () async {
      when(() => mockApi.getBrainEvents(
            component: any(named: 'component'),
            eventName: any(named: 'eventName'),
            project: any(named: 'project'),
            since: any(named: 'since'),
            until: any(named: 'until'),
            limit: any(named: 'limit'),
            offset: any(named: 'offset'),
          )).thenAnswer((_) async => null);

      await vm.fetchHistory();

      // Should not crash; events remain empty.
      expect(vm.historyEvents, isEmpty);
      expect(vm.isLoadingHistory.value, isFalse);
    });
  });

  group('BrainEventModel', () {
    test('fromJson parses all fields', () {
      final model = BrainEventModel.fromJson({
        'id': 1,
        'event_name': 'instance_heartbeat',
        'component': 'monitoring',
        'payload': {'uptime': 3600},
        'machine_hostname': 'macbook',
        'project_slug': 'igris-ai',
        'instance_id': 'inst-001',
        'created_at': '2026-02-26T12:00:00Z',
      });

      expect(model.id, 1);
      expect(model.eventName, 'instance_heartbeat');
      expect(model.component, 'monitoring');
      expect(model.payload['uptime'], 3600);
      expect(model.machineHostname, 'macbook');
      expect(model.projectSlug, 'igris-ai');
      expect(model.instanceId, 'inst-001');
      expect(model.createdAt, '2026-02-26T12:00:00Z');
    });

    test('fromJson handles string payload', () {
      final model = BrainEventModel.fromJson({
        'id': 2,
        'event_name': 'test',
        'component': 'cache',
        'payload': '{"key":"value"}',
        'created_at': '2026-02-26T12:00:00Z',
      });

      expect(model.payload['key'], 'value');
    });

    test('fromJson handles missing optional fields', () {
      final model = BrainEventModel.fromJson({
        'id': 3,
        'event_name': 'test',
        'component': 'cache',
        'payload': <String, dynamic>{},
        'created_at': '2026-02-26T12:00:00Z',
      });

      expect(model.machineHostname, isNull);
      expect(model.projectSlug, isNull);
      expect(model.instanceId, isNull);
    });

    test('toJson round-trips correctly', () {
      final original = BrainEventModel(
        id: 1,
        eventName: 'test_event',
        component: 'cache',
        payload: {'key': 'value'},
        machineHostname: 'host',
        projectSlug: 'proj',
        instanceId: 'inst',
        createdAt: '2026-02-26T12:00:00Z',
      );

      final json = original.toJson();
      final restored = BrainEventModel.fromJson(json);

      expect(restored.id, original.id);
      expect(restored.eventName, original.eventName);
      expect(restored.component, original.component);
      expect(restored.payload, original.payload);
      expect(restored.machineHostname, original.machineHostname);
      expect(restored.projectSlug, original.projectSlug);
      expect(restored.instanceId, original.instanceId);
      expect(restored.createdAt, original.createdAt);
    });
  });
}
