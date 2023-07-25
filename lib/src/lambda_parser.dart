import 'package:lambda_calculus/src/lambda.dart';
import 'package:lambda_calculus/src/lambda_form.dart';

/// Parse a [Lambda] expression from a string.
///
/// See [toLambda] for more details.
extension ToLambdaExtension on String {
  /// Convert a string to a [Lambda] expression.
  ///
  /// Here is the semi-formal grammar of the supported syntax. If you don't want
  /// to read this, you can skip it and jump to the examples.
  ///
  /// ```
  /// <lambda> ::= <variable> | <abstraction> | <application>
  /// <variable> ::= <identifier> | <de-bruijn-index>
  /// <abstraction> ::= <lambda-symbol> [<variable>] <dot-symbol> <lambda>
  /// <application> ::= <lambda> <lambda>
  /// <lambda-symbol> ::= (λ|/|\\) -- lambda, slash, or backslash
  /// <dot-symbol> ::= (\.) | (->) -- A single dot or an arrow
  /// <identifier> ::= ([a-zA-Z][a-zA-Z0-9]*) -- Alpha-numeric strings that do not start with a digit
  /// <de-bruijn-index> ::= ([0-9]+) -- De Bruijn index
  /// ```
  ///
  /// In addition to the above, spaces are ignored and parentheses are used to
  /// determine the precedence of operations. For example, `λx.x x` is parsed
  /// as `λx.(x x)`, not `(λx.x) x`.
  ///
  /// As an example, let us start from the "succ" term `λa. λb. λc. b (a b c)`.
  /// The term itself can be successfully parsed, but we can also do the
  /// following modifications without affecting the parse result:
  ///
  /// - Remove spaces: `λa.λb.λc.b(a b c)` Note that the space in `(a b c)`
  ///   cannot be removed since otherwise it will treat `abc` as a single
  ///   variable.
  /// - Use other symbols for "λ": `/a.\\b./c.b(a b c)`, we support slash and
  ///   backslash as well.
  /// - Changing the doc to an arrow: `λa -> λb -> λc b (a b c)`.
  /// - Use De Bruijn indices for variables: `λa. λb. λc. 2 (3 2 1)`. Here `1`,
  ///   `2`, and `3` are the De Bruijn indices for `c`, `b`, and `a`.
  /// - If we are only using the De Bruijn indices, we can omit the variable
  ///   declaration: `λλλ2 (3 2 1)`.
  Lambda? toLambda() {
    final tokens = _lambdaLexer(this);
    if (tokens == null) {
      return null;
    }
    return _lambdaParser(tokens);
  }
}

/// Types of lambda tokens.
enum _LambdaTokenType {
  lambda,
  space,
  lbrace,
  rbrace,
  variable,
}

/// The class representing lambda tokens after lexing.
class _LambdaToken {
  _LambdaToken(
    this.type, {
    this.index,
    this.name,
  });
  final _LambdaTokenType type;
  final int? index;
  final String? name;

  @override
  String toString() {
    switch (type) {
      case _LambdaTokenType.lambda:
        return '{λ}';
      case _LambdaTokenType.space:
        return '{ }';
      case _LambdaTokenType.lbrace:
        return '{(}';
      case _LambdaTokenType.rbrace:
        return '{)}';
      case _LambdaTokenType.variable:
        return '{x$index}';
    }
  }
}

/// Convert a [String] to a [List]<[_LambdaToken]>?.
///
/// Returns null only if the [String] is not a valid lambda expression.
List<_LambdaToken>? _lambdaLexer(String str) {
  final tokens = <_LambdaToken>[];
  final iterator = str.runes.iterator;
  final boundedVars = <String>[];
  final freeVars = <String>[];
  // The int represents the number of 'λ's since here before the next bracket.
  // We push an 0 on left brackets and pop at right brackets.
  final bracketStack = [0];
  final alpha = RegExp(r'^[a-zA-Z]+$');
  final numeric = RegExp(r'^[0-9]+$');
  final alphanumeric = RegExp(r'^[a-zA-Z0-9]+$');
  final blank = RegExp(r'^[\r\n\t\v ]+$');

  while (iterator.moveNext()) {
    switch (String.fromCharCode(iterator.current)) {
      // MARK: Left Bracket
      case r'(':
        bracketStack.add(0);
        tokens.add(_LambdaToken(_LambdaTokenType.lbrace));
        break;
      // MARK: Right Bracket
      case r')':
        // MARK: Extraneous Right Bracket
        if (bracketStack.length == 1) {
          return null;
        }
        // Remove out-of-scope variables.
        boundedVars.removeRange(0, bracketStack.removeLast());
        tokens.add(_LambdaToken(_LambdaTokenType.rbrace));
        // MARK: Ignore Space
        if (iterator.moveNext()) {
          if (blank.hasMatch(String.fromCharCode(iterator.current)) ||
              String.fromCharCode(iterator.current) != ')') {
            while (blank.hasMatch(String.fromCharCode(iterator.current))) {
              if (!iterator.moveNext()) break;
            }
            if (iterator.current != -1 &&
                String.fromCharCode(iterator.current) != ')') {
              tokens.add(_LambdaToken(_LambdaTokenType.space));
            }
          }
          iterator.movePrevious();
        }
        break;
      // MARK: Lambda
      case r'λ':
      case r'/':
      case r'\':
        bracketStack.last++;
        if (!iterator.moveNext()) {
          return null;
        }

        // MARK: Ignore Space
        while (blank.hasMatch(String.fromCharCode(iterator.current))) {
          if (!iterator.moveNext()) {
            return null;
          }
        }

        // MARK: Anonymous Variable
        if (String.fromCharCode(iterator.current) == '.') {
          tokens.add(_LambdaToken(_LambdaTokenType.lambda));
          boundedVars.insert(0, '');
          break;
        }
        if (String.fromCharCode(iterator.current) == '-') {
          if (!iterator.moveNext()) {
            return null;
          }
          if (String.fromCharCode(iterator.current) != '>') {
            return null;
          }
          tokens.add(_LambdaToken(_LambdaTokenType.lambda));
          boundedVars.insert(0, '');
          break;
        }

        while (true) {
          // Determine the name of the variable.
          final tempVarBuffer = StringBuffer();

          // MARK: Ignore Space
          while (blank.hasMatch(String.fromCharCode(iterator.current))) {
            if (!iterator.moveNext()) {
              return null;
            }
          }

          // MARK: Explicit Variable
          if (alphanumeric.hasMatch(String.fromCharCode(iterator.current))) {
            while (
                alphanumeric.hasMatch(String.fromCharCode(iterator.current))) {
              tempVarBuffer.write(String.fromCharCode(iterator.current));
              if (!iterator.moveNext()) {
                return null;
              }
            }
            final tempVar = tempVarBuffer.toString();
            tokens.add(_LambdaToken(_LambdaTokenType.lambda, name: tempVar));
            boundedVars.insert(0, tempVar);
            continue;
          }

          break;
        }

        // MARK: Ignore Space
        while (blank.hasMatch(String.fromCharCode(iterator.current))) {
          if (!iterator.moveNext()) {
            return null;
          }
        }

        var hasDot = false;
        if (String.fromCharCode(iterator.current) == '.') {
          hasDot = true;
        } else if (String.fromCharCode(iterator.current) == '-') {
          if (!iterator.moveNext()) {
            return null;
          }
          if (String.fromCharCode(iterator.current) != '>') {
            return null;
          }
          hasDot = true;
        }
        if (!hasDot) {
          return null;
        }

        break;
      default:
        // MARK: Ignore Space
        if (blank.hasMatch(String.fromCharCode(iterator.current))) {
          break;
        }

        // MARK: Named Variable
        if (alpha.hasMatch(String.fromCharCode(iterator.current))) {
          final tempVarBuffer = StringBuffer();
          while (alphanumeric.hasMatch(String.fromCharCode(iterator.current))) {
            tempVarBuffer.write(String.fromCharCode(iterator.current));
            if (!iterator.moveNext()) break;
          }

          final tempVar = tempVarBuffer.toString();
          var index = boundedVars.indexOf(tempVar);
          if (index != -1) {
            // Bounded variable.
            tokens.add(_LambdaToken(
              _LambdaTokenType.variable,
              index: index,
              name: tempVar,
            ));
          } else if ((index = freeVars.indexOf(tempVar)) != -1) {
            // Free variable (appeared before).
            tokens.add(_LambdaToken(
              _LambdaTokenType.variable,
              index: boundedVars.length + index,
              name: tempVar,
            ));
          } else {
            // Free variable (first appearance).
            tokens.add(_LambdaToken(
              _LambdaTokenType.variable,
              index: boundedVars.length + freeVars.length,
              name: tempVar,
            ));
            freeVars.add(tempVar);
          }

          // MARK: Space if Necessary
          if (iterator.current >= 0 &&
              (blank.hasMatch(String.fromCharCode(iterator.current)) ||
                  String.fromCharCode(iterator.current) == '(')) {
            tokens.add(_LambdaToken(_LambdaTokenType.space));
          }
          iterator.movePrevious();
          break;
        }

        // MARK: De Bruijn Index
        if (numeric.hasMatch(String.fromCharCode(iterator.current))) {
          var index = 0;
          while (numeric.hasMatch(String.fromCharCode(iterator.current))) {
            index *= 10;
            index += int.parse(String.fromCharCode(iterator.current));
            if (!iterator.moveNext()) {
              break;
            }
          }
          // Does not support De Bruijn Index for free variables.
          if (index >= boundedVars.length) {
            return null;
          }
          tokens.add(_LambdaToken(_LambdaTokenType.variable, index: index));

          if (iterator.current >= 0) {
            // Does not allow letters immediately after an index.
            if (alpha.hasMatch(String.fromCharCode(iterator.current))) {
              return null;
            }
            // MARK: Space if Necessary
            if (blank.hasMatch(String.fromCharCode(iterator.current)) ||
                String.fromCharCode(iterator.current) == '(') {
              tokens.add(_LambdaToken(_LambdaTokenType.space));
            }
            iterator.movePrevious();
          }
          break;
        }
        return null;
    }
  }

  // Trim for potential final space.
  if (tokens.last.type == _LambdaTokenType.space) tokens.removeLast();

  return tokens;
}

/// Parse a [List]<[_LambdaToken]> to a [Lambda]?.
///
/// Returns null if the tokens do not represent a valid lambda expression.
Lambda? _lambdaParser(List<_LambdaToken> tokens) {
  final lambdaStack = <Lambda>[];
  final opStack = [_LambdaTokenType.rbrace];
  // Names of variables (null indicates either the name is implicit, or if it
  // shadows an existing name).
  final varStack = <String?>[];

  if (tokens.isEmpty) {
    return null;
  }

  // Shunting Yard Algorithm.
  for (final token in tokens) {
    switch (token.type) {
      // MARK: Lambda
      // Has lowest precedence.
      case _LambdaTokenType.lambda:
        opStack.add(_LambdaTokenType.lambda);
        varStack.add(token.name);
        break;
      // MARK: Application
      // Has highest precedence.
      case _LambdaTokenType.space:
        while (opStack.last == _LambdaTokenType.space) {
          opStack.removeLast();
          final lambda2 = lambdaStack.removeLast();
          final lambda1 = lambdaStack.removeLast();
          lambdaStack.add(
            Lambda(form: LambdaForm.application, exp1: lambda1, exp2: lambda2),
          );
        }
        opStack.add(_LambdaTokenType.space);
        break;
      // MARK: Left Bracket
      case _LambdaTokenType.lbrace:
        opStack.add(_LambdaTokenType.lbrace);
        break;
      // MARK: Left Bracket
      case _LambdaTokenType.rbrace:
        while (true) {
          final op = opStack.removeLast();
          if (op == _LambdaTokenType.lbrace) break;
          if (op == _LambdaTokenType.rbrace) return null;
          if (op == _LambdaTokenType.lambda) {
            final varName = varStack.removeLast();
            lambdaStack.add(
              Lambda(
                form: LambdaForm.abstraction,
                name: varName,
                exp1: lambdaStack.removeLast(),
              ),
            );
            continue;
          }
          final lambda2 = lambdaStack.removeLast();
          final lambda1 = lambdaStack.removeLast();
          lambdaStack.add(
            Lambda(form: LambdaForm.application, exp1: lambda1, exp2: lambda2),
          );
        }
        break;
      case _LambdaTokenType.variable:
        lambdaStack.add(Lambda(
          form: LambdaForm.variable,
          index: token.index,
          name: token.name,
        ));
        break;
    }
  }

  while (opStack.last != _LambdaTokenType.rbrace) {
    final op = opStack.removeLast();
    // MARK: Lambda
    if (op == _LambdaTokenType.lambda) {
      if (lambdaStack.isEmpty) return null;
      final varName = varStack.removeLast();
      lambdaStack.add(
        Lambda(
          form: LambdaForm.abstraction,
          name: varName,
          exp1: lambdaStack.removeLast(),
        ),
      );
      continue;
    }
    // MARK: Application
    if (op == _LambdaTokenType.space) {
      if (lambdaStack.length <= 1) return null;
      final lambda2 = lambdaStack.removeLast();
      final lambda1 = lambdaStack.removeLast();
      lambdaStack.add(
        Lambda(form: LambdaForm.application, exp1: lambda1, exp2: lambda2),
      );
      continue;
    }
    // MARK: Invalid Operator
    return null;
  }

  return lambdaStack.last;
}
