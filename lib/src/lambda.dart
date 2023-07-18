import 'package:dartz/dartz.dart';
import 'package:lambda_calculus/src/lambda_builder.dart';
import 'package:lambda_calculus/src/lambda_constants.dart';
import 'package:lambda_calculus/src/lambda_form.dart';
import 'package:lambda_calculus/src/lambda_interface.dart';
import 'package:lambda_calculus/src/lambda_parser.dart';

/// The class representing lambda expressions.
///
/// A lambda expression can have one of the three forms:
/// - Variable: `x`
/// - Abstraction: `λx.M`
/// - Application: `(M N)`
///
/// Lambda expressions are usually generated either directly from parsing a
/// string or via [LambdaBuilder].
///
/// See the documentation for [ToLambdaExtension] and [LamdbaBuilder] for more
/// information on how to create lambda expressions.
class Lambda implements ILambda<Lambda> {
  Lambda({
    required this.form,
    this.index, // For variable
    this.name,
    this.exp1, // For application and abstraction
    this.exp2, // For application
  }) : assert(!(form == LambdaForm.variable &&
                (index == null || exp1 != null || exp2 != null)) &&
            !(form == LambdaForm.application &&
                (index != null ||
                    name != null ||
                    exp1 == null ||
                    exp2 == null)) &&
            !(form == LambdaForm.abstraction &&
                (index != null || exp1 == null || exp2 != null)));

  @override
  LambdaForm form;

  @override
  int? index;

  @override
  String? name;

  @override
  Lambda? exp1;

  @override
  Lambda? exp2;

  /// Access the [LambdaConstants] instance which provides common constants and
  /// combinators.
  static final LambdaConstants constants = LambdaConstants();

  @override
  int get hashCode => toString().hashCode;

  /// The equality operator.
  ///
  /// Returns true iff the two [Lambda]s are syntactically identical up to alpha
  /// renaming.
  ///
  /// Avoids recursion.
  @override
  bool operator ==(Object other) {
    if (other.runtimeType != Lambda) return false;

    return toStringNameless() == (other as Lambda).toStringNameless();
  }

  /// A string representation of the [Lambda] without redundant brackets.
  ///
  /// Avoids recursion.
  @override
  String toString() {
    if (form == LambdaForm.dummy) return '[DUMMY]';

    final sb = StringBuffer();
    bool? isLeftParen = true;
    fmap<List<bool>>(
      initialParam: [false],
      onVar: (lambda, _, depth) {
        final curDepth = depth - lambda.index!;
        if (isLeftParen != true) {
          sb.write(' ');
        }
        if (lambda.name != null) {
          sb.write(lambda.name);
        } else if (curDepth > 0) {
          sb.write('_x$curDepth');
        } else {
          sb.write('_y${1 - curDepth}');
        }
        isLeftParen = null;
        return lambda;
      },
      onAbsEnter: (lambda, useBraces, depth) {
        if ((isLeftParen != true && useBraces!.last) ||
            (isLeftParen == false && !useBraces!.last)) {
          sb.write(' ');
        }
        if (useBraces!.last) {
          sb.write('(');
          isLeftParen = true;
        }
        if (lambda.name != null) {
          sb.write('λ${lambda.name}.');
        } else if (depth > 0) {
          sb.write('λ_x$depth.');
        } else {
          sb.write('λ_y${1 - depth}.');
        }
        useBraces.add(false);
        isLeftParen = false;
        return useBraces;
      },
      onAbsExit: (lambda, useBraces, depth) {
        useBraces!.removeLast();
        if (useBraces.last) {
          sb.write(')');
          isLeftParen = false;
        }
        return useBraces;
      },
      onAppEnter: (lambda, useBraces, depth, isLeft) {
        if (useBraces!.last ||
            !isLeft && lambda.form == LambdaForm.application) {
          if (isLeftParen != true) sb.write(' ');
          sb.write('(');
          isLeftParen = true;
        }
        useBraces.add(lambda.form == LambdaForm.abstraction);
        return useBraces;
      },
      onAppExit: (lambda, useBraces, depth, isLeft) {
        useBraces!.removeLast();
        if (useBraces.last ||
            !isLeft && lambda.form == LambdaForm.application) {
          sb.write(')');
          isLeftParen = false;
        }
        return useBraces;
      },
    );

    return sb.toString();
  }

  /// A higher-order function that iterates on the [Lambda], returning a value.
  ///
  /// It maintains an internal parameter of type `T` and calls the appropriate
  /// callback function for each sub-expression in the [Lambda], passing the
  /// parameter to the callback function and updating the parameter with the
  /// return value of the callback function.
  ///
  /// These callbacks should not modify the [Lambda] itself.
  ///
  /// In detail, the callback functions are called by the following rules:
  /// - If the form is [LambdaForm.variable], call [onVar]. It takes the current
  ///   Lambda expression (i.e. the variable itself), the current parameter, and
  ///   depth of the variable (i.e. the number of abstractions that the variable
  ///   is bounded by) as arguments, and returns a new value of type `T`.
  /// - If the form is [LambdaForm.application], call [onAppEnter] before
  ///   visiting the sub-expression, and call [onAppExit] after visiting the
  ///   sub-expression. Both callbacks take the current parameter and depth as
  ///   arguments and return a new value of type `T`. Note that it visits both
  ///   sub-expressions from left to right.
  /// - If the form is [LambdaForm.abstraction], call [onAbsEnter] before
  ///   visiting the sub-expression, and call [onAbsExit] after visiting the
  ///   sub-expression. Both callbacks take the current parameter and depth as
  ///   arguments and return a new value of type `T`.
  ///
  /// Finally, it applies the [select] function to the parameter and returns the
  /// result.
  R fold<R, T>({
    required T initialParam,
    required R Function(T finalParam) select,
    T Function(Lambda varLambda, T param, int depth)? onVar,
    T Function(T param, int depth)? onAbsEnter,
    T Function(T param, int depth)? onAbsExit,
    T Function(T param, int depth)? onAppEnter,
    T Function(T param, int depth)? onAppExit,
  }) {
    final lambdaStack = [this];
    final isExp1Stack = [true];
    var param = initialParam;
    final boundedVars = <String?>[];

    while (lambdaStack.isNotEmpty) {
      if (lambdaStack.last.form == LambdaForm.variable) {
        param = onVar?.call(
              lambdaStack.last,
              param,
              boundedVars.length,
            ) ??
            param;
        while (true) {
          lambdaStack.removeLast();
          if (lambdaStack.isEmpty) break;
          if (lambdaStack.last.form == LambdaForm.abstraction) {
            isExp1Stack.removeLast();
            boundedVars.removeAt(0);
            param = onAbsExit?.call(param, boundedVars.length) ?? param;
          } else if (isExp1Stack.last) {
            lambdaStack.add(lambdaStack.last.exp2!);
            isExp1Stack.last = false;
            param = onAppExit?.call(param, boundedVars.length) ?? param;
            param = onAppEnter?.call(param, boundedVars.length) ?? param;
            break;
          } else {
            isExp1Stack.removeLast();
            param = onAppExit?.call(param, boundedVars.length) ?? param;
          }
        }
      } else if (lambdaStack.last.form == LambdaForm.abstraction) {
        boundedVars.insert(0, lambdaStack.last.name);
        lambdaStack.add(lambdaStack.last.exp1!);
        isExp1Stack.add(true);
        param = onAbsEnter?.call(param, boundedVars.length) ?? param;
      } else {
        lambdaStack.add(lambdaStack.last.exp1!);
        isExp1Stack.add(true);
        param = onAppEnter?.call(param, boundedVars.length) ?? param;
      }
    }

    return select(param);
  }

  /// A higher-order function that turns recursion on the [Lambda] to iteration,
  /// returning another [Lambda].
  ///
  /// Note that it doesn't simplify the shape of the original [Lambda]. In other
  /// words, each variable in the original [Lambda] maps to a [Lambda] term on
  /// its own.
  ///
  /// These callbacks should not modify the [Lambda] itself.
  ///
  /// It maintains an internal parameter of type `T` and calls the appropriate
  /// callback function for each sub-expression in the [Lambda], passing the
  /// parameter to the callback function and updating the parameter with the
  /// return value of the callback function.
  ///
  /// In detail, the callback functions are called by the following rules:
  /// - If the form is [LambdaForm.variable], call [onVar]. It takes the current
  ///   Lambda expression (i.e. the variable itself), the current parameter, and
  ///   depth of the variable (i.e. the number of abstractions that the variable
  ///   is bounded by) as arguments, and returns a new [Lambda] as replacement.
  ///   Note that the original [Lambda] itself is not modified.
  /// - If the form is [LambdaForm.application], call [onAppEnter] before
  ///   visiting the sub-expression, and call [onAppExit] after visiting the
  ///   sub-expression. Both callbacks take the current parameter, the depth,
  ///   and a boolean value indicating whether the sub-expression is the left
  ///   sub-expression or not as arguments, and return a new value as the next
  ///   parameter. Note that it visits both sub-expressions from left to right.
  /// - If the form is [LambdaForm.abstraction], call [onAbsEnter] before
  ///   visiting the sub-expression, and call [onAbsExit] after visiting the
  ///   sub-expression. Both callbacks take the current parameter and the depth
  ///   as arguments, and return a new value as the next parameter.
  Lambda fmap<T>({
    required Lambda Function(Lambda, T? param, int depth) onVar,
    T? initialParam,
    T? Function(Lambda varLambda, T? param, int depth)? onAbsEnter,
    T? Function(Lambda varLambda, T? param, int depth)? onAbsExit,
    T? Function(Lambda varLambda, T? param, int depth, bool isLeft)? onAppEnter,
    T? Function(Lambda varLambda, T? param, int depth, bool isLeft)? onAppExit,
  }) {
    final lambdaStack = [this];
    final resultStack = <Lambda>[Lambda(form: LambdaForm.dummy)];
    final isExp1Stack = [true];
    final boundedVars = <String?>[];
    var param = initialParam;

    while (lambdaStack.isNotEmpty) {
      if (lambdaStack.last.form == LambdaForm.variable) {
        resultStack.last = onVar(lambdaStack.last, param, boundedVars.length);
        while (true) {
          final cur = lambdaStack.removeLast();
          if (lambdaStack.isEmpty) break;
          var tempLambda = resultStack.removeLast();
          if (resultStack.last.form == LambdaForm.abstraction) {
            resultStack.last.exp1 = tempLambda;
            isExp1Stack.removeLast();
            boundedVars.removeAt(0);
            param = onAbsExit?.call(cur, param, boundedVars.length) ?? param;
          } else if (isExp1Stack.last) {
            resultStack.last.exp1 = tempLambda;

            isExp1Stack.last = false;
            param = onAppExit?.call(
                  cur,
                  param,
                  boundedVars.length,
                  true,
                ) ??
                param;
            lambdaStack.add(lambdaStack.last.exp2!);
            resultStack.add(Lambda(form: LambdaForm.dummy));
            param = onAppEnter?.call(
                  lambdaStack.last,
                  param,
                  boundedVars.length,
                  false,
                ) ??
                param;
            break;
          } else {
            resultStack.last.exp2 = tempLambda;
            isExp1Stack.removeLast();
            param = onAppExit?.call(
                  cur,
                  param,
                  boundedVars.length,
                  false,
                ) ??
                param;
          }
        }
      } else if (lambdaStack.last.form == LambdaForm.abstraction) {
        resultStack.last.form = LambdaForm.abstraction;
        resultStack.last.name = lambdaStack.last.name;
        boundedVars.insert(0, lambdaStack.last.name);
        resultStack.add(Lambda(form: LambdaForm.dummy));
        param = onAbsEnter?.call(
              lambdaStack.last,
              param,
              boundedVars.length,
            ) ??
            param;
        lambdaStack.add(lambdaStack.last.exp1!);
        isExp1Stack.add(true);
      } else {
        resultStack.last.form = LambdaForm.application;
        resultStack.add(Lambda(form: LambdaForm.dummy));
        lambdaStack.add(lambdaStack.last.exp1!);
        isExp1Stack.add(true);
        param = onAppEnter?.call(
              lambdaStack.last,
              param,
              boundedVars.length,
              true,
            ) ??
            param;
      }
    }

    assert(resultStack.length == 1);
    return resultStack.first;
  }

  /// Clone this lambda expression.
  ///
  /// Avoids recursion.
  Lambda clone() => fmap<void>(
        onVar: (lambda, _, depth) => Lambda(
          form: LambdaForm.variable,
          index: lambda.index,
          name: lambda.name,
        ),
      );

  /// Returns the number of free variables in the lambda expression.
  ///
  /// If the `isDistinct` parameter is set to true, count for the number of
  /// distinct free variables; otherwise count for the total appearances.
  int freeCount({bool countDistinct = false}) =>
      fold<int, Tuple2<int, Set<int>>>(
        initialParam: Tuple2(0, {}),
        select: (tuple2) => tuple2.value1,
        onVar: countDistinct
            ? (lambda, tuple2, depth) {
                if (depth - lambda.index! <= 0 &&
                    !tuple2.value2.contains(depth - lambda.index!)) {
                  tuple2.value2.add(depth - lambda.index!);
                  return tuple2.copyWith(value1: tuple2.value1 + 1);
                } else {
                  return tuple2;
                }
              }
            : (lambda, tuple2, depth) {
                if (depth - lambda.index! <= 0) {
                  return tuple2.copyWith(value1: tuple2.value1 + 1);
                } else {
                  return tuple2;
                }
              },
      );

  /// A string representation of the [Lambda] without redundant brackets and
  /// ignores custom names (so that all variables are in the form of `x{n}` or
  /// `y{n}`).
  ///
  /// Avoids recursion.
  String toStringNameless() {
    if (form == LambdaForm.dummy) return '[DUMMY]';

    final sb = StringBuffer();
    bool? isLeftParen = true;
    fmap<List<bool>>(
      initialParam: [false],
      onVar: (lambda, _, depth) {
        final curDepth = depth - lambda.index!;
        if (isLeftParen != true) {
          sb.write(' ');
        }
        if (curDepth > 0) {
          sb.write('_x$curDepth');
        } else {
          sb.write('_y${1 - curDepth}');
        }
        isLeftParen = null;
        return lambda;
      },
      onAbsEnter: (lambda, useBraces, depth) {
        if ((isLeftParen != true && useBraces!.last) ||
            (isLeftParen == false && !useBraces!.last)) {
          sb.write(' ');
        }
        if (useBraces!.last) {
          sb.write('(');
          isLeftParen = true;
        }
        if (depth > 0) {
          sb.write('λ_x$depth.');
        } else {
          sb.write('λ_y${1 - depth}.');
        }
        useBraces.add(false);
        isLeftParen = false;
        return useBraces;
      },
      onAbsExit: (lambda, useBraces, depth) {
        useBraces!.removeLast();
        if (useBraces.last) {
          sb.write(')');
          isLeftParen = false;
        }
        return useBraces;
      },
      onAppEnter: (lambda, useBraces, depth, isLeft) {
        if (useBraces!.last ||
            !isLeft && lambda.form == LambdaForm.application) {
          if (isLeftParen != true) sb.write(' ');
          sb.write('(');
          isLeftParen = true;
        }
        useBraces.add(lambda.form == LambdaForm.abstraction);
        return useBraces;
      },
      onAppExit: (lambda, useBraces, depth, isLeft) {
        useBraces!.removeLast();
        if (useBraces.last ||
            !isLeft && lambda.form == LambdaForm.application) {
          sb.write(')');
          isLeftParen = false;
        }
        return useBraces;
      },
    );

    return sb.toString();
  }
}
