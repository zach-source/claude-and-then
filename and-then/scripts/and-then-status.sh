#!/usr/bin/env bash
# and-then-status.sh - Show current queue status

set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

QUEUE_FILE=".claude/and-then-queue.local.md"

if [[ ! -f "$QUEUE_FILE" ]]; then
    echo -e "${YELLOW}ℹ️  No active and-then queue${NC}"
    exit 0
fi

python3 << 'EOF'
import yaml

with open(".claude/and-then-queue.local.md", 'r') as f:
    content = f.read()

parts = content.split('---')
data = yaml.safe_load(parts[1])

current = data.get('current_index', 0)
tasks = data.get('tasks', [])
total = len(tasks)
started = data.get('started_at', 'unknown')

print(f"\033[0;34m📋 And-Then Queue Status\033[0m")
print(f"   Started: {started}")
print(f"   Progress: {current + 1}/{total} tasks")
print()

for i, task in enumerate(tasks):
    prompt = task.get('prompt', 'No prompt')
    done_when = task.get('done_when', 'No completion signal')

    if i < current:
        # Completed
        print(f"   \033[0;32m✓ {i + 1}. {prompt}\033[0m")
    elif i == current:
        # Current
        print(f"   \033[0;33m→ {i + 1}. {prompt}\033[0m")
        print(f"      \033[0;36mDone when: {done_when}\033[0m")
    else:
        # Pending
        print(f"   \033[0;90m○ {i + 1}. {prompt}\033[0m")

print()
print(f"\033[0;34mCommands:\033[0m")
print(f"   /and-then-add    - Add more tasks")
print(f"   /and-then-skip   - Skip current task")
print(f"   /and-then-cancel - Cancel the queue")
EOF
