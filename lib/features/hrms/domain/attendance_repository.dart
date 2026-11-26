import 'package:thedayhr_employee_app/core/constants/storage_keys.dart';
import 'package:thedayhr_employee_app/core/services/local_storage_service.dart';
import 'package:thedayhr_employee_app/core/utils/date_time_formatter.dart';
import 'package:thedayhr_employee_app/features/hrms/domain/attendance_record.dart';

/// Persistence contract for employee attendance records.
abstract class AttendanceRepository {
  /// Loads all saved attendance records for [employeeId], sorted newest first.
  ///
  /// On first launch (when no key exists yet), seeds clearly identified sample
  /// records strictly for previous calendar days—never for today.
  List<AttendanceRecord> loadRecords(String employeeId, {DateTime? now});

  /// Persists [records] for [employeeId].
  Future<bool> saveRecords(String employeeId, List<AttendanceRecord> records);
}

/// Local [AttendanceRepository] backed by [LocalStorageService].
class LocalAttendanceRepository implements AttendanceRepository {
  LocalAttendanceRepository(this._storage);

  final LocalStorageService _storage;

  @override
  List<AttendanceRecord> loadRecords(String employeeId, {DateTime? now}) {
    final key = StorageKeys.attendanceForEmployee(employeeId);
    final raw = _storage.readString(key);

    if (raw == null) {
      final seeded = _buildPreviousDaySamples(
        employeeId: employeeId,
        referenceNow: now ?? DateTime.now(),
      );
      // Persist initial sample history in the background for subsequent launches.
      saveRecords(employeeId, seeded);
      return seeded;
    }

    final decodedList = _storage.readJsonList(key);
    if (decodedList == null) {
      // Stored payload was corrupted; recover safely with an empty list.
      return const [];
    }

    final records = <AttendanceRecord>[];
    for (final item in decodedList) {
      final record = AttendanceRecord.tryFromJson(item);
      if (record != null) {
        records.add(record);
      }
    }

    return sortNewestFirst(records);
  }

  @override
  Future<bool> saveRecords(
    String employeeId,
    List<AttendanceRecord> records,
  ) {
    final key = StorageKeys.attendanceForEmployee(employeeId);
    final sorted = sortNewestFirst(records);
    final payload = sorted.map((record) => record.toJson()).toList();
    return _storage.writeJsonList(key, payload);
  }

  /// Sorts records newest-first by calendar date, then by check-in timestamp.
  static List<AttendanceRecord> sortNewestFirst(
    List<AttendanceRecord> records,
  ) {
    final copy = List<AttendanceRecord>.from(records);
    copy.sort((a, b) {
      final dateOrder = b.dateKey.compareTo(a.dateKey);
      if (dateOrder != 0) {
        return dateOrder;
      }
      return b.checkInTime.compareTo(a.checkInTime);
    });
    return copy;
  }

  /// Creates clearly marked sample attendance entries for previous days only.
  ///
  /// Never creates a record for today's date so real check-in testing starts
  /// clean.
  static List<AttendanceRecord> _buildPreviousDaySamples({
    required String employeeId,
    required DateTime referenceNow,
  }) {
    final todayStart = DateTime(
      referenceNow.year,
      referenceNow.month,
      referenceNow.day,
    );

    final day1 = todayStart.subtract(const Duration(days: 1));
    final day2 = todayStart.subtract(const Duration(days: 2));
    final day3 = todayStart.subtract(const Duration(days: 3));
    final day4 = todayStart.subtract(const Duration(days: 5));

    final samples = <AttendanceRecord>[
      AttendanceRecord(
        id: 'sample_${employeeId}_1',
        dateKey: DateTimeFormatter.toDateKey(day1),
        checkInTime: DateTime(day1.year, day1.month, day1.day, 9, 12),
        checkOutTime: DateTime(day1.year, day1.month, day1.day, 18, 5),
        isSample: true,
      ),
      AttendanceRecord(
        id: 'sample_${employeeId}_2',
        dateKey: DateTimeFormatter.toDateKey(day2),
        checkInTime: DateTime(day2.year, day2.month, day2.day, 9, 25),
        checkOutTime: null, // Demonstrates an incomplete historical record.
        isSample: true,
      ),
      AttendanceRecord(
        id: 'sample_${employeeId}_3',
        dateKey: DateTimeFormatter.toDateKey(day3),
        checkInTime: DateTime(day3.year, day3.month, day3.day, 8, 58),
        checkOutTime: DateTime(day3.year, day3.month, day3.day, 17, 45),
        isSample: true,
      ),
      AttendanceRecord(
        id: 'sample_${employeeId}_4',
        dateKey: DateTimeFormatter.toDateKey(day4),
        checkInTime: DateTime(day4.year, day4.month, day4.day, 9, 5),
        checkOutTime: DateTime(day4.year, day4.month, day4.day, 18, 15),
        isSample: true,
      ),
    ];

    return sortNewestFirst(samples);
  }
}

