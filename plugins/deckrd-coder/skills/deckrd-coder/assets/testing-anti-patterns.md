# Testing Anti-Patterns

<!-- textlint-disable
  ja-technical-writing/sentence-length -->

Patterns that corrupt the BDD cycle. Each one has been observed causing real failures.
When you recognize one, STOP and restart from Red.

## Anti-Pattern 1: Production Code Before Test

**What it looks like**:
Writing the implementation first, then writing a test to match it.

**Why it fails**:
The test cannot fail (Red phase is skipped). You lose the signal that your test
actually verifies behavior. The test becomes a description, not a specification.

**Red flag**:

> "I'll write the implementation, then write tests to cover it."

**Correct behavior**:
Write one failing test. See it fail. Then write the minimum implementation.

## Anti-Pattern 2: Test That Passes Immediately

**What it looks like**:
You write a test, run it, and it passes on the first run without any implementation.

**Why it fails**:
A test that cannot fail does not verify anything. Either the test is wrong,
or the behavior is already implemented (and you should check why).

**Red flag**:

> Test passes instantly after writing it.

**Correct behavior**:
If the test passes immediately, the test is wrong. Rewrite it so it fails first.

## Anti-Pattern 3: Multiple Tests at Once

**What it looks like**:
Writing 3-5 tests before writing any implementation.

**Why it fails**:
You cannot run the Red-Green cycle properly. You end up guessing which test
drives which implementation. Context grows and errors compound.

**Red flag**:

> "Let me write all the tests first, then implement."

**Correct behavior**:
One test. See it fail. Implement. See it pass. Refactor. Repeat.

## Anti-Pattern 4: Green Phase Over-Implementation

**What it looks like**:
While making one test pass, you also implement logic for the next 2-3 test cases
"since you're already there."

**Why it fails**:
The next tests may pass trivially, skipping their Red phase. You lose the
specification value of each test case. The refactor phase also becomes harder.

**Red flag**:

> "While I'm implementing X, I'll also add Y and Z since they're related."

**Correct behavior**:
Write only the code that makes the current test pass. Nothing more.

## Anti-Pattern 5: "Just This Once" Rationalization

**What it looks like**:
Any reasoning that justifies skipping a BDD phase due to time pressure,
sunk cost, authority, or social pressure.

Common forms:

- "We're under deadline, let's skip the test."
- "I already wrote 4 hours of code, I can't delete it now."
- "The senior engineer said TDD is too slow for this."
- "It feels rigid to write a test for something this obvious."

**Why it fails**:
Each exception trains you (and the AI) that the rule is optional.
The rule is not optional. It exists because "just this once" is how quality erodes.

**Correct behavior**:
Acknowledge the pressure. Do the cycle anyway.

## Anti-Pattern 6: Claiming Completion Without Evidence

**What it looks like**:
Saying "all tests pass" or "implementation is complete" without running
the commands and reading the full output.

**Why it fails**:
Memory is unreliable. The last run may have been on different code.
A test may have been skipped. A file may not have been saved.

**Red flag**:

> "should work now" / "looks correct" / "I'm confident it passes"

**Correct behavior**:
Run the command. Read the FULL output. Only then make the claim.

## Anti-Pattern 7: Tests Added After Implementation

**What it looks like**:
Implementation is complete and working. Tests are written afterward
to achieve coverage or satisfy a checklist.

**Why it fails**:
Tests written after implementation are documentation, not specification.
They tend to test what the code does rather than what it should do.
They also tend to pass trivially, providing false confidence.

**Red flag**:

> "Implementation is done, now let me add tests for it."

**Correct behavior**:
If you find yourself here, either:

1. Delete the implementation and start from Red, or
2. Acknowledge this is documentation-testing and treat the coverage accordingly.
