import 'dart:collection';

import 'package:collection/collection.dart';
import 'package:lambda_calculus/src/lambda.dart';
import 'package:lambda_calculus/src/lambda_form.dart';
import 'package:lambda_calculus/src/utilities.dart';

/// An extension to find the principal type of a [Lambda].
extension LamdbaTypeExtension on Lambda {
  /// Find the principal type of the [Lambda].
  LambdaType? findType() {
    LambdaType getFreshType(Map<List<List<int>>, LambdaType> context) {
      late final LambdaType result;
      context.update(
        [
          [7]
        ],
        (value) {
          result = value;
          return LambdaType._(isArrow: false, varIndex: value.varIndex! + 1);
        },
        ifAbsent: () {
          result = const LambdaType._(isArrow: false, varIndex: 0);
          return const LambdaType._(isArrow: false, varIndex: 1);
        },
      );
      return result;
    }

    void substitute(
      Map<List<List<int>>, LambdaType> context,
      Map<int, LambdaType> substitution,
    ) {
      context.forEach((key, _) {
        context.update(key, (value) => value.substitute(substitution)!);
      });
    }

    LambdaType useContext(
      Map<List<List<int>>, LambdaType> context,
      List<List<int>> curVar,
    ) {
      context.update(
        curVar,
        (value) => value,
        ifAbsent: () => getFreshType(context),
      );

      return context[curVar]!;
    }

    /// TODO: Avoid recursion
    MapEntry<Map<int, LambdaType>, LambdaType>? work(
      Map<List<List<int>>, LambdaType> context,
      Lambda term,
      List<List<int>> curVar,
    ) {
      switch (term.form) {
        case LambdaForm.variable:
          final depth = term.index!;
          if (depth >= curVar.length - 1) {
            return MapEntry(
              {},
              useContext(context, [
                [curVar.length - depth - 2]
              ]),
            );
          }
          return MapEntry({}, useContext(context, curVar.sublist(depth + 1)));
        case LambdaForm.abstraction:
          final curType = useContext(context, curVar);
          final redex = work(
            context,
            term.exp1!,
            List.of(curVar)..insert(0, []),
          );
          if (redex != null) {
            return MapEntry(
              redex.key,
              LambdaType._(
                isArrow: true,
                type1: curType,
                type2: redex.value,
              ).substitute(redex.key)!,
            );
          }
          return null;
        case LambdaForm.application:
          final freshType = getFreshType(context);
          final term1 =
              work(context, term.exp1!, List.of(curVar)..first.insert(0, 0));
          if (term1 == null) {
            return null;
          }
          substitute(context, term1.key);
          final term2 =
              work(context, term.exp2!, List.of(curVar)..first.insert(0, 1));
          if (term2 == null) {
            return null;
          }
          final s1 = term1.value.substitute(term2.key)!.unify(
                LambdaType._(
                    isArrow: true, type1: term2.value, type2: freshType),
              );
          if (s1 == null) {
            return null;
          }
          return MapEntry(
            LambdaType.compose(s1, LambdaType.compose(term2.key, term1.key))!,
            freshType.substitute(s1)!,
          );
      }
    }

    return work(
      LinkedHashMap(
        equals: const DeepCollectionEquality().equals,
        hashCode: (l) => Object.hashAll(l.map(Object.hashAll)),
      ),
      this,
      [[]],
    )?.value._clean();
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
    // return this;
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
