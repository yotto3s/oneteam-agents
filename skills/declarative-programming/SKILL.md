---
name: declarative-programming
description: >-
  Enforces declarative programming style: decompose every meaningful procedure
  into named functions so calling code reads as a sequence of intentions, not
  inline logic blocks.
---

# Declarative Programming

## Overview

**Declarative programming via decomposition:** Every meaningful procedure MUST be
extracted into its own named function. The calling code should declare *what*
happens -- a sequence of clearly-named steps -- not contain inline *how* logic.

## When to Use

- Writing code (implementation agents)
- Writing code examples in plans (architect agent)
- Reviewing code for quality (self-review, review-navi)

## When NOT to Use

- Trivial one-liner functions that would add indirection without clarity
- Configuration files, data definitions, or markup that is not procedural code

## Signal to Decompose

A comment that labels a block of code (e.g., `# validate input`,
`// calculate totals`) is a signal that block should be a named function instead.

## Good Example

```python
def process_order(order):
    validated = validate_order(order)
    priced = calculate_pricing(validated)
    receipt = charge_payment(priced)
    send_confirmation(receipt)
```

The top-level function reads as a sequence of intentions. Each step is a named
function whose implementation lives elsewhere.

## Bad Example

```python
def process_order(order):
    # validate
    if not order.items:
        raise ValueError("Empty")
    for item in order.items:
        if item.qty < 1:
            raise ValueError("Bad qty")
    # calculate pricing
    subtotal = sum(i.price * i.qty for i in order.items)
    tax = subtotal * 0.1
    total = subtotal + tax
    # charge
    resp = payment_api.charge(order.card, total)
    if resp.status != 'ok':
        raise PaymentError(resp.msg)
    # send confirmation
    email_service.send(to=order.email, subject='Order confirmed', body=f'Total: {total}')
```

The comment headers (`# validate`, `# calculate pricing`, etc.) are signals that
each block should be extracted into a named function.

## Constraints

- **ALWAYS** extract meaningful procedures into named functions.
- **NEVER** leave inline logic blocks with comment headers -- extract them.
- A comment labeling a code block is a code smell: replace it with a named
  function call.
