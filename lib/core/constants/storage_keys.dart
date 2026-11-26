/// Centralized keys used for local persistence in [SharedPreferences].
abstract final class StorageKeys {
  /// Stores the currently authenticated [EmployeeUser] JSON (never passwords).
  static const String authSession = 'thedayhr_auth_session_v1';

  /// Per-employee storage key for attendance records.
  static String attendanceForEmployee(String employeeId) =>
      'thedayhr_attendance_${employeeId.trim().toUpperCase()}_v1';

  /// Per-employee storage key for chat message history.
  static String chatMessagesForEmployee(String employeeId) =>
      'thedayhr_chat_${employeeId.trim().toUpperCase()}_v1';
}

