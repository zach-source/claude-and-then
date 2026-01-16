---
name: and-then
description: Create a sequential task queue that auto-advances when each task completes
arguments:
  - name: args
    description: Task/promise pairs using --task and --promise flags
    required: true
allowed_tools:
  - Bash
---

# And-Then Task Queue

Execute a series of tasks sequentially, automatically advancing to the next task when you complete the current one.

## Usage

```bash
/and-then --task "Task 1 description" --promise "Completion signal 1" \
          --task "Task 2 description" --promise "Completion signal 2"
```

## How It Works

1. Creates a task queue in `.claude/and-then-queue.local.md`
2. You work on the current task
3. When done, output `<promise>COMPLETION_SIGNAL</promise>`
4. The session automatically advances to the next task
5. Repeats until all tasks are complete

## Signaling Completion

For each task, output the exact promise text in XML tags:

```
<promise>Completion signal 1</promise>
```

The promise must match **exactly** (whitespace-normalized) for the task to be marked complete.

## Managing the Queue

- `/and-then-add` - Add more tasks to the queue
- `/and-then-skip` - Skip current task, move to next
- `/and-then-status` - Show current queue status
- `/and-then-cancel` - Clear the queue and exit

## Example

```bash
/and-then --task "Create a REST API endpoint for users" --promise "API endpoint created" \
          --task "Write unit tests for the endpoint" --promise "Tests passing" \
          --task "Update API documentation" --promise "Docs updated"
```

---

**Setting up the task queue...**

```bash
${CLAUDE_PLUGIN_ROOT}/scripts/setup-and-then.sh $ARGUMENTS
```

Once the queue is created, I'll begin working on the first task. When I complete it, I'll output the completion promise and automatically move to the next task.
