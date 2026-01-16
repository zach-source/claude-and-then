---
name: and-then-add
description: Add a task to an existing and-then queue
arguments:
  - name: args
    description: Task/promise pair using --task and --promise flags
    required: true
allowed_tools:
  - Bash
---

# Add Task to And-Then Queue

Add a new task to the end of an existing task queue.

## Usage

```bash
/and-then-add --task "New task description" --promise "Completion signal"
```

## Notes

- The task is added to the **end** of the queue
- Can be used while the queue is actively running
- Requires an existing queue (use `/and-then` to create one first)

---

**Adding task to queue...**

```bash
${CLAUDE_PLUGIN_ROOT}/scripts/and-then-add.sh $ARGUMENTS
```
