import 'package:lambda_calculus/lambda_calculus.dart';
import 'package:test/test.dart';

void main() {
  test('Playground', () {
    final l1 = r'(\x \y \z. x z (y z)) (\a\b a)'.toLambda()!;
    print(l1.eval(evalType: LambdaEvaluationType.fullReduction));
  });

  test(
    'Clone Test',
    () {
      expect(
        identityHashCode(LambdaConstants.lambdaTrue.build()),
        isNot(identityHashCode(LambdaConstants.lambdaTrue.build().clone())),
      );
      expect(
        LambdaConstants.lambdaTrue.build(),
        LambdaConstants.lambdaTrue.build().clone(),
      );
      expect(
        identityHashCode(LambdaConstants.lambdaSeven),
        isNot(identityHashCode(LambdaConstants.lambdaSeven.clone())),
      );
      expect(LambdaConstants.lambdaSeven, LambdaConstants.lambdaSeven.clone());
      expect(
        identityHashCode(LambdaConstants.yCombinator.build()),
        isNot(identityHashCode(LambdaConstants.yCombinator.build().clone())),
      );
      expect(
        LambdaConstants.yCombinator.build(),
        LambdaConstants.yCombinator.build().clone(),
      );
    },
  );

  test('Parse Test', () {
    expect(
      r'\x1(λx2. x1 (λx3. x2 x2 x3)) (λx2. x1 (λ x2 x2 0))'.toLambda(),
      LambdaConstants.yCombinator.build(),
    );
    expect(
      r'\_x1 _x1'.toLambda(),
      LambdaConstants.lambdaIdentity.build(),
    );
    expect(r'\_x2 _x1'.toLambda(), null);
    expect(r'((x1 (\x2 x2))'.toLambda(), null);
  });

  test(
    'Evaluation Test',
    () {
      expect(
        LambdaBuilder.applyAll([
          LambdaConstants.lambdaTest,
          LambdaConstants.lambdaFalse,
          LambdaConstants.lambdaTwo,
          LambdaConstants.lambdaOne,
        ]).build().eval(),
        LambdaConstants.lambdaOne,
      );
      expect(
        LambdaConstants.yCombinator.build().eval(),
        LambdaConstants.yCombinator.build(),
      );
      expect(
        LambdaBuilder.applyAll([
          LambdaConstants.lambdaSucc,
          LambdaConstants.lambdaSix,
        ]).build().toInt(),
        7,
      );
      expect(
        LambdaBuilder.applyAll([
          LambdaConstants.lambdaPlus,
          LambdaConstants.lambdaTwo,
          LambdaConstants.lambdaThree,
        ]).build().toInt(),
        5,
      );
      expect(
        LambdaBuilder.applyAll([
          LambdaConstants.lambdaTimes,
          LambdaConstants.lambdaTwo,
          LambdaConstants.lambdaThree,
        ]).build().toInt(),
        6,
      );
      expect(
        LambdaBuilder.applyAll([
          LambdaConstants.lambdaPower,
          LambdaConstants.lambdaTwo,
          LambdaConstants.lambdaThree,
        ]).build().toInt(),
        8,
      );
      expect(
        LambdaBuilder.applyAll([
          LambdaConstants.lambdaIsZero,
          LambdaConstants.lambdaTwo,
        ]).build().eval(),
        LambdaConstants.lambdaFalse.build(),
      );
      expect(
        LambdaBuilder.applyAll([
          LambdaConstants.lambdaIsZero,
          LambdaConstants.lambdaZero,
        ]).build().eval(),
        LambdaConstants.lambdaTrue.build(),
      );
      expect(
        LambdaBuilder.applyAll([
          LambdaConstants.lambdaAnd,
          LambdaConstants.lambdaFalse,
          LambdaConstants.omega,
        ]).build().eval(evalType: LambdaEvaluationType.callByName),
        LambdaConstants.lambdaFalse.build(),
      );
    },
  );
}
