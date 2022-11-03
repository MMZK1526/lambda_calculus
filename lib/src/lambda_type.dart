import 'dart:collection';

import 'package:collection/collection.dart';
import 'package:lambda_calculus/src/lambda.dart';

extension LamdbaTypeExtension on Lambda {
  LambdaType? findType() {
    LambdaType getFreshType(Map<List<List<int>>, LambdaType> context) {
      late final LambdaType result;
      context.update(
        [
          [7]
        ],
        (value) {
          result = value;
          return LambdaType(isArrow: false, varIndex: value.varIndex! + 1);
        },
        ifAbsent: () {
          result = const LambdaType(isArrow: false, varIndex: 0);
          return const LambdaType(isArrow: false, varIndex: 1);
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
          final redex =
              work(context, term.exp1!, List.of(curVar)..insert(0, []));
          if (redex != null) {
            return MapEntry(
              redex.key,
              LambdaType(
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
                LambdaType(isArrow: true, type1: term2.value, type2: freshType),
              );
          if (s1 == null) {
            return null;
          }
          return MapEntry(
            LambdaType.compose(s1, LambdaType.compose(term2.key, term1.key))!,
            freshType.substitute(s1)!,
          );
        case LambdaForm.dummy:
          return null;
      }
    }

    return work(
      LinkedHashMap(
        equals: const DeepCollectionEquality().equals,
        hashCode: (l) => Object.hashAll(l.map(Object.hashAll)),
      ),
      this,
      [[]],
    )?.value;
  }
}

class LambdaType {
  const LambdaType({
    required this.isArrow,
    this.varIndex,
    this.type1,
    this.type2,
  }) : assert((isArrow && type1 != null && type2 != null && varIndex == null) ||
            (!isArrow && type1 == null && type2 == null && varIndex != null));

  final bool isArrow;
  final int? varIndex;
  final LambdaType? type1;
  final LambdaType? type2;

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

  // TODO: Avoid recursion and omit redundant parenthesis
  @override
  String toString() {
    if (isArrow) {
      return "(${type1!} -> ${type2!})";
    } else {
      return "t${varIndex!}";
    }
  }

  // TODO: Avoid recursion
  /// Check if the [LambdaType] contains the given variable.
  bool contains(int otherVar) {
    if (!isArrow) {
      return varIndex == otherVar;
    }

    return type1!.contains(otherVar) || type2!.contains(otherVar);
  }

  // TODO: Avoid recursion
  /// Substitute with the given substitution.
  LambdaType? substitute(Map<int, LambdaType>? substitution) {
    if (substitution == null) {
      return null;
    }

    if (!isArrow) {
      return substitution[varIndex!] ?? this;
    }

    return LambdaType(
      isArrow: true,
      type1: type1!.substitute(substitution),
      type2: type2!.substitute(substitution),
    );
  }

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
}
