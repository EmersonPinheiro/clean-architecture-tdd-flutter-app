import 'package:clean_architecture_tdd/core/errors/failures.dart';
import 'package:clean_architecture_tdd/core/usecases/usecase.dart';
import 'package:clean_architecture_tdd/core/utils/input_converter.dart';
import 'package:clean_architecture_tdd/features/number_trivia/domain/entities/number_trivia.dart';
import 'package:clean_architecture_tdd/features/number_trivia/domain/usecases/get_concrete_number_trivia.dart';
import 'package:clean_architecture_tdd/features/number_trivia/domain/usecases/get_random_number_trivia.dart';
import 'package:clean_architecture_tdd/features/number_trivia/presentation/bloc/number_trivia_bloc.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockGetConcreteNumberTrivia extends Mock
    implements GetConcreteNumberTrivia {}

class MockGetRandomNumberTrivia extends Mock implements GetRandomNumberTrivia {}

class MockInputConverter extends Mock implements InputConverter {}

void main() {
  late MockGetConcreteNumberTrivia mockGetConcreteNumberTrivia;
  late MockGetRandomNumberTrivia mockGetRandomNumberTrivia;
  late MockInputConverter mockInputConverter;
  late NumberTriviaBloc bloc;

  setUp(() {
    mockGetConcreteNumberTrivia = MockGetConcreteNumberTrivia();
    mockGetRandomNumberTrivia = MockGetRandomNumberTrivia();
    mockInputConverter = MockInputConverter();
    bloc = NumberTriviaBloc(
      concrete: mockGetConcreteNumberTrivia,
      random: mockGetRandomNumberTrivia,
      inputConverter: mockInputConverter,
    );
  });

  test('initialState should be Empty', () {
    //assert
    expect(bloc.state, equals(Empty()));
  });

  group('GetConcreteNumberTrivia', () {
    const tNumberString = '1';
    final tNumberParsed = int.parse(tNumberString);
    const tNumberTrivia = NumberTrivia(text: 'test trivia', number: 1);

    void setUpMockInputConverterSuccess() {
      when(() => mockInputConverter.stringToUnsignedInteger(any()))
          .thenReturn(Right(tNumberParsed));
    }

    void mockGetConcreteNumberTriviaSuccess() {
      when(() => mockGetConcreteNumberTrivia(any()))
          .thenAnswer((_) async => const Right(tNumberTrivia));
    }

    setUpAll(() {
      registerFallbackValue(Params(number: tNumberParsed));
    });

    test('''should call the InputConverter to validate and 
        convert the string to an unsigned integer''', () async {
      //arrange
      setUpMockInputConverterSuccess();
      mockGetConcreteNumberTriviaSuccess();
      //act
      bloc.add(const GetTriviaForConcreteNumber(tNumberString));
      await untilCalled(
          () => mockInputConverter.stringToUnsignedInteger(any()));
      //assert
      verify(() => mockInputConverter.stringToUnsignedInteger(tNumberString));
    });

    //it is possible (and even better) to use bloc_test package to test the bloc.
    test('should emit [Error] when the input is invalid', () async {
      //arrange
      when(() => mockInputConverter.stringToUnsignedInteger(any()))
          .thenReturn(Left(InvalidInputFailure()));
      //assert later
      final expected = [const Error(message: invalidInputFailureMessage)];
      expectLater(bloc.stream, emitsInOrder(expected));

      //act
      bloc.add(const GetTriviaForConcreteNumber(tNumberString));
    });

    test('should get data from the concrete use case', () async {
      //arrange
      setUpMockInputConverterSuccess();
      mockGetConcreteNumberTriviaSuccess();
      //act
      bloc.add(const GetTriviaForConcreteNumber(tNumberString));
      await untilCalled(() => mockGetConcreteNumberTrivia(any()));
      //assert
      verify(() => mockGetConcreteNumberTrivia(Params(number: tNumberParsed)));
    });

    test('should emit [Loading, Loaded] when data is gotten successful', () {
      //arrange
      setUpMockInputConverterSuccess();
      mockGetConcreteNumberTriviaSuccess();
      //assert later
      final expected = [Loading(), const Loaded(trivia: tNumberTrivia)];
      expectLater(bloc.stream, emitsInOrder(expected));
      //act
      bloc.add(const GetTriviaForConcreteNumber(tNumberString));
    });

    test('should emit [Loading, Error] when getting data fails', () async {
      //arrange
      setUpMockInputConverterSuccess();
      when(() => mockGetConcreteNumberTrivia(any()))
          .thenAnswer((_) async => Left(ServerFailure()));
      //assert later
      final expected = [Loading(), const Error(message: serverFailureMessage)];
      expectLater(bloc.stream, emitsInOrder(expected));
      //act
      bloc.add(const GetTriviaForConcreteNumber(tNumberString));
    });

    test(
        'should emit [Loading, Error] with the proper message for the error when getting data fails',
        () async {
      //arrange
      setUpMockInputConverterSuccess();
      when(() => mockGetConcreteNumberTrivia(any()))
          .thenAnswer((_) async => Left(CacheFailure()));
      //assert later
      final expected = [Loading(), const Error(message: cacheFailureMessage)];
      expectLater(bloc.stream, emitsInOrder(expected));
      //act
      bloc.add(const GetTriviaForConcreteNumber(tNumberString));
    });
  });

  group('GetRandomNumberTrivia', () {
    const tNumberTrivia = NumberTrivia(text: 'test trivia', number: 1);

    void mockGetRandomNumberTriviaSuccess() {
      when(() => mockGetRandomNumberTrivia(any()))
          .thenAnswer((_) async => const Right(tNumberTrivia));
    }

    setUpAll(() {
      registerFallbackValue(NoParams());
    });

    test('should get data from the concrete use case', () async {
      //arrange
      mockGetRandomNumberTriviaSuccess();
      //act
      bloc.add(GetTriviaForRandomNumber());
      await untilCalled(() => mockGetRandomNumberTrivia(any()));
      //assert
      verify(() => mockGetRandomNumberTrivia(NoParams()));
    });

    test('should emit [Loading, Loaded] when data is gotten successful', () {
      //arrange
      mockGetRandomNumberTriviaSuccess();
      //assert later
      final expected = [Loading(), const Loaded(trivia: tNumberTrivia)];
      expectLater(bloc.stream, emitsInOrder(expected));
      //act
      bloc.add(GetTriviaForRandomNumber());
    });

    test('should emit [Loading, Error] when getting data fails', () async {
      //arrange
      when(() => mockGetRandomNumberTrivia(any()))
          .thenAnswer((_) async => Left(ServerFailure()));
      //assert later
      final expected = [Loading(), const Error(message: serverFailureMessage)];
      expectLater(bloc.stream, emitsInOrder(expected));
      //act
      bloc.add(GetTriviaForRandomNumber());
    });

    test(
        'should emit [Loading, Error] with the proper message for the error when getting data fails',
        () async {
      //arrange
      when(() => mockGetRandomNumberTrivia(any()))
          .thenAnswer((_) async => Left(CacheFailure()));
      //assert later
      final expected = [Loading(), const Error(message: cacheFailureMessage)];
      expectLater(bloc.stream, emitsInOrder(expected));
      //act
      bloc.add(GetTriviaForRandomNumber());
    });
  });
}
