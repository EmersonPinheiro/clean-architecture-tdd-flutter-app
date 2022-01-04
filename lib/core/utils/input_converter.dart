import 'package:clean_architecture_tdd/core/errors/failures.dart';
import 'package:dartz/dartz.dart';

class InputConverter {
  Either<Failure, int> stringToUnsignedInteger(String str) {
    final integer = int.tryParse(str);
    if (integer != null && integer > 0) {
      return Right(integer);
    } else {
      return Left(InvalidInputFailure());
    }
  }
}

class InvalidInputFailure extends Failure {
  @override
  List<Object?> get props => [];
}
