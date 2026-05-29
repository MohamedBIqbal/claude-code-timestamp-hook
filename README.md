# claude-code-timestamp-hook

A [Claude Code](https://docs.anthropic.com/en/docs/claude-code) hook that injects wall-clock time into every assistant turn.

## The Problem

Claude Code has **no sense of time**. Between your messages, it does not know whether 2 minutes or 2 hours have passed. It cannot see timestamps on your messages. It has no internal clock.

This causes three concrete failure modes in real engineering workflows:

### 1. Duration hallucination

When monitoring a long-running process (build, test suite, deployment, soak test), Claude will estimate elapsed time from conversational cues — and get it wrong. You ask "how's it going?" and Claude says "about 10 minutes in" when it's actually been 45 minutes. You make decisions based on fabricated numbers.

### 2. Stale process blindness

Claude launches a background build at some unknown time. You ask for a status check later. Without knowing how much time has passed, Claude cannot reason about whether the process *should* have finished. It might re-launch a duplicate, or wait indefinitely for something that crashed 30 minutes ago.

### 3. Log correlation failure

Server logs, crash reports, and metrics all have timestamps. When Claude reads `2026-05-28 09:17:01 SIGBUS`, it cannot tell you "that was 3 minutes ago" or "that was during the soak test we started at 08:36" — because it doesn't know what time it is *now*, or what time anything else happened relative to now.

## The Fix

A 6-line shell script that runs on every prompt via Claude Code's hook system. It injects the current wall-clock time (with timezone) into Claude's context as `additionalContext` and displays it in the UI status bar via `statusMessage`.

**Before:** Claude guesses. Sometimes it calls `date` manually if it remembers to. Usually it doesn't. You can't see what time Claude thinks it is.

**After:** Claude knows the current time on every turn, automatically. The timestamp is also visible to you in the status bar. No prompting required. Elapsed time calculations, log correlation, and process monitoring become reliable.

## Installation

### 1. Copy the hook

**Project-level** (recommended — scoped to one repo):
```bash
mkdir -p .claude/hooks
cp timestamp-inject.sh .claude/hooks/
chmod +x .claude/hooks/timestamp-inject.sh
```

**User-level** (applies to all projects):
```bash
mkdir -p ~/.claude/hooks
cp timestamp-inject.sh ~/.claude/hooks/
chmod +x ~/.claude/hooks/timestamp-inject.sh
```

### 2. Register in settings

Add to `.claude/settings.json` (project) or `~/.claude/settings.json` (user):

```json
{
  "hooks": {
    "UserPromptSubmit": [
      {
        "hooks": [
          {
            "type": "command",
            "command": ".claude/hooks/timestamp-inject.sh",
            "timeout": 2
          }
        ]
      }
    ]
  }
}
```

If you already have `UserPromptSubmit` hooks, add the timestamp hook to the existing `hooks` array:

```json
{
  "hooks": {
    "UserPromptSubmit": [
      {
        "hooks": [
          {
            "type": "command",
            "command": ".claude/hooks/timestamp-inject.sh",
            "timeout": 2
          },
          {
            "type": "command",
            "command": ".claude/hooks/your-other-hook.sh",
            "timeout": 5
          }
        ]
      }
    ]
  }
}
```

### 3. Verify

Restart Claude Code (or start a new session), then send any message. Claude should now be aware of the current time without you asking or it running `date`.

```bash
# Quick test outside Claude Code:
.claude/hooks/timestamp-inject.sh
# Output: {"additionalContext":"Current time: 2026-05-28 14:30:00 EDT","statusMessage":"2026-05-28 14:30:00 EDT"}
```

## How It Works

Claude Code [hooks](https://docs.anthropic.com/en/docs/claude-code/hooks) run shell commands at specific lifecycle events. The `UserPromptSubmit` event fires on every user message. The hook's JSON output supports two fields:

- **`additionalContext`** — injected into Claude's system context (invisible to user, visible to Claude)
- **`statusMessage`** — displayed in the UI status bar (visible to user)

The hook runs `date` once per prompt (~2ms) and returns the formatted timestamp in both fields. No network calls, no dependencies, no state.

## Cost

- **Latency:** ~2ms per prompt (one `date` call)
- **Tokens:** ~10 tokens per turn (`Current time: 2026-05-28 14:30:00 EDT`)
- **Dependencies:** None. POSIX `date` only.

## When This Matters Most

- Soak tests, load tests, long CI runs
- Multi-step deployments with timing constraints
- Debugging with timestamped logs or crash reports
- Any workflow where "how long has it been?" is a question you'd ask

## License

MIT
