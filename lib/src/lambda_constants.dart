import 'package:lambda_calculus/src/lambda.dart';
import 'package:lambda_calculus/src/lambda_builder.dart';
import 'package:lambda_calculus/src/lambda_conversion.dart';
import 'package:lambda_calculus/src/lambda_interface.dart';

/// Common lambda terms and combinators, but in the [LambdaBuilder] form.
///
/// They are accessible via [LambdaBuilder.constants].
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
            LambdaBuilder.applyAll([
              LambdaBuilder.fromVar(name: 'y'),
              LambdaBuilder.applyAll(
                [
                  LambdaBuilder.fromVar(name: 'x'),
                  LambdaBuilder.fromVar(name: 'y'),
                  LambdaBuilder.fromVar(name: 'z'),
                ],
              ),
            ]),
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
  LambdaBuilder one() => 1.toChurchNumberBuilder();

  @override
  LambdaBuilder two() => 2.toChurchNumberBuilder();

  @override
  LambdaBuilder three() => 3.toChurchNumberBuilder();

  @override
  LambdaBuilder four() => 4.toChurchNumberBuilder();

  @override
  LambdaBuilder five() => 5.toChurchNumberBuilder();

  @override
  LambdaBuilder six() => 6.toChurchNumberBuilder();

  @override
  LambdaBuilder seven() => 7.toChurchNumberBuilder();

  @override
  LambdaBuilder eight() => 8.toChurchNumberBuilder();

  @override
  LambdaBuilder nine() => 9.toChurchNumberBuilder();

  @override
  LambdaBuilder ten() => 10.toChurchNumberBuilder();

  @override
  LambdaBuilder eleven() => 11.toChurchNumberBuilder();

  @override
  LambdaBuilder twelve() => 12.toChurchNumberBuilder();

  @override
  LambdaBuilder iiyokoiyo() => 114514.toChurchNumberBuilder();

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
        LambdaBuilder.apply(
          exp1: LambdaBuilder.abstract(
            LambdaBuilder.apply(
              exp1: LambdaBuilder.fromVar(name: 'f'),
              exp2: LambdaBuilder.abstract(
                LambdaBuilder.apply(
                  exp1: LambdaBuilder.apply(
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
            LambdaBuilder.apply(
              exp1: LambdaBuilder.fromVar(name: 'f'),
              exp2: LambdaBuilder.abstract(
                LambdaBuilder.apply(
                  exp1: LambdaBuilder.apply(
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

/// Common lambda terms and combinators.
///
/// They are accessible via [Lambda.constants].
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
