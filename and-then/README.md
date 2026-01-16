# And-Then Plugin

A Claude Code plugin that provides a sequential task queue system. Tasks are executed one at a time, automatically advancing when each task completes.

## Installation

Add to your `.claude/plugins.json`:

```json
{
  "plugins": [
    "/path/to/z-claude-plugins/and-then"
  ]
}
```

Or symlink to your `.claude/plugins/` directory:

```bash
ln -s /path/to/z-claude-plugins/and-then ~/.claude/plugins/and-then
```

## Usage

### Create a Task Queue

```bash
/and-then --task "Build the API" --promise "API is working" \
          --task "Write tests" --promise "All tests passing" \
          --task "Update docs" --promise "Docs updated"
```

### How It Works

1. The queue is stored in `.claude/and-then-queue.local.md`
2. Claude works on the current task
3. When done, Claude outputs `<promise>COMPLETION_SIGNAL</promise>`
4. The Stop hook detects the promise and advances to the next task
5. Repeats until all tasks are complete

### Commands

| Command | Description |
|---------|-------------|
| `/and-then` | Create a new task queue |
| `/and-then-add` | Add a task to the existing queue |
| `/and-then-skip` | Skip current task, move to next |
| `/and-then-status` | Show queue progress |
| `/and-then-cancel` | Cancel the queue |

### Signaling Task Completion

For each task, output the exact promise text in XML tags:

```
<promise>API is working</promise>
```

The promise must match **exactly** (whitespace-normalized) for the task to be marked complete.

## State File Format

The queue state is stored in `.claude/and-then-queue.local.md`:

```yaml
---
active: true
current_index: 0
started_at: "2025-01-15T10:30:45Z"
tasks:
  - prompt: "Build the API"
    done_when: "API is working"
  - prompt: "Write tests"
    done_when: "All tests passing"
---
```

## License

MIT
