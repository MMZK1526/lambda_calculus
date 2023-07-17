import 'package:lambda_calculus/src/lambda_form.dart';

abstract class ILambda<T> {
  LambdaForm get form;

  String? get name;

  int? get index;

  T? get exp1;

  T? get exp2;
}

abstract class ILambdaConstants<T> {
  /// The identity expression.
  T identity();

  /// Church boolean: true.
  T lambdaTrue();

  /// Church boolean: false.
  T lambdaFalse();

  /// The if expression.
  T test();

  /// The and expression.
  T and();

  /// The or expression.
  T or();

  /// The not expression.
  T not();

  /// The church pair.
  T pair();

  /// The first projection of a pair.
  T fst();

  /// The second projection of a pair.
  T snd();

  /// The church number zero.
  T zero();

  /// The church number one.
  T one();

  /// The church number two.
  T two();

  /// The church number three.
  T three();

  /// The church number four.
  T four();

  /// The church number five.
  T five();

  /// The church number six.
  T six();

  /// The church number seven.
  T seven();

  /// The church number eight.
  T eight();

  /// The church number nine.
  T nine();

  /// The church number ten.
  T ten();

  /// The church number eleven.
  T eleven();

  /// The church number twelve.
  T twelve();

  /// The good era is approaching!
  T iiyokoiyo();

  /// The is_zero expression.
  T isZero();

  /// The successor expression.
  T succ();

  /// The addition expression.
  T plus();

  /// The multiplication expression.
  T times();

  /// The exponentiation expression.
  T power();

  /// The diverging omega expression.
  T omega();

  /// The Y combinator.
  T yCombinator();
}
