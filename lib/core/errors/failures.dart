import 'package:equatable/equatable.dart';

abstract class Failure extends Equatable {
  final String message;
  final int? statusCode;

  const Failure(this.message, {this.statusCode});

  @override
  List<Object?> get props => [message, statusCode];
}

class ServerFailure extends Failure {
  const ServerFailure(super.message, {super.statusCode});
}

class AuthFailure extends Failure {
  const AuthFailure(super.message, {super.statusCode});
}

class UnauthorizedFailure extends Failure {
  const UnauthorizedFailure(super.message) : super(statusCode: 403);
}

class NotFoundFailure extends Failure {
  const NotFoundFailure(super.message) : super(statusCode: 404);
}

class NetworkTimeoutFailure extends Failure {
  const NetworkTimeoutFailure([super.message = "Request timed out. Please try again."]) : super(statusCode: 408);
}

class OfflineFailure extends Failure {
  const OfflineFailure([super.message = "No connection available. Displaying cached data."]);
}

class ValidationError extends Failure {
  final Map<String, String>? fieldErrors;

  const ValidationError(super.message, {this.fieldErrors, super.statusCode = 422});

  @override
  List<Object?> get props => [message, statusCode, fieldErrors];
}
