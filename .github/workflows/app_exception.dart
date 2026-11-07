class AppException implements Exception {
  final String message;
  final String? code;
  final dynamic details;

  AppException(this.message, {this.code, this.details});

  @override
  String toString() => message;
}

class AuthException extends AppException {
  AuthException(super.message, {super.code, super.details});
}

class GroupFullException extends AppException {
  GroupFullException([super.message = 'Group has reached its maximum member capacity of 11.']);
}

class UnauthorizedException extends AppException {
  UnauthorizedException([super.message = 'You do not have permission to perform this action.']);
}
