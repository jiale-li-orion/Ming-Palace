/// A simple Result type for error handling without exceptions.
///
/// Use [Ok] for success values and [Err] for failures.
sealed class Result<T, E> {
  const Result();

  bool get isOk => this is Ok<T, E>;
  bool get isErr => this is Err<T, E>;

  T? get okValue => isOk ? (this as Ok<T, E>).value : null;
  E? get errValue => isErr ? (this as Err<T, E>).error : null;

  U fold<U>(U Function(T value) onOk, U Function(E error) onErr) {
    if (this is Ok<T, E>) return onOk((this as Ok<T, E>).value);
    return onErr((this as Err<T, E>).error);
  }
}

class Ok<T, E> extends Result<T, E> {
  final T value;
  const Ok(this.value);
}

class Err<T, E> extends Result<T, E> {
  final E error;
  const Err(this.error);
}
