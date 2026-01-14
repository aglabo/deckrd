# init Command

Initialize module directory structure and session.

## Usage

```bash
# Base directory initialization only
/deckrd init

# Full module initialization
/deckrd init [--lang <lang>] [--ai-model <model>] <namespace>/<module>
```

## Options

| Option               | Default  | Description                                                      |
| -------------------- | -------- | ---------------------------------------------------------------- |
| `--lang <lang>`      | `system` | Document language: `system`, `en`, `ja`                          |
| `--ai-model <model>` | `sonnet` | AI model: `gpt-*`, `o1-*`, `claude-*`, `haiku`, `sonnet`, `opus` |

## Example

```bash
# Base directory only (no module)
/deckrd init

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

### Without module parameter (base initialization)

1. Create base directory structure:

   ```bash
   docs/.deckrd/
   ├── notes/
   └── temp/
   ```

2. Copy template files from `assets/inits/` to `docs/.deckrd/`

### With module parameter (full initialization)

1. Create base directory structure (same as above)

2. Create module directory structure:

   ```bash
   docs/.deckrd/<namespace>/<module>/
   ├── requirements/
   ├── specifications/
   ├── implementation/
   └── tasks/
   ```

3. Initialize or update `.session.json`:

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
# Base initialization only
bash ${CLAUDE_PLUGIN_ROOT}/scripts/init-dirs.sh

# Full module initialization
bash ${CLAUDE_PLUGIN_ROOT}/scripts/init-dirs.sh [--lang <lang>] [--ai-model <model>] <namespace>/<module>
```

> **Note**: `${CLAUDE_PLUGIN_ROOT}` resolves to the plugin installation directory.
> For local projects, this is `.claude/skills/deckrd`.

## Next Step

- Without module: Base directory is ready. Run `init` again with module parameter to start a project.
- With module: Prompt user for requirements input, then run `req`.
