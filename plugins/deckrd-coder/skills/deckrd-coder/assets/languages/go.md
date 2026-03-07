---
language: go
---

# Go Language Rules

## Build & Run

| Task  | Command               |
| ----- | --------------------- |
| Build | `go build ./...`      |
| Run   | `go run .`            |
| Clean | `go clean ./...`      |

## Quality Gates

| Gate        | Command                                     |
| ----------- | ------------------------------------------- |
| Lint        | `golangci-lint run ./...`                   |
| Vet         | `go vet ./...`                              |
| Format      | `gofmt -w .` or `goimports -w .`            |
| Test        | `go test ./...`                             |
| Test+Cover  | `go test -cover ./...`                      |
| Test+Race   | `go test -race ./...`                       |

## Test Framework

| Item           | Value                              |
| -------------- | ---------------------------------- |
| Framework      | `testing` (standard library)       |
| File pattern   | `*_test.go`                        |
| Run command    | `go test ./...`                    |
| BDD mapping    | `t.Run("Given ... When ... Then")` |

### Test Structure

```go
func TestFunctionName(t *testing.T) {
    t.Run("Given <context> When <action> Then <result>", func(t *testing.T) {
        // Arrange
        // Act
        // Assert
    })
}
```

## Project Conventions

| Item           | Value                          |
| -------------- | ------------------------------ |
| Extension      | `.go`                          |
| Module system  | Go modules (`go.mod`)          |
| Package naming | Lowercase, no underscores      |
| Error handling | Explicit `error` return values |

## Project Detection

Identifying files for Go projects:

- `go.mod` — module definition (required)
- `go.sum` — dependency checksums
- `*.go` source files
