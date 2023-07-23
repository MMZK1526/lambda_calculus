import 'package:lambda_calculus/src/lambda.dart';
import 'package:lambda_calculus/src/lambda_form.dart';
import 'package:lambda_calculus/src/utilities.dart';

/// An interface for [Lambda]-ish expressions.
abstract class ILambda<T> {
  /// The form of the lambda expression.
  LambdaForm get form;

  /// The name of the variable introduced; only makes sense if the form is
  /// [LambdaForm.variable] or [LambdaForm.abstraction].
  String? get name;

  /// The De Bruijn index of the variable introduced; only makes sense if the
  /// form is [LambdaForm.variable].
  int? get index;

  /// The "first" sub-expression. If the form is [LambdaForm.abstraction], it
  /// the "function body", otherwise it is the "function" `M` in `(M N)`.
  T? get exp1;

  /// The "second" sub-expression. If the form is [LambdaForm.application], it
  /// the "argument".
  T? get exp2;

  /// A higher-order function for [ILambda] transformation.
  ///
  /// See [Lambda.fmap] for more details.
  static D fmap<S extends ILambda, D extends ILambda, T>({
    required D Function(S varLambda, T? param, int depth) onVar,
    T? initialParam,
    T? Function(T? param, int depth)? onAbsEnter,
    T? Function(T? param, int depth)? onAbsExit,
    T? Function(T? param, int depth, bool isLeft)? onAppEnter,
    T? Function(T? param, int depth, bool isLeft)? onAppExit,
    required S initialLambda,
    required D Function(D lambda, [String? name]) abstract,
    required D Function({required D exp1, required D exp2}) apply,
  }) {
    final lambdaStack = <Triple<bool, bool, S>>[
      Triple(true, true, initialLambda),
    ];
    final resultStack = <D>[];
    int depth = 0;
    var param = initialParam;

    while (lambdaStack.isNotEmpty) {
      final cur = lambdaStack.last;
      if (cur.first) {
        if (cur.third.form == LambdaForm.application) {
          if (cur.second) {
            param = onAppEnter?.call(param, depth, true) ?? param;
            lambdaStack.add(Triple(true, true, cur.third.exp1!));
            cur.second = false;
          } else {
            param = onAppExit?.call(param, depth, true) ?? param;
            param = onAppEnter?.call(param, depth, false) ?? param;
            lambdaStack.add(Triple(true, true, cur.third.exp2!));
            cur.first = false;
          }
        } else if (cur.third.form == LambdaForm.abstraction) {
          param = onAbsEnter?.call(param, depth) ?? param;
          depth += 1;
          lambdaStack.add(Triple(true, true, cur.third.exp1!));
          cur.first = false;
        } else {
          resultStack.add(onVar(cur.third, param, depth));
          lambdaStack.removeLast();
        }
      } else {
        lambdaStack.removeLast();
        if (cur.third.form == LambdaForm.abstraction) {
          final lambda = resultStack.removeLast();
          resultStack.add(abstract(
            lambda,
            cur.third.name,
          ));
          depth -= 1;
          param = onAbsExit?.call(param, depth) ?? param;
        } else {
          param = onAppExit?.call(param, depth, false) ?? param;
          final lambda2 = resultStack.removeLast();
          final lambda1 = resultStack.removeLast();
          resultStack.add(apply(
            exp1: lambda1,
            exp2: lambda2,
          ));
        }
      }
    }

    return resultStack.first;
  }
}

/// An interface for common constants/combinators in lambda calculus.
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
