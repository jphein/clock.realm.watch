#!/usr/bin/env bash
# UserPromptSubmit hook — inject system time only when the prompt is time-related.
# False positives cost ~25 tokens; false negatives miss grounding. Pattern errs slightly
# toward over-matching since the failure mode of missing is worse than redundant context.

LOG=${TIME_AWARENESS_LOG:-/tmp/time-awareness.log}
INPUT=$(cat)
PROMPT=$(echo "$INPUT" | jq -r '.prompt // .userPrompt // ""' 2>/dev/null)

if echo "$PROMPT" | grep -qiE '(what (time|day|date)|how long (ago|until|has|did|will)|(second|minute|hour|day|week|month|year)s? (ago|from now)|elapsed|deadline|schedule|[Ee][Tt][Aa]\b|(this|last|next) (morning|evening|afternoon|night|week|month|year)|tonight|yesterday|tomorrow|today|right now|current (time|date)|since when|time ?zone|stale|out.?of.?date)'; then
  TIME=$(date +"%A %Y-%m-%d %H:%M %Z")
  printf '{"hookSpecificOutput":{"hookEventName":"UserPromptSubmit","additionalContext":"Current system time: %s"}}\n' "$TIME"
  echo "$(date -Iseconds) UserPromptSubmit MATCH" >> "$LOG" 2>/dev/null
else
  echo "$(date -Iseconds) UserPromptSubmit skip" >> "$LOG" 2>/dev/null
fi
