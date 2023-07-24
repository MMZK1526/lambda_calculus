## 1.2.0 (unreleased)

- Change the signature of `fmap` so that "non-leaf" callbacks no longer have access
  to the term itself. This is because previous usage of this term is not consistent.

- Fix the problem where variables with the same name can conflict with each other
  during evaluation.

- Better printing format for `LambdaType`.

- Fix typos in documentation.

- Make `Lambda` final.

- Remove dependency on `dartz`.

## 1.1.1

- Better documentation.

## 1.1.0

- Stop allowing constructing `Lambda` directly, instead, use `LambdaBuilder`.
- Access constants via `LambdaBuilder.constants` or `Lambda.constants`.
- Fix the problem where the index of a variable is sometimes `null`.

## 1.0.0

- Initial version.
