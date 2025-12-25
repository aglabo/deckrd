# init Command

Initialize module directory structure and session.

## Usage

```bash
/deckrd init [--lang <lang>] <namespace>/<module>
```

## Options

| Option          | Default  | Description                             |
| --------------- | -------- | --------------------------------------- |
| `--lang <lang>` | `system` | Document language: `system`, `en`, `ja` |

## Example

```bash
# Default language (system)
/deckrd init AGTKind/isCollection

# Specify Japanese
/deckrd init --lang ja AGTKind/isCollection

# Specify English
/deckrd init --lang en AGTKind/isCollection
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

Execute: [scripts/init-docs.sh](../../scripts/init-docs.sh)

```bash
bash ${CLAUDE_PLUGIN_ROOT}/scripts/init-docs.sh [--lang <lang>] <namespace>/<module>
```

> **Note**: `${CLAUDE_PLUGIN_ROOT}` resolves to the plugin installation directory.
> For local projects, this is `.claude/skills/deckrd`.

## Next Step

After init, prompt user for requirements input, then run `req`.
