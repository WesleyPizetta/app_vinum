abstract class LoginEvent {}

class LoginSessionChecked extends LoginEvent {}

class LoginSubmitted extends LoginEvent {
  final String email;
  final String password;

  LoginSubmitted({required this.email, required this.password});
}

class LoginSocialSubmitted extends LoginEvent {
  final String provider;
  final String idToken;
  final String? nonce;

  LoginSocialSubmitted({
    required this.provider,
    required this.idToken,
    this.nonce,
  });
}
