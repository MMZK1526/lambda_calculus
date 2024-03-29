## 1.3.6

- Revert due to the upstream https://github.com/dart-lang/sdk/issues/53944 is fixed.

## 1.3.5

- Fixed a parser bug.
  - Will rewrite the parser in later versions.

- Better printing of free variables, retaining their names.

## 1.3.4

- A temporary patch to evade the bug https://github.com/dart-lang/sdk/issues/53944.

## 1.3.3

- Reimplement type inference using a more efficient data structure.

- Remove now unused `collection` dependency.

- Deprecate the `LambdaType.fromVar`. Use the constructor instead.

## 1.3.2

- Fix a concurrency bug in type inference.

- The current type inference implementation is very nasty and inefficient. I
  will rewrite it in the future.

## 1.3.0

- Modify the parsing syntax:
  1. Stop allowing abstractions without delimiters, *e.g.* `λx x` is not allowed
     anymore, use `λx. x` or `λx -> x` instead.
  2. Allow spaces between the lambda symbol and the variable, *e.g.* `λ x -> x`
     is now allowed. It was already allowed according to the previous
      documentation, but the implementation was not consistent.
  3. Allow inner abstractions to be omitted, *e.g.* `λx. λy. x y` can be
     written as `λx y. x y`.
  4. Stop allowing special depth variables such as `_x1` or `_y2`. These
     underscore variables are not prohibited.

- Improve the pretty-printing of `Lambda` to not creating variables with
  underscores. Instead it will choose appropriate fresh names that are
  guaranteed to not conflict with existing variables.

- Fix bugs in the parser.

- Make `LambdaBuilder` and `Lambda` final.

- More documentation.


## 1.2.0

- Change the signature of `fmap` so that "non-leaf" callbacks no longer have access
  to the term itself. This is because previous usage of this term is not consistent.

- Fix the problem where variables with the same name can conflict with each other
  during evaluation.

- Better printing format for `LambdaType`.

- Fix typos in documentation.

- Make `Lambda` final.

- Remove dependency on `dartz`.

- More tests.


## 1.1.1

- Better documentation.


## 1.1.0

- Stop allowing constructing `Lambda` directly, instead, use `LambdaBuilder`.

- Access constants via `LambdaBuilder.constants` or `Lambda.constants`.

- Fix the problem where the index of a variable is sometimes `null`.


## 1.0.0

- Initial version.
