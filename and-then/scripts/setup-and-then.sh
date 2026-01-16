#!/usr/bin/env bash
# setup-and-then.sh - Creates the and-then task queue state file
# Usage: setup-and-then.sh --task "task1" --promise "promise1" [--task "task2" --promise "promise2" ...]

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# State file location
QUEUE_FILE=".claude/and-then-queue.local.md"
RALPH_FILE=".claude/ralph-loop.local.md"

# Arrays to hold tasks and promises
declare -a TASKS=()
declare -a PROMISES=()

# Parse arguments
while [[ $# -gt 0 ]]; do
    case "$1" in
        --task|-t)
            if [[ -z "${2:-}" ]]; then
                echo -e "${RED}Error: --task requires a value${NC}" >&2
                exit 1
            fi
            TASKS+=("$2")
            shift 2
            ;;
        --promise|-p)
            if [[ -z "${2:-}" ]]; then
                echo -e "${RED}Error: --promise requires a value${NC}" >&2
                exit 1
            fi
            PROMISES+=("$2")
            shift 2
            ;;
        --help|-h)
            echo "Usage: setup-and-then.sh --task \"task1\" --promise \"promise1\" [--task \"task2\" --promise \"promise2\" ...]"
            echo ""
            echo "Options:"
            echo "  --task, -t      Task description/prompt"
            echo "  --promise, -p   Completion promise for the preceding task"
            echo "  --help, -h      Show this help message"
            echo ""
            echo "Example:"
            echo "  setup-and-then.sh --task \"Build API\" --promise \"API working\" --task \"Write tests\" --promise \"Tests pass\""
            exit 0
            ;;
        *)
            echo -e "${RED}Error: Unknown argument: $1${NC}" >&2
            echo "Use --help for usage information" >&2
            exit 1
            ;;
    esac
done

# Validate we have at least one task
if [[ ${#TASKS[@]} -eq 0 ]]; then
    echo -e "${RED}Error: At least one --task is required${NC}" >&2
    exit 1
fi

# Validate tasks and promises are paired
if [[ ${#TASKS[@]} -ne ${#PROMISES[@]} ]]; then
    echo -e "${RED}Error: Each --task must have a corresponding --promise${NC}" >&2
    echo -e "${RED}  Tasks: ${#TASKS[@]}, Promises: ${#PROMISES[@]}${NC}" >&2
    exit 1
fi

# Check for Ralph loop conflict
if [[ -f "$RALPH_FILE" ]]; then
    echo -e "${YELLOW}Warning: Ralph loop is active at $RALPH_FILE${NC}" >&2
    echo -e "${YELLOW}The and-then queue and Ralph loop may conflict.${NC}" >&2
    echo -e "${YELLOW}Consider canceling Ralph loop first: /cancel-ralph${NC}" >&2
fi

# Check if queue already exists
if [[ -f "$QUEUE_FILE" ]]; then
    echo -e "${YELLOW}Warning: An and-then queue already exists.${NC}" >&2
    echo -e "${YELLOW}Use /and-then-add to add tasks, or /and-then-cancel to start fresh.${NC}" >&2
    exit 1
fi

# Create .claude directory if needed
mkdir -p .claude

# Get current timestamp
TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

# Build YAML tasks array
YAML_TASKS=""
for i in "${!TASKS[@]}"; do
    # Escape quotes in task and promise
    TASK="${TASKS[$i]//\"/\\\"}"
    PROMISE="${PROMISES[$i]//\"/\\\"}"
    YAML_TASKS+="  - prompt: \"$TASK\"
    done_when: \"$PROMISE\"
"
done

# Write the state file
cat > "$QUEUE_FILE" << EOF
---
active: true
current_index: 0
started_at: "$TIMESTAMP"
tasks:
$YAML_TASKS---
EOF

# Display confirmation
echo -e "${GREEN}✓ And-then queue created with ${#TASKS[@]} task(s)${NC}"
echo ""
echo -e "${BLUE}Tasks:${NC}"
for i in "${!TASKS[@]}"; do
    echo -e "  $((i + 1)). ${TASKS[$i]}"
    echo -e "     ${YELLOW}→ done when: ${PROMISES[$i]}${NC}"
done
echo ""
echo -e "${BLUE}State file:${NC} $QUEUE_FILE"
echo ""
echo -e "${YELLOW}⚠️  IMPORTANT:${NC}"
echo -e "  • Output ${GREEN}<promise>PROMISE_TEXT</promise>${NC} when each task is complete"
echo -e "  • The session will auto-advance to the next task"
echo -e "  • Use ${BLUE}/and-then-add${NC} to add more tasks"
echo -e "  • Use ${BLUE}/and-then-cancel${NC} to stop the queue"
