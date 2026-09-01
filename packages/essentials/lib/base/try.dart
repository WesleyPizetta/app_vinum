import 'package:dartz/dartz.dart';

import 'failure.dart';

abstract class Try<T> extends Either<Failure, T> {
  static Try<T> success<T>(T data) => Success(data);
  static Try<T> reject<T>(Failure error) => Rejection(error);

  Try<O> transform<O>({required O data}) =>
      fold((err) => Rejection<O>(err), (_) => Success<O>(data));
}

class Success<T> extends Right<Failure, T> implements Try<T> {
  Success(super.value);

  @override
  Try<O> transform<O>({required O data}) => Success<O>(data);

  T get() => (this as Right<Failure, T>).value;
}

class Rejection<T> extends Left<Failure, T> implements Try<T> {
  Rejection(super.error);

  @override
  Try<O> transform<O>({required O data}) =>
      Rejection<O>((this as Left<Failure, T>).value);

  Failure get() => (this as Left<Failure, T>).value;
}
