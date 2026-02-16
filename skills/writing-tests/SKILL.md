---
name: writing-tests
description: >-
  Use when adding tests to existing code that lacks coverage, backfilling tests
  for legacy code, or writing tests after reading an implementation. Not for
  test-first development (use test-driven-development instead).
---

# Writing Tests

## Overview

Write tests by reading **both** the spec and the implementation. The spec tells you what the code *should* do. The implementation tells you what the code *actually* does — including hidden paths, implicit assumptions, and unreachable branches the spec never mentions.

**Core principle:** Spec-derived tests verify intent. Implementation-derived tests verify reality. You need both.

## When to Use

- Adding tests to existing code that has no tests
- Backfilling coverage for legacy code
- Writing tests after reading someone else's implementation
- Auditing test coverage for code you didn't write

**When NOT to use:** For new features or bug fixes, use `test-driven-development` instead (test-first).

## Workflow

### Phase 1: Read the Spec

Read docs, JSDoc, README, type signatures, and any requirements documents. Derive test cases for:

- **Documented behavior** — what the function/class promises to do
- **Documented constraints** — input ranges, return types, error conditions
- **Documented edge cases** — anything the spec explicitly calls out

### Phase 2: Read the Implementation

Read every line of the actual code. For each line, ask: *"What input would make execution reach here?"*

Derive test cases for:

- **Every branch** — each `if/else`, `switch` case, ternary, `&&`/`||` short-circuit
- **Every guard clause** — early returns, validation checks, null guards
- **Every catch block** — what triggers it? Is the error handled correctly?
- **Implicit type coercions** — `if (value)` is truthy check, not `=== true`. Test with `undefined`, `null`, `0`, `""`
- **Unreachable code** — code paths that exist but can't be triggered with valid inputs. These are bugs or dead code. See "Dead Code Detection" below for how to find them
- **Default values and fallbacks** — `|| default`, `?? fallback`, optional parameters

### Phase 3: Merge and Organize

Combine spec-derived and implementation-derived test cases. Remove duplicates. Organize by:

```
describe('functionName', () => {
  describe('valid inputs', () => {       // happy paths
    ...
  });
  describe('edge cases', () => {         // boundaries, empty, zero
    ...
  });
  describe('invalid inputs', () => {     // validation, error paths
    ...
  });
});
```

For classes with multiple methods, nest by method first, then by category.

**For gtest (C++):**

```cpp
// Organize by behavior category
TEST(FunctionName, HandlesValidInput) { ... }
TEST(FunctionName, HandlesEdgeCase_EmptyString) { ... }
TEST(FunctionName, RejectsInvalidInput) { ... }

// For parameterized tests, group related cases
INSTANTIATE_TEST_SUITE_P(ValidInputs, FunctionTest, ...);
INSTANTIATE_TEST_SUITE_P(EdgeCases, FunctionTest, ...);
INSTANTIATE_TEST_SUITE_P(InvalidInputs, FunctionTest, ...);
```

### Phase 4: Write Tests

Write each test following the best practices below.

### Phase 5: Verify

Run the tests. Check:
- All pass (or fail for expected reasons if testing bugs)
- Coverage report shows the code paths you targeted are actually hit
- No tests are tautological (always pass regardless of implementation)

## Best Practices

### Arrange-Act-Assert (AAA)

Every test has three sections. Separate them with a blank line if the test is longer than a few lines.

```typescript
it('rejects empty email', () => {
  // Arrange
  const input = { email: '' };

  // Act
  const result = validate(input);

  // Assert
  expect(result.error).toBe('Email required');
});
```

**For gtest (C++):**

```cpp
TEST(ValidatorTest, RejectsEmptyEmail) {
  // Arrange
  Input input{.email = ""};

  // Act
  auto result = validate(input);

  // Assert
  EXPECT_EQ(result.error, "Email required");
}
```

### One Behavior Per Test

Each test verifies one behavior. If the test name contains "and", split it.

```typescript
// BAD — two behaviors, unclear which failed
it('validates email and normalizes case', () => {
  expect(validate('')).toHaveProperty('error');
  expect(normalize('FOO@BAR.COM')).toBe('foo@bar.com');
});

// GOOD — one behavior each
it('rejects empty email', () => { ... });
it('normalizes email to lowercase', () => { ... });
```

**Exception:** Testing a full return object (like a pricing breakdown) can use multiple assertions on the same result — that's still one behavior (the computation).

### Test Names Describe Behavior

Use the pattern: `[action] [condition] [expected result]`

```typescript
// BAD
it('test1', () => { ... });
it('works', () => { ... });

// GOOD
it('returns null for empty string', () => { ... });
it('retries once before falling through to next channel', () => { ... });
it('applies volume discount at exactly 10 seats', () => { ... });
```

### Boundary Value Analysis

For every numeric boundary in the code, test three values: **below, at, and above**.

```typescript
// Code: if (seats >= 10) discount = 0.15;
it('no volume discount at 9 seats', () => { ... });   // below
it('applies 15% volume discount at 10 seats', () => { ... }); // at
it('applies 15% volume discount at 11 seats', () => { ... }); // above
```

For ranges with two boundaries, test both edges:

```typescript
// Code: if (seats >= 50) rate = 0.25; else if (seats >= 10) rate = 0.15;
// Test: 9, 10, 11, 49, 50, 51
```

**With gtest parameterized tests**, boundary testing becomes concise and data-driven:

```cpp
// Code: if (seats >= 10) discount = 0.15;
struct BoundaryCase { int seats; double expectedDiscount; };
class DiscountTest : public testing::TestWithParam<BoundaryCase> {};

TEST_P(DiscountTest, AppliesCorrectDiscount) {
  auto [seats, expected] = GetParam();
  EXPECT_EQ(calculateDiscount(seats), expected);
}

INSTANTIATE_TEST_SUITE_P(
  VolumeBoundary,
  DiscountTest,
  testing::Values(
    BoundaryCase{9, 0.0},   // below
    BoundaryCase{10, 0.15}, // at
    BoundaryCase{11, 0.15}  // above
  )
);
```

Apply boundary analysis to:
- Numeric thresholds (`>=`, `>`, `<=`, `<`)
- Time windows (rate limits, TTLs, timeouts) — test at exact expiry, not just "after"
- String lengths (min/max length checks)
- Array sizes (empty, one, boundary count)

### Parameterized Tests (gtest)

When testing C++ code with gtest, use parameterized tests (TEST_P) when you have multiple inputs that exercise the same behavior. This reduces duplication and makes test intent clearer.

**When to parameterize:**
- Testing boundary values (below/at/above threshold)
- Testing multiple valid inputs with different expected outputs
- Testing error cases with different invalid inputs
- Testing the same logic across different data types or configurations

**When NOT to parameterize:**
- Each test case requires significantly different setup/teardown
- The test logic differs between cases (use separate tests)
- Only 1-2 cases exist (not worth the complexity)

```cpp
// BAD — repetitive, hard to extend
TEST(PricingTest, NoDiscountAt9Seats) {
  auto result = calculatePrice(9);
  EXPECT_EQ(result.discount, 0.0);
}
TEST(PricingTest, Apply15PercentDiscountAt10Seats) {
  auto result = calculatePrice(10);
  EXPECT_EQ(result.discount, 0.15);
}
TEST(PricingTest, Apply15PercentDiscountAt11Seats) {
  auto result = calculatePrice(11);
  EXPECT_EQ(result.discount, 0.15);
}

// GOOD — parameterized, clear data-driven approach
struct PricingTestCase {
  int seats;
  double expectedDiscount;
  std::string description;
};

class PricingTest : public testing::TestWithParam<PricingTestCase> {};

TEST_P(PricingTest, AppliesCorrectVolumeDiscount) {
  auto [seats, expectedDiscount, description] = GetParam();
  auto result = calculatePrice(seats);
  EXPECT_EQ(result.discount, expectedDiscount) << description;
}

INSTANTIATE_TEST_SUITE_P(
  VolumeDiscountBoundaries,
  PricingTest,
  testing::Values(
    PricingTestCase{9, 0.0, "below threshold"},
    PricingTestCase{10, 0.15, "at threshold"},
    PricingTestCase{11, 0.15, "above threshold"}
  )
);
```

**Structure:**
1. Define a test case struct with input parameters and expected outputs
2. Create a test fixture inheriting from `testing::TestWithParam<YourStruct>`
3. Write TEST_P that uses `GetParam()` to access parameters
4. Use INSTANTIATE_TEST_SUITE_P to provide test data with descriptive names

**Naming conventions:**
- Test suite name (first arg to INSTANTIATE_TEST_SUITE_P) should describe what varies: `VolumeDiscountBoundaries`, `InvalidEmailFormats`, `EdgeCases`
- Include a description field in your struct for better failure messages

### Exact Expected Values

Always calculate the exact expected value. Never use fuzzy matchers because you're unsure of the right answer.

```typescript
// BAD — hides uncertainty about the correct value
expect(result.savings).toBeCloseTo(26.9, 2);

// GOOD — calculated manually: (100 * 0.075) + 100 - 73.44 - 5.51 = 28.55...
// Actually compute step by step and assert the exact rounded result
expect(result.savings).toBe(28.55);
```

Use `toBeCloseTo` only when floating-point imprecision is inherent (e.g., `0.1 + 0.2`), not as a shortcut for "I didn't calculate this."

For gtest C++ tests:

```cpp
// BAD — vague tolerance
EXPECT_NEAR(result.savings, 26.9, 0.1);

// GOOD — exact calculation, precise expected value
// Calculated: (100 * 0.075) + 100 - 73.44 - 5.51 = 28.55
EXPECT_DOUBLE_EQ(result.savings, 28.55);
```

Use `EXPECT_NEAR` only for inherent floating-point precision issues, not as a shortcut.

### Test Isolation

Each test must be independent. No test should depend on another test's side effects.

- Use `beforeEach` to reset shared state
- Create fresh instances per test (don't share mutable objects across tests)
- Use fake timers when testing time-dependent behavior

### Mocking Guidance

**Mock at boundaries** — external services, databases, network calls, file system, timers.

**Don't mock the unit under test** — if you're testing `calculatePrice`, don't mock the discount logic inside it.

**Verify mock interactions when the interaction IS the behavior:**

```typescript
// GOOD — verifying the logger was called is the behavior we're testing
expect(logger.error).toHaveBeenCalledWith('All channels failed for user1');

// BAD — verifying internal implementation detail
expect(internalHelper).toHaveBeenCalledWith(42);
```

### Testing Implicit Truthy/Falsy Checks

When the implementation uses `if (value)` instead of `if (value === true)`, test the difference. This applies to **both inputs AND return values from dependencies**.

```typescript
// Implementation: if (success) { ... }  where success = await channel.send(...)
// This is a truthy check — test values that are falsy but not false:
it('treats undefined response as failure', () => { ... });
it('treats null response as failure', () => { ... });
it('treats 0 response as failure', () => { ... });
it('treats empty string response as failure', () => { ... });
```

**Common miss:** Testing truthy/falsy only for function inputs (userId, message) but not for values returned by dependencies (channel.send(), db.query()). Both sides of the truthy check need testing.

### Dead Code Detection

After writing all other tests, do a **reachability audit** for every clamp, floor, ceiling, and fallback in the code:

1. Find every `Math.max`, `Math.min`, `Math.ceil`, `Math.floor`, `|| default`, `?? fallback`
2. For each one, calculate: **can any valid input actually trigger the fallback/clamp side?**
3. Work backward from the clamp through all preceding transformations

```typescript
// Example: Math.max(discountedPrice, minimumCharge)
// minimumCharge = seats * 1.0
// discountedPrice = basePrice after all discounts
// For starter plan ($10/seat): worst case = 10 * 0.8 * 0.75 * 0.9 = $5.40/seat
// $5.40 > $1.00 → clamp NEVER activates with current plan prices!
//
// This is dead code. Document it in your test:
it('minimum charge floor cannot activate with current plan prices (lowest is $5.40/seat)', () => {
  // Maximum discounts: annual 20% + volume 25% + referral 10%
  const result = calculatePrice({
    plan: 'starter', seats: 50, billingCycle: 'annual',
    referralCode: 'CODE', isFirstInvoice: true,
    trialDaysRemaining: 0, taxRate: 0,
  });
  // $10 * 0.8 * 0.75 * 0.9 = $5.40/seat — still above $1 minimum
  expect(result.perSeatPrice).toBe(5.4);
  expect(result.perSeatPrice).toBeGreaterThan(1); // minimum never triggers
});
```

**If a clamp can't activate, that's a finding worth documenting.** Either the code is dead, the business rules changed, or the guard is there for safety. Write a test that proves it and annotate why.

## Code Path Checklist

Use this when reading implementation (Phase 2) to make sure you don't miss paths:

| Look for | Test question |
|----------|--------------|
| `if/else` branches | What input triggers each branch? |
| Guard clauses (`if (!x) return`) | What makes the guard trigger? What's the return value? |
| `try/catch` blocks | What exception triggers the catch? Is it handled correctly? |
| Loops | What happens with 0 iterations? 1 iteration? Many? |
| `Math.max/min`, clamps, floors | Can you craft input where the clamp activates? Work backward through all transformations. If no valid input triggers it, document it as dead code. |
| Default parameters | What happens when the parameter is omitted? |
| Type coercions (`if (x)`, `x \|\| y`) | What falsy values could `x` have? Check both inputs AND dependency return values. |
| Sorting/ordering | Is the sort stable? Does it handle equal elements? |
| Regex patterns | What matches? What almost-matches but shouldn't? |
| Numeric overflow | Can the computation exceed `MAX_SAFE_INTEGER`? |
| State mutation | Does the function modify its input? Should it? |

## Common Anti-Patterns

| Anti-pattern | Problem | Fix |
|-------------|---------|-----|
| Testing only happy paths | Misses all the ways code actually breaks | Use Phase 2 to find every branch |
| Testing from docs only | Misses implementation-specific code paths | Read every line of implementation |
| Fuzzy assertions when unsure | Hides calculation errors in tests themselves | Calculate exact expected values |
| Testing implementation details | Tests break when refactoring | Test behavior (inputs → outputs), not how |
| Shared mutable state between tests | Tests pass alone, fail together | Fresh state in `beforeEach` |
| Giant test with 10 assertions | Can't tell which behavior broke | One behavior per test |
| Copy-paste test blocks | Hard to maintain, easy to miss updates | Extract test helpers for shared setup |
| Not testing after writing | Assumes tests are correct | Always run and verify tests pass |
| Over-parameterizing gtest tests | Obscures test logic, hard to debug failures | Only parameterize when testing same behavior with different data |
| Under-parameterizing boundary tests | Repetitive code, missed test cases | Use TEST_P for boundary value sets (below/at/above) |
