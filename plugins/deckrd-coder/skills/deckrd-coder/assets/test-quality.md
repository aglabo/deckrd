# Test Quality Principles

<!-- textlint-disable ja-technical-writing/sentence-length -->

Cross-cutting test quality rules for all languages and frameworks.
Referenced from language assets and bdd-coder.md.

---

## Host Environment Safety

Tests must not leave side effects on the host machine.

### Rules

- **Write to tempdir only.** Test-generated files and directories MUST be created
  inside a temporary directory, never in `$HOME`, project root, or system paths.
- **Restore after test.** Any file, directory, or environment variable changed by a
  test MUST be restored in `afterEach` / `teardown` / destructor — even when the
  test fails.
- **No real network calls.** Tests MUST NOT connect to external services or APIs.
  Use stubs, recorded responses (VCR/playback), or service containers.
- **No permanent config changes.** Tests MUST NOT write to user config files
  (`~/.config`, `~/.local/share`, registry, etc.) or project config files.

### Failure pattern

A test that passes on a clean machine but fails on a colleague's machine, or
that leaves files behind after a failed run, violates host safety.

---

## Idempotency

Tests must produce the same result on every run, in any environment, in any order.

### Rules

- **No `Date.now()` / `time.Now()` / `date` in tests.** Inject a fixed timestamp
  as a parameter, environment variable, or dependency-injected provider.
  Production code that depends on the current time MUST accept a clock parameter.
- **No random values without seeding.** If randomness is required, inject the seed
  or use a fixed deterministic value in tests.
- **No run-order dependencies.** Each test must pass in isolation and in any order.
  Shared mutable state between tests is forbidden.
- **No environment assumptions.** Tests MUST NOT rely on a specific OS locale,
  timezone, `$PATH`, or installed toolchain beyond what the project declares as required.

### Failure pattern

A test that passes Monday but fails Friday, passes on CI but fails locally,
or passes only when run after another specific test, violates idempotency.

---

## Mock Discipline

### What to mock (legitimate test doubles)

Mock or stub only **external dependencies and collaborators outside the unit under test**:

- Clock / system time → inject a fixed `Date` / `time.Time` / timestamp
- Filesystem → use a real tempdir (not a mock), or a filesystem stub if I/O is not under test
- Network / HTTP → stub responses or use a recorded fixture
- Non-deterministic system calls → inject a controlled provider

These are **deterministic test doubles**. They isolate the test from the environment,
not from the code under test. They are required for idempotency and are NOT forbidden.

### What NOT to mock (AP9 — skeletal mock)

**Never mock the unit under test itself.**

If the function you are testing is mocked, the test only verifies that the mock returns
what you told it to return. No defects in the real implementation can be detected.
Coverage numbers go up; confidence does not.

See: [testing-anti-patterns.md](testing-anti-patterns.md) — AP9: Skeletal Mock

### Distinction summary

| Double type | Mock target | Verdict |
| ----------- | ----------- | ------- |
| Clock injection (`vi.setSystemTime`, `t.Setenv`) | Environment | Required for idempotency |
| Tempdir (`mktemp -d`, `t.TempDir()`) | Filesystem isolation | Required for host safety |
| HTTP stub / VCR fixture | External network | Required |
| `vi.mock('./myUnit')` on the unit under test | The unit itself | **Forbidden (AP9)** |

---

## CRAP Score

Coverage alone does not measure test quality. The CRAP score combines cyclomatic complexity
(CC) and branch coverage to surface high-risk, under-tested code.

### Formula

```
CRAP = CC² × (1 - coverage/100)³ + CC
```

Where:

- **CC** — Cyclomatic Complexity of the function (number of independent paths through the code)
- **coverage** — branch/line coverage percentage for that function (0–100)

### Interpretation

| CRAP score | Risk level | Meaning |
| ---------- | ---------- | ------- |
| ≤ 5        | Low        | Well-tested, simple code |
| 6–15       | Moderate   | Acceptable; monitor on growth |
| 16–30      | High       | Refactor or increase coverage |
| > 30       | Critical   | Must not ship without fixing |

A function with CC=10 and 0% coverage scores **110** (critical).
The same function at 100% coverage scores **10** (low).

### Required actions by score

| Score | Action |
| ----- | ------ |
| > 30  | BLOCKED — must refactor (reduce CC) or add tests before proceeding |
| 16–30 | WARN — report to caller with `DONE_WITH_CONCERNS`; include score in notes |
| ≤ 15  | PASS — include score in quality gate report |

### How to compute

Use the coverage + complexity report from the language toolchain:

| Language   | Tool / command |
| ---------- | -------------- |
| TypeScript | `vitest run --coverage` → parse per-function `complexity` from coverage JSON, or use `ts-complex` |
| Go         | `go test -cover ./...` + `gocyclo ./...` → compute per function |
| Rust       | `cargo llvm-cov` + `cargo clippy` complexity lint → compute per function |
| Shell      | `shellspec --format documentation` + manual CC count (branches in function) |

When an automated per-function score is not available, compute manually:
CC = 1 + (number of `if` / `case` / `while` / `for` / `&&` / `||` branches in the function).

### Reporting format

Include per-function CRAP scores in the quality gate report:

```
CRAP SCORES:
  functionA  CC=3  cov=95%  CRAP=3.0   [PASS]
  functionB  CC=8  cov=60%  CRAP=34.2  [CRITICAL — must fix]
  functionC  CC=5  cov=80%  CRAP=5.4   [PASS]
OVERALL: 1 critical, 0 warnings
```
