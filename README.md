# clock.realm.watch

A clock for an AI that doesn't have one.

Live at **[jphein.github.io/clock.realm.watch](https://jphein.github.io/clock.realm.watch/)**.

## Why this exists

Large language models can't see your system clock. They have no `time.now()`. What they "know" about the current time is whatever happens to land in their prompt — and that's almost always nothing, or a timestamp from training data that's already months stale.

This shows up the moment you ask a model anything time-relative. *"How long ago did we ship that?"* — plausible answer, fabricated. *"Is the deploy window still open?"* — confident guess, wrong. *"What day is it?"* — depends on what the conversation history accidentally implied. A long Claude Code session that started yesterday will feel "current" to the model today, because nothing in the transcript contradicts that assumption.

You can't fix this inside the model. You have to fix it at the seams — by intercepting the moments where the model is about to read the prompt, and stitching real-world state into the context. Claude Code calls that surface "hooks." This project is what fits in that seam: a tiny, no-dependency pair of bash scripts that put the actual current time in front of Claude exactly when (and only when) it's about to need one.

The fantasy clock at the URL is a deliberate piece of branding for the technique: a thing humans look at to know what time it is, served from the same repo as the thing that tells the same to an AI. The clock is the metaphor; the hooks are the product.

## The fix

Two Claude Code hooks that put the actual time in front of the model, cheaply and only when it matters:

```
~/.claude/hooks/time-anchor.sh       SessionStart   fires once per session
~/.claude/hooks/time-awareness.sh    UserPromptSubmit fires only on time-related prompts
```

Both are bash one-liners that emit `hookSpecificOutput.additionalContext` JSON:

```json
{"hookSpecificOutput":{"hookEventName":"UserPromptSubmit","additionalContext":"Current system time: Saturday 2026-04-25 10:13 PDT"}}
```

Output gets injected into the model's context for that turn. No tool call, no API hop, no token cost on prompts that don't mention time.

## Design

**SessionStart anchor** (`time-anchor.sh`) — fires once when a session opens. Establishes a baseline so the model knows when the conversation began. ~15 tokens, one-shot.

**Gated UserPromptSubmit** (`time-awareness.sh`) — fires every prompt, but only injects when the prompt regex-matches time phrasing:

```
what time | how long (ago|until|has|did|will) | (minute|hour|day|week|month|year)s? (ago|from now)
elapsed | deadline | schedule | ETA | (this|last|next) (morning|evening|...)
tonight | yesterday | tomorrow | today | right now | current (time|date) | since when | timezone
```

Trade-offs deliberately made:

- **Minute precision, not seconds.** Almost no real query needs sub-minute resolution, and a stable-for-60-seconds prefix is much friendlier to prompt-cache hit rates.
- **Over-match on the regex.** False positives cost ~25 tokens; false negatives let the model hallucinate. The regex errs slightly toward firing more often than strictly necessary.
- **No imperative language in the injected text.** Just the bare fact (`Current system time: ...`). Telling the model "do not estimate from conversation history" tends to prime the failure mode it's trying to prevent.
- **Logs to `/tmp/time-awareness.log`.** A silently broken hook is the worst kind. Override path with `TIME_AWARENESS_LOG=/path`.

An earlier iteration injected unconditionally on every prompt. That pattern is simpler but burns ~30 tokens per turn forever and invalidates the prompt cache prefix every second. The current design is strictly Pareto-better — see `git log` for the full retrograde.

## Install

```bash
git clone https://github.com/jphein/clock.realm.watch.git
cd clock.realm.watch
ln -sf "$PWD/hooks/time-awareness.sh" ~/.claude/hooks/time-awareness.sh
ln -sf "$PWD/hooks/time-anchor.sh"    ~/.claude/hooks/time-anchor.sh
```

Then add to `~/.claude/settings.json`:

```json
{
  "hooks": {
    "SessionStart": [
      { "hooks": [{ "type": "command", "command": "bash ~/.claude/hooks/time-anchor.sh", "timeout": 5000 }] }
    ],
    "UserPromptSubmit": [
      { "hooks": [{ "type": "command", "command": "bash ~/.claude/hooks/time-awareness.sh", "timeout": 5000 }] }
    ]
  }
}
```

Symlinking (rather than copying) means edits to the repo files take effect immediately — `clock.realm.watch` is the canonical source for both files.

Verify:

```bash
echo '{"prompt":"how long ago did we ship?"}' | bash hooks/time-awareness.sh
# → {"hookSpecificOutput":{...,"additionalContext":"Current system time: ..."}}

echo '{"prompt":"refactor this function"}' | bash hooks/time-awareness.sh
# → (silent, no match)
```

## The clock UI

`index.html` is a single-file static page: live system clock with second-precision and a fantasy frame. Inline CSS, inline JS, no build step, no dependencies. Served by GitHub Pages straight from `main`.

It exists primarily to give the project a visible footprint in the browser — the hooks are the actual product, but a repo named `clock.realm.watch` should at least *show* a clock when you visit the URL.

## Versioning

This project uses [realm-sigil](https://github.com/jphein/realm-sigil) for unified versioning across the realm. Each commit deterministically generates a two-word build name (e.g. `Binary Galaxy · fd09e19`, `Quantized Impulse · 57dbc58`) keyed on the commit hash and project realm.

Regenerate `version.json` after code changes:

```bash
~/Projects/realm-sigil/static/build.sh \
  --name clock.realm.watch \
  --description "Temporal grounding for the realm" \
  --realm stellar \
  --repo https://github.com/jphein/clock.realm.watch \
  --html index.html
```

Live version always available at `version.json` next to `index.html`. The HTML page also embeds it in a `<meta name="realm-version">` tag for client-side reads without a network round-trip.

## Layout

```
clock.realm.watch/
├── index.html                  fantasy clock UI (static)
├── version.json                realm-sigil version metadata
├── hooks/
│   ├── time-anchor.sh          SessionStart hook
│   └── time-awareness.sh       UserPromptSubmit hook (gated)
├── CLAUDE.md                   instructions for Claude Code working in this repo
└── docs/superpowers/           historical spec + plan from project bootstrap
```

## See also

- [realm-sigil](https://github.com/jphein/realm-sigil) — the versioning library this project uses
- [Claude Code hooks reference](https://docs.claude.com/en/docs/claude-code/hooks) — the mechanism that makes this work
