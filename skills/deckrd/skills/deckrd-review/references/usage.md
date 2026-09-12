---
title: deckrd-review Usage
description: Invocation examples and when to pick each focus area
---

## deckrd-review Usage

## Examples

```bash
# Second opinion on current requirements (deckrd active module)
/deckrd:deckrd-review req

# Risk-focused review of specifications
/deckrd:deckrd-review spec --focus risk

# Completeness check on any file
/deckrd:deckrd-review @docs/design/architecture.md --focus completeness

# Consistency check on tasks
/deckrd:deckrd-review tasks --focus consistency
```

## When to Use

| Trigger                                       | Recommended focus |
| --------------------------------------------- | ----------------- |
| After `/deckrd review req` or `spec`          | `risk`            |
| Before transitioning to the next deckrd phase | (none — balanced) |
| Unclear design decision                       | `consistency`     |
| Implementation feels underspecified           | `feasibility`     |
| Edge cases feel missing                       | `completeness`    |
| An approach has failed twice                  | `feasibility`     |
