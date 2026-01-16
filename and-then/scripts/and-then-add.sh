#!/usr/bin/env bash
# and-then-add.sh - Add a task to an existing and-then queue
# Usage: and-then-add.sh --task "task" --promise "promise"

set -euo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m'

QUEUE_FILE=".claude/and-then-queue.local.md"

# Parse arguments
TASK=""
PROMISE=""

while [[ $# -gt 0 ]]; do
    case "$1" in
        --task|-t)
            TASK="$2"
            shift 2
            ;;
        --promise|-p)
            PROMISE="$2"
            shift 2
            ;;
        --help|-h)
            echo "Usage: and-then-add.sh --task \"task\" --promise \"promise\""
            exit 0
            ;;
        *)
            echo -e "${RED}Error: Unknown argument: $1${NC}" >&2
            exit 1
            ;;
    esac
done

# Validate inputs
if [[ -z "$TASK" ]]; then
    echo -e "${RED}Error: --task is required${NC}" >&2
    exit 1
fi

if [[ -z "$PROMISE" ]]; then
    echo -e "${RED}Error: --promise is required${NC}" >&2
    exit 1
fi

# Check queue exists
if [[ ! -f "$QUEUE_FILE" ]]; then
    echo -e "${RED}Error: No and-then queue exists.${NC}" >&2
    echo -e "${YELLOW}Use /and-then to create a queue first.${NC}" >&2
    exit 1
fi

# Add task using Python
python3 -c "
import yaml

with open('$QUEUE_FILE', 'r') as f:
    content = f.read()

parts = content.split('---')
data = yaml.safe_load(parts[1])

# Add new task
if 'tasks' not in data:
    data['tasks'] = []

data['tasks'].append({
    'prompt': '''$TASK''',
    'done_when': '''$PROMISE'''
})

# Rebuild file
output = '---\n'
output += yaml.dump(data, default_flow_style=False)
output += '---\n'

with open('$QUEUE_FILE', 'w') as f:
    f.write(output)
"

# Get updated task count
TASK_COUNT=$(python3 -c "
import yaml
with open('$QUEUE_FILE', 'r') as f:
    content = f.read()
parts = content.split('---')
data = yaml.safe_load(parts[1])
print(len(data.get('tasks', [])))
")

echo -e "${GREEN}✓ Task added to queue (now $TASK_COUNT tasks)${NC}"
echo -e "  ${BLUE}Task:${NC} $TASK"
echo -e "  ${YELLOW}Done when:${NC} $PROMISE"
