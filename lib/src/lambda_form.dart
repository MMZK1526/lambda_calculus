/// The forms of lambda expressions.
///
/// [variable] is a variable (e.g. `x`).
///
/// [application] is an application of two lambda expressions (e.g. `A B`).
///
/// [abstraction] is an abstraction of a lambda expression (e.g. `λx. M`).
enum LambdaForm {
  variable,
  application,
  abstraction,
}
