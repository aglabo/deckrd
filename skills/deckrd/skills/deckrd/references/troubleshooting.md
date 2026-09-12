---
title: Deckrd Troubleshooting
description: Common deckrd command failures, their causes, and how to recover
---

## Deckrd Troubleshooting

**Session not found**
Cause: `init` has not been run, or wrong directory.
Solution: Run `/deckrd init <project> <project-type>` first.

**Command out of order**
Cause: Trying to run `spec` before `req`, etc.
Solution: Check `/deckrd status` to see the current step, then run the correct next command.

**Gate Rule violation**
Cause: Required document from previous step is missing.
Solution: Complete the missing step before proceeding. Use `/deckrd status` to confirm.
