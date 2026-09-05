abstract class AuthEvent {
	const AuthEvent();
}

class AuthInitialized extends AuthEvent {}

class AuthLoginRequested extends AuthEvent {}

class AuthLogoutRequested extends AuthEvent {}
