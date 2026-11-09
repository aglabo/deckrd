---
title: "Task List"
source: "{{ SOURCE }}"
task_id: "{{ TASK_ID }}"
tasks_md: "{{ TASKS_MD }}"
created: "{{ YYYY-MM-DD HH:MM:SS }}"
---

<!-- markdownlint-disable line-length -->

> This task list is orchestrator state for bdd-coder.
> Each item is one task: its `Handoff` makes exactly one checklist.
> Never pass this file to checklist-builder or bdd-coder. Pass only the `Handoff` of one item.

<!--
source:   tasks | natural-language
task_id:  Target ID (T-XX) when source is tasks; "-" otherwise
tasks_md: path to tasks.md when source is tasks; "-" otherwise
Status:   pending | needs-split (<reason>) | done
-->

## Items

- [ ] **L-01**: {{ ITEM_TITLE }}
  - Target: `{{ TARGET_NAME }}`
  - Handoff: {{ HANDOFF }}
  - Depends-on: {{ DEPENDS_ON }}
  - Status: {{ STATUS }}
