abstract class Failure {
  final dynamic error;
  final String? code;

  Failure({this.code, this.error});

  @override
  bool operator ==(other) =>
      other is Failure && other.code == code && other.error == error;

  @override
  int get hashCode => Object.hash(code, error);
}

class UnknownFailure extends Failure {
  UnknownFailure(dynamic err) : super(code: 'UNKNOWN', error: err);
}

class KnownFailure extends Failure {
  final String? message;
  KnownFailure(String code, dynamic err, {this.message})
      : super(code: code, error: err);

  @override
  String toString() => 'code: $code - err: $error - message: $message';
}

class ServerConnectionFailure extends Failure {}

class InvalidParamFailure extends Failure {}
