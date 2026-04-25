#!/usr/bin/env bash
# SessionStart hook — anchor the conversation with a single timestamp at session start.
# Pairs with time-awareness.sh (UserPromptSubmit) so the model has a baseline plus
# on-demand grounding. Cheap (~15 tokens, fires once).

LOG=${TIME_AWARENESS_LOG:-/tmp/time-awareness.log}
TIME=$(date +"%A %Y-%m-%d %H:%M %Z")
printf '{"hookSpecificOutput":{"hookEventName":"SessionStart","additionalContext":"Session begins at %s."}}\n' "$TIME"
echo "$(date -Iseconds) SessionStart anchor=$TIME" >> "$LOG" 2>/dev/null
