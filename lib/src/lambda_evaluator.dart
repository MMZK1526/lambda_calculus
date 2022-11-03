import 'package:dartz/dartz.dart';
import 'package:lambda_calculus/src/lambda.dart';

enum LambdaEvaluationType {
  /// Call by name, attempts to reduce everything.
  fullReduction,

  /// Call by name, does not reduce within abstraction.
  callByName,

  /// Call by value, does not reduce within abstraction.
  callByValue,
}

extension LambdaEvaluationExtension on Lambda {
  Lambda _shift(int amount, int cutoff) => fmap<int>(
        initialParam: 0,
        onVar: (lambda, depth) => Lambda(
          form: LambdaForm.variable,
          index: lambda.index! >= cutoff + depth!
              ? lambda.index! + amount
              : lambda.index,
        ),
        onAbsEnter: (depth) => depth = depth! + 1,
        onAbsExit: (depth) => depth = depth! - 1,
      );

  Lambda _substitution(Lambda term) => fmap<Tuple2<int, List<Lambda>>>(
        initialParam: Tuple2(0, [term]),
        onVar: (lambda, param) =>
            param!.value1 == lambda.index ? param.value2.last : lambda,
        onAbsEnter: (param) {
          param!.value2.add(param.value2.last._shift(1, 0));
          return Tuple2(param.value1 + 1, param.value2);
        },
        onAbsExit: (param) {
          param!.value2.removeLast();
          return Tuple2(param.value1 - 1, param.value2);
        },
      );

  Lambda _betaReduction() {
    assert(
      form == LambdaForm.application && exp1!.form == LambdaForm.abstraction,
    );

    return exp1!.exp1!._substitution(exp2!._shift(1, 0))._shift(-1, 0);
  }

  /// Evaluate the lambda expression to its simplest form. No guarantee that
  /// this function will converge.
  ///
  /// Avoids recursion.
  Lambda eval({
    LambdaEvaluationType evalType = LambdaEvaluationType.callByValue,
  }) {
    Lambda? result = this;
    var prev = this;

    while (result != null) {
      prev = result;
      result = result.eval1(evalType: evalType);
    }

    return prev;
  }

  /// Evaluate for one step; throws [UnimplementedError] when the lambda
  /// expression is not reduceable.
  ///
  /// Avoids recursion.
  Lambda? eval1({
    LambdaEvaluationType evalType = LambdaEvaluationType.callByValue,
  }) {
    switch (evalType) {
      case LambdaEvaluationType.fullReduction:
        final lambdaStack = [clone()];
        final isExp1Stack = [true];
        var isReduced = false;
        Lambda? result;
        while (lambdaStack.isNotEmpty) {
          if (lambdaStack.last.form == LambdaForm.variable || isReduced) {
            while (true) {
              final temp = lambdaStack.removeLast();
              if (lambdaStack.isEmpty) {
                result = temp;
                break;
              }
              if (lambdaStack.last.form == LambdaForm.abstraction) {
                lambdaStack.last.exp1 = temp;
                isExp1Stack.removeLast();
              } else if (isExp1Stack.last) {
                lambdaStack.last.exp1 = temp;
                lambdaStack.add(lambdaStack.last.exp2!);
                isExp1Stack.last = false;
                break;
              } else {
                lambdaStack.last.exp2 = temp;
                isExp1Stack.removeLast();
              }
            }
          } else if (lambdaStack.last.form == LambdaForm.abstraction) {
            lambdaStack.add(lambdaStack.last.exp1!);
            isExp1Stack.add(true);
          } else {
            if (lambdaStack.last.exp1!.form == LambdaForm.abstraction) {
              lambdaStack.last = lambdaStack.last._betaReduction();
              isReduced = true;
            } else {
              lambdaStack.add(lambdaStack.last.exp1!);
              isExp1Stack.add(true);
            }
          }
        }

        if (isReduced) return result!;
        break;
      case LambdaEvaluationType.callByName:
        final lambdaStack = [clone()];
        final isExp1Stack = [true];
        var isReduced = false;
        Lambda? result;
        while (lambdaStack.isNotEmpty) {
          if (lambdaStack.last.form != LambdaForm.application || isReduced) {
            while (true) {
              final temp = lambdaStack.removeLast();
              if (lambdaStack.isEmpty) {
                result = temp;
                break;
              }
              if (isExp1Stack.last) {
                lambdaStack.last.exp1 = temp;
                lambdaStack.add(lambdaStack.last.exp2!);
                isExp1Stack.last = false;
                break;
              } else {
                lambdaStack.last.exp2 = temp;
                isExp1Stack.removeLast();
              }
            }
          } else {
            if (lambdaStack.last.exp1!.form == LambdaForm.abstraction) {
              lambdaStack.last = lambdaStack.last._betaReduction();
              isReduced = true;
            } else {
              lambdaStack.add(lambdaStack.last.exp1!);
              isExp1Stack.add(true);
            }
          }
        }

        if (isReduced) return result!;
        break;
      case LambdaEvaluationType.callByValue:
        final lambdaStack = [clone()];
        final isExp1Stack = [true];
        var isReduced = false;
        Lambda? result;
        while (lambdaStack.isNotEmpty) {
          if (lambdaStack.last.form != LambdaForm.application || isReduced) {
            while (true) {
              final temp = lambdaStack.removeLast();
              if (lambdaStack.isEmpty) {
                result = temp;
                break;
              }
              if (isExp1Stack.last) {
                lambdaStack.last.exp1 = temp;
                lambdaStack.add(lambdaStack.last.exp2!);
                isExp1Stack.last = false;
                break;
              } else {
                lambdaStack.last.exp2 = temp;
                isExp1Stack.removeLast();
              }
            }
          } else {
            if (lambdaStack.last.exp1!.form == LambdaForm.abstraction &&
                lambdaStack.last.exp2!.form == LambdaForm.abstraction) {
              lambdaStack.last = lambdaStack.last._betaReduction();
              isReduced = true;
            } else if (lambdaStack.last.exp1!.form != LambdaForm.abstraction) {
              lambdaStack.add(lambdaStack.last.exp1!);
              isExp1Stack.add(true);
            } else {
              lambdaStack.add(lambdaStack.last.exp2!);
              isExp1Stack.add(false);
            }
          }
        }

        if (isReduced) return result!;
        break;
    }
    return null;
  }
}
