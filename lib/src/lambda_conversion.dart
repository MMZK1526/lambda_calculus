import 'dart:math';

import 'package:lambda_calculus/src/lambda_evaluator.dart';
import 'package:lambda_calculus/src/lambda.dart';

extension LambdaConversionIntExtension on int {
  /// Convert a natural number to church number.
  ///
  /// Negative numbers treat as zero.
  Lambda toChurchNumber() {
    var n = max(this, 0);

    return Lambda.abstract(
      Lambda.abstract(
        Lambda.applyAllReversed([
          for (int ix = 0; ix < n; ix++) Lambda.fromVar(name: 'x'),
          Lambda.fromVar(name: 'y'),
        ]),
        'y',
      ),
      'x',
    );
  }
}

extension LambdaConversionExtension on Lambda {
  /// The succ (+1) expression.
  static final lambdaSucc = Lambda.abstract(
    Lambda.abstract(
      Lambda.abstract(
        Lambda(
          form: LambdaForm.application,
          exp1: Lambda.fromVar(name: 'y'),
          exp2: Lambda.applyAll([
            Lambda.fromVar(name: 'x'),
            Lambda.fromVar(name: 'y'),
            Lambda.fromVar(name: 'z'),
          ]),
        ),
        'z',
      ),
      'y',
    ),
    'x',
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
      while (temp.form == LambdaForm.application) {
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
