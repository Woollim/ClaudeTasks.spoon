---
name: task-save
description: |
  This skill should be used when the user asks to "save current task", "save progress",
  "create task from context", "task-save", or wants to capture current work state.
  Usage: /task-save [query] - optional topic filter; uses full conversation context if omitted.
user-invocable: true
---

# Task Save

Capture current work state as a structured task entry using TaskCreate.

## Purpose

Transform conversation context into actionable task entries by:
1. Analyzing current conversation for work state
2. Identifying current status and pending next steps
3. Creating a concise TaskCreate entry with status and action items

## Input

- `$ARGUMENTS`: Optional topic filter. If provided, focus extraction on this topic.
- If omitted, analyze entire recent conversation.

## Output

Create a single TaskCreate with:

| Field | Format |
|-------|--------|
| **subject** | Imperative verb phrase (task goal) |
| **description** | `**Current Status**: ...`<br>`**Next Steps**: ...` |
| **activeForm** | Present continuous form (spinner display) |
| **metadata** | Optional context (e.g., `source: "slack"`, `topic: "..."`) |

## Extraction Sources

1. Conversation messages (user requests, assistant responses)
2. Tool results (Slack, Linear, file reads, etc.)
3. User's additional instructions in current message

## Rules

- Concise, actionable content only
- Single focused task per invocation
- Adapt structure to user's additional instructions if provided
- If context insufficient, ask user for clarification before creating task
