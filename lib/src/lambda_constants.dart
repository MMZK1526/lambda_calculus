import 'package:lambda_calculus/src/lambda_builder.dart';
import 'package:lambda_calculus/src/lambda_conversion.dart';
import 'package:lambda_calculus/src/lambda_form.dart';

/// Common lambda expressions.
class LambdaConstants {
  /// The identity expression.
  static final lambdaIdentity = LambdaBuilder.abstract(
    LambdaBuilder.fromVar(index: 0),
    'x',
  );

  /// Church boolean: true.
  static final lambdaTrue = LambdaBuilder.abstract(
    LambdaBuilder.abstract(LambdaBuilder.fromVar(index: 1), 'y'),
    'x',
  );

  /// Church boolean: false.
  static final lambdaFalse = LambdaBuilder.abstract(
    LambdaBuilder.abstract(LambdaBuilder.fromVar(index: 0), 'y'),
    'x',
  );

  /// The if expression.
  static final lambdaTest = LambdaBuilder.abstract(
    LambdaBuilder.abstract(
      LambdaBuilder.abstract(
        LambdaBuilder.applyAll(
          [
            LambdaBuilder.fromVar(name: 'x'),
            LambdaBuilder.fromVar(name: 'y'),
            LambdaBuilder.fromVar(name: 'z'),
          ],
        ),
        'z',
      ),
      'y',
    ),
    'x',
  );

  /// The and expression.
  static final lambdaAnd = LambdaBuilder.abstract(
    LambdaBuilder.abstract(
      LambdaBuilder.applyAll(
        [
          LambdaBuilder.fromVar(name: 'x'),
          LambdaBuilder.fromVar(name: 'y'),
          lambdaFalse,
        ],
      ),
      'y',
    ),
    'x',
  );

  /// The or expression.
  static final lambdaOr = LambdaBuilder.abstract(
    LambdaBuilder.abstract(
      LambdaBuilder.applyAll(
        [
          LambdaBuilder.fromVar(name: 'x'),
          lambdaTrue,
          LambdaBuilder.fromVar(name: 'y'),
        ],
      ),
      'y',
    ),
    'x',
  );

  /// The not expression.
  static final lambdaNot = LambdaBuilder.abstract(
    LambdaBuilder.applyAll([
      LambdaBuilder.fromVar(name: 'x'),
      lambdaFalse,
      lambdaTrue,
    ]),
    'x',
  );

  /// The church pair.
  static final lambdaPair = LambdaBuilder.abstract(
    LambdaBuilder.abstract(
      LambdaBuilder.abstract(
        LambdaBuilder.applyAll(
          [
            LambdaBuilder.fromVar(name: 'z'),
            LambdaBuilder.fromVar(name: 'x'),
            LambdaBuilder.fromVar(name: 'y'),
          ],
        ),
        'z',
      ),
      'y',
    ),
    'x',
  );

  /// The fst expression.
  static final lambdaFst = LambdaBuilder.abstract(
    LambdaBuilder.applyAll([
      LambdaBuilder.fromVar(name: 'x'),
      LambdaConstants.lambdaTrue,
    ]),
    'x',
  );

  /// The snd expression.
  static final lambdaSnd = LambdaBuilder.abstract(
    LambdaBuilder.applyAll([
      LambdaBuilder.fromVar(name: 'x'),
      LambdaConstants.lambdaFalse,
    ]),
    'x',
  );

  /// The succ (+1) expression.
  static final lambdaSucc = LambdaConversionExtension.lambdaSucc;

  /// The addition expression.
  static final lambdaPlus = LambdaBuilder.abstract(
    LambdaBuilder.abstract(
      LambdaBuilder.abstract(
        LambdaBuilder.abstract(
          LambdaBuilder.applyAll([
            LambdaBuilder.fromVar(name: 'x'),
            LambdaBuilder.fromVar(name: 'z'),
            LambdaBuilder.applyAll([
              LambdaBuilder.fromVar(name: 'y'),
              LambdaBuilder.fromVar(name: 'z'),
              LambdaBuilder.fromVar(name: 'u'),
            ]),
          ]),
          'u',
        ),
        'z',
      ),
      'y',
    ),
    'x',
  );

  /// The multiplication expression.
  static final lambdaTimes = LambdaBuilder.abstract(
    LambdaBuilder.abstract(
      LambdaBuilder.abstract(
        LambdaBuilder.applyAll([
          LambdaBuilder.fromVar(name: 'x'),
          LambdaBuilder.applyAll([
            LambdaBuilder.fromVar(name: 'y'),
            LambdaBuilder.fromVar(name: 'z'),
          ]),
        ]),
        'z',
      ),
      'y',
    ),
    'x',
  );

  /// The power expression.
  static final lambdaPower = LambdaBuilder.abstract(
    LambdaBuilder.abstract(
      LambdaBuilder.applyAll([
        LambdaBuilder.fromVar(name: 'x'),
        LambdaBuilder.fromVar(name: 'y'),
      ]),
      'x',
    ),
    'y',
  );

  /// The is_zero expression.
  static final lambdaIsZero = LambdaBuilder.abstract(
    LambdaBuilder.applyAll([
      LambdaBuilder.fromVar(name: 'x'),
      LambdaBuilder.abstract(lambdaFalse),
      LambdaConstants.lambdaTrue,
    ]),
    'x',
  );

  /// Church number: 0.
  static final lambdaZero = lambdaFalse;

  /// Church number: 1.
  static final lambdaOne = 1.toChurchNumber();

  /// Church number: 2.
  static final lambdaTwo = 2.toChurchNumber();

  /// Church number: 3.
  static final lambdaThree = 3.toChurchNumber();

  /// Church number: 4.
  static final lambdaFour = 4.toChurchNumber();

  /// Church number: 5.
  static final lambdaFive = 5.toChurchNumber();

  /// Church number: 6.
  static final lambdaSix = 6.toChurchNumber();

  /// Church number: 7.
  static final lambdaSeven = 7.toChurchNumber();

  /// Church number: 8.
  static final lambdaEight = 8.toChurchNumber();

  /// Church number: 9.
  static final lambdaNine = 9.toChurchNumber();

  /// Church number: 10.
  static final lambdaTen = 10.toChurchNumber();

  /// Church number: 11.
  static final lambdaEleven = 11.toChurchNumber();

  /// Church number: 12.
  static final lambdaTwelve = 12.toChurchNumber();

  /// The good era is approaching!
  static final iiyoKoiyo = 114514.toChurchNumber();

  /// The diverging omega expression.
  static final omega = LambdaBuilder.applyAll([
    LambdaBuilder.abstract(
      LambdaBuilder.applyAll([
        LambdaBuilder.fromVar(name: 'w'),
        LambdaBuilder.fromVar(name: 'w'),
      ]),
      'w',
    ),
    LambdaBuilder.abstract(
      LambdaBuilder.applyAll([
        LambdaBuilder.fromVar(name: 'w'),
        LambdaBuilder.fromVar(name: 'w'),
      ]),
      'w',
    ),
  ]);

  /// The Y-Combinator that works for both 'call by name' and 'call by value'
  /// schemes.
  static final yCombinator = LambdaBuilder.abstract(
    LambdaBuilder(
      form: LambdaForm.application,
      exp1: LambdaBuilder.abstract(
        LambdaBuilder(
          form: LambdaForm.application,
          exp1: LambdaBuilder.fromVar(name: 'f'),
          exp2: LambdaBuilder.abstract(
            LambdaBuilder(
              form: LambdaForm.application,
              exp1: LambdaBuilder(
                form: LambdaForm.application,
                exp1: LambdaBuilder.fromVar(name: 'x'),
                exp2: LambdaBuilder.fromVar(name: 'x'),
              ),
              exp2: LambdaBuilder.fromVar(name: 'y'),
            ),
            'y',
          ),
        ),
        'x',
      ),
      exp2: LambdaBuilder.abstract(
        LambdaBuilder(
          form: LambdaForm.application,
          exp1: LambdaBuilder.fromVar(name: 'f'),
          exp2: LambdaBuilder.abstract(
            LambdaBuilder(
              form: LambdaForm.application,
              exp1: LambdaBuilder(
                form: LambdaForm.application,
                exp1: LambdaBuilder.fromVar(name: 'x'),
                exp2: LambdaBuilder.fromVar(name: 'x'),
              ),
              exp2: LambdaBuilder.fromVar(name: 'y'),
            ),
            'y',
          ),
        ),
        'x',
      ),
    ),
    'f',
  );
}
