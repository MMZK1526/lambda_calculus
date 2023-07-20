import 'package:lambda_calculus/src/lambda.dart';
import 'package:lambda_calculus/src/lambda_form.dart';

/// The evaluation strategies for lambda calculus.
///
/// It provides three strategies:
/// - [fullReduction]: Call by name, attempts to reduce everything.
/// - [callByName]: Call by name, does not reduce within abstraction. Usually
///   corresponds to "lazy evaluation".
/// - [callByValue]: Call by value, does not reduce within abstraction. Usually
///   corresponds to "eager evaluation".
enum LambdaEvaluationType {
  fullReduction,
  callByName,
  callByValue,
}

/// Extension for evaluating [Lambda] expressions.
extension LambdaEvaluationExtension on Lambda {
  Lambda _shift(int amount, int cutoff) => fmap<int>(
        initialParam: 0,
        onVar: (lambda, _, depth) => Lambda(
          form: LambdaForm.variable,
          index: lambda.index! >= cutoff + depth
              ? lambda.index! + amount
              : lambda.index,
          name: lambda.name,
        ),
        onAbsEnter: (_, depth) => depth = depth + 1,
        onAbsExit: (_, depth) => depth = depth - 1,
      );

  Lambda _substitution(Lambda term) => fmap<List<Lambda>>(
        initialParam: [term],
        onVar: (lambda, param, depth) =>
            depth == lambda.index ? param!.last : lambda,
        onAbsEnter: (param, depth) {
          param!.add(param.last._shift(1, 0));
          return param;
        },
        onAbsExit: (param, depth) {
          param!.removeLast();
          return param;
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

  /// Evaluate for one step; returns `null` if no further reduction can be done.
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
