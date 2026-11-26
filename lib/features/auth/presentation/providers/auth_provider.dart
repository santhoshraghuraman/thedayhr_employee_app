import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:thedayhr_employee_app/core/services/local_storage_service.dart';
import 'package:thedayhr_employee_app/features/auth/domain/auth_repository.dart';
import 'package:thedayhr_employee_app/features/auth/domain/employee_user.dart';

/// Provides the [AuthRepository] implementation.
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return LocalAuthRepository(ref.watch(localStorageServiceProvider));
});

/// Immutable authentication state exposed by [AuthNotifier].
class AuthState {
  const AuthState({
    this.user,
    this.isLoading = false,
    this.errorMessage,
  });

  final EmployeeUser? user;
  final bool isLoading;
  final String? errorMessage;

  bool get isAuthenticated => user != null;

  AuthState copyWith({
    EmployeeUser? user,
    bool clearUser = false,
    bool? isLoading,
    String? errorMessage,
    bool clearError = false,
  }) {
    return AuthState(
      user: clearUser ? null : (user ?? this.user),
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

/// Manages employee login, logout, and persistent session restoration.
class AuthNotifier extends Notifier<AuthState> {
  @override
  AuthState build() {
    final existingUser = ref.read(authRepositoryProvider).getCurrentUser();
    return AuthState(user: existingUser);
  }

  Future<bool> login({
    required String identifier,
    required String password,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final user = await ref.read(authRepositoryProvider).login(
            identifier: identifier,
            password: password,
          );
      state = AuthState(user: user);
      return true;
    } on AuthException catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.message,
      );
      return false;
    } catch (_) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'An unexpected error occurred while signing in.',
      );
      return false;
    }
  }

  Future<void> logout() async {
    await ref.read(authRepositoryProvider).logout();
    state = const AuthState();
  }

  void clearError() {
    if (state.errorMessage != null) {
      state = state.copyWith(clearError: true);
    }
  }
}

/// Global authentication state provider.
final authProvider = NotifierProvider<AuthNotifier, AuthState>(
  AuthNotifier.new,
);

