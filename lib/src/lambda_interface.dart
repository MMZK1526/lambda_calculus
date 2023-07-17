import 'package:lambda_calculus/src/lambda_form.dart';

abstract class ILambda<T> {
  ILambda({required this.form});

  LambdaForm form;

  String? name;

  int? index;

  T? exp1;

  T? exp2;
}
