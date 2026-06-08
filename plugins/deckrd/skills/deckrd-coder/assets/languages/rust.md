---
language: rust
---

# Rust Language Rules

## Build & Run

| Task  | Command                 |
| ----- | ----------------------- |
| Build | `cargo build`           |
| Build | `cargo build --release` |
| Run   | `cargo run`             |
| Clean | `cargo clean`           |

## Quality Gates

| Gate       | Command                                               |
| ---------- | ----------------------------------------------------- |
| Lint       | `cargo clippy -- -D warnings`                         |
| Type Check | `cargo check`                                         |
| Format     | `cargo fmt`                                           |
| Test       | `cargo llvm-cov` or `cargo tarpaulin` (with coverage) |
| Test+Doc   | `cargo test --doc`                                    |

## Test Framework

| Item         | Value                                      |
| ------------ | ------------------------------------------ |
| Framework    | Built-in `#[test]` attribute               |
| File pattern | `tests/` directory, `*_test.rs`, or inline |
| Run command  | `cargo test`                               |
| BDD mapping  | Test function names as `given_when_then`   |

### Test Structure

```rust
#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn given_context_when_action_then_expected_result() {
        // Arrange
        // Act
        // Assert
        assert_eq!(result, expected);
    }
}
```

### Integration Tests

```rust
// tests/integration_test.rs
#[test]
fn given_context_when_action_then_result() {
    // ...
}
```

## Project Conventions

| Item           | Value                           |
| -------------- | ------------------------------- |
| Extension      | `.rs`                           |
| Module system  | Cargo workspaces and crates     |
| Config files   | `Cargo.toml`, `Cargo.lock`      |
| Error handling | `Result<T, E>` and `?` operator |

## Test Quality (Rust-specific)

For canonical host-safety, idempotency, and mock discipline principles, see:
[../test-quality.md](../test-quality.md)

- **Tempdir**: Use the `tempfile` crate — `tempfile::tempdir()` returns a `TempDir`
  that is automatically deleted when dropped.
- **Clock injection**: Accept `SystemTime` or `std::time::Instant` as a parameter
  instead of calling `SystemTime::now()` directly inside the function under test.
- **No filesystem side effects**: Write test artifacts to `std::env::temp_dir()`,
  never to the project directory or `$HOME`.

## Project Detection

Identifying files for Rust projects:

- `Cargo.toml` — package manifest (required)
- `Cargo.lock` — dependency lockfile
- `src/main.rs` or `src/lib.rs` — entry point
