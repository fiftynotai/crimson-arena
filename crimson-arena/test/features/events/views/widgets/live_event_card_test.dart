import 'dart:ui';

import 'package:crimson_arena/features/events/views/widgets/live_event_card.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('componentColor', () {
    test('returns correct color for each known component', () {
      expect(componentColor('schedules'), const Color(0xFF4A9EFF));
      expect(componentColor('cache'), const Color(0xFF4ADE80));
      expect(componentColor('coordination'), const Color(0xFFFB923C));
      expect(componentColor('tasks'), const Color(0xFFA78BFA));
      expect(componentColor('monitoring'), const Color(0xFFF472B6));
      expect(componentColor('sync'), const Color(0xFF38BDF8));
      expect(componentColor('instances'), const Color(0xFFFBBF24));
    });

    test('returns gray for unknown component', () {
      expect(componentColor('unknown'), const Color(0xFF94A3B8));
      expect(componentColor(''), const Color(0xFF94A3B8));
      expect(componentColor('foobar'), const Color(0xFF94A3B8));
    });
  });
}
