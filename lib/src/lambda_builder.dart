import 'package:lambda_calculus/src/lambda_form.dart';
import 'package:lambda_calculus/src/lambda_interface.dart';
import 'package:lambda_calculus/src/lambda.dart';

/// The class representing lambda expressions.
class LambdaBuilder implements ILambda<LambdaBuilder> {
  LambdaBuilder({
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

  static LambdaBuilder _fromILambda(ILambda lambda) {
    if (lambda.runtimeType == LambdaBuilder) {
      return lambda as LambdaBuilder;
    }

    return LambdaBuilder(
      form: lambda.form,
      index: lambda.index,
      name: lambda.name,
      exp1: lambda.exp1 != null ? _fromILambda(lambda.exp1!) : null,
      exp2: lambda.exp2 != null ? _fromILambda(lambda.exp2!) : null,
    );
  }

  /// Construct a lambda variable with the given De Bruijn index and name. At
  /// most one of them can be optional.
  static LambdaBuilder fromVar({int? index, String? name}) {
    assert(index != null || name != null);
    return LambdaBuilder(form: LambdaForm.variable, index: index, name: name);
  }

  /// Construct the abstraction of a given lambda expression, with an optional
  /// name of the argument.
  static LambdaBuilder abstract(ILambda lambda, [String? name]) =>
      LambdaBuilder(
        form: LambdaForm.abstraction,
        exp1: _fromILambda(lambda),
        name: name,
      );

  /// Apply a list of lambda expressions together from left to right.
  static LambdaBuilder applyAll(List<ILambda> lambdas) {
    if (lambdas.isEmpty) {
      return LambdaBuilder(
        form: LambdaForm.abstraction,
        exp1: LambdaBuilder(form: LambdaForm.variable, index: 0),
      );
    }

    return lambdas.map(_fromILambda).reduce(
          (previousValue, element) => LambdaBuilder(
            form: LambdaForm.application,
            exp1: previousValue,
            exp2: element,
          ),
        );
  }

  /// Apply a list of lambda expressions together from right to left.
  static LambdaBuilder applyAllReversed(List<LambdaBuilder> lambdas) {
    if (lambdas.isEmpty) {
      return LambdaBuilder(
        form: LambdaForm.abstraction,
        exp1: LambdaBuilder(form: LambdaForm.variable, index: 0),
      );
    }

    LambdaBuilder applyAllReversedHelper(List<LambdaBuilder> lambdas) {
      if (lambdas.length == 1) {
        return _fromILambda(lambdas.first);
      }

      final first = lambdas.removeAt(0);
      return LambdaBuilder(
        form: LambdaForm.application,
        exp1: _fromILambda(first),
        exp2: applyAllReversed(lambdas),
      );
    }

    return applyAllReversedHelper(List.of(lambdas));
  }

  Lambda build() {
    final lambdaStack = <ILambda>[this];
    final resultStack = <Lambda>[Lambda(form: LambdaForm.dummy)];
    final isExp1Stack = [true];
    final freeVars = <String>[];
    final boundedVars = <String?>[];

    while (lambdaStack.isNotEmpty) {
      if (lambdaStack.last.form == LambdaForm.variable) {
        if (lambdaStack.last.index == null) {
          var index = boundedVars.indexOf(lambdaStack.last.name!);

          if (index != -1) {
            // Bounded variable.
            lambdaStack.last.index = index;
          } else if ((index = freeVars.indexOf(lambdaStack.last.name!)) != -1) {
            // Free variable (appeared before).
            lambdaStack.last.index = index + boundedVars.length;
          } else {
            // Free variable (first appearance).
            lambdaStack.last.index = freeVars.length + boundedVars.length;
            freeVars.add(lambdaStack.last.name!);
          }
        } else if (lambdaStack.last.name == null) {
          var index = lambdaStack.last.index!;

          if (index < boundedVars.length) {
            // Bounded variable.
            lambdaStack.last.name = boundedVars[index];
          } else if (index - boundedVars.length < freeVars.length) {
            lambdaStack.last.name = freeVars[index - boundedVars.length];
          }
        }

        resultStack.last = Lambda(
          form: LambdaForm.variable,
          index: lambdaStack.last.index,
          name: lambdaStack.last.name,
        );
        while (true) {
          lambdaStack.removeLast();
          if (lambdaStack.isEmpty) break;
          var tempLambda = resultStack.removeLast();
          if (resultStack.last.form == LambdaForm.abstraction) {
            resultStack.last.exp1 = tempLambda;
            isExp1Stack.removeLast();
            boundedVars.removeAt(0);
          } else if (isExp1Stack.last) {
            resultStack.last.exp1 = tempLambda;
            isExp1Stack.last = false;
            lambdaStack.add(lambdaStack.last.exp2!);
            resultStack.add(Lambda(form: LambdaForm.dummy));
            break;
          } else {
            resultStack.last.exp2 = tempLambda;
            isExp1Stack.removeLast();
          }
        }
      } else if (lambdaStack.last.form == LambdaForm.abstraction) {
        resultStack.last.form = LambdaForm.abstraction;
        resultStack.last.name = lambdaStack.last.name;
        boundedVars.insert(0, lambdaStack.last.name);
        resultStack.add(Lambda(form: LambdaForm.dummy));
        lambdaStack.add(lambdaStack.last.exp1!);
        isExp1Stack.add(true);
      } else {
        resultStack.last.form = LambdaForm.application;
        resultStack.add(Lambda(form: LambdaForm.dummy));
        lambdaStack.add(lambdaStack.last.exp1!);
        isExp1Stack.add(true);
      }
    }

    assert(resultStack.length == 1);
    return resultStack.first;
  }

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
}
