import 'package:lambda_calculus/src/lambda.dart';
import 'package:lambda_calculus/src/lambda_builder.dart';
import 'package:lambda_calculus/src/lambda_conversion.dart';
import 'package:lambda_calculus/src/lambda_form.dart';
import 'package:lambda_calculus/src/lambda_interface.dart';

/// Common lambda expressions.
class LambdaBuilderConstants implements ILambdaConstants<LambdaBuilder> {
  @override
  LambdaBuilder identity() => LambdaBuilder.abstract(
        LambdaBuilder.fromVar(index: 0),
        'x',
      );

  @override
  LambdaBuilder lambdaTrue() => LambdaBuilder.abstract(
        LambdaBuilder.abstract(LambdaBuilder.fromVar(index: 1), 'y'),
        'x',
      );

  @override
  LambdaBuilder lambdaFalse() => LambdaBuilder.abstract(
        LambdaBuilder.abstract(LambdaBuilder.fromVar(index: 0), 'y'),
        'x',
      );

  @override
  LambdaBuilder test() => LambdaBuilder.abstract(
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

  @override
  LambdaBuilder and() => LambdaBuilder.abstract(
        LambdaBuilder.abstract(
          LambdaBuilder.applyAll(
            [
              LambdaBuilder.fromVar(name: 'x'),
              LambdaBuilder.fromVar(name: 'y'),
              lambdaFalse(),
            ],
          ),
          'y',
        ),
        'x',
      );

  @override
  LambdaBuilder or() => LambdaBuilder.abstract(
        LambdaBuilder.abstract(
          LambdaBuilder.applyAll(
            [
              LambdaBuilder.fromVar(name: 'x'),
              lambdaTrue(),
              LambdaBuilder.fromVar(name: 'y'),
            ],
          ),
          'y',
        ),
        'x',
      );

  @override
  LambdaBuilder not() => LambdaBuilder.abstract(
        LambdaBuilder.applyAll(
          [
            LambdaBuilder.fromVar(name: 'x'),
            lambdaFalse(),
            lambdaTrue(),
          ],
        ),
        'x',
      );

  @override
  LambdaBuilder pair() => LambdaBuilder.abstract(
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

  @override
  LambdaBuilder fst() => LambdaBuilder.abstract(
        LambdaBuilder.applyAll(
          [
            LambdaBuilder.fromVar(name: 'x'),
            lambdaTrue(),
          ],
        ),
        'x',
      );

  @override
  LambdaBuilder snd() => LambdaBuilder.abstract(
        LambdaBuilder.applyAll(
          [
            LambdaBuilder.fromVar(name: 'x'),
            lambdaFalse(),
          ],
        ),
        'x',
      );

  @override
  LambdaBuilder succ() => LambdaBuilder.abstract(
        LambdaBuilder.abstract(
          LambdaBuilder.abstract(
            LambdaBuilder(
              form: LambdaForm.application,
              exp1: LambdaBuilder.fromVar(name: 'y'),
              exp2: LambdaBuilder.applyAll(
                [
                  LambdaBuilder.fromVar(name: 'x'),
                  LambdaBuilder.fromVar(name: 'y'),
                  LambdaBuilder.fromVar(name: 'z'),
                ],
              ),
            ),
            'z',
          ),
          'y',
        ),
        'x',
      );

  @override
  LambdaBuilder plus() => LambdaBuilder.abstract(
        LambdaBuilder.abstract(
          LambdaBuilder.abstract(
            LambdaBuilder.abstract(
              LambdaBuilder.applyAll(
                [
                  LambdaBuilder.fromVar(name: 'x'),
                  LambdaBuilder.fromVar(name: 'z'),
                  LambdaBuilder.applyAll(
                    [
                      LambdaBuilder.fromVar(name: 'y'),
                      LambdaBuilder.fromVar(name: 'z'),
                      LambdaBuilder.fromVar(name: 'u'),
                    ],
                  ),
                ],
              ),
              'u',
            ),
            'z',
          ),
          'y',
        ),
        'x',
      );

  @override
  LambdaBuilder times() => LambdaBuilder.abstract(
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

  @override
  LambdaBuilder power() => LambdaBuilder.abstract(
        LambdaBuilder.abstract(
          LambdaBuilder.applyAll(
            [
              LambdaBuilder.fromVar(name: 'x'),
              LambdaBuilder.fromVar(name: 'y'),
            ],
          ),
          'x',
        ),
        'y',
      );

  @override
  LambdaBuilder isZero() => LambdaBuilder.abstract(
        LambdaBuilder.applyAll([
          LambdaBuilder.fromVar(name: 'x'),
          LambdaBuilder.abstract(lambdaFalse()),
          lambdaTrue(),
        ]),
        'x',
      );

  @override
  LambdaBuilder zero() => lambdaFalse();

  @override
  LambdaBuilder one() => 1.toChurchNumber();

  @override
  LambdaBuilder two() => 2.toChurchNumber();

  @override
  LambdaBuilder three() => 3.toChurchNumber();

  @override
  LambdaBuilder four() => 4.toChurchNumber();

  @override
  LambdaBuilder five() => 5.toChurchNumber();

  @override
  LambdaBuilder six() => 6.toChurchNumber();

  @override
  LambdaBuilder seven() => 7.toChurchNumber();

  @override
  LambdaBuilder eight() => 8.toChurchNumber();

  @override
  LambdaBuilder nine() => 9.toChurchNumber();

  @override
  LambdaBuilder ten() => 10.toChurchNumber();

  @override
  LambdaBuilder eleven() => 11.toChurchNumber();

  @override
  LambdaBuilder twelve() => 12.toChurchNumber();

  @override
  LambdaBuilder iiyokoiyo() => 114514.toChurchNumber();

  @override
  LambdaBuilder omega() => LambdaBuilder.applyAll([
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

  @override
  LambdaBuilder yCombinator() => LambdaBuilder.abstract(
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

class LambdaConstants implements ILambdaConstants<Lambda> {
  @override
  Lambda identity() => LambdaBuilderConstants().identity().build();

  @override
  Lambda lambdaTrue() => LambdaBuilderConstants().lambdaTrue().build();

  @override
  Lambda lambdaFalse() => LambdaBuilderConstants().lambdaFalse().build();

  @override
  Lambda and() => LambdaBuilderConstants().and().build();

  @override
  Lambda or() => LambdaBuilderConstants().or().build();

  @override
  Lambda not() => LambdaBuilderConstants().not().build();

  @override
  Lambda test() => LambdaBuilderConstants().test().build();

  @override
  Lambda pair() => LambdaBuilderConstants().pair().build();

  @override
  Lambda fst() => LambdaBuilderConstants().fst().build();

  @override
  Lambda snd() => LambdaBuilderConstants().snd().build();

  @override
  Lambda succ() => LambdaBuilderConstants().succ().build();

  @override
  Lambda plus() => LambdaBuilderConstants().plus().build();

  @override
  Lambda times() => LambdaBuilderConstants().times().build();

  @override
  Lambda power() => LambdaBuilderConstants().power().build();

  @override
  Lambda isZero() => LambdaBuilderConstants().isZero().build();

  @override
  Lambda zero() => LambdaBuilderConstants().zero().build();

  @override
  Lambda one() => LambdaBuilderConstants().one().build();

  @override
  Lambda two() => LambdaBuilderConstants().two().build();

  @override
  Lambda three() => LambdaBuilderConstants().three().build();

  @override
  Lambda four() => LambdaBuilderConstants().four().build();

  @override
  Lambda five() => LambdaBuilderConstants().five().build();

  @override
  Lambda six() => LambdaBuilderConstants().six().build();

  @override
  Lambda seven() => LambdaBuilderConstants().seven().build();

  @override
  Lambda eight() => LambdaBuilderConstants().eight().build();

  @override
  Lambda nine() => LambdaBuilderConstants().nine().build();

  @override
  Lambda ten() => LambdaBuilderConstants().ten().build();

  @override
  Lambda eleven() => LambdaBuilderConstants().eleven().build();

  @override
  Lambda twelve() => LambdaBuilderConstants().twelve().build();

  @override
  Lambda iiyokoiyo() => LambdaBuilderConstants().iiyokoiyo().build();

  @override
  Lambda omega() => LambdaBuilderConstants().omega().build();

  @override
  Lambda yCombinator() => LambdaBuilderConstants().yCombinator().build();
}
