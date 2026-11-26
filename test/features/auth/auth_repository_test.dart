import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:thedayhr_employee_app/core/constants/storage_keys.dart';
import 'package:thedayhr_employee_app/core/services/local_storage_service.dart';
import 'package:thedayhr_employee_app/features/auth/domain/auth_repository.dart';

void main() {
  group('LocalAuthRepository', () {
    test('authenticates with employee ID or email and never stores password', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final storage = LocalStorageService(prefs);
      final repository = LocalAuthRepository(storage);

      const demo = LocalAuthRepository.primaryDemo;
      final user = await repository.login(
        identifier: '  ${demo.employeeId.toLowerCase()}  ',
        password: demo.password,
      );

      expect(user, demo.user);
      expect(repository.getCurrentUser(), demo.user);

      final rawStored = prefs.getString(StorageKeys.authSession);
      expect(rawStored, isNotNull);
      expect(rawStored!.toLowerCase(), isNot(contains('password')));
      expect(rawStored, isNot(contains(demo.password)));
    });

    test('authenticates case-insensitively with work email', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final repository = LocalAuthRepository(LocalStorageService(prefs));

      const demo = LocalAuthRepository.primaryDemo;
      final user = await repository.login(
        identifier: demo.email.toUpperCase(),
        password: demo.password,
      );

      expect(user.employeeId, demo.employeeId);
    });

    test('throws AuthException on invalid credentials', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final repository = LocalAuthRepository(LocalStorageService(prefs));

      await expectLater(
        () => repository.login(
          identifier: LocalAuthRepository.primaryDemo.employeeId,
          password: 'WrongPassword123',
        ),
        throwsA(isA<AuthException>()),
      );
      expect(repository.getCurrentUser(), isNull);
    });

    test('safely ignores and clears malformed session JSON', () async {
      SharedPreferences.setMockInitialValues({
        StorageKeys.authSession: '{"employeeId": 123, "broken": true}',
      });
      final prefs = await SharedPreferences.getInstance();
      final repository = LocalAuthRepository(LocalStorageService(prefs));

      expect(repository.getCurrentUser(), isNull);
      expect(prefs.getString(StorageKeys.authSession), isNull);
    });

    test('logout clears persisted session', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final repository = LocalAuthRepository(LocalStorageService(prefs));

      const demo = LocalAuthRepository.primaryDemo;
      await repository.login(
        identifier: demo.employeeId,
        password: demo.password,
      );
      expect(repository.getCurrentUser(), isNotNull);

      await repository.logout();
      expect(repository.getCurrentUser(), isNull);
    });
  });
}

