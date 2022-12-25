import 'package:lambda_calculus/src/lambda.dart';

/// Types of lambda tokens.
enum LambdaTokenType {
  lambda,
  space,
  lbrace,
  rbrace,
  variable,
}

/// The class representing lambda tokens after lexing.
class LambdaToken {
  LambdaToken(
    this.type, {
    this.index,
    this.name,
  });
  final LambdaTokenType type;
  final int? index;
  final String? name;

  @override
  String toString() {
    switch (type) {
      case LambdaTokenType.lambda:
        return '{λ}';
      case LambdaTokenType.space:
        return '{ }';
      case LambdaTokenType.lbrace:
        return '{(}';
      case LambdaTokenType.rbrace:
        return '{)}';
      case LambdaTokenType.variable:
        return '{x$index}';
    }
  }
}

/// Convert a [String] to a [List]<[LambdaToken]>?.
///
/// Returns null only if the [String] is not a valid lambda expression.
List<LambdaToken>? _lambdaLexer(String str) {
  final tokens = <LambdaToken>[];
  final iterator = str.runes.iterator;
  final boundedVars = <String>[];
  final freeVars = <String>[];
  // The int represents the number of 'λ's since here before the next bracket.
  // We push an 0 on left brackets and pop at right brackets.
  final bracketStack = [0];
  final alpha = RegExp(r'^[a-zA-Z]+$');
  final numeric = RegExp(r'^[0-9]+$');
  final alphanumeric = RegExp(r'^[a-zA-Z0-9]+$');
  final xnumeric = RegExp(r'^_x[0-9]+([^a-zA-Z0-9]+|$)');
  final ynumeric = RegExp(r'^_y[0-9]+([^a-zA-Z0-9]+|$)');
  final blank = RegExp(r'^[\r\n\t\v ]+$');

  while (iterator.moveNext()) {
    switch (String.fromCharCode(iterator.current)) {
      // MARK: Left Bracket
      case r'(':
        bracketStack.add(0);
        tokens.add(LambdaToken(LambdaTokenType.lbrace));
        break;
      // MARK: Right Bracket
      case r')':
        // MARK: Extraneous Right Bracket
        if (bracketStack.length == 1) return null;
        // Remove out-of-scope variables.
        boundedVars.removeRange(0, bracketStack.removeLast());
        tokens.add(LambdaToken(LambdaTokenType.rbrace));
        // MARK: Space if Necessary
        if (iterator.moveNext()) {
          if (blank.hasMatch(String.fromCharCode(iterator.current)) ||
              String.fromCharCode(iterator.current) != ')') {
            tokens.add(LambdaToken(LambdaTokenType.space));
          }
          iterator.movePrevious();
        }
        break;
      // MARK: Lambda
      case r'λ':
      case r'/':
      case r'\':
        bracketStack.last++;
        if (!iterator.moveNext()) return null;
        // Determine the name of the variable.
        final tempVarBuffer = StringBuffer();

        // MARK: Depth Variables are not allowed here unless the depth is
        // correct
        if (ynumeric.hasMatch(str.substring(iterator.rawIndex))) {
          return null;
        }
        if (xnumeric.hasMatch(str.substring(iterator.rawIndex))) {
          iterator.moveNext();
          iterator.moveNext();
          var index = 0;
          while (numeric.hasMatch(String.fromCharCode(iterator.current))) {
            index *= 10;
            index += int.parse(String.fromCharCode(iterator.current));
            if (!iterator.moveNext()) break;
          }
          if (index == boundedVars.length + 1) {
            tokens.add(LambdaToken(LambdaTokenType.lambda));
            boundedVars.insert(0, '');
            break;
          }
          return null;
        }

        // MARK: Anonymous Variable
        if (String.fromCharCode(iterator.current) == '.') {
          tokens.add(LambdaToken(LambdaTokenType.lambda));
          boundedVars.insert(0, '');
          break;
        }
        if (!alpha.hasMatch(String.fromCharCode(iterator.current))) {
          tokens.add(LambdaToken(LambdaTokenType.lambda));
          boundedVars.insert(0, '');
          iterator.movePrevious();
          break;
        }

        // MARK: Explicit Variable
        while (alphanumeric.hasMatch(String.fromCharCode(iterator.current))) {
          tempVarBuffer.write(String.fromCharCode(iterator.current));
          if (!iterator.moveNext()) return null;
        }

        // MARK: Ignore Space
        while (blank.hasMatch(String.fromCharCode(iterator.current))) {
          if (!iterator.moveNext()) return null;
        }
        if (String.fromCharCode(iterator.current) == '.') {
          if (!iterator.moveNext()) return null;
        }
        if (String.fromCharCode(iterator.current) == '-') {
          if (!iterator.moveNext()) return null;
          if (String.fromCharCode(iterator.current) != '>') return null;
          if (!iterator.moveNext()) return null;
        }

        iterator.movePrevious();

        final tempVar = tempVarBuffer.toString();
        tokens.add(LambdaToken(LambdaTokenType.lambda, name: tempVar));
        boundedVars.insert(0, tempVar);
        break;
      default:
        // MARK: Ignore Space
        if (blank.hasMatch(String.fromCharCode(iterator.current))) break;

        // MARK: Depth Variable
        if (xnumeric.hasMatch(str.substring(iterator.rawIndex)) ||
            ynumeric.hasMatch(str.substring(iterator.rawIndex))) {
          iterator.moveNext();
          final isFree = String.fromCharCode(iterator.current) == 'y';
          iterator.moveNext();
          var index = 0;
          while (numeric.hasMatch(String.fromCharCode(iterator.current))) {
            index *= 10;
            index += int.parse(String.fromCharCode(iterator.current));
            if (!iterator.moveNext()) break;
          }
          if (!isFree && index > boundedVars.length) return null;
          tokens.add(LambdaToken(
            LambdaTokenType.variable,
            index: isFree
                ? boundedVars.length + index - 1
                : boundedVars.length - index,
          ));

          // MARK: Space if Necessary
          if (iterator.current >= 0 &&
              (blank.hasMatch(String.fromCharCode(iterator.current)) ||
                  String.fromCharCode(iterator.current) == '(')) {
            tokens.add(LambdaToken(LambdaTokenType.space));
          }
          iterator.movePrevious();
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
            tokens.add(LambdaToken(
              LambdaTokenType.variable,
              index: index,
              name: tempVar,
            ));
          } else if ((index = freeVars.indexOf(tempVar)) != -1) {
            // Free variable (appeared before).
            tokens.add(LambdaToken(
              LambdaTokenType.variable,
              index: boundedVars.length + index,
              name: tempVar,
            ));
          } else {
            // Free variable (first appearance).
            tokens.add(LambdaToken(
              LambdaTokenType.variable,
              index: boundedVars.length + freeVars.length,
              name: tempVar,
            ));
            freeVars.add(tempVar);
          }

          // MARK: Space if Necessary
          if (iterator.current >= 0 &&
              (blank.hasMatch(String.fromCharCode(iterator.current)) ||
                  String.fromCharCode(iterator.current) == '(')) {
            tokens.add(LambdaToken(LambdaTokenType.space));
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
            if (!iterator.moveNext()) break;
          }
          // Does not support De Bruijn Index for free variables.
          if (index >= boundedVars.length) return null;
          tokens.add(LambdaToken(LambdaTokenType.variable, index: index));

          if (iterator.current >= 0) {
            // Does not allow letters immediately after an index.
            if (alpha.hasMatch(String.fromCharCode(iterator.current))) {
              return null;
            }
            // MARK: Space if Necessary
            if (blank.hasMatch(String.fromCharCode(iterator.current)) ||
                String.fromCharCode(iterator.current) == '(') {
              tokens.add(LambdaToken(LambdaTokenType.space));
            }
            iterator.movePrevious();
          }
          break;
        }
        return null;
    }
  }

  // Trim for potential final space.
  if (tokens.last.type == LambdaTokenType.space) tokens.removeLast();

  return tokens;
}

/// Parse a [List]<[LambdaToken]> to a [Lambda]?.
///
/// Returns null if the tokens do not represent a valid lambda expression.
Lambda? _lambdaParser(List<LambdaToken> tokens) {
  final lambdaStack = <Lambda>[];
  final opStack = [LambdaTokenType.rbrace];
  // Names of variables (null indicates either the name is implicit, or if it
  // shadows an existing name).
  final varStack = <String?>[];

  if (tokens.isEmpty) return null;

  // Shunting Yard Algorithm.
  for (final token in tokens) {
    switch (token.type) {
      // MARK: Lambda
      // Has lowest precedence.
      case LambdaTokenType.lambda:
        opStack.add(LambdaTokenType.lambda);
        varStack.add(token.name);
        break;
      // MARK: Application
      // Has hitghes precedence.
      case LambdaTokenType.space:
        while (opStack.last == LambdaTokenType.space) {
          opStack.removeLast();
          final lambda2 = lambdaStack.removeLast();
          final lambda1 = lambdaStack.removeLast();
          lambdaStack.add(
            Lambda(form: LambdaForm.application, exp1: lambda1, exp2: lambda2),
          );
        }
        opStack.add(LambdaTokenType.space);
        break;
      // MARK: Left Bracket
      case LambdaTokenType.lbrace:
        opStack.add(LambdaTokenType.lbrace);
        break;
      // MARK: Left Bracket
      case LambdaTokenType.rbrace:
        while (true) {
          final op = opStack.removeLast();
          if (op == LambdaTokenType.lbrace) break;
          if (op == LambdaTokenType.rbrace) return null;
          if (op == LambdaTokenType.lambda) {
            final varName = varStack.removeLast();
            lambdaStack.add(Lambda.abstract(lambdaStack.removeLast(), varName));
            continue;
          }
          final lambda2 = lambdaStack.removeLast();
          final lambda1 = lambdaStack.removeLast();
          lambdaStack.add(
            Lambda(form: LambdaForm.application, exp1: lambda1, exp2: lambda2),
          );
        }
        break;
      case LambdaTokenType.variable:
        lambdaStack.add(Lambda.fromVar(index: token.index, name: token.name));
        break;
    }
  }

  while (opStack.last != LambdaTokenType.rbrace) {
    final op = opStack.removeLast();
    // MARK: Lambda
    if (op == LambdaTokenType.lambda) {
      if (lambdaStack.isEmpty) return null;
      final varName = varStack.removeLast();
      lambdaStack.add(Lambda.abstract(lambdaStack.removeLast(), varName));
      continue;
    }
    // MARK: Application
    if (op == LambdaTokenType.space) {
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

extension ToLambdaExtension on String {
  Lambda? toLambda() {
    final tokens = _lambdaLexer(this);
    if (tokens == null) return null;
    return _lambdaParser(tokens);
  }
}
