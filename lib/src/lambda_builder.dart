import 'package:lambda_calculus/src/lambda_constants.dart';
import 'package:lambda_calculus/src/lambda_form.dart';
import 'package:lambda_calculus/src/lambda_interface.dart';
import 'package:lambda_calculus/src/lambda.dart';

/// A builder for [Lambda].
///
/// It provides some convenient methods for constructing lambda expressions.
/// Do not forget to call `build()` to get the final result.
///
/// The following is a simple example that constructs the "false" term
/// (`λx.λy.y`):
/// ```dart
/// LambdaBuilder.abstract(
///   LambdaBuilder.abstract(LambdaBuilder.fromVar(name: 'y'), 'y'),
///   'x',
/// ).build();
/// ```
///
/// See [here](https://github.com/MMZK1526/lambda_calculus/blob/master/example/example.dart)
/// for more examples.
///
/// It is safer to use this builder rather than the constructors in [Lambda]
/// because in [Lambda] the [index] for variables are not optional, thus it is
/// easy to make mistakes. Here however, you can use either [index] or [name]
/// to construct a variable, and the class will eventually do the necessary
/// calculation for the De Bruijn index.
class LambdaBuilder implements ILambda<LambdaBuilder> {
  LambdaBuilder._({
    required this.form,
    this.index, // For variable
    this.name,
    this.exp1, // For application and abstraction
    this.exp2, // For application
  }) : assert(!(form == LambdaForm.variable &&
                ((index == null && name == null) ||
                    exp1 != null ||
                    exp2 != null)) &&
            !(form == LambdaForm.application &&
                (index != null ||
                    name != null ||
                    exp1 == null ||
                    exp2 == null)) &&
            !(form == LambdaForm.abstraction &&
                (index != null || exp1 == null || exp2 != null)));

  @override
  LambdaForm form;

  @override
  int? index;

  @override
  String? name;

  @override
  LambdaBuilder? exp1;

  @override
  LambdaBuilder? exp2;

  /// Access the [LambdaBuilderConstants] instance which provides common
  /// constants and combinators.
  static final LambdaBuilderConstants constants = LambdaBuilderConstants();

  @override
  int get hashCode => build().toString().hashCode;

  /// The equality operator.
  ///
  /// Returns true iff the two [LambdaBuilder]s are syntactically identical up to alpha
  /// renaming.
  ///
  /// Avoids recursion.
  @override
  bool operator ==(Object other) {
    if (other.runtimeType != LambdaBuilder) return false;

    return build() == (other as LambdaBuilder).build();
  }

  /// Construct a lambda variable with the given De Bruijn index and name. At
  /// most one of them can be optional.
  static LambdaBuilder fromVar({int? index, String? name}) {
    assert(index != null || name != null);
    return LambdaBuilder._(form: LambdaForm.variable, index: index, name: name);
  }

  /// Construct the abstraction of a given lambda expression, with an optional
  /// name of the argument.
  static LambdaBuilder abstract(ILambda lambda, [String? name]) =>
      LambdaBuilder._(
        form: LambdaForm.abstraction,
        exp1: _fromILambda(lambda),
        name: name,
      );

  /// Apply two lambda expressions together.
  static LambdaBuilder apply({required ILambda exp1, required ILambda exp2}) =>
      LambdaBuilder._(
        form: LambdaForm.application,
        exp1: _fromILambda(exp1),
        exp2: _fromILambda(exp2),
      );

  /// Apply a list of lambda expressions together with default (left-to-right)
  /// associativity.
  static LambdaBuilder applyAll(List<ILambda> lambdas) {
    if (lambdas.isEmpty) {
      return LambdaBuilder._(
        form: LambdaForm.abstraction,
        exp1: LambdaBuilder._(form: LambdaForm.variable, index: 0),
      );
    }

    return lambdas.map(_fromILambda).reduce(
          (previousValue, element) => LambdaBuilder._(
            form: LambdaForm.application,
            exp1: previousValue,
            exp2: element,
          ),
        );
  }

  /// Apply a list of lambda expressions together with right-to-left
  /// associativity.
  static LambdaBuilder applyAllReversed(List<LambdaBuilder> lambdas) {
    if (lambdas.isEmpty) {
      return LambdaBuilder._(
        form: LambdaForm.abstraction,
        exp1: LambdaBuilder._(form: LambdaForm.variable, index: 0),
      );
    }

    LambdaBuilder applyAllReversedHelper(List<LambdaBuilder> lambdas) {
      if (lambdas.length == 1) {
        return _fromILambda(lambdas.first);
      }

      final first = lambdas.removeAt(0);
      return LambdaBuilder._(
        form: LambdaForm.application,
        exp1: _fromILambda(first),
        exp2: applyAllReversed(lambdas),
      );
    }

    return applyAllReversedHelper(List.of(lambdas));
  }

  /// Build the [LambdaBuilder] into a [Lambda].
  Lambda build() {
    // final lambdaStack = [this];
    // final resultStack = <Lambda>[Lambda(form: LambdaForm.dummy)];
    // final isExp1Stack = [true];
    final freeVars = <String>[];
    final boundedVars = <String?>[];

    return ILambda.fmap<LambdaBuilder, Lambda, void>(
      initialLambda: this,
      onVar: (varLambda, _, __) {
        if (varLambda.index == null) {
          var index = boundedVars.indexOf(varLambda.name!);

          if (index != -1) {
            // Bounded variable.
            varLambda.index = index;
          } else if ((index = freeVars.indexOf(varLambda.name!)) != -1) {
            // Free variable (appeared before).
            varLambda.index = index + boundedVars.length;
          } else {
            // Free variable (first appearance).
            varLambda.index = freeVars.length + boundedVars.length;
            freeVars.add(varLambda.name!);
          }
        } else if (varLambda.name == null) {
          var index = varLambda.index!;

          if (index < boundedVars.length) {
            // Bounded variable.
            varLambda.name = boundedVars[index];
          } else if (index - boundedVars.length < freeVars.length) {
            varLambda.name = freeVars[index - boundedVars.length];
          }
        }

        return Lambda(
          form: LambdaForm.variable,
          index: varLambda.index,
          name: varLambda.name,
        );
      },
      onAbsEnter: (_, __, name) {
        boundedVars.insert(0, name);
      },
      onAbsExit: (_, __, ___) {
        boundedVars.removeAt(0);
      },
      abstract: (lambda, [name]) => Lambda(
        form: LambdaForm.abstraction,
        name: name,
        exp1: lambda,
      ),
      apply: ({required exp1, required exp2}) => Lambda(
        form: LambdaForm.application,
        exp1: exp1,
        exp2: exp2,
      ),
    );
  }

  static LambdaBuilder _fromILambda(ILambda lambda) {
    if (lambda.runtimeType == LambdaBuilder) {
      return lambda as LambdaBuilder;
    }

    return LambdaBuilder._(
      form: lambda.form,
      index: lambda.index,
      name: lambda.name,
      exp1: lambda.exp1 != null ? _fromILambda(lambda.exp1!) : null,
      exp2: lambda.exp2 != null ? _fromILambda(lambda.exp2!) : null,
    );
  }
}
