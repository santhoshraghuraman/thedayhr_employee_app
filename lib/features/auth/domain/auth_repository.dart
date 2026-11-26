import 'package:thedayhr_employee_app/core/constants/storage_keys.dart';
import 'package:thedayhr_employee_app/core/services/local_storage_service.dart';
import 'package:thedayhr_employee_app/features/auth/domain/employee_user.dart';

/// Exception thrown when authentication fails or session persistence errors.
class AuthException implements Exception {
  const AuthException(this.message);

  final String message;

  @override
  String toString() => 'AuthException: $message';
}

/// Public demo credential descriptor shown on the login screen for testing.
class DemoEmployeeCredential {
  const DemoEmployeeCredential({
    required this.employeeId,
    required this.email,
    required this.password,
    required this.user,
  });

  final String employeeId;
  final String email;
  final String password;
  final EmployeeUser user;
}

/// Authentication contract decoupling UI/state from storage implementation.
abstract class AuthRepository {
  EmployeeUser? getCurrentUser();

  Future<EmployeeUser> login({
    required String identifier,
    required String password,
  });

  Future<void> logout();
}

/// Local [AuthRepository] backed by [LocalStorageService].
///
/// Passwords are verified in memory only and are never written to
/// [SharedPreferences].
class LocalAuthRepository implements AuthRepository {
  LocalAuthRepository(this._storage);

  final LocalStorageService _storage;

  /// Primary demo employee credentials for technical evaluation.
  static const DemoEmployeeCredential primaryDemo = DemoEmployeeCredential(
    employeeId: 'EMP-1042',
    email: 'santhosh@thedayhr.com',
    password: 'TheDayHR@2026',
    user: EmployeeUser(
      employeeId: 'EMP-1042',
      name: 'Santhosh R',
      email: 'santhosh@thedayhr.com',
      department: 'Mobile Engineering',
      designation: 'Flutter Developer Intern',
    ),
  );

  /// Secondary demo employee so per-employee persistence can also be tested.
  static const DemoEmployeeCredential secondaryDemo = DemoEmployeeCredential(
    employeeId: 'EMP-1088',
    email: 'ananya@thedayhr.com',
    password: 'TheDayHR@2026',
    user: EmployeeUser(
      employeeId: 'EMP-1088',
      name: 'Ananya Nair',
      email: 'ananya@thedayhr.com',
      department: 'People Operations',
      designation: 'HR Specialist',
    ),
  );

  static const List<DemoEmployeeCredential> _accounts = [
    primaryDemo,
    secondaryDemo,
  ];

  @override
  EmployeeUser? getCurrentUser() {
    final json = _storage.readJsonMap(StorageKeys.authSession);
    if (json == null) {
      return null;
    }
    final user = EmployeeUser.tryFromJson(json);
    if (user == null) {
      // Clear corrupted session payload safely so future launches start clean.
      _storage.remove(StorageKeys.authSession);
      return null;
    }
    return user;
  }

  @override
  Future<EmployeeUser> login({
    required String identifier,
    required String password,
  }) async {
    final normalizedId = identifier.trim().toLowerCase();
    if (normalizedId.isEmpty || password.isEmpty) {
      throw const AuthException(
        'Please enter both your Employee ID / email and password.',
      );
    }

    DemoEmployeeCredential? matchedAccount;
    for (final account in _accounts) {
      final matchesId = account.employeeId.toLowerCase() == normalizedId;
      final matchesEmail = account.email.toLowerCase() == normalizedId;
      if (matchesId || matchesEmail) {
        matchedAccount = account;
        break;
      }
    }

    if (matchedAccount == null || matchedAccount.password != password) {
      throw const AuthException(
        'Invalid Employee ID/email or password. Check the demo credentials below.',
      );
    }

    // Store ONLY the non-sensitive EmployeeUser profile (never the password).
    final saved = await _storage.writeJsonMap(
      StorageKeys.authSession,
      matchedAccount.user.toJson(),
    );

    if (!saved) {
      throw const AuthException(
        'Could not save your session locally. Please try again.',
      );
    }

    return matchedAccount.user;
  }

  @override
  Future<void> logout() async {
    await _storage.remove(StorageKeys.authSession);
  }
}

