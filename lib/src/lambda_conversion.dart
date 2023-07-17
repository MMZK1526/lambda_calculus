import 'dart:math';

import 'package:lambda_calculus/src/lambda_builder.dart';
import 'package:lambda_calculus/src/lambda_evaluator.dart';
import 'package:lambda_calculus/src/lambda.dart';
import 'package:lambda_calculus/src/lambda_form.dart';

extension LambdaConversionIntExtension on int {
  /// Convert a natural number to church number.
  ///
  /// Negative numbers treated as zero.
  Lambda toChurchNumber() => toChurchNumberBuilder().build();

  LambdaBuilder toChurchNumberBuilder() {
    var n = max(this, 0);

    return LambdaBuilder.abstract(
      LambdaBuilder.abstract(
        LambdaBuilder.applyAllReversed([
          for (int ix = 0; ix < n; ix++) LambdaBuilder.fromVar(name: 'x'),
          LambdaBuilder.fromVar(name: 'y'),
        ]),
        'y',
      ),
      'x',
    );
  }
}

extension LambdaConversionExtension on Lambda {
  /// The succ (+1) expression.
  static final lambdaSucc = LambdaBuilder.abstract(
    LambdaBuilder.abstract(
      LambdaBuilder.abstract(
        LambdaBuilder(
          form: LambdaForm.application,
          exp1: LambdaBuilder.fromVar(name: 'y'),
          exp2: LambdaBuilder.applyAll([
            LambdaBuilder.fromVar(name: 'x'),
            LambdaBuilder.fromVar(name: 'y'),
            LambdaBuilder.fromVar(name: 'z'),
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
      var temp =
          LambdaBuilder.applyAll([this, lambdaSucc, 0.toChurchNumberBuilder()])
              .build()
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
