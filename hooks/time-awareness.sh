#!/usr/bin/env bash
# UserPromptSubmit hook — inject real system time so Claude can't drift.

TIME=$(date +"%A %Y-%m-%d %H:%M:%S %Z")
cat <<EOF
{"hookSpecificOutput":{"hookEventName":"UserPromptSubmit","additionalContext":"Current system time: $TIME. Use this exact value for any time/date/elapsed-time claim. Do not estimate from conversation history."}}
EOF
