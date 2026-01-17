---
description: Add tasks to an existing and-then queue
argument-hint: --task "Task" [--fork "Sub 1" "Sub 2"] [--fork --workers N ...]
allowed-tools: [Bash]
---

# Add Tasks to And-Then Queue

Add more tasks to an existing queue (even while it's running).

## Usage

```bash
# Add sequential tasks
/and-then-add --task "New task 1" --task "New task 2"

# Add parallel fork task
/and-then-add --fork "Subtask A" "Subtask B" "Subtask C"

# Mix both
/and-then-add --task "Sequential task" --fork "Parallel A" "Parallel B"
```

---

```bash
eval ${CLAUDE_PLUGIN_ROOT}/scripts/and-then-add.sh $ARGUMENTS
```
