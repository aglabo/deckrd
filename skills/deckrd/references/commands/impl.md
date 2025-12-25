# impl Command
<!-- markdownlint-disable line-length -->

Derive an implementation plan defining code-level constraints and contracts from specifications.

```bash
DECKRD_ROOT="./docs/"
```

<!-- textlint-disable ja-technical-writing/no-exclamation-question-mark -->

## Usage

```bash
/deckrd impl
```

## Preconditions

- Session must exist with active module
- `spec` must be completed for active module
- `specifications/specifications.md` must exist

## Input

Read specifications document from session's active module:

```bash
docs/.deckrd/<namespace>/<module>/specifications/specifications.md
```

The `@` prefix indicates file reference:

```bash
/deckrd impl @specifications/specifications.md
```

## Output

Create: `docs/.deckrd/<namespace>/<module>/implementation/implementation.md`

## Prompt & Documents

Use prompt and template for writing implementation.md

> Note:
> Implementation defines **code contracts and constraints**.
> It bridges specifications to executable code.

```bash
deckrd/assets/
       ├── prompts/implementation.prompt.md
       └── templates/implementation.template.md
```

## Script

Execute: [run-prompt.sh](../../scripts/run-prompt.sh)

```bash
bash ${CLAUDE_PLUGIN_ROOT}/scripts/run-prompt.sh impl @specifications/specifications.md [--lang <lang>] --output "implementation/implementation.md"
```

> **Note**: The `@` prefix resolves to the active module's document path:
> `docs/.deckrd/<namespace>/<module>/specifications/specifications.md`

## Session Update

After completion, update `.session.json`:

```json
{
  "current_step": "impl",
  "completed": ["init", "req", "spec", "impl"],
  "documents": {
    "requirements": "requirements.md",
    "specifications": "specifications.md",
    "implementation": "implementation.md"
  }
}
```

## Next Step

Run `tasks` to derive executable tasks from implementation plan.
