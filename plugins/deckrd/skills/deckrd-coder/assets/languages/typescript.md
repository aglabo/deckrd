---
language: typescript
---

# TypeScript Language Rules

## Build & Run

| Task  | Command                                        |
| ----- | ---------------------------------------------- |
| Build | `tsc` or `pnpm build` / `npm run build`        |
| Run   | `node dist/index.js` or `ts-node src/index.ts` |
| Clean | `rm -rf dist`                                  |

## Quality Gates

| Gate       | Command                                      |
| ---------- | -------------------------------------------- |
| Lint       | `eslint "**/*.{ts,tsx}"`                     |
| Type Check | `tsc --noEmit`                               |
| Format     | `prettier --write "**/*.{ts,tsx,json}"`      |
| Test       | `vitest run --coverage` or `jest --coverage` |

## Test Framework

| Item         | Value                          |
| ------------ | ------------------------------ |
| Framework    | `vitest` (preferred) or `jest` |
| File pattern | `*.test.ts`, `*.spec.ts`       |
| Run command  | `vitest run` or `jest`         |
| BDD mapping  | `describe` / `it` / `expect`   |

### Test Structure

```typescript
describe('Given <context>', () => {
  describe('When <action>', () => {
    it('Then <expected result>', () => {
      // Arrange
      // Act
      // Assert
    });
  });
});
```

## Project Conventions

| Item            | Value                                |
| --------------- | ------------------------------------ |
| Extension       | `.ts`, `.tsx`                        |
| Module system   | ESM (`"type": "module"`) or CommonJS |
| Config files    | `tsconfig.json`, `eslint.config.js`  |
| Package manager | `pnpm` (preferred), `npm`, or `yarn` |

## Test Quality (TypeScript-specific)

For canonical host-safety, idempotency, and mock discipline principles, see:
[../test-quality.md](../test-quality.md)

### Clock Injection (Vitest)

```typescript
beforeEach(() => vi.setSystemTime(new Date('2024-01-01T00:00:00Z')));
afterEach(() => vi.useRealTimers());
```

### Tempdir Isolation (Node.js)

```typescript
import { mkdtempSync, rmSync } from 'node:fs';
import { tmpdir } from 'node:os';
import path from 'node:path';

let _testDir: string;
beforeEach(() => {
  _testDir = mkdtempSync(path.join(tmpdir(), 'test-'));
});
afterEach(() => rmSync(_testDir, { recursive: true, force: true }));
```

## Project Detection

Identifying files for TypeScript projects:

- `package.json` — project manifest (required)
- `tsconfig.json` — TypeScript configuration (required)
- `pnpm-lock.yaml`, `package-lock.json`, or `yarn.lock` — lockfile
