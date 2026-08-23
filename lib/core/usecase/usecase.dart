import 'package:equatable/equatable.dart';
import '../errors/failures.dart';

/// Result type representing either a Failure [F] or Success Value [S]
abstract class Either<F, S> extends Equatable {
  const Either();

  bool get isLeft => this is Left<F, S>;
  bool get isRight => this is Right<F, S>;

  F? get left => isLeft ? (this as Left<F, S>).value : null;
  S? get right => isRight ? (this as Right<F, S>).value : null;

  R fold<R>(R Function(F failure) ifLeft, R Function(S success) ifRight) {
    if (isLeft) {
      return ifLeft((this as Left<F, S>).value);
    } else {
      return ifRight((this as Right<F, S>).value);
    }
  }
}

class Left<F, S> extends Either<F, S> {
  final F value;
  const Left(this.value);

  @override
  List<Object?> get props => [value];
}

class Right<F, S> extends Either<F, S> {
  final S value;
  const Right(this.value);

  @override
  List<Object?> get props => [value];
}

/// Abstract contract for asynchronous UseCases in Clean Architecture
abstract class UseCase<Type, Params> {
  Future<Either<Failure, Type>> call(Params params);
}

/// Helper class for usecases that do not require any input parameters
class NoParams extends Equatable {
  const NoParams();

  @override
  List<Object?> get props => [];
}
