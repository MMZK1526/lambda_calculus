import 'package:lambda_calculus/src/lambda.dart';
import 'package:lambda_calculus/src/lambda_form.dart';
import 'package:lambda_calculus/src/utilities.dart';

class _Counter {
  int value = 0;
}

class _Context {
  final Map<String, LambdaType> typeMap = {};
  final _Counter _typeIndex;

  _Context(_Counter counter) : _typeIndex = counter;

  int get typeIndex => _typeIndex.value;
  set typeIndex(int value) => _typeIndex.value = value;

  LambdaType getFreshType() {
    final result = LambdaType(typeIndex);
    typeIndex += 1;
    return result;
  }

  void substitute(Map<int, LambdaType> substitution) {
    for (final key in typeMap.keys) {
      typeMap[key] = typeMap[key]!.substitute(substitution)!;
    }
  }

  LambdaType useContext(int depth) {
    final identifier = '$depth';
    if (!typeMap.containsKey(identifier)) {
      typeMap[identifier] = getFreshType();
    }

    return typeMap[identifier]!;
  }

  _Context copy() {
    final result = _Context(_typeIndex);
    result.typeMap.addAll(typeMap);
    return result;
  }
}

/// An extension to find the principal type of a [Lambda].
extension LamdbaTypeExtension on Lambda {
  /// Find the principal type of the [Lambda].
  LambdaType? findType() {
    /// TODO: Avoid recursion
    MapEntry<Map<int, LambdaType>, LambdaType>? work(
      _Context context,
      Lambda term, [
      int depth = 0,
    ]) {
      switch (term.form) {
        case LambdaForm.variable:
          final varDepth = depth - term.index!;
          return MapEntry({}, context.useContext(varDepth));
        case LambdaForm.abstraction:
          final varType = context.useContext(depth + 1);
          final pp = work(context, term.exp1!, depth + 1);
          if (pp == null) {
            return null;
          }
          return MapEntry(
            pp.key,
            LambdaType.arrow(
              type1: varType,
              type2: pp.value,
            ).substitute(pp.key)!,
          );
        case LambdaForm.application:
          final backupContext = context.copy();
          final pp1 = work(context, term.exp1!, depth);
          if (pp1 == null) {
            return null;
          }
          final sub1 = pp1.key;
          backupContext.substitute(sub1);
          final pp2 = work(backupContext, term.exp2!, depth);
          if (pp2 == null) {
            return null;
          }
          final sub2 = pp2.key;
          final freshType = backupContext.getFreshType();
          final sub3 = pp1.value.substitute(sub2)!.unify(
                LambdaType.arrow(type1: pp2.value, type2: freshType),
              );
          if (sub3 == null) {
            return null;
          }
          return MapEntry(
            LambdaType.compose(sub3, LambdaType.compose(sub2, sub1))!,
            freshType.substitute(sub3)!,
          );
      }
    }

    final context = _Context(_Counter());
    final result = work(context, this);
    return result?.value._clean();
  }
}

/// The Hindley-Milner type for [Lambda] expressions.
class LambdaType {
  const LambdaType._({
    required this.isArrow,
    this.varIndex,
    this.type1,
    this.type2,
  }) : assert((isArrow && type1 != null && type2 != null && varIndex == null) ||
            (!isArrow && type1 == null && type2 == null && varIndex != null));

  LambdaType(int index) : this._(isArrow: false, varIndex: index);

  /// Is the type an arrow type?
  final bool isArrow;

  /// The index of the variable type. Only valid when [isArrow] is `false`.
  final int? varIndex;

  /// The left-hand side of the arrow type. Only valid when [isArrow] is `true`.
  final LambdaType? type1;

  /// The right-hand side of the arrow type. Only valid when [isArrow] is
  /// `true`.
  final LambdaType? type2;

  /// Compose two substitutions.
  static Map<int, LambdaType>? compose(
    Map<int, LambdaType>? s2,
    Map<int, LambdaType>? s1,
  ) {
    if (s1 == null || s2 == null) {
      return null;
    }

    return s1.map((key, value) => MapEntry(key, value.substitute(s2)!))
      ..addAll(s2..removeWhere((key, _) => s1.containsKey(key)));
  }

  /// Construct a [LambdaType] from a type variable.
  ///
  /// Note that we don't have type variable names, so we use indices instead.
  @Deprecated('Use [LambdaType] constructor instead')
  static LambdaType fromVar({required int index}) {
    return LambdaType._(isArrow: false, varIndex: index);
  }

  /// Construct an arrow type [LambdaType] from two smaller [LambdaType]s.
  static LambdaType arrow({
    required LambdaType type1,
    required LambdaType type2,
  }) {
    return LambdaType._(isArrow: true, type1: type1, type2: type2);
  }

  /// Print out the type without redundant parentheses and resetting all type
  /// variable indices to 1, 2, 3, and so on.
  @override
  String toString() {
    final sb = StringBuffer();
    final typeStack = [this];
    final useBracesStack = [false];
    final isExp1Stack = [true];

    while (typeStack.isNotEmpty) {
      final cur = typeStack.last;
      if (typeStack.last.isArrow) {
        if (useBracesStack.last) {
          sb.write("(");
        }
        typeStack.add(cur.type1!);
        useBracesStack.add(cur.type1!.isArrow);
        isExp1Stack.add(true);
      } else {
        sb.write("t${cur.varIndex!}");
        while (true) {
          typeStack.removeLast();
          if (typeStack.isEmpty) {
            break;
          }
          if (isExp1Stack.last) {
            isExp1Stack.last = false;
            useBracesStack.removeLast();
            sb.write(" -> ");
            typeStack.add(typeStack.last.type2!);
            useBracesStack.add(false);
            break;
          }
          isExp1Stack.removeLast();
          useBracesStack.removeLast();
          if (useBracesStack.last) {
            sb.write(")");
          }
        }
      }
    }

    return sb.toString();
  }

  @override
  int get hashCode => _clean().toString().hashCode;

  @override
  bool operator ==(Object other) =>
      other is LambdaType && _clean().toString() == other._clean().toString();

  LambdaType fmap<T>({
    required LambdaType Function(LambdaType varLambdaType, T? param) onVar,
    T? initialParam,
    T? Function(T? param)? onArrowEnter,
    T? Function(T? param)? onArrowExit,
  }) {
    final typeStack = [Pair(true, this)];
    final resultStack = <LambdaType>[];
    var param = initialParam;

    while (typeStack.isNotEmpty) {
      final cur = typeStack.last;

      if (!cur.second.isArrow) {
        typeStack.removeLast();
        resultStack.add(onVar(cur.second, param));
      } else if (cur.first) {
        cur.first = false;
        param = onArrowEnter?.call(param) ?? param;
        typeStack.add(Pair(true, cur.second.type2!));
        typeStack.add(Pair(true, cur.second.type1!));
      } else {
        typeStack.removeLast();
        final type2 = resultStack.removeLast();
        final type1 = resultStack.removeLast();
        resultStack.add(LambdaType._(
          isArrow: true,
          type1: type1,
          type2: type2,
        ));
        param = onArrowExit?.call(param) ?? param;
      }
    }

    return resultStack.first;
  }

  /// Check if the [LambdaType] contains the given variable.
  bool contains(int otherVar) {
    final typeStack = [this];

    while (typeStack.isNotEmpty) {
      final cur = typeStack.removeLast();
      if (cur.isArrow) {
        typeStack.add(cur.type1!);
        typeStack.add(cur.type2!);
      } else {
        if (cur.varIndex == otherVar) {
          return true;
        }
      }
    }

    return false;
  }

  /// Substitute with the given substitution.
  LambdaType? substitute(Map<int, LambdaType>? substitution) {
    return fmap<void>(
      onVar: (lambdaType, _) =>
          substitution![lambdaType.varIndex!] ?? lambdaType,
    );
  }

  /// Unify `this` with the given [LambdaType], returning a substitution if
  /// possible.
  ///
  /// TODO: avoid recursion
  Map<int, LambdaType>? unify(LambdaType? other) {
    if (other == null) {
      return null;
    }

    if (!isArrow) {
      if (varIndex == other.varIndex || !other.contains(varIndex!)) {
        return {varIndex!: other};
      }

      return null;
    }

    if (!other.isArrow) {
      if (varIndex == other.varIndex || !contains(other.varIndex!)) {
        return {other.varIndex!: this};
      }

      return null;
    }

    final s1 = type1!.unify(other.type1!);
    final s2 = type2!.substitute(s1)?.unify(other.type2!.substitute(s1));

    return compose(s2, s1);
  }

  LambdaType _clean() {
    final indexMap = <int, int>{};
    return fmap<Solo<int>>(
      onVar: (lambdaType, freshIndex) {
        final newIndex = indexMap.putIfAbsent(
          lambdaType.varIndex!,
          () {
            final index = freshIndex!.value;
            freshIndex.value += 1;
            return index;
          },
        );
        return LambdaType._(isArrow: false, varIndex: newIndex);
      },
      initialParam: Solo(1),
    );
  }
}
