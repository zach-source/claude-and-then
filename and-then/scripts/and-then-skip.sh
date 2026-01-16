#!/usr/bin/env bash
# and-then-skip.sh - Skip the current task and move to the next one

set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m'

QUEUE_FILE=".claude/and-then-queue.local.md"

if [[ ! -f "$QUEUE_FILE" ]]; then
    echo -e "${RED}Error: No and-then queue active${NC}" >&2
    exit 1
fi

# Get current state and advance index
python3 -c "
import yaml
import sys

with open('$QUEUE_FILE', 'r') as f:
    content = f.read()

parts = content.split('---')
data = yaml.safe_load(parts[1])

current = data.get('current_index', 0)
tasks = data.get('tasks', [])
total = len(tasks)

if current >= total - 1:
    print(f'EXHAUSTED|{current}|{total}')
else:
    # Skip to next
    data['current_index'] = current + 1
    output = '---\n'
    output += yaml.dump(data, default_flow_style=False)
    output += '---\n'
    with open('$QUEUE_FILE', 'w') as f:
        f.write(output)
    next_task = tasks[current + 1]
    print(f'SKIPPED|{current}|{total}|{next_task[\"prompt\"]}|{next_task[\"done_when\"]}')
" | {
    IFS='|' read -r STATUS CURRENT TOTAL NEXT_TASK NEXT_PROMISE

    if [[ "$STATUS" == "EXHAUSTED" ]]; then
        echo -e "${YELLOW}⚠️  Already on the last task (${CURRENT}/${TOTAL})${NC}"
        echo -e "${YELLOW}Cannot skip - use /and-then-cancel to stop the queue${NC}"
    else
        echo -e "${GREEN}✓ Skipped task $((CURRENT + 1)), now on task $((CURRENT + 2))/${TOTAL}${NC}"
        echo -e "  ${BLUE}Next task:${NC} $NEXT_TASK"
        echo -e "  ${YELLOW}Done when:${NC} $NEXT_PROMISE"
    fi
}
