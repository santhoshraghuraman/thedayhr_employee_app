import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:thedayhr_employee_app/core/constants/storage_keys.dart';
import 'package:thedayhr_employee_app/core/services/local_storage_service.dart';
import 'package:thedayhr_employee_app/core/utils/date_time_formatter.dart';

void main() {
  group('StorageKeys', () {
    test('uses distinct normalized keys per employee for attendance and chat', () {
      expect(
        StorageKeys.attendanceForEmployee('emp-1042'),
        'thedayhr_attendance_EMP-1042_v1',
      );
      expect(
        StorageKeys.chatMessagesForEmployee('EMP-1042'),
        'thedayhr_chat_EMP-1042_v1',
      );
      expect(
        StorageKeys.attendanceForEmployee('EMP-1042'),
        isNot(StorageKeys.attendanceForEmployee('EMP-1088')),
      );
      expect(
        StorageKeys.chatMessagesForEmployee('EMP-1042'),
        isNot(StorageKeys.chatMessagesForEmployee('EMP-1088')),
      );
    });
  });

  group('LocalStorageService', () {
    test('writes and reads JSON maps and lists reliably', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final storage = LocalStorageService(prefs);

      final mapSaved = await storage.writeJsonMap('map_key', {'a': 1});
      final listSaved = await storage.writeJsonList('list_key', [
        {'id': '1'},
        {'id': '2'},
      ]);

      expect(mapSaved, isTrue);
      expect(listSaved, isTrue);
      expect(storage.readJsonMap('map_key'), {'a': 1});
      expect(storage.readJsonList('list_key'), [
        {'id': '1'},
        {'id': '2'},
      ]);
    });

    test('returns null safely for malformed JSON map or wrong JSON type', () async {
      SharedPreferences.setMockInitialValues({
        'corrupt_json': '{not valid json',
        'wrong_type': '["a", "b"]',
        'empty_str': '   ',
      });
      final prefs = await SharedPreferences.getInstance();
      final storage = LocalStorageService(prefs);

      expect(storage.readJsonMap('corrupt_json'), isNull);
      expect(storage.readJsonMap('wrong_type'), isNull);
      expect(storage.readJsonMap('empty_str'), isNull);
      expect(storage.readJsonMap('missing_key'), isNull);
    });

    test('returns null for corrupt JSON list and skips invalid list items', () async {
      SharedPreferences.setMockInitialValues({
        'corrupt_list': '[broken',
        'not_a_list': '{"hello":"world"}',
        'mixed_list': '[{"ok":1}, "bad_item", 42, {"ok":2}]',
      });
      final prefs = await SharedPreferences.getInstance();
      final storage = LocalStorageService(prefs);

      expect(storage.readJsonList('corrupt_list'), isNull);
      expect(storage.readJsonList('not_a_list'), isNull);
      expect(storage.readJsonList('mixed_list'), [
        {'ok': 1},
        {'ok': 2},
      ]);
    });
  });

  group('DateTimeFormatter', () {
    test('formats durations and date keys consistently', () {
      final dt = DateTime(2026, 11, 26, 9, 5, 3);
      expect(DateTimeFormatter.toDateKey(dt), '2026-11-26');
      expect(
        DateTimeFormatter.formatHoursMinutes(
          const Duration(hours: 8, minutes: 5),
        ),
        '08h 05m',
      );
      expect(
        DateTimeFormatter.formatElapsedClock(
          const Duration(hours: 1, minutes: 2, seconds: 9),
        ),
        '01:02:09',
      );
      expect(
        DateTimeFormatter.formatHoursMinutes(const Duration(minutes: -5)),
        '00h 00m',
      );
    });
  });
}

