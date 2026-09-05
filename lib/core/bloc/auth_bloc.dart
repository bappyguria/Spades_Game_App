import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'auth_event.dart';
import 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  AuthBloc() : super(AuthInitial()) {
    on<AuthInitialized>(_onInitialized);
    on<AuthLoginRequested>(_onLoginRequested);
    on<AuthLogoutRequested>(_onLogoutRequested);
  }

  Future<void> _onInitialized(
    AuthInitialized event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        emit(AuthAuthenticated(userId: user.uid));
      } else {
        emit(AuthUnauthenticated());
      }
    } catch (_) {
      emit(AuthUnauthenticated());
    }
  }

  Future<void> _onLoginRequested(
    AuthLoginRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    try {
      await FirebaseAuth.instance.signInAnonymously();
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        emit(const AuthError(message: 'Login failed: user was not created'));
        return;
      }
      emit(AuthAuthenticated(userId: user.uid));
    } catch (e) {
      emit(AuthError(message: 'Login failed: $e'));
    }
  }

  Future<void> _onLogoutRequested(
    AuthLogoutRequested event,
    Emitter<AuthState> emit,
  ) async {
    try {
      await FirebaseAuth.instance.signOut();
      emit(AuthUnauthenticated());
    } catch (e) {
      emit(AuthError(message: 'Logout failed: $e'));
    }
  }
}
