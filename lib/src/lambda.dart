import 'package:dartz/dartz.dart';

/// Types of lambda expressions.
enum LambdaForm {
  variable,
  application,
  abstraction,
  dummy,
}

/// The class representing lambda expressions.
class Lambda {
  Lambda({
    required this.form,
    this.index, // For variable
    this.exp1, // For application and abstraction
    this.exp2, // For application
  }) : assert(!(form == LambdaForm.variable &&
                (index == null || exp1 != null || exp2 != null)) &&
            !(form == LambdaForm.application &&
                (index != null || exp1 == null || exp2 == null)) &&
            !(form == LambdaForm.abstraction &&
                (index != null || exp1 == null || exp2 != null)));
  LambdaForm form;
  int? index;
  Lambda? exp1;
  Lambda? exp2;

  /// Construct a lambda variable with the given De Bruijn index.
  static Lambda fromIndex(int index) =>
      Lambda(form: LambdaForm.variable, index: index);

  /// Construct the abstraction of a given lambda expression.
  static Lambda abstract(Lambda lambda) =>
      Lambda(form: LambdaForm.abstraction, exp1: lambda);

  /// Apply a list of lambda expressions together from left to right.
  static Lambda applyAll(List<Lambda> lambdas) {
    if (lambdas.isEmpty) {
      return Lambda(
        form: LambdaForm.abstraction,
        exp1: Lambda(form: LambdaForm.variable, index: 0),
      );
    }

    return lambdas.reduce(
      (previousValue, element) => Lambda(
        form: LambdaForm.application,
        exp1: previousValue,
        exp2: element,
      ),
    );
  }

  /// Apply a list of lambda expressions together from right to left.
  static Lambda applyAllReversed(List<Lambda> lambdas) {
    if (lambdas.isEmpty) {
      return Lambda(
        form: LambdaForm.abstraction,
        exp1: Lambda(form: LambdaForm.variable, index: 0),
      );
    }

    Lambda _applyAllReversed(List<Lambda> lambdas) {
      if (lambdas.length == 1) {
        return lambdas.first;
      }

      final first = lambdas.removeAt(0);
      return Lambda(
        form: LambdaForm.application,
        exp1: first,
        exp2: applyAllReversed(lambdas),
      );
    }

    return _applyAllReversed(lambdas);
  }

  /// A higher-order function that iterates on the [Lambda], returning a value.
  R fold<R, T>({
    required T initialParam,
    required R Function(T) select,
    T Function(Lambda, T)? onVar,
    T Function(T)? onAbsEnter,
    T Function(T)? onAbsExit,
    T Function(T)? onAppEnter,
    T Function(T)? onAppExit,
  }) {
    final lambdaStack = [this];
    final isExp1Stack = [true];
    var param = initialParam;

    while (lambdaStack.isNotEmpty) {
      if (lambdaStack.last.form == LambdaForm.variable) {
        param = onVar?.call(lambdaStack.last, param) ?? param;
        while (true) {
          lambdaStack.removeLast();
          if (lambdaStack.isEmpty) break;
          if (lambdaStack.last.form == LambdaForm.abstraction) {
            isExp1Stack.removeLast();
            param = onAbsExit?.call(param) ?? param;
          } else if (isExp1Stack.last) {
            lambdaStack.add(lambdaStack.last.exp2!);
            isExp1Stack.last = false;
            param = onAppExit?.call(param) ?? param;
            param = onAppEnter?.call(param) ?? param;
            break;
          } else {
            isExp1Stack.removeLast();
            param = onAppExit?.call(param) ?? param;
          }
        }
      } else if (lambdaStack.last.form == LambdaForm.abstraction) {
        lambdaStack.add(lambdaStack.last.exp1!);
        isExp1Stack.add(true);
        param = onAbsEnter?.call(param) ?? param;
      } else {
        lambdaStack.add(lambdaStack.last.exp1!);
        isExp1Stack.add(true);
        param = onAppEnter?.call(param) ?? param;
      }
    }

    return select(param);
  }

  /// A higher-order function that turns recursion on the [Lambda] to iteration,
  /// returning another [Lambda].
  Lambda fmap<T>({
    required Lambda Function(Lambda, T?) onVar,
    T? initialParam,
    T? Function(T?)? onAbsEnter,
    T? Function(T?)? onAbsExit,
    T? Function(T?)? onAppEnter,
    T? Function(T?)? onAppExit,
  }) {
    final lambdaStack = [this];
    final resultStack = <Lambda>[Lambda(form: LambdaForm.dummy)];
    final isExp1Stack = [true];
    var param = initialParam;

    while (lambdaStack.isNotEmpty) {
      if (lambdaStack.last.form == LambdaForm.variable) {
        resultStack.last = onVar(lambdaStack.last, param);
        while (true) {
          lambdaStack.removeLast();
          if (lambdaStack.isEmpty) break;
          var tempLambda = resultStack.removeLast();
          if (resultStack.last.form == LambdaForm.abstraction) {
            resultStack.last.exp1 = tempLambda;
            isExp1Stack.removeLast();
            param = onAbsExit?.call(param) ?? param;
          } else if (isExp1Stack.last) {
            resultStack.last.exp1 = tempLambda;
            lambdaStack.add(lambdaStack.last.exp2!);
            resultStack.add(Lambda(form: LambdaForm.dummy));
            isExp1Stack.last = false;
            param = onAppExit?.call(param) ?? param;
            param = onAppEnter?.call(param) ?? param;
            break;
          } else {
            resultStack.last.exp2 = tempLambda;
            isExp1Stack.removeLast();
            param = onAppExit?.call(param) ?? param;
          }
        }
      } else if (lambdaStack.last.form == LambdaForm.abstraction) {
        resultStack.last.form = LambdaForm.abstraction;
        resultStack.add(Lambda(form: LambdaForm.dummy));
        lambdaStack.add(lambdaStack.last.exp1!);
        isExp1Stack.add(true);
        param = onAbsEnter?.call(param) ?? param;
      } else {
        resultStack.last.form = LambdaForm.application;
        resultStack.add(Lambda(form: LambdaForm.dummy));
        lambdaStack.add(lambdaStack.last.exp1!);
        isExp1Stack.add(true);
        param = onAppEnter?.call(param) ?? param;
      }
    }

    assert(resultStack.length == 1);
    return resultStack.first;
  }

  /// Clone this lambda expression.
  ///
  /// Avoids recursion.
  Lambda clone() => fmap<void>(
        onVar: (lambda, _) => Lambda(
          form: LambdaForm.variable,
          index: lambda.index,
        ),
      );

  /// Returns the number of free variables in the lambda expression.
  ///
  /// If the 'isDistinct' parameter is set to true, count for the number of
  /// distinct free variables; otherwise count for the total appearances.
  int freeCount({bool isDistinct = false}) =>
      fold<int, Tuple3<int, int, Set<int>>>(
        initialParam: const Tuple3(0, 0, {}),
        select: (tuple3) => tuple3.value1,
        onAbsEnter: (tuple3) => tuple3.copyWith(value2: tuple3.value2 + 1),
        onAbsExit: (tuple3) => tuple3.copyWith(value2: tuple3.value2 - 1),
        onVar: isDistinct
            ? (lambda, tuple3) {
                if (tuple3.value2 - lambda.index! <= 0 &&
                    !tuple3.value3.contains(tuple3.value2 - lambda.index!)) {
                  tuple3.value3.add(tuple3.value2 - lambda.index!);
                  return tuple3.copyWith(value1: tuple3.value1 + 1);
                } else {
                  return tuple3;
                }
              }
            : (lambda, tuple3) {
                if (tuple3.value2 - lambda.index! <= 0) {
                  return tuple3.copyWith(value1: tuple3.value1 + 1);
                } else {
                  return tuple3;
                }
              },
      );

  @override
  int get hashCode => toString().hashCode;

  /// The equality operator.
  ///
  /// Returns true iff the two [Lambda]s are syntactically identical.
  ///
  /// Avoids recursion.
  @override
  bool operator ==(Object other) {
    if (other.runtimeType != Lambda) return false;

    final lambdaStack1 = [this];
    final lambdaStack2 = [other as Lambda];
    final isExp1Stack = [true];

    while (lambdaStack1.isNotEmpty) {
      if (lambdaStack1.last.form != lambdaStack2.last.form) return false;
      if (lambdaStack1.last.form == LambdaForm.variable) {
        if (lambdaStack1.last.index != lambdaStack2.last.index) return false;
        while (true) {
          lambdaStack1.removeLast();
          lambdaStack2.removeLast();
          if (lambdaStack1.isEmpty) break;
          if (lambdaStack1.last.form == LambdaForm.abstraction) {
            isExp1Stack.removeLast();
          } else if (isExp1Stack.last) {
            lambdaStack1.add(lambdaStack1.last.exp2!);
            lambdaStack2.add(lambdaStack2.last.exp2!);
            isExp1Stack.last = false;
            break;
          } else {
            isExp1Stack.removeLast();
          }
        }
      } else {
        lambdaStack1.add(lambdaStack1.last.exp1!);
        lambdaStack2.add(lambdaStack2.last.exp1!);
        isExp1Stack.add(true);
      }
    }

    return true;
  }

  /// A string representation of the [Lambda] without redundant brackets.
  ///
  /// Avoids recursion.
  @override
  String toString() {
    if (form == LambdaForm.dummy) return '[DUMMY]';

    final lambdaStack = <Lambda?>[];
    final sb = StringBuffer();
    var cur = this;
    var depth = 0;
    final useBraces = [false];

    while (true) {
      if (cur.form == LambdaForm.variable) {
        final curDepth = depth - cur.index!;
        if (curDepth > 0) {
          sb.write('x$curDepth');
        } else {
          sb.write('y${1 - curDepth}');
        }
        while (lambdaStack.isNotEmpty) {
          if (lambdaStack.last == null) {
            depth--;
            useBraces.removeLast();
            if (useBraces.last) {
              sb.write(')');
            }
            lambdaStack.removeLast();
          } else if (lambdaStack.last!.form == LambdaForm.dummy) {
            useBraces.removeLast();
            if (useBraces.last) {
              sb.write(')');
            }
            lambdaStack.removeLast();
          } else {
            break;
          }
        }
        if (lambdaStack.isEmpty) break;
        sb.write(' ');
        cur = lambdaStack.removeLast()!;
        useBraces.removeLast();
        useBraces.add(true);
      } else if (cur.form == LambdaForm.application) {
        if (useBraces.last) {
          sb.write('(');
        }
        lambdaStack.add(Lambda(form: LambdaForm.dummy));
        lambdaStack.add(cur.exp2);
        cur = cur.exp1!;
        useBraces.add(cur.form == LambdaForm.abstraction);
      } else {
        depth++;
        if (useBraces.last) {
          sb.write('(');
        }
        if (depth > 0) {
          sb.write('λx$depth. ');
        } else {
          sb.write('λy${1 - depth}');
        }
        lambdaStack.add(null);
        useBraces.add(false);
        cur = cur.exp1!;
      }
    }

    return sb.toString();
  }
}
