# Systematic Test Case Derivation

When planning which tests to write, use these techniques to discover cases systematically rather than ad hoc.

## 1. Happy Path First

Start with the primary success scenario — the most common use case:

```
Feature: User registration
Happy path: valid email + valid password → account created successfully
```

## 2. Boundary Value Analysis

Test at the edges of valid input ranges:

```
Input: password length (min 8, max 64)
Test values: 7 (reject), 8 (accept), 64 (accept), 65 (reject)
```

For numeric ranges, test: `min-1`, `min`, `min+1`, `max-1`, `max`, `max+1`

## 3. Equivalence Partitioning

Group inputs into classes that should behave identically. Test one representative from each class:

```
Email validation:
- Valid emails: "user@example.com" (one test is enough)
- Missing @: "userexample.com"
- Missing domain: "user@"
- Empty string: ""
- Null/undefined
```

## 4. Error Path Analysis

For each operation, identify what can go wrong:

```
File upload:
- File too large → size limit error
- Invalid format → format error
- Network timeout → timeout error
- Disk full → storage error
- Permission denied → auth error
```

## 5. State Transition Testing

When objects have distinct states, test transitions between them:

```
Order states: draft → submitted → paid → shipped → delivered
Test: draft→submitted (valid), draft→shipped (invalid), paid→draft (invalid)
```

## 6. Common Edge Cases Checklist

Apply to every function accepting external input:

| Input type | Edge cases to test |
|------------|-------------------|
| String | empty `""`, whitespace `"  "`, very long, special characters, unicode |
| Number | 0, negative, MAX_SAFE_INTEGER, NaN, Infinity, floating point |
| Array | empty `[]`, single element, very large, duplicate elements |
| Object | empty `{}`, missing required fields, extra fields, null |
| Date | epoch, far future, timezone boundaries, invalid date |
| Boolean | both true and false, plus truthy/falsy values if loosely typed |

## Prioritization

Not every edge case needs a test. Prioritize by:

1. **Business impact** — what causes data loss or financial harm?
2. **Likelihood** — what inputs do real users actually send?
3. **Complexity** — where is the logic most intricate?

Confirm priorities with the user. Testing everything is neither possible nor necessary.
