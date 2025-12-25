# req Command

<!-- textlint-disable ja-technical-writing/no-exclamation-question-mark -->
<!-- markdownlint-disable line-length -->

Derive a normative requirements document from the user's goals, ideas, and constraints.

## Usage

```bash
/deckrd req <your requirements or goals by free-form text>
```

## Preconditions

- Session must exist with active module
- `init` must be completed for active module

## Input

User provides goals, ideas, or problem description in free-form text.

**Prompt user for:**

- What problem are you trying to solve?
- What are your goals?
- Any constraints or preferences?

## Output

Create: `docs/.deckrd/<namespace>/<module>/requirements/requirements.md`

## Prompt & Documents

use prompt,template for write requirements.md

> Note:
> Requirements documents define **normative intent and constraints**.
> Only stated requirements and constraints are normative; examples and explanations are illustrative.

```bash
deckrd/assets/
       ├── prompts/requirements.prompt.md
       └── templates/requirements.template.md
```

## Script

Execute: [run_prompt.sh](../../scripts/run-prompt.sh)

```bash
bash ${CLAUDE_PLUGIN_ROOT}/scripts/run_prompt.sh requirements <user_input> [--lang <lang>] --output "requirements/requirements.md"
```

## Session Update

After completion, update `.session.json`:

```json
{
  "current_step": "req",
  "completed": ["init", "req"],
  "documents": {
    "requirements": "requirements.md"
  }
}
```

## Next Step

Run `spec` to derive specifications from requirements.
