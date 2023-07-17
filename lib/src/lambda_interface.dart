import 'package:lambda_calculus/src/lambda_form.dart';

abstract class ILambda<T> {
  LambdaForm get form;

  String? get name;

  int? get index;

  T? get exp1;

  T? get exp2;
}
