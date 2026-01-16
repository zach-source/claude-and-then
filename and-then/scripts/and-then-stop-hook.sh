#!/usr/bin/env bash
# and-then-stop-hook.sh - Stop hook for the and-then task queue
# Detects task completion via <promise> tags and advances to the next task

set -euo pipefail

# State file location
QUEUE_FILE=".claude/and-then-queue.local.md"

# Exit early if no queue is active
if [[ ! -f "$QUEUE_FILE" ]]; then
    exit 0
fi

# Read hook input from stdin
HOOK_INPUT=$(cat)

# Get transcript path from hook input
TRANSCRIPT_PATH=$(echo "$HOOK_INPUT" | jq -r '.transcript_path // empty' 2>/dev/null || echo "")

if [[ -z "$TRANSCRIPT_PATH" ]] || [[ ! -f "$TRANSCRIPT_PATH" ]]; then
    echo "⚠️  And-then queue: No transcript found, allowing exit" >&2
    rm -f "$QUEUE_FILE"
    exit 0
fi

# Parse state file using Python (reliable YAML parsing)
STATE_JSON=$(python3 -c "
import yaml
import json
import sys

try:
    with open('$QUEUE_FILE', 'r') as f:
        content = f.read()

    # Extract YAML frontmatter between --- markers
    parts = content.split('---')
    if len(parts) < 2:
        print(json.dumps({'error': 'Invalid state file format'}))
        sys.exit(0)

    data = yaml.safe_load(parts[1])
    if data is None:
        print(json.dumps({'error': 'Empty YAML'}))
        sys.exit(0)

    print(json.dumps(data))
except Exception as e:
    print(json.dumps({'error': str(e)}))
" 2>/dev/null || echo '{"error": "Python parsing failed"}')

# Check for parsing errors
if echo "$STATE_JSON" | jq -e '.error' >/dev/null 2>&1; then
    ERROR=$(echo "$STATE_JSON" | jq -r '.error')
    echo "⚠️  And-then queue: State file error: $ERROR" >&2
    rm -f "$QUEUE_FILE"
    exit 0
fi

# Extract state values
CURRENT_INDEX=$(echo "$STATE_JSON" | jq -r '.current_index // 0')
TASKS_JSON=$(echo "$STATE_JSON" | jq -c '.tasks // []')
TASK_COUNT=$(echo "$TASKS_JSON" | jq 'length')

# Validate we have tasks
if [[ "$TASK_COUNT" -eq 0 ]]; then
    echo "⚠️  And-then queue: No tasks in queue" >&2
    rm -f "$QUEUE_FILE"
    exit 0
fi

# Validate current_index is numeric
if ! [[ "$CURRENT_INDEX" =~ ^[0-9]+$ ]]; then
    echo "⚠️  And-then queue: Invalid current_index, resetting" >&2
    rm -f "$QUEUE_FILE"
    exit 0
fi

# Get current task info
CURRENT_TASK=$(echo "$TASKS_JSON" | jq -r ".[$CURRENT_INDEX].prompt // empty")
CURRENT_PROMISE=$(echo "$TASKS_JSON" | jq -r ".[$CURRENT_INDEX].done_when // empty")

if [[ -z "$CURRENT_TASK" ]]; then
    echo "⚠️  And-then queue: No task at index $CURRENT_INDEX" >&2
    rm -f "$QUEUE_FILE"
    exit 0
fi

# Extract last assistant message from transcript
# Transcript is JSONL format (one JSON object per line)
LAST_OUTPUT=$(tac "$TRANSCRIPT_PATH" 2>/dev/null | while read -r line; do
    ROLE=$(echo "$line" | jq -r '.role // empty' 2>/dev/null || echo "")
    if [[ "$ROLE" == "assistant" ]]; then
        # Extract text content from message
        echo "$line" | jq -r '
            .message.content[]? |
            select(.type == "text") |
            .text // empty
        ' 2>/dev/null | head -1
        break
    fi
done)

if [[ -z "$LAST_OUTPUT" ]]; then
    # No assistant output found, re-feed current task
    echo "⚠️  And-then queue: No assistant output found" >&2
fi

# Check for completion promise in output using Perl for multiline matching
PROMISE_TEXT=""
if [[ -n "$LAST_OUTPUT" ]]; then
    PROMISE_TEXT=$(echo "$LAST_OUTPUT" | perl -0777 -pe \
        's/.*?<promise>(.*?)<\/promise>.*/$1/s; s/^\s+|\s+$//g; s/\s+/ /g' 2>/dev/null || echo "")

    # If perl didn't find a match, the output won't change, so check for the tag
    if [[ "$PROMISE_TEXT" == "$LAST_OUTPUT" ]] || ! echo "$LAST_OUTPUT" | grep -q '<promise>' 2>/dev/null; then
        PROMISE_TEXT=""
    fi
fi

# Check if promise matches current task's done_when
TASK_COMPLETE=false
if [[ -n "$PROMISE_TEXT" ]] && [[ -n "$CURRENT_PROMISE" ]]; then
    # Normalize whitespace for comparison
    NORMALIZED_PROMISE=$(echo "$PROMISE_TEXT" | tr -s ' ' | sed 's/^ *//;s/ *$//')
    NORMALIZED_EXPECTED=$(echo "$CURRENT_PROMISE" | tr -s ' ' | sed 's/^ *//;s/ *$//')

    if [[ "$NORMALIZED_PROMISE" == "$NORMALIZED_EXPECTED" ]]; then
        TASK_COMPLETE=true
        echo "✅ And-then queue: Task $((CURRENT_INDEX + 1))/$TASK_COUNT complete" >&2
    fi
fi

# Determine next action
if [[ "$TASK_COMPLETE" == true ]]; then
    NEXT_INDEX=$((CURRENT_INDEX + 1))

    # Check if queue is exhausted
    if [[ $NEXT_INDEX -ge $TASK_COUNT ]]; then
        echo "🎉 And-then queue: All $TASK_COUNT tasks complete!" >&2
        rm -f "$QUEUE_FILE"
        exit 0  # Allow session exit
    fi

    # Get next task info
    NEXT_TASK=$(echo "$TASKS_JSON" | jq -r ".[$NEXT_INDEX].prompt // empty")
    NEXT_PROMISE=$(echo "$TASKS_JSON" | jq -r ".[$NEXT_INDEX].done_when // empty")

    # Update state file with new index
    TEMP_FILE="${QUEUE_FILE}.tmp.$$"
    python3 -c "
import yaml

with open('$QUEUE_FILE', 'r') as f:
    content = f.read()

parts = content.split('---')
data = yaml.safe_load(parts[1])
data['current_index'] = $NEXT_INDEX

# Rebuild file
output = '---\n'
output += yaml.dump(data, default_flow_style=False)
output += '---\n'

with open('$TEMP_FILE', 'w') as f:
    f.write(output)
"
    mv "$TEMP_FILE" "$QUEUE_FILE"

    # Build system message for next task
    SYSTEM_MSG="📋 Task $((NEXT_INDEX + 1))/$TASK_COUNT | Output <promise>$NEXT_PROMISE</promise> when complete"

    # Block exit and feed next task
    jq -n \
        --arg prompt "$NEXT_TASK" \
        --arg msg "$SYSTEM_MSG" \
        '{
            "decision": "block",
            "reason": $prompt,
            "systemMessage": $msg
        }'
else
    # Task not complete, re-feed current task
    SYSTEM_MSG="📋 Task $((CURRENT_INDEX + 1))/$TASK_COUNT | Output <promise>$CURRENT_PROMISE</promise> when complete"

    jq -n \
        --arg prompt "$CURRENT_TASK" \
        --arg msg "$SYSTEM_MSG" \
        '{
            "decision": "block",
            "reason": $prompt,
            "systemMessage": $msg
        }'
fi
