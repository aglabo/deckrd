# spec Command

<!-- textlint-disable ja-technical-writing/no-exclamation-question-mark -->
<!-- markdownlint-disable line-length -->

Derive technically verifiable behavioral goals and constraints from requirements.

## Usage

```bash
/deckrd spec
```

## Preconditions

- Session must exist with active module
- `req` must be completed for active module
- `requirements/requirements.md` must exist

## Input

Read requirements document from session's active module:

```bash
docs/.deckrd/<namespace>/<module>/requirements/requirements.md
```

The `@` prefix indicates file reference:

```bash
specifications @requirements/requirements.md
```

## Output

Create: `docs/.deckrd/<namespace>/<module>/specifications/specifications.md`

## Prompt & Documents

Use prompt and template for writing specifications.md

> Note:
> Specifications define **technical behavioral contracts**.
> They bridge requirements to implementation planning, without prescribing code structure.

```bash
deckrd/assets/
       ├── prompts/specifications.prompt.md
       └── templates/specifications.template.md
```

## Script

Execute: [run-prompt.sh](../../scripts/run-prompt.sh)

```bash
bash ${CLAUDE_PLUGIN_ROOT}/scripts/run-prompt.sh specifications @requirements/requirements.md [--lang <lang>] --output "specifications/specifications.md"
```

> **Note**:
> The `@` prefix resolves to the active module's document path:
> `docs/.deckrd/<namespace>/<module>/requirements/requirements.md`

## Session Update

After completion, update `.session.json`:

```json
{
  "current_step": "spec",
  "completed": ["init", "req", "spec"],
  "documents": {
    "requirements": "requirements.md",
    "specifications": "specifications.md"
  }
}
```

## Next Step

Run `impl` to derive implementation plan from specifications.
