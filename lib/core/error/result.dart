/// Failure types.
///
/// Astrological calculation is the core of this app and it fails in specific,
/// recoverable ways — a missing ephemeris file, a birth date outside the
/// ephemeris range, an unresolvable birth place. Modelling those explicitly
/// keeps error handling honest instead of collapsing everything into a generic
/// "something went wrong" that we cannot show a useful message for.
sealed class Failure {
  const Failure(this.message, {this.cause});

  final String message;
  final Object? cause;

  @override
  String toString() => '$runtimeType: $message';
}

/// Swiss Ephemeris could not produce a result.
class EphemerisFailure extends Failure {
  const EphemerisFailure(super.message, {super.cause});
}

/// Birth data was missing, malformed, or outside a supported range.
class InvalidBirthDataFailure extends Failure {
  const InvalidBirthDataFailure(super.message, {super.cause});
}

/// A place name could not be resolved to coordinates.
class GeocodingFailure extends Failure {
  const GeocodingFailure(super.message, {super.cause});
}

/// Local database read or write failed.
class StorageFailure extends Failure {
  const StorageFailure(super.message, {super.cause});
}

/// Sign-in, sign-out or account linking failed.
///
/// [code] is the raw Firebase code, kept alongside the readable [message]
/// because the caller sometimes has to branch on it — "that email is taken" is
/// an offer to sign in instead, not something to apologise for.
class AuthFailure extends Failure {
  const AuthFailure(super.message, {super.cause, required this.code});

  final String code;
}

class UnexpectedFailure extends Failure {
  const UnexpectedFailure(super.message, {super.cause});
}

/// A value that is either a success or a [Failure].
///
/// Used for operations whose failure is expected and must be handled by the
/// caller. Programmer errors should still throw.
sealed class Result<T> {
  const Result();

  const factory Result.success(T value) = Success<T>;
  const factory Result.failure(Failure failure) = FailureResult<T>;

  bool get isSuccess => this is Success<T>;

  /// The value, or null when this is a failure.
  T? get valueOrNull => switch (this) {
    Success<T>(:final value) => value,
    FailureResult<T>() => null,
  };

  /// The failure, or null when this is a success.
  Failure? get failureOrNull => switch (this) {
    Success<T>() => null,
    FailureResult<T>(:final failure) => failure,
  };

  R when<R>({
    required R Function(T value) success,
    required R Function(Failure failure) failure,
  }) => switch (this) {
    Success<T>(value: final v) => success(v),
    FailureResult<T>(failure: final f) => failure(f),
  };
}

final class Success<T> extends Result<T> {
  const Success(this.value);
  final T value;
}

final class FailureResult<T> extends Result<T> {
  const FailureResult(this.failure);
  final Failure failure;
}
