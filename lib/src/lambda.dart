import 'package:lambda_calculus/src/lambda_builder.dart';
import 'package:lambda_calculus/src/lambda_constants.dart';
import 'package:lambda_calculus/src/lambda_form.dart';
import 'package:lambda_calculus/src/lambda_interface.dart';
import 'package:lambda_calculus/src/lambda_parser.dart';
import 'package:lambda_calculus/src/utilities.dart';

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
/// See the documentation for [ToLambdaExtension] and [LambdaBuilder] for more
/// information on how to create lambda expressions.
class Lambda implements ILambda<Lambda> {
  /// Do not use the constructor directly. Use [LambdaBuilder] instead.
  const Lambda({
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
  final LambdaForm form;

  @override
  final int? index;

  @override
  final String? name;

  @override
  final Lambda? exp1;

  @override
  final Lambda? exp2;

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
  /// It does its best to retain the original names of the variables, but in
  /// case of name conflicts, it will choose a fresh variable that is guaranteed
  /// to be different from all the other variables in the [Lambda] term.
  ///
  /// Avoids recursion.
  @override
  String toString() {
    final sb = <Object>[];
    bool? isLeftParen = true;
    final lambdaStack = <Triple<bool, bool, Lambda>>[Triple(true, true, this)];
    final useBracesStack = [false];
    final boundVariables = <_LambdaFragment>[];
    final variableDepths = <String, List<int>>{};
    int depth = 0;
    final freshName = Solo<String>('[FRESH_VAR]');
    final usedVars = <String>{};

    while (lambdaStack.isNotEmpty) {
      final cur = lambdaStack.last;
      if (cur.first) {
        if (cur.third.form == LambdaForm.application) {
          if (cur.second) {
            if (useBracesStack.last) {
              if (isLeftParen != true) {
                sb.add(' ');
              }
              sb.add('(');
              isLeftParen = true;
            }
            useBracesStack.add(cur.third.exp1!.form == LambdaForm.abstraction);
            lambdaStack.add(Triple(true, true, cur.third.exp1!));
            cur.second = false;
          } else {
            if (useBracesStack.last ||
                cur.third.exp2!.form == LambdaForm.application) {
              if (isLeftParen != true) {
                sb.add(' ');
              }
              sb.add('(');
              isLeftParen = true;
            }
            useBracesStack.add(cur.third.exp2!.form == LambdaForm.abstraction);
            lambdaStack.add(Triple(true, true, cur.third.exp2!));
            cur.first = false;
          }
        } else if (cur.third.form == LambdaForm.abstraction) {
          if ((isLeftParen != true && useBracesStack.last) ||
              (isLeftParen == false && !useBracesStack.last)) {
            sb.add(' ');
          }
          if (useBracesStack.last) {
            sb.add('(');
            isLeftParen = true;
          }
          depth += 1;
          final fragment = _LambdaFragment(
            name: cur.third.name,
            depth: depth,
            freshName: freshName,
          );
          boundVariables.add(fragment);
          if (cur.third.name != null) {
            variableDepths.update(
              cur.third.name!,
              (value) => value..add(depth),
              ifAbsent: () => [depth],
            );
            usedVars.add(cur.third.name!);
          }
          sb.add(fragment);
          useBracesStack.add(false);
          lambdaStack.add(Triple(true, true, cur.third.exp1!));
          isLeftParen = false;
          cur.first = false;
        } else {
          final curIndex = depth - cur.third.index!;
          if (isLeftParen != true) {
            sb.add(' ');
          }
          if (cur.third.name != null &&
              variableDepths[cur.third.name]?.isNotEmpty == true &&
              variableDepths[cur.third.name]!.last == curIndex) {
            sb.add(cur.third.name!);
          } else if (curIndex > 0) {
            boundVariables[curIndex - 1].name = null;
            sb.add(freshName);
            sb.add(curIndex);
          } else {
            sb.add('y');
            sb.add(1 - curIndex);
          }
          isLeftParen = null;
          lambdaStack.removeLast();
          if (lambdaStack.isEmpty) {
            break;
          }
          if (lambdaStack.last.third.form == LambdaForm.application) {
            useBracesStack.removeLast();
            if (useBracesStack.last) {
              sb.add(')');
              isLeftParen = false;
            }
          }
        }
      } else {
        lambdaStack.removeLast();
        if (cur.third.form == LambdaForm.abstraction) {
          useBracesStack.removeLast();
          if (useBracesStack.last) {
            sb.add(')');
            isLeftParen = false;
          }
          depth -= 1;
          boundVariables.removeLast();
          if (cur.third.name != null) {
            variableDepths[cur.third.name!]!.removeLast();
          }
        }

        if (lambdaStack.isEmpty) {
          break;
        }
        if (lambdaStack.last.third.form == LambdaForm.application) {
          useBracesStack.removeLast();
          if (useBracesStack.last ||
              !lambdaStack.last.first &&
                  cur.third.form == LambdaForm.application) {
            sb.add(')');
            isLeftParen = false;
          }
        }
      }
    }

    freshName.value = _findFreshVariable(usedVars);

    return sb.map((e) => e.toString()).join();
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
          if (lambdaStack.isEmpty) {
            break;
          }
          if (lambdaStack.last.form == LambdaForm.abstraction) {
            isExp1Stack.removeLast();
            boundedVars.removeAt(0);
            param = onAbsExit?.call(param, boundedVars.length) ?? param;
          } else if (isExp1Stack.last) {
            lambdaStack.add(lambdaStack.last.exp2!);
            // https://github.com/dart-lang/sdk/issues/53944
            isExp1Stack.removeLast();
            isExp1Stack.add(false);
            // isExp1Stack.last = false;
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
  ///   sub-expression. Both callbacks take the current parameter, the depth,
  ///   and the name of the abstraction parameter as arguments, and return a new
  /// value as the next parameter.
  Lambda fmap<T>({
    required Lambda Function(Lambda varLambda, T? param, int depth) onVar,
    T? initialParam,
    T? Function(T? param, int depth, String? name)? onAbsEnter,
    T? Function(T? param, int depth, String? name)? onAbsExit,
    T? Function(T? param, int depth, bool isLeft)? onAppEnter,
    T? Function(T? param, int depth, bool isLeft)? onAppExit,
  }) {
    return ILambda.fmap<Lambda, Lambda, T>(
      onVar: onVar,
      initialParam: initialParam,
      onAbsEnter: onAbsEnter,
      onAbsExit: onAbsExit,
      onAppEnter: onAppEnter,
      onAppExit: onAppExit,
      initialLambda: this,
      abstract: (lambda, [name]) => Lambda(
        form: LambdaForm.abstraction,
        exp1: lambda,
        name: name,
      ),
      apply: ({required exp1, required exp2}) => Lambda(
        form: LambdaForm.application,
        exp1: exp1,
        exp2: exp2,
      ),
    );
  }

  /// Clone this lambda expression.
  ///
  /// Avoids recursion.
  Lambda clone() => fmap<void>(
        onVar: (lambda, _, __) => Lambda(
          form: LambdaForm.variable,
          index: lambda.index,
          name: lambda.name,
        ),
      );

  /// Returns the number of free variables in the lambda expression.
  ///
  /// If the `countDistinct` parameter is set to true, count for the number of
  /// distinct free variables; otherwise count for the total appearances.
  int freeCount({bool countDistinct = false}) => fold<int, Pair<int, Set<int>>>(
        initialParam: Pair(0, {}),
        select: (tuple2) => tuple2.first,
        onVar: countDistinct
            ? (lambda, tuple2, depth) {
                if (depth - lambda.index! <= 0 &&
                    !tuple2.second.contains(depth - lambda.index!)) {
                  tuple2.second.add(depth - lambda.index!);
                  return Pair(tuple2.first + 1, tuple2.second);
                } else {
                  return tuple2;
                }
              }
            : (lambda, tuple2, depth) {
                if (depth - lambda.index! <= 0) {
                  return Pair(tuple2.first + 1, tuple2.second);
                } else {
                  return tuple2;
                }
              },
      );

  /// A string representation of the [Lambda] without redundant brackets and
  /// ignoring custom names (so that all variables are in the form of `x{n}` or
  /// `y{n}`).
  ///
  /// Avoids recursion.
  String toStringNameless() {
    final sb = StringBuffer();
    bool? isLeftParen = true;
    final lambdaStack = <Triple<bool, bool, Lambda>>[Triple(true, true, this)];
    final useBracesStack = [false];
    int depth = 0;

    while (lambdaStack.isNotEmpty) {
      final cur = lambdaStack.last;

      if (cur.first) {
        if (cur.third.form == LambdaForm.application) {
          if (cur.second) {
            if (useBracesStack.last) {
              if (isLeftParen != true) {
                sb.write(' ');
              }
              sb.write('(');
              isLeftParen = true;
            }
            useBracesStack.add(cur.third.exp1!.form == LambdaForm.abstraction);
            lambdaStack.add(Triple(true, true, cur.third.exp1!));
            cur.second = false;
          } else {
            if (useBracesStack.last ||
                cur.third.exp2!.form == LambdaForm.application) {
              if (isLeftParen != true) {
                sb.write(' ');
              }
              sb.write('(');
              isLeftParen = true;
            }
            useBracesStack.add(cur.third.exp2!.form == LambdaForm.abstraction);
            lambdaStack.add(Triple(true, true, cur.third.exp2!));
            cur.first = false;
          }
        } else if (cur.third.form == LambdaForm.abstraction) {
          if ((isLeftParen != true && useBracesStack.last) ||
              (isLeftParen == false && !useBracesStack.last)) {
            sb.write(' ');
          }
          if (useBracesStack.last) {
            sb.write('(');
            isLeftParen = true;
          }
          depth += 1;
          sb.write('λx$depth.');
          useBracesStack.add(false);
          lambdaStack.add(Triple(true, true, cur.third.exp1!));
          isLeftParen = false;
          cur.first = false;
        } else {
          final curIndex = depth - cur.third.index!;
          if (isLeftParen != true) {
            sb.write(' ');
          }
          if (curIndex > 0) {
            sb.write('x$curIndex');
          } else {
            sb.write('y${1 - curIndex}');
          }
          isLeftParen = null;
          lambdaStack.removeLast();
          if (lambdaStack.isEmpty) {
            break;
          }
          if (lambdaStack.last.third.form == LambdaForm.application) {
            useBracesStack.removeLast();
            if (useBracesStack.last) {
              sb.write(')');
              isLeftParen = false;
            }
          }
        }
      } else {
        lambdaStack.removeLast();
        if (cur.third.form == LambdaForm.abstraction) {
          useBracesStack.removeLast();
          if (useBracesStack.last) {
            sb.write(')');
            isLeftParen = false;
          }
          depth -= 1;
        }

        if (lambdaStack.isEmpty) {
          break;
        }
        if (lambdaStack.last.third.form == LambdaForm.application) {
          useBracesStack.removeLast();
          if (useBracesStack.last ||
              !lambdaStack.last.first &&
                  cur.third.form == LambdaForm.application) {
            sb.write(')');
            isLeftParen = false;
          }
        }
      }
    }

    return sb.toString();
  }
}

class _LambdaFragment {
  _LambdaFragment({this.name, required this.depth, required this.freshName});

  String? name;

  int depth;

  Solo<String> freshName;

  @override
  int get hashCode => name.hashCode * 31 + depth.hashCode;

  @override
  bool operator ==(Object other) =>
      other is _LambdaFragment && name == other.name && depth == other.depth;

  @override
  String toString() => name != null ? 'λ$name.' : 'λ${freshName.value}$depth.';
}

String _findFreshVariable(Set<String> usedNames) {
  var index = 0;
  var namesToBeRemoved = <String>{};
  var usedChars = <String>{}; // a-z
  var curFreshNameSB = StringBuffer();
  while (true) {
    namesToBeRemoved = <String>{};
    usedChars = <String>{};

    for (final name in usedNames) {
      if (index >= name.length) {
        namesToBeRemoved.add(name);
        continue;
      }

      usedChars.add(name[index]);
    }

    if (!usedChars.contains("x")) {
      curFreshNameSB.write("x");
      break;
    }

    bool flag = false;
    for (final char in [
      'a', 'b', 'c', 'd', 'e', 'f', 'g', 'h', 'i', 'j', //
      'k', 'l', 'm', 'n', 'o', 'p', 'q', 'r', 's', 't', //
      'u', 'v', 'w', 'y', 'z'
    ]) {
      if (!usedChars.contains(char)) {
        curFreshNameSB.write(char);
        flag = true;
        break;
      }
    }

    if (flag) {
      break;
    }

    curFreshNameSB.write("x");
    index += 1;
  }

  return curFreshNameSB.toString();
}
