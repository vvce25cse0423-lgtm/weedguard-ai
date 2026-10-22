sealed class AppError {
  final String message;
  const AppError(this.message);
}

class NetworkError extends AppError {
  const NetworkError([super.message = 'No internet connection. Please check your network.']);
}

class AuthError extends AppError {
  const AuthError([super.message = 'Authentication failed. Please sign in again.']);
}

class NotFoundError extends AppError {
  const NotFoundError([super.message = 'The requested data was not found.']);
}

class StorageError extends AppError {
  const StorageError([super.message = 'File upload failed. Please try again.']);
}

class ValidationError extends AppError {
  const ValidationError(super.message);
}

class UnknownError extends AppError {
  const UnknownError([super.message = 'An unexpected error occurred. Please try again.']);
}
