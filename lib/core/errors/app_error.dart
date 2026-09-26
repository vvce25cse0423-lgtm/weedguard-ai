sealed class AppError {
  final String message;
  const AppError(this.message);
}

class NetworkError extends AppError {
  const NetworkError([String message = 'No internet connection. Please check your network.'])
      : super(message);
}

class AuthError extends AppError {
  const AuthError([String message = 'Authentication failed. Please sign in again.'])
      : super(message);
}

class NotFoundError extends AppError {
  const NotFoundError([String message = 'The requested data was not found.']) : super(message);
}

class StorageError extends AppError {
  const StorageError([String message = 'File upload failed. Please try again.']) : super(message);
}

class ValidationError extends AppError {
  const ValidationError(String message) : super(message);
}

class UnknownError extends AppError {
  const UnknownError([String message = 'An unexpected error occurred. Please try again.'])
      : super(message);
}
