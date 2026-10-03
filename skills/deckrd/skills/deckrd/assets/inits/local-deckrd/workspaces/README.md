---
title: Shared Notes Directory
description: Purpose and usage of the deckrd shared notes layer
---

## workspaces/

This directory is the **shared notes layer** of deckrd working files.

Put notes that must survive the session but belong to no single module.
Module-scoped notes go to `docs/.deckrd/<namespace>/<module>/workspaces/` instead.

- Contents are tracked by git.
- Contents are not part of the design chain: no IDs, no references from documents.
- This README is managed by deckrd. `/deckrd update --update` may overwrite it,
  so keep your notes in other files.

## What does not belong here

| Kind                                                                 | Where it goes                                   |
| -------------------------------------------------------------------- | ----------------------------------------------- |
| Checklists, phase intermediates, environment profiles, progress logs | `.local/deckrd/temp/` (never tracked)           |
| Notes about one module                                               | `docs/.deckrd/<namespace>/<module>/workspaces/` |

Anything reproducible by re-running a command belongs to the temporary layer.
Mixing it in here makes it impossible to tell what is safe to delete.

Placement rules are defined by `deckrd-rule-document-model.md`.
