---
title: "MCP Servers API Reference"
description: "Complete API reference for MCP servers used in deckrd project"
category: "specs"
tags: ["api", "mcp", "cocoindex-code", "filesystem"]
created: "2026-01-14"
version: "0.1.0"
authors:
  - atsushifx <https://github.com/atsushifx>
changes:
  - 0.0.4   2026-01-14  Initial version
  - 0.1.0   2026-03-21  Update to cocoindex-code / filesystem
copyright:
  - Copyright (c) 2026- atsushifx <https://github.com/atsushifx>
  - This software is released under the MIT License.
  - https://opensource.org/licenses/MIT
status: "published"
---

<!-- textlint-disable
  ja-technical-writing/sentence-length,
  ja-technical-writing/no-exclamation-question-mark,
  ja-technical-writing/max-comma -->
<!-- markdownlint-disable line-length -->

## MCP Servers API Reference

## Overview

This document provides detailed API reference for the three MCP servers used in the deckrd project.

See also: [MCP Server Configuration](./mcp-servers-config.md) for setup instructions.

## serena-mcp

**Purpose**: Semantic code analysis for bash scripts

**Configuration**: `.mcp.json` → `serena-mcp`

**Memory Location**: `.serena/memories/`

### Core APIs

#### list_dir

Lists files and directories in a given directory.

**Parameters**:

- `relative_path` (string, required) - Path relative to project root
- `recursive` (boolean, required) - Whether to scan recursively
- `skip_ignored_files` (boolean, optional) - Skip gitignored files

**Example**:

```bash
serena-mcp list_dir --relative-path "plugins/deckrd" --recursive true
```

#### find_file

Finds files matching a given pattern.

**Parameters**:

- `file_mask` (string, required) - Filename or pattern (* or ?)
- `relative_path` (string, required) - Directory to search in

**Example**:

```bash
serena-mcp find_file --file-mask "*.sh" --relative-path "scripts"
```

#### search_for_pattern

Searches for regex patterns in files.

**Parameters**:

- `substring_pattern` (string, required) - Regex pattern
- `relative_path` (string, optional) - Restrict to path
- `restrict_search_to_code_files` (boolean, optional) - Code files only
- `paths_include_glob` (string, optional) - Include glob pattern
- `paths_exclude_glob` (string, optional) - Exclude glob pattern
- `context_lines_before` (number, optional) - Lines before match
- `context_lines_after` (number, optional) - Lines after match

**Example**:

```bash
serena-mcp search_for_pattern --substring-pattern "function main"
```

#### get_symbols_overview

Gets high-level overview of code symbols in a file.

**Parameters**:

- `relative_path` (string, required) - File path
- `depth` (number, optional) - Depth of child symbols (default: 0)

**Example**:

```bash
serena-mcp get_symbols_overview --relative-path "scripts/init.sh"
```

#### find_symbol

Retrieves information about symbols matching a name path pattern.

**Parameters**:

- `name_path_pattern` (string, required) - Symbol name/path pattern
- `relative_path` (string, optional) - Restrict to file/directory
- `depth` (number, optional) - Depth of descendants
- `include_body` (boolean, optional) - Include source code
- `include_info` (boolean, optional) - Include hover info
- `substring_matching` (boolean, optional) - Use substring matching

**Example**:

```bash
serena-mcp find_symbol --name-path-pattern "main" --include-body true
```

#### find_referencing_symbols

Finds references to a symbol.

**Parameters**:

- `name_path` (string, required) - Symbol name path
- `relative_path` (string, required) - File containing symbol
- `include_info` (boolean, optional) - Include hover info

**Example**:

```bash
serena-mcp find_referencing_symbols --name-path "main" --relative-path "init.sh"
```

### Editing APIs

#### replace_symbol_body

Replaces the body of a symbol.

**Parameters**:

- `name_path` (string, required) - Symbol to replace
- `relative_path` (string, required) - File containing symbol
- `body` (string, required) - New symbol body

#### insert_after_symbol

Inserts content after a symbol.

**Parameters**:

- `name_path` (string, required) - Symbol to insert after
- `relative_path` (string, required) - File containing symbol
- `body` (string, required) - Content to insert

#### insert_before_symbol

Inserts content before a symbol.

**Parameters**:

- `name_path` (string, required) - Symbol to insert before
- `relative_path` (string, required) - File containing symbol
- `body` (string, required) - Content to insert

#### rename_symbol

Renames a symbol throughout the codebase.

**Parameters**:

- `name_path` (string, required) - Symbol to rename
- `relative_path` (string, required) - File containing symbol
- `new_name` (string, required) - New symbol name

### Memory APIs

#### list_memories

Lists available project memories.

**Returns**: Array of memory filenames

#### read_memory

Reads content of a memory file.

**Parameters**:

- `memory_file_name` (string, required) - Memory filename

#### write_memory

Writes content to a memory file.

**Parameters**:

- `memory_file_name` (string, required) - Memory filename
- `content` (string, required) - Memory content

#### delete_memory

Deletes a memory file.

**Parameters**:

- `memory_file_name` (string, required) - Memory filename

#### edit_memory

Edits memory content using regex replacement.

**Parameters**:

- `memory_file_name` (string, required) - Memory filename
- `needle` (string, required) - Pattern to match
- `repl` (string, required) - Replacement text
- `mode` (string, required) - "literal" or "regex"

## lsmcp

**Purpose**: Language Server Protocol integration for TypeScript/JavaScript

**Configuration**: `.mcp.json` → `lsmcp` with `-p typescript`

**Cache Location**: `.lsmcp/`

### Core LSP APIs

#### lsp_get_hover

Gets hover information at a specific position.

**Parameters**:

- `root` (string, required) - Project root directory
- `relativePath` (string, required) - File path
- `line` (number|string, required) - Line number (1-based) or line text
- `textTarget` (string, optional) - Text to find hover info for

#### lsp_get_definitions

Gets definition(s) of a symbol.

**Parameters**:

- `root` (string, required) - Project root
- `relativePath` (string, required) - File path
- `line` (number|string, required) - Line number or text
- `symbolName` (string, required) - Symbol name
- `includeBody` (boolean, optional) - Include full body
- `before` (number, optional) - Lines before
- `after` (number, optional) - Lines after

#### lsp_find_references

Finds all references to a symbol.

**Parameters**:

- `root` (string, required) - Project root
- `relativePath` (string, required) - File path
- `line` (number|string, required) - Line number or text
- `symbolName` (string, required) - Symbol name

#### lsp_get_diagnostics

Gets diagnostics (errors, warnings) for a file.

**Parameters**:

- `root` (string, required) - Project root
- `relativePath` (string, required) - File path
- `forceRefresh` (boolean, optional) - Force refresh (default: true)
- `timeout` (number, optional) - Timeout in ms (default: 5000)

#### lsp_get_document_symbols

Gets all symbols in a document.

**Parameters**:

- `root` (string, required) - Project root
- `relativePath` (string, required) - File path

#### lsp_get_completion

Gets code completion suggestions.

**Parameters**:

- `root` (string, required) - Project root
- `relativePath` (string, required) - File path
- `line` (number|string, required) - Line number or text
- `textTarget` (string, optional) - Text at position
- `includeAutoImport` (boolean, optional) - Include auto-imports
- `resolve` (boolean, optional) - Resolve for details

#### lsp_rename_symbol

Renames a symbol across the codebase.

**Parameters**:

- `root` (string, required) - Project root
- `relativePath` (string, required) - File path
- `textTarget` (string, required) - Symbol to rename
- `newName` (string, required) - New symbol name

#### lsp_format_document

Formats an entire document.

**Parameters**:

- `root` (string, required) - Project root
- `relativePath` (string, required) - File path
- `applyChanges` (boolean, optional) - Apply formatting (default: false)
- `tabSize` (number, optional) - Tab size (default: 2)
- `insertSpaces` (boolean, optional) - Use spaces (default: true)

### Index APIs

#### search_symbols

Searches for symbols using indexed search.

**Parameters**:

- `root` (string, optional) - Project root
- `query` or `name` (string, optional) - Symbol name/pattern
- `kind` (string|array, optional) - Symbol kind(s) to filter
- `file` (string, optional) - File to search within
- `containerName` (string, optional) - Container name
- `includeChildren` (boolean, optional) - Include child symbols
- `includeExternal` (boolean, optional) - Include external libraries
- `onlyExternal` (boolean, optional) - Only external symbols
- `sourceLibrary` (string, optional) - Filter by library name

**Symbol Kinds**:

- File, Module, Namespace, Package
- Class, Method, Property, Field, Constructor
- Enum, EnumMember, Interface, Struct
- Function, Variable, Constant
- String, Number, Boolean, Array, Object
- Event, Operator, TypeParameter

#### get_symbol_details

Gets comprehensive details about a symbol.

**Parameters**:

- `root` (string, optional) - Project root
- `relativePath` (string, required) - File path
- `line` (number|string, required) - Line number or text
- `symbol` (string, required) - Symbol name

#### replace_range

Replaces a specific range of text.

**Parameters**:

- `root` (string, required) - Project root
- `relativePath` (string, required) - File path
- `startLine` (number, required) - Start line (1-based)
- `startCharacter` (number, required) - Start char (0-based)
- `endLine` (number, required) - End line (1-based)
- `endCharacter` (number, required) - End char (0-based)
- `newContent` (string, required) - Replacement content
- `preserveIndentation` (boolean, optional) - Preserve indentation

### External Library APIs

#### index_external_libraries

Indexes TypeScript declarations from node_modules.

**Parameters**:

- `root` (string, required) - Project root
- `maxFiles` (number, optional) - Max files to index (default: 5000)
- `includePatterns` (array, optional) - Glob patterns to include
- `excludePatterns` (array, optional) - Glob patterns to exclude

#### get_typescript_dependencies

Lists TypeScript dependencies available in the project.

**Parameters**:

- `root` (string, required) - Project root

#### resolve_symbol

Resolves a symbol to its definition in external libraries.

**Parameters**:

- `root` (string, required) - Project root
- `filePath` (string, required) - File containing import
- `symbolName` (string, required) - Symbol name to resolve

## codex-mcp

**Purpose**: AI-powered code generation and template processing

**Configuration**: `.mcp.json` → `codex-mcp`

### APIs

> Note: codex-mcp provides AI-powered generation APIs. Specific API methods depend on the codex-mcp version installed. Consult the codex-mcp documentation for detailed API reference.

Semantic code search. Searches code using a natural language query.

**Parameters**:

- `query` (string, required) - Search query (natural language)
- `lang` (string, optional) - Language filter

## filesystem

**Purpose**: File system access.

**Configuration**:

```json
{
  "filesystem": {
    "command": "pnpx",
    "args": ["@modelcontextprotocol/server-filesystem", "."]
  }
}
```

### APIs

#### read_file

Reads the content of the specified file.

**Parameters**:

- `path` (string, required) - File path

#### write_file

Writes content to a file.

**Parameters**:

- `path` (string, required) - File path
- `content` (string, required) - Content to write

#### list_directory

Lists the contents of a directory.

**Parameters**:

- `path` (string, required) - Directory path

#### create_directory

Creates a directory.

**Parameters**:

- `path` (string, required) - Path of the directory to create

## Usage Patterns

### Bash Script Analysis (serena-mcp)

```text
# Search code using natural language
query: "function that handles session initialization"

# Search with language filter
query: "error handling pattern"
lang: "bash"
```

### TypeScript Analysis (lsmcp)

```text
# Read a file
path: "plugins/deckrd/skills/deckrd/scripts/init.sh"

# List a directory
path: "plugins/deckrd/skills/"
```

## Performance Tips

### Token Usage

1. **Use Memories**: Cache project context in memories
2. **Symbolic Search**: Prefer `find_symbol` over full file reads
3. **Pattern Search**: Use `search_for_pattern` for quick lookups
4. **Lazy Loading**: Only load what you need

### Search Optimization

1. **Natural language queries**: cocoindex-code uses semantic understanding to find related code even when the exact keyword is unknown
2. **Language filter**: Use the `lang` parameter to narrow the search target

## Error Handling

### Common Errors

#### "File not found"

- Rephrase the query and retry
- Remove the `lang` filter to broaden the search scope

## Related Documentation

- [MCP Server Configuration](./mcp-servers-config.md) - Setup guide
- [Tool Selection Guide](../developer-guides/tool-selection.md) - When to use which tool
- [Architecture](../developer-guides/architecture.md) - System architecture
- [Development Workflow](../developer-guides/workflow.md) - Workflow integration
