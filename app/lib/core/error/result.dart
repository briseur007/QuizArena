import 'failure.dart';

/// Résultat d'une opération du domaine : un succès ([Ok]) OU un échec ([Err]).
///
/// Les repositories ne lèvent jamais d'exception vers la présentation ;
/// les blocs font un `switch` sur le résultat.
sealed class Result<T> {
  const Result();

  R fold<R>(R Function(Failure failure) onErr, R Function(T value) onOk) => switch (this) {
    Ok<T>(:final value) => onOk(value),
    Err<T>(:final failure) => onErr(failure),
  };
}

final class Ok<T> extends Result<T> {
  const Ok(this.value);
  final T value;
}

final class Err<T> extends Result<T> {
  const Err(this.failure);
  final Failure failure;
}
