#!/usr/bin/env bash
# Time-awareness hook for Claude Code.
# Fires on UserPromptSubmit. If the user's message contains time-related
# keywords, injects the real system time into Claude's context.
#
# Input: JSON on stdin with "userPrompt" field
# Output: JSON with "systemMessage" if matched, empty otherwise

INPUT=$(cat)
PROMPT=$(echo "$INPUT" | python3 -c "import sys,json; print(json.load(sys.stdin).get('userPrompt',''))" 2>/dev/null)

if echo "$PROMPT" | grep -qiE '(what time|how long ago|when did|how recent|minutes? ago|hours? ago|elapsed|schedule|deadline|[Ee][Tt][Aa]|this morning|this evening|tonight|yesterday|tomorrow|how late|time is it|time ?zone|how early|since when|time remaining|time left|how long has|how long did|how long will|how long until|current time|right now)'; then
  TIME=$(date +"%A %Y-%m-%d %H:%M:%S %Z")
  echo "{\"systemMessage\": \"Current system time: $TIME. Use this value. Do not estimate or guess the time.\"}"
fi
