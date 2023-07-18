import 'dart:math';

import 'package:lambda_calculus/src/lambda_builder.dart';
import 'package:lambda_calculus/src/lambda_evaluator.dart';
import 'package:lambda_calculus/src/lambda.dart';
import 'package:lambda_calculus/src/lambda_form.dart';

/// An extension that converts [int] to [Lambda] using the Church natural number
/// encoding.
extension LambdaConversionIntExtension on int {
  /// Convert a natural number to church number.
  ///
  /// Negative numbers treated as zero.
  Lambda toChurchNumber() => toChurchNumberBuilder().build();

  /// Similar to [toChurchNumber], but returns a [LambdaBuilder] instead.
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

/// An extension that converts [Lambda] to [int] using the Church natural number
/// encoding.
///
/// Note that this extension performs full reduction on the lambda expression
/// before converting it to an integer. And due to undecidability of the
/// lambda calculus, this operation may not terminate, and there is no way to
/// tell in general.
extension LambdaConversionExtension on Lambda {
  /// Convert the lambda expression that is a church number to a natural number.
  ///
  /// Returns -1 if the expression is not behaviourally equivalent to a church
  /// number.
  int toInt() {
    try {
      var temp = LambdaBuilder.applyAll([
        this,
        LambdaBuilder.constants.succ(),
        0.toChurchNumberBuilder(),
      ]).build().eval(evalType: LambdaEvaluationType.fullReduction).exp1!.exp1!;
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
