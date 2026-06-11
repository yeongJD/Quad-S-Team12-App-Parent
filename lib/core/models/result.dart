/// Generic result wrapper for repository / service calls.
///
/// Use [Result.success] for successful outcomes carrying a value of type [T],
/// and [Result.failure] for error outcomes carrying a human-readable
/// [message] plus optional [cause] / [stack] for diagnostics.
///
/// Sealed so that `switch` expressions over a [Result] are exhaustive
/// without requiring a default branch (Dart 3 pattern matching).
sealed class Result<T> {
  const Result();

  factory Result.success(T data) = Success<T>;
  factory Result.failure(String message, {Object? cause, StackTrace? stack}) =
      Failure<T>;

  bool get isSuccess => this is Success<T>;
  bool get isFailure => this is Failure<T>;
}

final class Success<T> extends Result<T> {
  const Success(this.data);

  final T data;
}

final class Failure<T> extends Result<T> {
  const Failure(this.message, {this.cause, this.stack});

  final String message;
  final Object? cause;
  final StackTrace? stack;
}
