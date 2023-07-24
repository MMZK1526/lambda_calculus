import 'package:lambda_calculus/src/lambda.dart';
import 'package:lambda_calculus/src/lambda_form.dart';
import 'package:lambda_calculus/src/utilities.dart';

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
        onAbsEnter: (_, depth, __) => depth = depth + 1,
        onAbsExit: (_, depth, __) => depth = depth - 1,
      );

  Lambda _substitution(Lambda term) => fmap<List<Lambda>>(
        initialParam: [term],
        onVar: (lambda, param, depth) =>
            depth == lambda.index ? param!.last : lambda,
        onAbsEnter: (param, depth, __) {
          param!.add(param.last._shift(1, 0));
          return param;
        },
        onAbsExit: (param, depth, __) {
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
        final lambdaStack = [Pair(true, this)];
        final resultStack = <Lambda>[];
        var isReduced = false;

        while (lambdaStack.isNotEmpty) {
          final cur = lambdaStack.last;
          if (cur.first) {
            if (isReduced || cur.second.form == LambdaForm.variable) {
              resultStack.add(cur.second);
              lambdaStack.removeLast();
            } else if (cur.second.form == LambdaForm.abstraction) {
              lambdaStack.add(Pair(true, cur.second.exp1!));
              cur.first = false;
            } else {
              if (cur.second.exp1!.form == LambdaForm.abstraction) {
                resultStack.add(cur.second._betaReduction());
                isReduced = true;
                lambdaStack.removeLast();
              } else {
                lambdaStack.add(Pair(true, cur.second.exp2!));
                lambdaStack.add(Pair(true, cur.second.exp1!));
                cur.first = false;
              }
            }
          } else {
            if (cur.second.form == LambdaForm.application) {
              final lambda2 = resultStack.removeLast();
              final lambda1 = resultStack.removeLast();
              resultStack.add(Lambda(
                form: LambdaForm.application,
                exp1: lambda1,
                exp2: lambda2,
              ));
            } else {
              final lambda = resultStack.removeLast();
              resultStack.add(Lambda(
                form: LambdaForm.abstraction,
                exp1: lambda,
                name: cur.second.name,
              ));
            }
            lambdaStack.removeLast();
          }
        }

        if (isReduced) return resultStack.first;
        break;
      case LambdaEvaluationType.callByName:
        final lambdaStack = [Pair(true, this)];
        final resultStack = <Lambda>[];
        var isReduced = false;

        while (lambdaStack.isNotEmpty) {
          final cur = lambdaStack.last;
          if (cur.first) {
            if (isReduced || cur.second.form != LambdaForm.application) {
              resultStack.add(cur.second);
              lambdaStack.removeLast();
            } else {
              if (cur.second.exp1!.form == LambdaForm.abstraction) {
                resultStack.add(cur.second._betaReduction());
                isReduced = true;
                lambdaStack.removeLast();
              } else {
                lambdaStack.add(Pair(true, cur.second.exp2!));
                lambdaStack.add(Pair(true, cur.second.exp1!));
                cur.first = false;
              }
            }
          } else {
            final lambda2 = resultStack.removeLast();
            final lambda1 = resultStack.removeLast();
            resultStack.add(Lambda(
              form: LambdaForm.application,
              exp1: lambda1,
              exp2: lambda2,
            ));
            lambdaStack.removeLast();
          }
        }

        if (isReduced) return resultStack.first;
        break;
      case LambdaEvaluationType.callByValue:
        final lambdaStack = [Pair(true, this)];
        final resultStack = <Lambda>[];
        var isReduced = false;

        while (lambdaStack.isNotEmpty) {
          final cur = lambdaStack.last;
          if (cur.first) {
            if (isReduced || cur.second.form != LambdaForm.application) {
              resultStack.add(cur.second);
              lambdaStack.removeLast();
            } else {
              if (cur.second.exp1!.form == LambdaForm.abstraction &&
                  cur.second.exp2!.form != LambdaForm.application) {
                resultStack.add(cur.second._betaReduction());
                isReduced = true;
                lambdaStack.removeLast();
              } else {
                lambdaStack.add(Pair(true, cur.second.exp2!));
                lambdaStack.add(Pair(true, cur.second.exp1!));
                cur.first = false;
              }
            }
          } else {
            final lambda2 = resultStack.removeLast();
            final lambda1 = resultStack.removeLast();
            resultStack.add(Lambda(
              form: LambdaForm.application,
              exp1: lambda1,
              exp2: lambda2,
            ));
            lambdaStack.removeLast();
          }
        }

        if (isReduced) return resultStack.first;
        break;
    }
    return null;
  }
}
