import 'package:dartz/dartz.dart';
import 'package:lambda_calculus/src/lambda_form.dart';
import 'package:lambda_calculus/src/lambda_interface.dart';

/// The class representing lambda expressions.
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

  /// A higher-order function that iterates on the [Lambda], returning a value.
  R fold<R, T>({
    required T initialParam,
    required R Function(T) select,
    T Function(Lambda, T, int)? onVar,
    T Function(T, int)? onAbsEnter,
    T Function(T, int)? onAbsExit,
    T Function(T, int)? onAppEnter,
    T Function(T, int)? onAppExit,
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
  Lambda fmap<T>({
    required Lambda Function(Lambda, T? param, int depth) onVar,
    T? initialParam,
    T? Function(Lambda, T? param, int depth)? onAbsEnter,
    T? Function(Lambda, T? param, int depth)? onAbsExit,
    T? Function(Lambda, T? param, int depth, bool isLeft)? onAppEnter,
    T? Function(Lambda, T? param, int depth, bool isLeft)? onAppExit,
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
  /// If the 'isDistinct' parameter is set to true, count for the number of
  /// distinct free variables; otherwise count for the total appearances.
  int freeCount({bool countDistinct = false}) =>
      fold<int, Tuple2<int, Set<int>>>(
        // We need to make the map mutable, thus not const.
        // ignore: prefer_const_constructors
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
  /// ignores custom names (so that all variables are in the form of x{n} or
  /// y{n}).
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
}
