// ignore_for_file: avoid_print

import 'package:lambda_calculus/lambda_calculus.dart';

void main(List<String> arguments) {
  // This main function is a walkthrough for this lambda-calculus interpreter,
  // assuming you already know about untyped lambda-calculus.
  // Check out each function for more details.

  print('PART I:   UNTYPED LAMBDA CALCULUS\n');
  _printExamples();
  _parseLambda();
  _countFreeVars();
  _evaluationsByValue();
  _fullEvaluations();
  _evaluationsByName();
  _factorial();
  print('');

  print('PART II:  TYPED LAMBDA CALCULUS\n');

  final l = r"\f. \g. \x. f (g x)".toLambda()!;
  print("The type for $l is ${l.findType()}");
  final m = r"\a. \b. \c. a c (b c)".toLambda()!;
  print("The type for $m is ${m.findType()}");
  print("The type for ${Lambda.constants.and()} is "
      "${Lambda.constants.and().findType()}");
}

void _printExamples() {
  // This function prints out several useful lambda expressions.

  print('Some lambda expressions with minimal brackets: ');
  print('Lambda Id:    ${Lambda.constants.identity()}');
  print('Lambda True:  ${Lambda.constants.lambdaTrue()}');
  print('Lambda False: ${Lambda.constants.lambdaFalse()}');
  print('Lambda Test:  ${Lambda.constants.test()}');
  print('Lambda And:   ${Lambda.constants.and()}');
  print('Lambda Pair:  ${Lambda.constants.pair()}');
  print('Lambda Not:   ${Lambda.constants.not()}');
  print('Lambda Succ:  ${Lambda.constants.succ()}');
  print('Lambda Times: ${Lambda.constants.times()}');
  print('Lambda Plus:  ${Lambda.constants.plus()}');
  print('Lambda Seven: ${Lambda.constants.seven()}');
  print('Omega:        ${Lambda.constants.omega()}');
  print('Y-Combinator: ${Lambda.constants.yCombinator()}');
  print('');
}

void _parseLambda() {
  // This function parses several lambda expressions from String.

  String str;
  Lambda? temp;

  print('Lambda parser: ');

  // The names of the variables are usually preserved.
  // Nameless variables are converted to _x1, _x2 etc., but otherwise they are
  // syntactically identical.
  print("1. Print the 'succ' expression:");
  str = 'λa. λb . λc. b (a b c)';
  temp = str.toLambda();
  print('    original: $str');
  print('    parsed:   $temp');

  // We can also use slash and backslash to replace the lambda letter, as well
  // as "->" to replace the ".".
  print('2. Print the Y-Combinator:');
  str = r'/x. (\y -> x (\z. y y z)) (/y. x (/z. y y z))';
  temp = str.toLambda();
  print('    original: $str');
  print('    parsed:   $temp');

  print('3. Print an invalid lambda expression:');
  str = 'λx. ';
  temp = str.toLambda();
  print('    original: $str');
  print('    parsed:   $temp');

  // We can omit the variable after 'λ' if it is not used. In this case, a name
  // in the form of _x{n} will be generated.
  print('4. Print a lambda expression with an unused variable:');
  str = 'λx. λ. x';
  temp = str.toLambda();
  print('    original: $str');
  print('    parsed:   $temp');

  // We can also parse lambda expression written in De Bruijn Indices. Again,
  // names in the form of _x{n} will be generated.
  print('5. Print a lambda expression with De Bruijn Indices:');
  str = 'λ. λ. 1 (1 0)';
  temp = str.toLambda();
  print('    original: $str');
  print('    parsed:   $temp');

  // We can use the shorthand _x{n} to represent the variable declared at depth
  // n in the current scope. Similarly, _y{n} can be used to represent anonymous
  // free variables.
  print('6. Same as before, but use explicit depth:');
  str = 'λ. λ. _x1 (_x1 _x2)';
  temp = str.toLambda();
  print('    original: $str');
  print('    parsed:   $temp');

  // Since _x{n} (and _y{n}) has the special semantics mentioned above, they can
  // be used only if the depth is correct. It is not recommended to write these
  // variables, but we can safely copy a printed lambda term that contains the
  // underscore notations.
  print('7. Invalid abstraction using _x2');
  str = 'λ_x2. _x1';
  temp = str.toLambda();
  print('    original: $str');
  print('    parsed:   $temp');
  print('');

  // If the same variable name has been defined more than once, each usage is
  // bounded to the closest definition.
  print('7. λx. λx. x is the same as λx. λy. y');
  str = 'λx. λx. x';
  temp = str.toLambda();
  print('    original:             $str');
  print('    parsed without names: ${temp!.toStringNameless()}');
  print('');

  /// For nested abstractions, we can omit the lambda symbol for the inner
  /// abstractions.
  print('8. λx y z. x y z is the same as λx. λy. λz. x y z');
  str = 'λx y z. x y z';
  temp = str.toLambda();
  print('    original:             $str');
  print('    parsed without names: $temp');
  print('');
}

void _countFreeVars() {
  Lambda temp;

  temp = r'(\x. \y. x c) (\a. \b. c a (\d. \c. a c d))'.toLambda()!;
  print('Lambda: $temp');
  print('Number of free vars: ${temp.freeCount(countDistinct: true)}');
  print('');
}

void _evaluationsByValue() {
  // This function demonstrates the evaluation of lambda expressions through
  // beta-reduction with the "call by value" scheme.

  Lambda temp;

  print('Evaluate lambda expressions with the "call by value" scheme: ');
  temp = LambdaBuilder.applyAll([
    LambdaBuilder.constants.test(),
    LambdaBuilder.constants.lambdaTrue(),
    LambdaBuilder.constants.two(),
    LambdaBuilder.constants.one(),
  ]).build();

  // We use the .eval1() method to evaluate a lambda expression by one step.
  print("1. Evaluate 'test true 2 1' step-by-step: ");
  print('    $temp');
  print('  = ${temp.eval1()}');
  print('  = ${temp.eval1()!.eval1()}');
  print('  = ${temp.eval1()!.eval1()!.eval1()}');
  print('  = ${temp.eval1()!.eval1()!.eval1()!.eval1()}');
  print('  = ${temp.eval1()!.eval1()!.eval1()!.eval1()!.eval1()}');

  // We use the .eval() method to evaluate a lambda expression fully.
  print("2. Evaluate 'test false 2 1' directly to its simplest form: ");
  temp = LambdaBuilder.applyAll([
    LambdaBuilder.constants.test(),
    LambdaBuilder.constants.lambdaFalse(),
    LambdaBuilder.constants.two(),
    LambdaBuilder.constants.one(),
  ]).build();
  print('    $temp\n  = ${temp.eval()}');

  // Demonstration of the "call by value" scheme.
  print('3. An application within an abstraction is not reduced: ');
  temp = Lambda(
    form: LambdaForm.abstraction,
    exp1: LambdaBuilder.applyAll(
      [
        LambdaBuilder.constants.identity(),
        LambdaBuilder.constants.lambdaFalse(),
      ],
    ).build(),
  );
  print('    $temp\n  = ${temp.eval()}');

  // Another example: 'succ 2' results an expression behaviourally equivalent to
  // but syntactically distinct from 3.
  print("4. Evaluate 'succ 2', but the result is not the same as '3': ");
  temp = LambdaBuilder.applyAll([
    LambdaBuilder.constants.succ(),
    LambdaBuilder.constants.two(),
  ]).build();
  print('    $temp\n  = ${temp.eval()}');
  print("5. Evaluate 'succ 2', converting it to a natural number: ");
  print('    $temp\n  = ${temp.toInt()}');
  print('');
}

void _fullEvaluations() {
  // This function demonstrates the evaluation of lambda expressions through
  // full beta-reduction.

  Lambda temp;

  print('Evaluate lambda expressions using full beta-reduction: ');
  // We pass 'LambdaEvaluationType.FULL_REDUCTION' to the 'evalType' parameter
  // in .eval() method to evaluate a lambda expression through full
  // beta-reduction.
  print("1. Evaluate '2 + 3' directly to its simplest form: ");
  temp = LambdaBuilder.applyAll([
    LambdaBuilder.constants.plus(),
    LambdaBuilder.constants.two(),
    LambdaBuilder.constants.three(),
  ]).build();
  print('    $temp');
  print('  = ${temp.eval(evalType: LambdaEvaluationType.fullReduction)}');

  print("2. Evaluate '2 * 3' directly to its simplest form: ");
  temp = LambdaBuilder.applyAll([
    LambdaBuilder.constants.times(),
    LambdaBuilder.constants.two(),
    LambdaBuilder.constants.three(),
  ]).build();
  print('    $temp');
  print('  = ${temp.eval(evalType: LambdaEvaluationType.fullReduction)}');

  print("3. Evaluate '2 ^ 3' directly to its simplest form: ");
  temp = LambdaBuilder.applyAll([
    LambdaBuilder.constants.power(),
    LambdaBuilder.constants.two(),
    LambdaBuilder.constants.three(),
  ]).build();
  print('    $temp');
  print('  = ${temp.eval(evalType: LambdaEvaluationType.fullReduction)}');
  print('');
}

void _evaluationsByName() {
  // This function demonstrates the evaluation of lambda expressions through
  // beta-reduction with the "call by name" scheme.

  Lambda temp;

  print('Compare "call by name" with "call by value": ');
  // We pass 'LambdaEvaluationType.CALL_BY_NAME' to the 'evalType' parameter
  // in .eval1() method to evaluate a lambda expression through the
  // "call-by-name" scheme.
  print("1. Evaluate 'true 1 omega' lazily (call by name): ");
  temp = LambdaBuilder.applyAll([
    LambdaBuilder.constants.lambdaTrue(),
    LambdaBuilder.constants.one(),
    LambdaBuilder.constants.omega(),
  ]).build();
  print('    $temp');
  print('  = ${temp.eval1(evalType: LambdaEvaluationType.callByName)}');
  print(
    '  = ${temp.eval1(evalType: LambdaEvaluationType.callByName)!.eval1(evalType: LambdaEvaluationType.callByName)}',
  );
  // In contrast, the expression diverges in a "call by value" scheme.
  print("2. Evaluate 'true 1 omega' strictly (call by value): ");
  print('    $temp');
  print('  = ${temp.eval1()}');
  print('  = ${temp.eval1()!.eval1()}');
  print('  = ${temp.eval1()!.eval1()!.eval1()}');
  print('  = ${temp.eval1()!.eval1()!.eval1()!.eval1()}');
  print('  = ${temp.eval1()!.eval1()!.eval1()!.eval1()!.eval1()}');
  print('  ...');
  print('');
}

void _factorial() {
  // The factorial function.

  Lambda result;

  print('Recursive factorial function with the Y-Combinator: ');
  final factorial = LambdaBuilder.applyAll([
    Lambda.constants.yCombinator(),
    r'''
    \a.\b.(\.\c.\.2(c)(0))((\.0(\.\.\.0)(\.\.1))b)(\.\.\.1(0))(\.(\.\d.\.2(d(0)))b(a((\c.(\.0(\.\.1))
    (c(\d.(\a.\b.\.0(a)(b))((\.0(\.\.0))d)((\a.\.\.1(a(1)(0)))((\.0(\.\.0))d)))((\d.\a.\.0(d)
    (a))(\.\.0)(\.\.0))))b)))(\.0)
    '''
        .toLambda()!,
  ]).build();
  print('The factorial lamdba expression: ');
  print('    $factorial');
  print('1. Evaluate 0!: ');
  result = LambdaBuilder.applyAll([factorial, LambdaBuilder.constants.zero()])
      .build()
      .eval();
  print('    $result');
  print('  = ${result.toInt()}');
  print('2. Evaluate 3!: ');
  result = LambdaBuilder.applyAll([factorial, LambdaBuilder.constants.three()])
      .build()
      .eval();
  print('    $result');
  print('  = ${result.toInt()}');
  print('');
}
