import 'package:thedayhr_employee_app/core/utils/date_time_formatter.dart';

/// Lifecycle status of a single [AttendanceRecord].
enum AttendanceRecordStatus {
  /// Employee is currently checked in for today and has not checked out yet.
  active,

  /// Employee has both check-in and check-out timestamps recorded.
  completed,

  /// Past-day record that has a check-in timestamp without a check-out.
  incomplete,
}

/// Immutable attendance entry for one employee on one calendar day.
class AttendanceRecord {
  const AttendanceRecord({
    required this.id,
    required this.dateKey,
    required this.checkInTime,
    this.checkOutTime,
    this.isSample = false,
  });

  final String id;
  final String dateKey;
  final DateTime checkInTime;
  final DateTime? checkOutTime;
  final bool isSample;

  bool get isCheckedOut => checkOutTime != null;

  /// Returns the status relative to [referenceNow] (defaults to `DateTime.now()`).
  AttendanceRecordStatus statusAt(DateTime referenceNow) {
    if (checkOutTime != null) {
      return AttendanceRecordStatus.completed;
    }
    if (dateKey == DateTimeFormatter.toDateKey(referenceNow)) {
      return AttendanceRecordStatus.active;
    }
    return AttendanceRecordStatus.incomplete;
  }

  /// Completed working duration, or [Duration.zero] if not checked out yet.
  Duration get workedDuration {
    final outTime = checkOutTime;
    if (outTime == null) {
      return Duration.zero;
    }
    final diff = outTime.difference(checkInTime);
    return diff.isNegative ? Duration.zero : diff;
  }

  /// Live working duration as of [referenceNow] when checked in, or completed
  /// duration once checked out.
  Duration elapsedDurationAt(DateTime referenceNow) {
    if (checkOutTime != null) {
      return workedDuration;
    }
    if (dateKey != DateTimeFormatter.toDateKey(referenceNow)) {
      return Duration.zero;
    }
    final diff = referenceNow.difference(checkInTime);
    return diff.isNegative ? Duration.zero : diff;
  }

  AttendanceRecord copyWith({
    String? id,
    String? dateKey,
    DateTime? checkInTime,
    DateTime? checkOutTime,
    bool? isSample,
  }) {
    return AttendanceRecord(
      id: id ?? this.id,
      dateKey: dateKey ?? this.dateKey,
      checkInTime: checkInTime ?? this.checkInTime,
      checkOutTime: checkOutTime ?? this.checkOutTime,
      isSample: isSample ?? this.isSample,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'dateKey': dateKey,
        'checkInTime': checkInTime.toIso8601String(),
        'checkOutTime': checkOutTime?.toIso8601String(),
        'isSample': isSample,
      };

  /// Parses an [AttendanceRecord] from JSON, returning `null` if malformed.
  static AttendanceRecord? tryFromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return null;
    }
    final id = json['id'];
    final dateKey = json['dateKey'];
    final checkInRaw = json['checkInTime'];
    final checkOutRaw = json['checkOutTime'];
    final isSampleRaw = json['isSample'];

    if (id is! String ||
        id.trim().isEmpty ||
        dateKey is! String ||
        dateKey.trim().isEmpty ||
        checkInRaw is! String) {
      return null;
    }

    final checkIn = DateTime.tryParse(checkInRaw);
    if (checkIn == null) {
      return null;
    }

    DateTime? checkOut;
    if (checkOutRaw != null) {
      if (checkOutRaw is! String) {
        return null;
      }
      final parsedOut = DateTime.tryParse(checkOutRaw);
      if (parsedOut == null) {
        return null;
      }
      if (!parsedOut.isBefore(checkIn)) {
        checkOut = parsedOut;
      }
    }

    return AttendanceRecord(
      id: id.trim(),
      dateKey: dateKey.trim(),
      checkInTime: checkIn,
      checkOutTime: checkOut,
      isSample: isSampleRaw is bool ? isSampleRaw : false,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AttendanceRecord &&
        other.id == id &&
        other.dateKey == dateKey &&
        other.checkInTime == checkInTime &&
        other.checkOutTime == checkOutTime &&
        other.isSample == isSample;
  }

  @override
  int get hashCode =>
      Object.hash(id, dateKey, checkInTime, checkOutTime, isSample);
}

