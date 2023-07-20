import 'package:lambda_calculus/lambda_calculus.dart';
import 'package:test/test.dart';

void main() {
  test(
    'Lambda Clone Test',
    () {
      expect(
        identityHashCode(Lambda.constants.lambdaTrue()),
        isNot(identityHashCode(Lambda.constants.lambdaTrue().clone())),
      );
      expect(
        Lambda.constants.lambdaTrue(),
        Lambda.constants.lambdaTrue().clone(),
      );
      expect(
        identityHashCode(Lambda.constants.seven()),
        isNot(identityHashCode(Lambda.constants.seven().clone())),
      );
      expect(Lambda.constants.seven(), Lambda.constants.seven().clone());
      expect(
        identityHashCode(Lambda.constants.yCombinator()),
        isNot(identityHashCode(Lambda.constants.yCombinator().clone())),
      );
      expect(
        Lambda.constants.yCombinator(),
        Lambda.constants.yCombinator().clone(),
      );
    },
  );

  test('Lambda Parse Test', () {
    expect(
      r'\x1(λx2. x1 (λx3. x2 x2 x3)) (λx2. x1 (λ x2 x2 0))'.toLambda(),
      Lambda.constants.yCombinator(),
    );
    expect(r'\_x1 _x1'.toLambda(), Lambda.constants.identity());
    expect(r'\_x2 _x1'.toLambda(), null);
    expect(r'((x1 (\x2 x2))'.toLambda(), null);
  });

  test(
    'Lambda Evaluation Test',
    () {
      expect(
        LambdaBuilder.applyAll([
          LambdaBuilder.constants.test(),
          LambdaBuilder.constants.lambdaFalse(),
          LambdaBuilder.constants.two(),
          LambdaBuilder.constants.one(),
        ]).build().eval(),
        Lambda.constants.one(),
      );
      expect(
        Lambda.constants.yCombinator().eval(),
        Lambda.constants.yCombinator(),
      );
      expect(
        LambdaBuilder.applyAll([
          LambdaBuilder.constants.succ(),
          LambdaBuilder.constants.six(),
        ]).build().toInt(),
        7,
      );
      expect(
        LambdaBuilder.applyAll([
          LambdaBuilder.constants.plus(),
          LambdaBuilder.constants.two(),
          LambdaBuilder.constants.three(),
        ]).build().toInt(),
        5,
      );
      expect(
        LambdaBuilder.applyAll([
          LambdaBuilder.constants.times(),
          LambdaBuilder.constants.two(),
          LambdaBuilder.constants.three(),
        ]).build().toInt(),
        6,
      );
      expect(
        LambdaBuilder.applyAll([
          LambdaBuilder.constants.power(),
          LambdaBuilder.constants.two(),
          LambdaBuilder.constants.three(),
        ]).build().toInt(),
        8,
      );
      expect(
        LambdaBuilder.applyAll([
          LambdaBuilder.constants.isZero(),
          LambdaBuilder.constants.two(),
        ]).build().eval(),
        Lambda.constants.lambdaFalse(),
      );
      expect(
        LambdaBuilder.applyAll([
          LambdaBuilder.constants.isZero(),
          LambdaBuilder.constants.zero(),
        ]).build().eval(),
        Lambda.constants.lambdaTrue(),
      );
      expect(
        LambdaBuilder.applyAll([
          LambdaBuilder.constants.and(),
          LambdaBuilder.constants.lambdaFalse(),
          Lambda.constants.omega(),
        ]).build().eval(evalType: LambdaEvaluationType.callByName),
        Lambda.constants.lambdaFalse(),
      );
    },
  );

  test('Type Inference Test', () {
    expect(
      Lambda.constants.and().findType(),
      LambdaType.arrow(
        type1: LambdaType.arrow(
          type1: LambdaType.fromVar(index: 1),
          type2: LambdaType.arrow(
            type1: LambdaType.arrow(
              type1: LambdaType.fromVar(index: 2),
              type2: LambdaType.arrow(
                type1: LambdaType.fromVar(index: 3),
                type2: LambdaType.fromVar(index: 3),
              ),
            ),
            type2: LambdaType.fromVar(index: 4),
          ),
        ),
        type2: LambdaType.arrow(
          type1: LambdaType.fromVar(index: 1),
          type2: LambdaType.fromVar(index: 4),
        ),
      ),
    );
  });
}
