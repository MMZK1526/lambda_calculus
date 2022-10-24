import 'package:lambda_calculus/src/lambda_evaluator.dart';
import 'package:lambda_calculus/src/lambda.dart';

extension LambdaConversionIntExtension on int {
  /// Convert a natural number to church number.
  ///
  /// Negative numbers treat as zero.
  Lambda toChurchNumber() {
    var n = this;
    if (this < 0) {
      n = 0;
    }

    return Lambda.abstract(
      Lambda.abstract(
        Lambda.applyAllReversed([
          for (var _ in List.generate(n, (_) => null)) Lambda.fromIndex(1),
          Lambda.fromIndex(0),
        ]),
      ),
    );
  }
}

extension LambdaConversionExtension on Lambda {
  /// The succ (+1) expression.
  static final lambdaSucc = Lambda.abstract(
    Lambda.abstract(
      Lambda.abstract(
        Lambda(
          type: LambdaType.application,
          exp1: Lambda.fromIndex(1),
          exp2: Lambda.applyAll([
            Lambda.fromIndex(2),
            Lambda.fromIndex(1),
            Lambda.fromIndex(0),
          ]),
        ),
      ),
    ),
  );

  /// Convert the lambda expression that is a church number to a natural number.
  ///
  /// Returns -1 if the expression is not behaviourally equivalent to a church
  /// number.
  int toInt() {
    try {
      var temp = Lambda.applyAll([this, lambdaSucc, 0.toChurchNumber()])
          .eval(evalType: LambdaEvaluationType.fullReduction)
          .exp1!
          .exp1!;
      var num = 0;
      while (temp.type == LambdaType.application) {
        num++;
        if (temp.exp1?.index != 1) return -1;
        temp = temp.exp2!;
      }
      if (temp.index != 0) return -1;
      return num;
    } catch (_) {
      return -1;
    }
  }
}
