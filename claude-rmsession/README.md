# claude-rmsession (`ccrm`)

Moves a Claude Code session to the macOS Trash, by session ID or by session name.
Claude Code has no built-in command for this; `claude rm` manages background
jobs, not sessions.

```bash
ccrm -l                     # list sessions: ID, last activity, name, folder
ccrm -l homelab             # filter the list (matches ID, name or project folder)
ccrm 4315242f               # remove by ID, or by a unique ID prefix
ccrm "qwen-tts-setup"       # remove by name
ccrm -n <target>            # dry run: show what would be removed
ccrm -y <target>            # skip the confirmation prompt
ccrm <target> <target> ...  # several at once
```

## What it does

- **Name** means the `/rename` title, falling back to the agent name, then the
  auto-generated title. These are the names `ccrm -l` shows. A name has to
  match exactly, but case doesn't matter.
- **If more than one session matches**, nothing is removed. It prints the
  candidates so you can pick one by ID.
- **A running session is refused.** Exit it first (`/exit`), because Claude
  Code would otherwise write the transcript straight back.
- **What gets removed:** the transcript
  `~/.claude/projects/<project>/<id>.jsonl`, plus whichever of these exist:
  `<project>/<id>/` (subagents), `~/.claude/session-env/<id>/`,
  `~/.claude/file-history/<id>/` and `~/.claude/todos/<id>*`.
- Everything goes to the **Trash** (`/usr/bin/trash`), so you can get it back
  with Put Back. Prompt history in `~/.claude/history.jsonl` is left alone.

Requires `jq`. Works with the stock macOS bash 3.2. Honors `CLAUDE_CONFIG_DIR`.

---

## Setup prompt (copy-paste into Claude Code)

```
Install the `claude-rmsession` script with a `ccrm` alias, so it can be run from anywhere.

1. Find the script source. Use `claude-rmsession/claude-rmsession` from the
   `setup-script` repo: first check the current directory, then
   ~/Learning/setup-script. If neither has it, shallow-clone
   git@github.com:rasyid7/setup-script.git into a temp dir and use the copy
   there. Read the file before installing it.

2. Make sure `jq` is installed (`command -v jq`); if not, `brew install jq`.

3. Copy (do NOT symlink) the script to ~/.local/bin/claude-rmsession
   (create ~/.local/bin if needed) and `chmod +x` it. If a file is already
   there, show me a diff and overwrite it only if they differ.

4. In ~/.zshrc:
   - Make sure ~/.local/bin is on PATH. Check for an existing *uncommented*
     line first, and only add `export PATH="$HOME/.local/bin:$PATH"` if none
     exists.
   - Add `alias ccrm='claude-rmsession'`, unless an alias called `ccrm`
     already exists. Put it under a `# claude-rmsession` comment.
   Do not duplicate lines that are already there.

5. Verify in a fresh login shell and show me the real output:
     zsh -ilc 'command -v claude-rmsession; alias ccrm; ccrm -l | head -5'
   Do NOT run a removal as part of the test. Use `ccrm -n <id>` if you want
   to show the dry run.

6. Tell me to run `source ~/.zshrc`, or open a new terminal, so the alias
   works in my current shell.
```
