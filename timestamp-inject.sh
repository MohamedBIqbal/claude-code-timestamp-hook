#!/bin/bash
# Claude Code hook: injects wall-clock time into assistant context.
# Hook type: UserPromptSubmit
# Zero dependencies. ~2ms overhead per prompt.

NOW=$(date '+%Y-%m-%d %H:%M:%S %Z')
echo "{\"additionalContext\":\"Current time: ${NOW}\"}"
