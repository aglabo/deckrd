# init Command

Initialize module directory structure and session.

## Usage

```bash
/deckrd init [--lang <lang>] [--ai-model <model>] <namespace>/<module>
```

## Options

| Option               | Default  | Description                                                      |
| -------------------- | -------- | ---------------------------------------------------------------- |
| `--lang <lang>`      | `system` | Document language: `system`, `en`, `ja`                          |
| `--ai-model <model>` | `sonnet` | AI model: `gpt-*`, `o1-*`, `claude-*`, `haiku`, `sonnet`, `opus` |

## Example

```bash
# Default settings (system language, sonnet model)
/deckrd init AGTKind/isCollection

# Specify Japanese language
/deckrd init --lang ja AGTKind/isCollection

# Specify AI model
/deckrd init --ai-model claude-sonnet-4-5 AGTKind/isCollection

# Specify both language and model
/deckrd init --lang en --ai-model gpt-4o AGTKind/isCollection
```

## Actions

1. Create directory structure:

   ```bash
   docs/.deckrd/<namespace>/<module>/
   ├── requirements/
   ├── specifications/
   ├── implementation/
   └── tasks/
   ```

2. Initialize or update `.session.json`:

   ```json
   {
     "active": "<namespace>/<module>",
     "lang": "system",
     "ai_model": "sonnet",
     "created_at": "<timestamp>",
     "updated_at": "<timestamp>",
     "modules": {
       "<namespace>/<module>": {
         "current_step": "init",
         "completed": ["init"],
         "documents": {}
       }
     }
   }
   ```

## Script

Execute: [scripts/init-dirs.sh](../../scripts/init-dirs.sh)

```bash
bash ${CLAUDE_PLUGIN_ROOT}/scripts/init-dirs.sh [--lang <lang>] [--ai-model <model>] <namespace>/<module>
```

> **Note**: `${CLAUDE_PLUGIN_ROOT}` resolves to the plugin installation directory.
> For local projects, this is `.claude/skills/deckrd`.

## Next Step

After init, prompt user for requirements input, then run `req`.
