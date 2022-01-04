import 'package:bloc/bloc.dart';
import 'package:clean_architecture_tdd/core/errors/failures.dart';
import 'package:clean_architecture_tdd/core/usecases/usecase.dart';
import 'package:clean_architecture_tdd/core/utils/input_converter.dart';
import 'package:clean_architecture_tdd/features/number_trivia/domain/entities/number_trivia.dart';
import 'package:clean_architecture_tdd/features/number_trivia/domain/usecases/get_concrete_number_trivia.dart';
import 'package:clean_architecture_tdd/features/number_trivia/domain/usecases/get_random_number_trivia.dart';
import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

part 'number_trivia_event.dart';
part 'number_trivia_state.dart';

const String serverFailureMessage = 'Server Failure';
const String cacheFailureMessage = 'Cache Failure';
const String invalidInputFailureMessage =
    'Invalid Input - The number must be a positive integer or zero.';

class NumberTriviaBloc extends Bloc<NumberTriviaEvent, NumberTriviaState> {
  final GetConcreteNumberTrivia getConcreteNumberTrivia;
  final GetRandomNumberTrivia getRandomNumberTrivia;
  final InputConverter inputConverter;

  NumberTriviaBloc({
    required GetConcreteNumberTrivia concrete,
    required GetRandomNumberTrivia random,
    required this.inputConverter,
  })  : getConcreteNumberTrivia = concrete,
        getRandomNumberTrivia = random,
        super(Empty()) {
    on<GetTriviaForConcreteNumber>((event, emit) async {
      final inputEither =
          inputConverter.stringToUnsignedInteger(event.numberString);

      await emit.onEach(
          inputEither.fold(
            (failure) async* {
              emit(const Error(message: invalidInputFailureMessage));
            },
            (integer) async* {
              emit(Loading());
              final eitherFailureOrTrivia = await getConcreteNumberTrivia(
                Params(number: integer),
              );
              emit(_eitherLoadedOrErrorState(eitherFailureOrTrivia));
            },
          ),
          onData: (_) {});
    });
    on<GetTriviaForRandomNumber>(
      (event, emit) async {
        emit(Loading());
        final eitherFailureOrTrivia = await getRandomNumberTrivia(NoParams());
        emit(_eitherLoadedOrErrorState(eitherFailureOrTrivia));
      },
    );
  }

  NumberTriviaState _eitherLoadedOrErrorState(
          Either<Failure, NumberTrivia> eitherFailureOrTrivia) =>
      eitherFailureOrTrivia.fold(
          (failure) => Error(message: _mapFailureToMessage(failure)),
          (trivia) => Loaded(trivia: trivia));

  String _mapFailureToMessage(Failure failure) {
    switch (failure.runtimeType) {
      case ServerFailure:
        return serverFailureMessage;
      case CacheFailure:
        return cacheFailureMessage;
      default:
        return 'Unexpected Error';
    }
  }
}
