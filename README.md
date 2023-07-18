# lamdba-calculus

## Introduction

A Lambda Calculus parser & evaluator in `dart`.

Use `import 'package:lambda_calculus/lambda_calculus.dart';` to use this library.

Currently, it supports evaluating untyped Lambda Calculus as well as type inference.

Check out the [quickstart](#quickstart) for a quick usage guide.

If you notice any issues or have any suggestions, please feel free to open an issue or contact me via email.

## Quickstart

```dart
import 'package:lambda_calculus/lambda_calculus.dart';

// Parse a lambda expression
// the lambda character 'λ' can be replaced by '/' or '\' for convenience;
final yCombinator = r'/x. (\y -> x (\z. y y z)) (/y. x (/z. y y z))'.toLambda()!;
// The output tries its best to preserve the variable names.
print(yCombinator);

// Church numbers
final fortyTwo = 42.toChurchNumber();
final iiyokoiyo = 114514.toChurchNumber(); // I wouldn't try to print out this one...

// Evaluate a lambda expression
// Note that we use `LambdaBuilder` to constructor lambda expressions bottom-up.
// We need to call the `build` method at the end to get the final lambda
// expression.
// Both `LambdaBuilder` and `Lambda` provides a number of constants and
// combinators for convenience.
final twoTimesThree = LambdaBuilder.applyAll([
  LambdaBuilder.constants.lambdaTimes(),
  2.toChurchNumberBuilder(),
  3.toChurchNumberBuilder(),
]).build();
final evalOneStep = twoTimesThree.eval1();
// Note that the 'eval' function does not terminate if the term does not have
// a normal form.
final callByValueResult = twoTimesThree.eval();
final callByNameResult = twoTimesThree.eval(LambdaEvaluationType.callByName);
final fullReductionResult = twoTimesThree.eval(LambdaEvaluationType.fullReduction);
print(fullReductionResult); // Same as `LambdaConstants.lambdaSix` or `6.toChurchNumber()`

// Find the type of a lambda expression;
final term = r'\x \y. x y'.toLambda()!;
print(term.findType()); // (t1 -> t2) -> (t1 -> t2)
// The Y-combinator has no type under the Hindley-Milner type system
print(yCombinator.findType()); // null
```

See [here](example/example.dart) for more examples.

TODO: Improve the API documentation.
